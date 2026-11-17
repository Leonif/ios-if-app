#!/usr/bin/env python3
"""IF24 release pipeline: from a clean tree to a build waiting in App Store Connect.

    ./release/release.py all --version 1.5.1 --dry-run
    ./release/release.py all --version 1.5.1

Steps, each also runnable on its own:

    version    create the App Store version if it is not there yet
    metadata   push What's New and promotional text for every locale in PACK_TO_ASC
    archive    xcodebuild archive + exportArchive, signed for distribution
    upload     send the .ipa and wait for App Store Connect to finish processing
    attach     bind the processed build to the version
    status     print where the release currently stands

One more step runs only on its own, never as part of `all`:

    screenshots  replace the 6.7" iPhone screenshot set of every locale

There is no submit step, and adding one is not an oversight to be corrected. The
owner presses Submit for Review; the pipeline stops one step short of it on
purpose.

Signing needs no keychain password. The archive is signed with the development
identity already in the keychain, and `-exportArchive` re-signs with the team's
cloud-managed Apple Distribution certificate, whose private key lives on Apple's
side — reached through `-allowProvisioningUpdates` and the ASC API key. Verified
20.08.2026; see ARCHITECTURE.md, section "Конвейер релиза".
"""

from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import re
import zipfile
import shutil
import struct
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    import asc as ascmod
    import store_pack
except ImportError as exc:                       # pragma: no cover
    sys.exit(f"missing dependency: {exc}\n"
             "  pip3 install -r release/requirements.txt")

REPO = Path(__file__).resolve().parent.parent
PROJECT = REPO / "IFApp.xcodeproj"
SCHEME = "IFApp"
DEFAULT_PACK = (REPO.parent / "wiki/raw/2026-08-18_store-pack-1.5.1.md")
# The screenshot set is not tied to one release the way a store pack is, but the
# default still is: it was made for 1.5.3, and any other version has to name its
# set with --shots.
DEFAULT_SHOTS = (REPO.parent / "wiki/raw/2026-11-15_screenshots-IF-77-final")
DEFAULT_SHOTS_VERSION = "1.5.3"
SHOT_SIZE = (1290, 2796)
SHOT_NAMES = [f"{i:02d}.png" for i in range(1, 6)]
SHOT_WAIT_SECONDS = 600
WORK = Path("/tmp/if24-release")
DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer"


# --- output ---------------------------------------------------------------

def say(msg):    print(f"  {msg}")
def step(msg):   print(f"\n== {msg}")
def ok(msg):     print(f"  OK  {msg}")
def warn(msg):   print(f"  !!  {msg}")


def die(msg, code=1):
    print(f"\nFAILED: {msg}", file=sys.stderr)
    sys.exit(code)


def run(cmd, **kw):
    env = dict(kw.pop("env", None) or __import__("os").environ)
    env["DEVELOPER_DIR"] = DEVELOPER_DIR
    say("$ " + " ".join(str(c) for c in cmd[:6]) + (" ..." if len(cmd) > 6 else ""))
    return subprocess.run(cmd, env=env, **kw)


# --- preflight ------------------------------------------------------------

def git_state():
    head = subprocess.run(["git", "-C", REPO, "rev-parse", "--abbrev-ref", "HEAD"],
                          capture_output=True, text=True).stdout.strip()
    dirty = subprocess.run(["git", "-C", REPO, "status", "--porcelain"],
                           capture_output=True, text=True).stdout.strip()
    sha = subprocess.run(["git", "-C", REPO, "rev-parse", "--short", "HEAD"],
                         capture_output=True, text=True).stdout.strip()
    return head, sha, dirty


RELEASE_BASE = "current-release"
# The only file a release commit may change on top of current-release: the
# version bump. 16.11.2026 1.5.3 (3) was archived from a stale release branch with
# a cherry-pick on it and shipped without the IF-91 splash that current-release had.
BUMP_FILES = {"IFApp.xcodeproj/project.pbxproj"}


def _git(*a):
    return subprocess.run(["git", "-C", REPO, *a], capture_output=True, text=True)


def check_release_base(args):
    """A release is archived from current-release (plus the version bump), nothing else."""
    if args.allow_any_base:
        warn(f"--allow-any-base: NOT checking that HEAD is {RELEASE_BASE}")
        return
    if _git("status", "--porcelain").stdout.strip():
        msg = (f"uncommitted changes would go into the archive unchecked; the "
               f"{RELEASE_BASE} check needs a clean tree (or --allow-any-base)")
        if args.dry_run:
            warn(msg)
        else:
            die(msg)
    if _git("fetch", "-q", "origin", RELEASE_BASE).returncode != 0:
        die(f"git fetch origin {RELEASE_BASE} failed - cannot check the release base")
    behind = _git("rev-list", "--count", f"{RELEASE_BASE}..origin/{RELEASE_BASE}").stdout.strip()
    if behind != "0":
        die(f"local {RELEASE_BASE} is {behind or '?'} commit(s) behind origin. Pull it first.")
    if _git("merge-base", "--is-ancestor", RELEASE_BASE, "HEAD").returncode != 0:
        die(f"HEAD does not contain {RELEASE_BASE}. A release is archived from "
            f"{RELEASE_BASE} after every branch is merged into it - not from a "
            "feature or an old release branch, and not with cherry-picks.")
    changed = set(_git("diff", "--name-only", RELEASE_BASE, "HEAD").stdout.split())
    extra = sorted(changed - BUMP_FILES)
    if extra:
        die(f"HEAD changes more than the version bump on top of {RELEASE_BASE}: "
            + ", ".join(extra) + f". Merge that work into {RELEASE_BASE} first.")
    diff = _git("diff", "-U0", RELEASE_BASE, "HEAD", "--", *BUMP_FILES).stdout.splitlines()
    foreign = [l for l in diff if l[:1] in "+-" and not l.startswith(("+++", "---"))
               and not re.search(r"\b(MARKETING_VERSION|CURRENT_PROJECT_VERSION) = ", l)]
    if foreign:
        die(f"the project file changes more than the version on top of {RELEASE_BASE}: "
            f"{foreign[0].strip()[:120]}")
    ok(f"release base: {RELEASE_BASE}" + (" + version bump" if changed else ""))


def preflight(args):
    step("Preflight")
    head, sha, dirty = git_state()
    say(f"branch {head} at {sha}")
    if dirty:
        n = len(dirty.splitlines())
        if args.allow_dirty or args.dry_run:
            why = "dry run" if args.dry_run and not args.allow_dirty else "--allow-dirty"
            warn(f"working tree has {n} uncommitted change(s) — continuing ({why})")
        else:
            die(f"working tree has {n} uncommitted change(s). "
                "A shipped build must match a commit you can go back to. "
                "Commit them, or pass --allow-dirty if you mean it.")
    else:
        ok("working tree clean")
    if args.step in ("all", "archive") and not args.ipa:
        check_release_base(args)
    if not ascmod.KEY_PATH.exists():
        die(f"App Store Connect key not found at {ascmod.KEY_PATH}")
    ok(f"API key {ascmod.KEY_ID}")
    return sha


# --- steps ----------------------------------------------------------------

EDITABLE_STATES = ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED",
                   "REJECTED", "METADATA_REJECTED", "INVALID_BINARY")


def step_version(client, args):
    step(f"App Store version {args.version}")
    v = client.find_version(args.version)
    if v:
        state = v["attributes"]["appStoreState"]
        ok(f"already exists: {v['id']} ({state})")
        if state not in EDITABLE_STATES:
            warn(f"state is {state} — metadata may be read-only until it returns "
                 "to PREPARE_FOR_SUBMISSION")
        return v["id"]
    say(f"creating {args.version} (IOS)")
    created = client.create_version(args.version)
    ok(f"created {created['id']}")
    return created["id"]


def step_metadata(client, args, version_id):
    step("Localised metadata")
    pack_path = Path(args.pack)
    if not pack_path.exists():
        die(f"store pack not found: {pack_path}\n"
            "  The default lives in the wiki repo next to this one. If you are "
            "working from a lone clone of ios-if-app, pass --pack explicitly.")
    # A store pack is written for one release. The default path is pinned to a
    # filename, so releasing 1.6.0 without --pack would otherwise push 1.5.1's
    # text — and the read-back check would confirm it, because it compares against
    # what was sent, not against the version.
    if args.version not in pack_path.name:
        die(f"store pack {pack_path.name!r} does not name version {args.version}. "
            "Pass the pack for this release with --pack, or rename it.")

    try:
        pack = store_pack.load(args.pack)
    except ValueError as exc:
        die(str(exc))
    say(f"store pack: {pack_path.name} — {len(pack)} locales")

    existing = {} if client.dry_run and version_id == "dry-run-id" \
        else client.localizations(version_id)
    if existing:
        say(f"version already carries: {', '.join(sorted(existing))}")

    unmapped = sorted(l for l in pack if l not in ascmod.PACK_TO_ASC)
    if unmapped:
        die(f"store pack has locales with no App Store Connect mapping: {unmapped}. "
            "Add them to PACK_TO_ASC in release/asc.py.")
    # And the other direction. A locale in the table but missing from the pack is
    # simply never written — which, on a draft that starts with every existing
    # localization empty, ships that market a blank What's New. Silent, and exactly the
    # failure the read-back check cannot see.
    uncovered = sorted(set(ascmod.PACK_TO_ASC) - set(pack))
    if uncovered:
        die(f"store pack is missing locales the app ships: {uncovered}. "
            "A draft version starts with every locale empty, so a locale left out "
            "here reaches the store blank.")

    # A locale the listing has never had needs more than this step writes: name
    # and subtitle live on appInfoLocalizations, keywords, description and
    # screenshots on the version, and none of them come from the store pack. The
    # step still creates the version localization — that is what puts the locale
    # on the version — but says out loud what is left, so a green run is not
    # mistaken for a submittable one.
    listing = client.app_info_locales()
    new_to_store = sorted(ascmod.PACK_TO_ASC[l] for l in pack
                          if ascmod.PACK_TO_ASC[l] not in listing)

    touched = {}
    for pack_locale, fields in sorted(pack.items()):
        asc_locale = ascmod.PACK_TO_ASC[pack_locale]
        tag = pack_locale if pack_locale == asc_locale else f"{pack_locale} -> {asc_locale}"
        loc = existing.get(asc_locale)
        if loc:
            say(f"{tag}: patch (whatsNew {len(fields['whatsNew'])}, "
                f"promo {len(fields['promotionalText'])})")
            client.update_localization(loc["id"], **fields)
        else:
            new = " — NEW to the store" if asc_locale in new_to_store else ""
            say(f"{tag}: create (whatsNew {len(fields['whatsNew'])}, "
                f"promo {len(fields['promotionalText'])}){new}")
            try:
                client.create_localization(version_id, asc_locale, **fields)
            except ascmod.ASCError as exc:
                die(f"{asc_locale}: could not create the version localization.\n"
                    f"  Locales before it in this run are already written; "
                    f"re-running `metadata` is safe, it patches them again.\n{exc}")
        touched[asc_locale] = fields

    def owner_todo():
        if not new_to_store:
            return
        warn(f"new to the store: {', '.join(new_to_store)}. This step wrote only "
             "What's New and promotional text. Still the owner's, in App Store "
             "Connect, before Submit:")
        say("      App Information: name (required), subtitle")
        say("      the version: keywords, description (required); "
            "screenshots: release.py screenshots")

    if client.dry_run:
        ok(f"{len(touched)} locales would be written")
        owner_todo()
        return

    # Read back rather than trust the 200s. A PATCH that lands on the wrong locale
    # still answers 200, and the whole point of the mapping table above is that
    # such a mistake is invisible from the response alone.
    after = client.localizations(version_id)
    bad = []
    for locale, fields in touched.items():
        got = after.get(locale)
        if not got:
            bad.append(f"{locale}: not present after write")
            continue
        for field, want in fields.items():
            if (got["attributes"].get(field) or "").strip() != want.strip():
                bad.append(f"{locale}.{field}: readback differs from what was sent")
    if bad:
        die("metadata verification failed:\n  " + "\n  ".join(bad))
    ok(f"{len(touched)} locales written and read back identical")
    owner_todo()


def _build_numbers(builds) -> list[int]:
    out = []
    for b in builds:
        try:
            out.append(int(b["attributes"]["version"]))
        except (TypeError, ValueError):
            pass
    return out


def _train_numbers(client, version_string: str) -> list[int]:
    """Build numbers already uploaded under one marketing version.

    App Store Connect numbers builds per marketing version, not per account: the
    1.5.0 train holds 1, 2, 3 and the 1.5.1 train starts again at 1. Both the next
    free number and the last used one are read from this train and nowhere else.
    """
    return _build_numbers(client.get_all("/builds", **{
        "filter[app]": ascmod.APP_ID,
        "filter[preReleaseVersion.version]": version_string,
        "fields[builds]": "version,processingState,uploadedDate",
    }))


def next_build_number(client, version_string: str) -> str:
    """The number the *next* archive should carry, inside this version's train.

    Counted over the train, not over the account. A global "highest plus one"
    would have handed the first 1.5.1 archive a 7 where the owner's manual build
    got a 2, leaving an unexplainable 2..6 hole in the train. Nothing would break
    — `find_build` matches on the pair — but the next reader could not tell
    whether five builds went missing.
    """
    nums = _train_numbers(client, version_string)
    return str((max(nums) if nums else 0) + 1)


def build_number_from_ipa(ipa: Path) -> tuple[str, str]:
    """(marketing version, build number) as actually baked into the .ipa.

    Asking App Store Connect what number to use for a build that has not been
    uploaded yet can only ever be a guess. The file knows.
    """
    with zipfile.ZipFile(ipa) as z:
        names = [n for n in z.namelist()
                 if n.startswith("Payload/") and n.endswith(".app/Info.plist")
                 and n.count("/") == 2]
        if not names:
            die(f"{ipa} has no Payload/*.app/Info.plist — is it an .ipa?")
        info = plistlib.loads(z.read(names[0]))
    return info["CFBundleShortVersionString"], info["CFBundleVersion"]


def uploaded_build_number(client, version_string: str) -> str | None:
    """The highest build already uploaded for this marketing version.

    Not `next_build_number` minus one. `attach` and a standalone `upload` operate
    on a build that already exists, and asking for "the next one" there hands them
    a number nothing was ever uploaded under — which is how the documented
    "re-run attach later" recovery would have failed every time.
    """
    nums = _train_numbers(client, version_string)
    return str(max(nums)) if nums else None


def export_options(path: Path):
    opts = {
        "method": "app-store-connect",
        "teamID": ascmod.TEAM_ID,
        "signingStyle": "automatic",
        "destination": "export",
        "uploadSymbols": True,
        "manageAppVersionAndBuildNumber": False,
    }
    path.write_bytes(plistlib.dumps(opts))
    return path


def step_archive(args, build_number):
    step(f"Archive {args.version} ({build_number})")
    WORK.mkdir(parents=True, exist_ok=True)
    archive = WORK / f"IFApp-{args.version}-{build_number}.xcarchive"
    export_dir = WORK / f"export-{args.version}-{build_number}"

    if args.dry_run:
        say(f"[dry-run] would archive to {archive}")
        say(f"[dry-run] would export .ipa to {export_dir}")
        say("[dry-run] the export would be re-signed with the cloud-managed "
            "Apple Distribution certificate")
        return export_dir / "IFApp.ipa"

    if archive.exists():
        shutil.rmtree(archive)
    if export_dir.exists():
        shutil.rmtree(export_dir)

    auth = ["-allowProvisioningUpdates",
            "-authenticationKeyPath", str(ascmod.KEY_PATH),
            "-authenticationKeyID", ascmod.KEY_ID,
            "-authenticationKeyIssuerID", ascmod.ISSUER_ID]

    # Version numbers are passed as build-setting overrides rather than written
    # into project.pbxproj. The project file is the owner's to edit in Xcode, and
    # a release script that rewrites it would be editing the one file where a
    # mistake is both expensive and slow to notice.
    r = run(["xcodebuild", "archive",
             "-project", str(PROJECT), "-scheme", SCHEME,
             "-configuration", "Release",
             "-destination", "generic/platform=iOS",
             "-archivePath", str(archive),
             *auth,
             f"MARKETING_VERSION={args.version}",
             f"CURRENT_PROJECT_VERSION={build_number}"])
    if r.returncode != 0:
        die("xcodebuild archive failed (see output above)")
    ok(f"archived: {archive}")

    plist = export_options(WORK / "ExportOptions.plist")
    r = run(["xcodebuild", "-exportArchive",
             "-archivePath", str(archive),
             "-exportPath", str(export_dir),
             "-exportOptionsPlist", str(plist),
             *auth])
    if r.returncode != 0:
        die("xcodebuild -exportArchive failed. The distribution signature is not "
            "taken from the archive and not from the local keychain: "
            "-allowProvisioningUpdates plus the API key above ask Apple to sign "
            "with the team's cloud-managed Apple Distribution certificate. So the "
            "usual causes are the key losing its Certificates/Identifiers/Profiles "
            "access, or no network — not a missing local identity, and not "
            "CODE_SIGN_IDENTITY in project.pbxproj. See ARCHITECTURE.md, section "
            "\"Конвейер релиза\". Do not edit project.pbxproj by hand.")

    ipas = list(export_dir.glob("*.ipa"))
    if not ipas:
        die(f"export produced no .ipa in {export_dir}")
    ok(f"exported: {ipas[0]} ({ipas[0].stat().st_size // 1024 // 1024} MB)")
    return ipas[0]


def step_upload(client, args, ipa: Path, build_number: str):
    step("Upload to App Store Connect")
    if args.dry_run:
        say(f"[dry-run] would upload {ipa}")
        say("[dry-run] would then poll until processing leaves PROCESSING")
        return None

    r = run(["xcrun", "altool", "--upload-app", "-f", str(ipa), "-t", "ios",
             "--apiKey", ascmod.KEY_ID, "--apiIssuer", ascmod.ISSUER_ID])
    if r.returncode != 0:
        die("altool --upload-app failed (see output above)")
    ok("uploaded; App Store Connect is now processing it")

    # Processing is minutes, not seconds, and the build does not appear in the API
    # the instant altool returns.
    deadline = time.time() + args.wait_minutes * 60
    build = None
    while time.time() < deadline:
        build = client.find_build(args.version, build_number)
        if build:
            state = build["attributes"]["processingState"]
            say(f"build {args.version} ({build_number}): {state}")
            if state == "VALID":
                ok(f"processed: {build['id']}")
                return build
            if state in ("INVALID", "FAILED"):
                die(f"App Store Connect rejected the build: {state}. "
                    "The reason arrives by email and is not in the API.")
        else:
            say("build not visible in the API yet...")
        time.sleep(30)
    die(f"build did not finish processing within {args.wait_minutes} min. "
        f"Processing continues on Apple's side — re-run `attach` later.")


def step_attach(client, args, version_id, build_number):
    step("Attach build to version")
    if args.dry_run:
        say(f"[dry-run] would attach build {build_number} to version {args.version}")
        return
    build = client.find_build(args.version, build_number)
    if not build:
        die(f"no build {args.version} ({build_number}) in App Store Connect")
    if build["attributes"]["processingState"] != "VALID":
        die(f"build is {build['attributes']['processingState']}, not VALID — "
            "cannot attach yet")
    client.attach_build(version_id, build["id"])
    got = client.version_build(version_id)
    if not got or got["id"] != build["id"]:
        die("attach reported success but the version does not carry the build")
    ok(f"version {args.version} now carries build {build_number}")


def png_info(path: Path) -> tuple[int, int, bool]:
    """(width, height, has alpha) read from the PNG header, no imaging library.

    Alpha is colour type 4 or 6, or a tRNS chunk before the image data — App Store
    Connect rejects either.
    """
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        die(f"{path} is not a PNG")
    width, height, _, colour = struct.unpack(">IIBB", data[16:26])
    alpha = colour in (4, 6)
    pos = 8
    while pos + 8 <= len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        if kind == b"tRNS":
            alpha = True
        if kind in (b"IDAT", b"IEND"):
            break
        pos += 12 + length
    return width, height, alpha


def load_shots(args) -> dict:
    """{asc locale: [(path, size, md5), ...] in 01..05 order}, every file checked.

    Nothing here talks to App Store Connect, so it runs in full on a dry run too.
    """
    shots_dir = Path(args.shots) if args.shots else DEFAULT_SHOTS
    if not args.shots and args.version != DEFAULT_SHOTS_VERSION:
        die(f"the default screenshot set {DEFAULT_SHOTS.name} was made for "
            f"{DEFAULT_SHOTS_VERSION}, not {args.version}. Name the set for this "
            "release with --shots, even if it is the same folder.")
    if not shots_dir.is_dir():
        die(f"screenshot set not found: {shots_dir}\n"
            "  The default lives in the wiki repo next to this one. If you are "
            "working from a lone clone of ios-if-app, pass --shots explicitly.")

    if set(ascmod.SHOTS_TO_ASC.values()) != set(ascmod.PACK_TO_ASC.values()):
        die("SHOTS_TO_ASC and PACK_TO_ASC in release/asc.py name different "
            "App Store Connect locales. Fix the tables, not the run.")

    folders = sorted(d.name for d in shots_dir.iterdir() if d.is_dir())
    unknown = sorted(set(folders) - set(ascmod.SHOTS_TO_ASC))
    missing = sorted(set(ascmod.SHOTS_TO_ASC) - set(folders))
    if unknown:
        die(f"{shots_dir.name} has folders with no App Store Connect mapping: "
            f"{unknown}. Add them to SHOTS_TO_ASC in release/asc.py.")
    if missing:
        die(f"{shots_dir.name} is missing locales the app ships: {missing}.")

    bad, out = [], {}
    for folder in sorted(ascmod.SHOTS_TO_ASC):
        pngs = sorted(p.name for p in (shots_dir / folder).glob("*.png"))
        if pngs != SHOT_NAMES:
            bad.append(f"{folder}: has {pngs or 'no PNG'}, want exactly "
                       f"{SHOT_NAMES[0]}..{SHOT_NAMES[-1]}")
            continue
        files = []
        for name in SHOT_NAMES:
            path = shots_dir / folder / name
            w, h, alpha = png_info(path)
            if (w, h) != SHOT_SIZE:
                bad.append(f"{folder}/{name}: {w}x{h}, want "
                           f"{SHOT_SIZE[0]}x{SHOT_SIZE[1]}")
            if alpha:
                bad.append(f"{folder}/{name}: has an alpha channel")
            data = path.read_bytes()
            files.append((path, len(data), hashlib.md5(data).hexdigest()))
        out[ascmod.SHOTS_TO_ASC[folder]] = files
    if bad:
        die("screenshot set failed preflight:\n  " + "\n  ".join(bad))
    ok(f"{shots_dir.name}: {len(out)} locales x {len(SHOT_NAMES)}, "
       f"{SHOT_SIZE[0]}x{SHOT_SIZE[1]} PNG, no alpha")
    return out


def _replace_shot_set(client, loc_id: str, asc_locale: str, files) -> str:
    """Empty the locale's 6.7" set and fill it with `files`. Returns the set id."""
    shot_set = client.screenshot_set(loc_id)
    set_id = shot_set["id"] if shot_set else \
        client.create_screenshot_set(loc_id)["id"]
    # Emptied first: a set holds at most ten, and a re-run after a half-finished
    # one must not end up with the old frames plus the new.
    for old in client.screenshots(set_id):
        client.delete_screenshot(old["id"])

    ids = []
    for path, size, md5 in files:
        data = path.read_bytes()
        if hashlib.md5(data).hexdigest() != md5:
            die(f"{path} changed since preflight")
        shot = client.reserve_screenshot(set_id, f"{asc_locale}-{path.name}", size)
        client.upload_parts(shot["attributes"]["uploadOperations"], data)
        client.commit_screenshot(shot["id"], md5)
        ids.append(shot["id"])

    # Apple processes each image after the commit. Ordering waits for that, so a
    # FAILED delivery stops here instead of being sorted into place.
    deadline = time.time() + SHOT_WAIT_SECONDS
    pending = set(ids)
    while pending:
        for shot_id in sorted(pending):
            state = (client.screenshot(shot_id)["attributes"]
                     .get("assetDeliveryState") or {})
            if state.get("state") == "COMPLETE":
                pending.discard(shot_id)
            elif state.get("state") == "FAILED":
                die(f"{asc_locale}: App Store Connect rejected a screenshot: "
                    f"{state.get('errors')}")
        if pending and time.time() > deadline:
            die(f"{asc_locale}: {len(pending)} screenshot(s) not COMPLETE after "
                f"{SHOT_WAIT_SECONDS // 60} min")
        if pending:
            time.sleep(5)

    client.order_screenshots(set_id, ids)
    return set_id


def step_screenshots(client, args):
    step(f"Screenshots for {args.version} ({ascmod.SCREENSHOT_DISPLAY_TYPE})")
    shots = load_shots(args)

    # Read-only from here until the plan is printed. The version and its
    # localizations come from `version` and `metadata`; this step creates neither.
    blockers, locs = [], {}
    v = client.find_version(args.version)
    if not v:
        blockers.append(f"version {args.version} does not exist in App Store "
                        "Connect yet. Run `version` and `metadata` first.")
    else:
        state = v["attributes"]["appStoreState"]
        say(f"version {v['id']} ({state})")
        if state not in EDITABLE_STATES:
            blockers.append(f"version is {state}; screenshots are read-only "
                            "until it returns to PREPARE_FOR_SUBMISSION.")
        locs = client.localizations(v["id"])
        absent = sorted(set(shots) - set(locs))
        if absent:
            blockers.append(f"the version has no localization for {absent}. "
                            "Run `metadata` first — it creates them.")
    if blockers and not args.dry_run:
        die("\n  ".join(blockers))

    for asc_locale, files in sorted(shots.items()):
        loc = locs.get(asc_locale)
        shot_set = client.screenshot_set(loc["id"]) if loc else None
        old = client.screenshots(shot_set["id"]) if shot_set else []
        where = (f"set {shot_set['id']}" if shot_set
                 else "new set" if loc else "no localization yet")
        say(f"{asc_locale}: {where} — replace {len(old)} with {len(files)}")
        for path, size, md5 in files:
            say(f"    {path.parent.name}/{path.name}  {size:>9,} B  md5 {md5}")

    if args.dry_run:
        n = sum(len(f) for f in shots.values())
        ok(f"{len(shots)} locales, {n} files would be uploaded")
        for b in blockers:
            warn(f"a real run would stop here: {b}")
        return

    done = {}
    for asc_locale, files in sorted(shots.items()):
        try:
            done[asc_locale] = _replace_shot_set(
                client, locs[asc_locale]["id"], asc_locale, files)
        except ascmod.ASCError as exc:
            die(f"{asc_locale}: {exc}\n  Re-running `screenshots` is safe: it "
                "empties the set and uploads again.")
        ok(f"{asc_locale}: {len(files)} uploaded")

    # Read back through a fresh lookup of the set, not the ids collected above.
    step("Screenshots read back")
    bad = []
    say(f"{'locale':<8} {'count':>5}  {'order':<20} state")
    for asc_locale, files in sorted(shots.items()):
        shot_set = client.screenshot_set(locs[asc_locale]["id"])
        got = client.screenshots(shot_set["id"]) if shot_set else []
        names = [(g["attributes"].get("fileName") or "?").rsplit("-", 1)[-1][:2]
                 for g in got]
        states = {(g["attributes"].get("assetDeliveryState") or {}).get("state")
                  for g in got}
        sums = [g["attributes"].get("sourceFileChecksum") for g in got]
        say(f"{asc_locale:<8} {len(got):>5}  {' '.join(names):<20} "
            f"{','.join(sorted(s or '?' for s in states))}")
        if len(got) != len(files):
            bad.append(f"{asc_locale}: {len(got)} screenshots, want {len(files)}")
        if names != [p.name[:2] for p, _, _ in files]:
            bad.append(f"{asc_locale}: order {names}")
        if states != {"COMPLETE"}:
            bad.append(f"{asc_locale}: states {sorted(s or '?' for s in states)}")
        if sums != [m for _, _, m in files]:
            bad.append(f"{asc_locale}: checksums differ from the files sent")
    if bad:
        die("screenshot verification failed:\n  " + "\n  ".join(bad))
    ok(f"{len(shots)} locales x {len(SHOT_NAMES)} read back: count, order, "
       "state and checksum match")


def step_status(client, args):
    step(f"Status of {args.version}")
    v = client.find_version(args.version)
    if not v:
        say("version does not exist in App Store Connect yet")
        return
    say(f"version {v['id']} — {v['attributes']['appStoreState']}")
    locs = client.localizations(v["id"])
    for locale in sorted(locs):
        a = locs[locale]["attributes"]
        say(f"  {locale:<8} whatsNew={len(a.get('whatsNew') or ''):>5} "
            f"promo={len(a.get('promotionalText') or ''):>4}")
    b = client.version_build(v["id"])
    say(f"build: {b['attributes']['version']} ({b['attributes']['processingState']})"
        if b else "build: none attached")
    print("\n  Submit for Review is the owner's step and is not automated.")


# --- cli ------------------------------------------------------------------

def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("step", choices=["all", "version", "metadata", "archive",
                                    "upload", "attach", "status",
                                    "screenshots"])
    p.add_argument("--version", required=True, help="marketing version, e.g. 1.5.1")
    p.add_argument("--build", help="build number. Default depends on the step: archive takes the next free, upload reads it from the .ipa, attach takes the one already uploaded")
    p.add_argument("--pack", default=str(DEFAULT_PACK), help="store pack markdown")
    p.add_argument("--shots", help="screenshot set: one folder per locale with "
                   f"01.png..05.png (default {DEFAULT_SHOTS.name}, "
                   f"{DEFAULT_SHOTS_VERSION} only)")
    p.add_argument("--dry-run", action="store_true",
                   help="print every write instead of performing it")
    p.add_argument("--allow-dirty", action="store_true")
    p.add_argument("--allow-any-base", action="store_true",
                   help=f"archive even if HEAD is not {RELEASE_BASE} + version bump")
    p.add_argument("--wait-minutes", type=int, default=45)
    p.add_argument("--ipa", help="skip archiving, upload this .ipa")
    args = p.parse_args()

    if not re.fullmatch(r"\d+\.\d+(\.\d+)?", args.version):
        die(f"--version {args.version!r} is not a marketing version")

    client = ascmod.ASC(dry_run=args.dry_run)

    if args.step == "status":
        return step_status(client, args)

    sha = preflight(args)
    if args.dry_run:
        print("\n  DRY RUN — nothing will be created, written or uploaded.")

    version_id = None
    if args.step in ("all", "version", "metadata", "attach"):
        version_id = step_version(client, args)

    build_number = args.build
    if not build_number and args.step in ("all", "archive", "upload", "attach"):
        if args.step in ("all", "archive"):
            build_number = next_build_number(client, args.version)
            say(f"build number: {build_number} (next free in the {args.version} train)")
        elif args.step == "upload":
            # The .ipa has not been uploaded yet, so App Store Connect cannot say
            # what number it carries — but the file itself can.
            if not args.ipa:
                die("`upload` on its own needs --ipa (or --build).")
            ipa_version, build_number = build_number_from_ipa(Path(args.ipa))
            if ipa_version != args.version:
                die(f"{args.ipa} is version {ipa_version}, not {args.version}.")
            say(f"build number: {build_number} (read from the .ipa)")
        else:
            build_number = uploaded_build_number(client, args.version)
            if not build_number:
                die(f"no build has been uploaded for {args.version} yet. "
                    f"Run `archive` and `upload` first, or pass --build.")
            say(f"build number: {build_number} (already uploaded)")
    elif build_number:
        say(f"build number: {build_number}")

    if args.step in ("all", "metadata"):
        step_metadata(client, args, version_id)

    ipa = Path(args.ipa) if args.ipa else None
    if args.step in ("all", "archive") and not ipa:
        ipa = step_archive(args, build_number)

    if args.step in ("all", "upload"):
        if not ipa:
            die("nothing to upload — run `archive` first or pass --ipa")
        step_upload(client, args, ipa, build_number)

    if args.step in ("all", "attach"):
        step_attach(client, args, version_id, build_number)

    if args.step == "screenshots":
        step_screenshots(client, args)

    print(f"\n  Done. Tree was at {sha}.")
    if args.step == "all" and not args.dry_run:
        print("  The build is in App Store Connect and the version is filled in.")
        print("  Remaining, and deliberately not automated: press Submit for Review.")


if __name__ == "__main__":
    main()

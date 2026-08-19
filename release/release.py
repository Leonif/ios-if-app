#!/usr/bin/env python3
"""IF24 release pipeline: from a clean tree to a build waiting in App Store Connect.

    ./release/release.py all --version 1.5.1 --dry-run
    ./release/release.py all --version 1.5.1

Steps, each also runnable on its own:

    version    create the App Store version if it is not there yet
    metadata   push What's New and promotional text for all ten locales
    archive    xcodebuild archive + exportArchive, signed for distribution
    upload     send the .ipa and wait for App Store Connect to finish processing
    attach     bind the processed build to the version
    status     print where the release currently stands

There is no submit step, and adding one is not an oversight to be corrected. The
owner presses Submit for Review; the pipeline stops one step short of it on
purpose.

The keychain will ask for a password during `archive`. That prompt is the owner's
to answer — nothing here tries to route around it, cache it, or script it.
"""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import zipfile
import shutil
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
DEFAULT_PACK = (REPO.parent / "obs-if24-wiki/raw/2026-08-18_store-pack-1.5.1.md")
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
    if not ascmod.KEY_PATH.exists():
        die(f"App Store Connect key not found at {ascmod.KEY_PATH}")
    ok(f"API key {ascmod.KEY_ID}")
    return sha


# --- steps ----------------------------------------------------------------

def step_version(client, args):
    step(f"App Store version {args.version}")
    v = client.find_version(args.version)
    if v:
        state = v["attributes"]["appStoreState"]
        ok(f"already exists: {v['id']} ({state})")
        if state not in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED",
                         "REJECTED", "METADATA_REJECTED", "INVALID_BINARY"):
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
    # simply never written — which, on a draft that starts with ten *empty*
    # localizations, ships that market a blank What's New. Silent, and exactly the
    # failure the read-back check cannot see.
    uncovered = sorted(set(ascmod.PACK_TO_ASC) - set(pack))
    if uncovered:
        die(f"store pack is missing locales the app ships: {uncovered}. "
            "A draft version starts with every locale empty, so a locale left out "
            "here reaches the store blank.")

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
            say(f"{tag}: create (whatsNew {len(fields['whatsNew'])}, "
                f"promo {len(fields['promotionalText'])})")
            client.create_localization(version_id, asc_locale, **fields)
        touched[asc_locale] = fields

    if client.dry_run:
        ok(f"{len(touched)} locales would be written")
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


def _build_numbers(builds) -> list[int]:
    out = []
    for b in builds:
        try:
            out.append(int(b["attributes"]["version"]))
        except (TypeError, ValueError):
            pass
    return out


def next_build_number(client) -> str:
    """The number the *next* archive should carry."""
    nums = _build_numbers(client.builds(limit=200))
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
    nums = _build_numbers(client.get_all("/builds", **{
        "filter[app]": ascmod.APP_ID,
        "filter[preReleaseVersion.version]": version_string,
        "fields[builds]": "version,processingState,uploadedDate",
    }))
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
        say("[dry-run] the keychain password prompt happens here")
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
        die("xcodebuild -exportArchive failed. If it complains about a signing "
            "identity: both configurations pin CODE_SIGN_IDENTITY to "
            "\"Apple Development\" (project.pbxproj:527 and :564). The owner "
            "changes Release to Apple Distribution in Xcode — see ARCHITECTURE.md, "
            "section \"Конвейер релиза\". Do not edit project.pbxproj by hand.")

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
                                    "upload", "attach", "status"])
    p.add_argument("--version", required=True, help="marketing version, e.g. 1.5.1")
    p.add_argument("--build", help="build number. Default depends on the step: archive takes the next free, upload reads it from the .ipa, attach takes the one already uploaded")
    p.add_argument("--pack", default=str(DEFAULT_PACK), help="store pack markdown")
    p.add_argument("--dry-run", action="store_true",
                   help="print every write instead of performing it")
    p.add_argument("--allow-dirty", action="store_true")
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
            build_number = next_build_number(client)
            say(f"build number: {build_number} (next free)")
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

    print(f"\n  Done. Tree was at {sha}.")
    if args.step == "all" and not args.dry_run:
        print("  The build is in App Store Connect and the version is filled in.")
        print("  Remaining, and deliberately not automated: press Submit for Review.")


if __name__ == "__main__":
    main()

# Release pipeline

Takes a release from a clean tree to a build sitting in App Store Connect with the
version filled in. What is left for the owner is the Submit for Review button.

```sh
./release/release.py all --version 1.5.1 --dry-run   # rehearse, writes nothing
./release/release.py all --version 1.5.1             # do it
./release/release.py status --version 1.5.1          # where does it stand
```

Individual steps — `version`, `metadata`, `archive`, `upload`, `attach` — run on
their own and are safe to repeat. `metadata` overwrites, `attach` rebinds, and
`version` finds the existing draft instead of creating a second one.

| Step | In `all` | What it does |
|---|---|---|
| `version` | yes | creates the App Store version, or finds the draft |
| `metadata` | yes | What's New and promotional text, every locale, read back |
| `archive` | yes | `xcodebuild archive` + export, signed for distribution |
| `upload` | yes | sends the `.ipa`, waits for processing |
| `attach` | yes | binds the build to the version |
| `screenshots` | **no** | replaces the 6.7" iPhone screenshots of every locale, read back |
| `status` | — | read-only: where the release stands |

`screenshots` is left out of `all` on purpose — see "Screenshots" below.

## There is no submit step

The pipeline stops one step short of Submit for Review, and that is a decision,
not a gap. Do not add the call: the last look at a release belongs to a person.

## What the owner has to do

**Press Submit for Review** in App Store Connect once the pipeline is done. That
is the whole list. Signing needs no password prompt — see "Signing" below.

## Files

| File | What it is |
|---|---|
| `release.py` | The pipeline. Step order, preflight, verification. |
| `asc.py` | App Store Connect client — JWT auth, versions, localizations, screenshots, builds. |
| `store_pack.py` | Reads What's New and promotional text out of a marketing store pack. |
| `requirements.txt` | `pip3 install -r release/requirements.txt` — PyJWT, requests, cryptography. |

## A store pack belongs to one release

`--pack` defaults to the 1.5.1 pack in the wiki repo next to this one. The pipeline
refuses to run if the pack's filename does not name the version being released, so
`--version 1.6.0` cannot silently push 1.5.1's text — the read-back check would not
have caught that, because it compares what came back against what was sent.

It also refuses a pack that does not cover every locale in `PACK_TO_ASC` (twelve
since 1.5.3). A draft version starts with every existing localization *empty*, so
a locale left out of the pack reaches the store blank rather than keeping the
previous release's text.

Because of that default, a lone clone of `ios-if-app` cannot release without
`--pack`: the store pack lives in the wiki repo.

## Locale names are not the same on both sides

The marketing store pack writes `de`, `fr`, `ar`. App Store Connect stores those
under `de-DE`, `fr-FR`, `ar-SA`. The table lives in `asc.py` as `PACK_TO_ASC`.

This matters more than it looks. A localization write to a locale that does not
exist does not fail — it creates a second, unused localization, and the three
locales you meant to update keep the previous release's text. That is why
`metadata` reads every locale back after writing and compares it to what it sent.
A new market means a new row in that table — and more than that, below.

## A new locale: the pipeline writes two fields, the owner the rest

`en-US` and `es-MX` joined the table in 1.5.3 (IF-75). A locale the listing has
never had is not in the draft, so `metadata` **creates** its version
localization instead of patching it, and writes What's New and promotional text
— nothing else. The rest of a store locale is not in the store pack and the
pipeline does not upload it:

| Where in App Store Connect | Field | |
|---|---|---|
| App Information (`appInfoLocalizations`) | name | required |
| App Information (`appInfoLocalizations`) | subtitle | |
| the version | keywords | |
| the version | description | required |
| the version | screenshots | `release.py screenshots` |

`metadata` reads the listing's locales first and marks such rows
`NEW to the store`, then ends with that list, so a green run is not mistaken for
a submittable locale:

```
  en-US: create (whatsNew 112, promo 143) — NEW to the store
  ...
  !!  new to the store: en-US, es-MX. This step wrote only What's New and
      promotional text. Still the owner's, in App Store Connect, before Submit:
        App Information: name (required), subtitle
        the version: keywords, description (required);
      screenshots: release.py screenshots
```

The marketing pack for a new locale carries those texts too; the owner pastes
them in. Once a release has gone out with the locale, it is an ordinary one.

## Screenshots

```sh
./release/release.py screenshots --version 1.5.3 --dry-run   # plan, writes nothing
./release/release.py screenshots --version 1.5.3             # do it
```

Replaces the `APP_IPHONE_67` (6.7", 1290x2796) set of every locale with the
five frames of a screenshot set. Other display types on the same locale — 6.5",
6.9", iPad — are not touched.

**The set.** `--shots` is a folder with one subfolder per locale, each holding
exactly `01.png` .. `05.png`. Folder names follow the marketing set, not App
Store Connect: `en`, `es`, `de`, `fr`, `ar` land on `en-GB`, `es-ES`, `de-DE`,
`fr-FR`, `ar-SA`. The table is `SHOTS_TO_ASC` in `asc.py`, and it must name the
same twelve App Store Connect locales as `PACK_TO_ASC` — the step refuses to run
if the two drift. The default set (`wiki/raw/2026-11-15_screenshots-IF-77-final`)
was made for 1.5.3; any other version must name its set with `--shots`, for the
same reason the store pack is pinned: the read-back would happily confirm last
release's frames.

**Preflight**, also on a dry run: every locale present, five files each, every
file a 1290x2796 PNG without alpha (App Store Connect rejects alpha). Then, read
only: the version exists and is editable, and it has a localization for every
locale. It does not create either — `version` and `metadata` do, and a missing
locale stops the run with that hint. A dry run prints the same stop as a warning
and still shows the plan: per locale the existing set id (or "new set") and how
many frames it holds, then each file with size and MD5.

**Per locale**, for real: find or create the 6.7" set, delete what is in it,
then for each frame the three-call upload — `POST appScreenshots` (name, size),
`PUT` the bytes to the URLs Apple returns, `PATCH uploaded: true` with the MD5.
It waits up to 10 minutes for every frame to reach `assetDeliveryState`
`COMPLETE`, then fixes the order 01..05.

**Read back** after all twelve: count, order, state and checksum per locale,
printed as a table. Anything off fails the run.

**Safe to repeat.** Every run empties the set first, so a run that died halfway
leaves a locale with fewer frames, and the next run fixes it.

**Not in `all`.** Screenshots change a few times a year, not every release, and
uploading sixty images re-triggers Apple's processing for nothing. With a default
set pinned to one version, putting it in `all` would also make every other
release fail until `--shots` is passed. Run it on its own when the set changes.

## Version numbers do not touch project.pbxproj

`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` are passed to `xcodebuild` as
build-setting overrides. The project file stays whatever Xcode last wrote.

Verified: an override of `MARKETING_VERSION=1.5.1 CURRENT_PROJECT_VERSION=2`
produces `CFBundleShortVersionString = 1.5.1`, `CFBundleVersion = 2` in the built
`Info.plist`, with the project file unmodified.

The build number is resolved per step, not by one rule: `archive` takes the next
free number, `upload` reads it out of the `.ipa`, and `attach` takes the one
already uploaded. `--build` overrides all three. One rule for all of them would
make `attach` chase a build that does not exist, and would make a second upload
attempt send build 3 while waiting on build 2 — then attach 2, silently.

"Next free" is counted **inside the marketing version's train**, not across the
account: App Store Connect numbers builds per version, so 1.5.0 holds 1, 2, 3 and
1.5.1 starts again at 1. Counting globally left a hole in the train instead
(fixed 20.08.2026, IF-40 — the case is written out in `ARCHITECTURE.md`).

## Signing: Apple holds the key, and that is fine

The distribution signature is **not** taken from the local keychain. It is not in
the archive either — the archive comes out signed `Apple Development`, exactly as
Xcode's does. `-exportArchive` re-signs, and the certificate it re-signs with is
the team's **cloud-managed Apple Distribution certificate**, whose private key
lives on Apple's side. `-allowProvisioningUpdates` plus the API key are what buy
access to it.

So there is nothing to create beforehand, and these three commands are all
misleading — none of them can see a cloud-managed certificate:

```sh
security find-identity -v -p codesigning   # two Apple Development, no Distribution
GET /v1/certificates                       # one DEVELOPMENT
GET /v1/profiles                           # empty
```

Reading them as "the account has no distribution certificate, a release cannot be
built" is the wrong conclusion, and it has been reached three times. The owner's
manual Xcode upload of 1.5.1 (1) happened with all three looking exactly like
that.

**Verified 20.08.2026.** A local `archive` run signed the exported `.ipa` with
`Apple Distribution: LEONID NIFANTIJEV (379294YDPQ)`, SHA-1
`9C:EE:E3:D8:…:BA:B0` — byte for byte the `certificateSHA1` the Xcode archive
recorded for the owner's own upload. Entitlements came out `get-task-allow =
false`, `beta-reports-active = true`; the embedded profile was `iOS Team Store
Provisioning Profile`. No keychain password was asked for at any point.

What can still break the export: the API key losing Certificates/Identifiers/
Profiles access, or no network. Not a missing local identity.

## Two more things that are not signing

- **Simulator builds are unaffected** — they stay unsigned, so no agent's build
  pops a keychain prompt. This pipeline signs only Release on
  `generic/platform=iOS`.
- **Upload processing is Apple's, and takes minutes.** A timeout is not a lost
  build; re-run `attach` later.

The long form of all of this — the state of the account's certificates, the
`CODE_SIGN_IDENTITY` situation, every trap paid for so far — lives in
`ARCHITECTURE.md`, section **«Конвейер релиза»**. What is here is the working
summary; that is the record.

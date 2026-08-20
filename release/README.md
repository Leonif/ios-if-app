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
| `asc.py` | App Store Connect client — JWT auth, versions, localizations, builds. |
| `store_pack.py` | Reads What's New and promotional text out of a marketing store pack. |
| `requirements.txt` | `pip3 install -r release/requirements.txt` — PyJWT, requests, cryptography. |

## A store pack belongs to one release

`--pack` defaults to the 1.5.1 pack in the wiki repo next to this one. The pipeline
refuses to run if the pack's filename does not name the version being released, so
`--version 1.6.0` cannot silently push 1.5.1's text — the read-back check would not
have caught that, because it compares what came back against what was sent.

It also refuses a pack that does not cover every locale in `PACK_TO_ASC`. A draft
version starts with all ten localizations *empty*, so a locale left out of the pack
reaches the store blank rather than keeping the previous release's text.

Because of that default, a lone clone of `ios-if-app` cannot release without
`--pack`: the store pack lives in the wiki repo.

## Locale names are not the same on both sides

The marketing store pack writes `de`, `fr`, `ar`. App Store Connect stores those
under `de-DE`, `fr-FR`, `ar-SA`. The table lives in `asc.py` as `PACK_TO_ASC`.

This matters more than it looks. A localization write to a locale that does not
exist does not fail — it creates a second, unused localization, and the three
locales you meant to update keep the previous release's text. That is why
`metadata` reads every locale back after writing and compares it to what it sent.
A new market means a new row in that table.

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

# Release pipeline

Takes a release from a clean tree to a build sitting in App Store Connect with the
version filled in. What is left for the owner is the keychain password during
archiving, and the Submit for Review button.

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

1. **Answer the keychain prompt** during `archive`. It comes from codesign wanting
   the private key. Nothing here caches it, stores it, or types it for you.
2. **Press Submit for Review** in App Store Connect once the pipeline is done.

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
build-setting overrides. The project file stays whatever Xcode last wrote. The
build number defaults to the highest one App Store Connect has seen, plus one.

Verified: an override of `MARKETING_VERSION=1.5.1 CURRENT_PROJECT_VERSION=7`
produces `CFBundleShortVersionString = 1.5.1`, `CFBundleVersion = 7` in the built
`Info.plist`, with the project file unmodified.

The build number is resolved per step, not by one rule: `archive` takes the next
free number, `upload` reads it out of the `.ipa`, and `attach` takes the one
already uploaded. `--build` overrides all three. One rule for all of them would
make `attach` chase a build that does not exist, and would make a second upload
attempt send build 8 while waiting on build 7 — then attach 7, silently.

## First run only: the distribution certificate

As of 19.08.2026 the account has one Development certificate and **no distribution
certificate**, so the very first release has to create one. Two ways, and the
recommended one is first.

**Path A — Xcode (recommended).** Xcode → Settings → Accounts → pick the Apple ID →
pick the team (`379294YDPQ`) → **Manage Certificates…** → the **+** in the bottom
left → **Apple Distribution**. Xcode generates the key pair, files the request and
installs the result in the login keychain in one step. The keychain may ask for the
password; that prompt is yours.

**Path B — the developer portal.** Keychain Access → Certificate Assistant →
Request a Certificate From a Certificate Authority → save to disk; then
developer.apple.com → Certificates → **+** → Apple Distribution → upload the CSR →
download the `.cer` → double-click to install.

Path A is recommended because it is one dialog and the private key is created
directly in the keychain that will sign. Path B splits the key from the certificate
across two applications and a file on disk, and a distribution certificate whose
private key went missing cannot be recovered — only revoked and reissued.

**Check it worked:**

```sh
security find-identity -v -p codesigning | grep Distribution
```

One line naming *Apple Distribution* means the pipeline can archive. Nothing
prints means it did not take, whatever the UI said.

The pipeline also passes `-allowProvisioningUpdates`, so in principle the first
`archive` could mint the certificate by itself. Doing it deliberately beforehand is
still the better order: it turns the pipeline's largest unknown into a thirty-second
step you can verify, instead of a surprise in the middle of a release.

## Signing, and where it can fall over

The full account of both — including the state of the account's certificates, the
`CODE_SIGN_IDENTITY` situation and why the first real run is the risky one — lives
in `ARCHITECTURE.md`, section **«Конвейер релиза»**. It is kept there rather than
here so there is one copy to keep true.

The short version, so nobody starts a release without knowing it:

- **The first real `archive` has to mint a distribution certificate and a
  provisioning profile**, because the account has neither. That is the single
  largest unknown in the pipeline.
- **Simulator builds are unaffected** — they stay unsigned, so no agent's build
  pops a keychain prompt. This pipeline signs only Release on
  `generic/platform=iOS`.
- **Upload processing is Apple's, and takes minutes.** A timeout is not a lost
  build; re-run `attach` later.

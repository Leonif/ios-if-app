# Data - notes for agents

Why the repositories are the way they are. `UserDefaults` keys and file names below are persisted on users' devices: renaming one loses the stored value on every existing install. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## AnalyticsRepository.swift

- `AnalyticsRepository` — stateless gateway for analytics events. Events are never logged from a view: they come from `AnalyticsMiddleware`, the caller for everything that travels as an action, and from the one failure that does not — `history_load_failed` is found by the file layer and wired to this gateway in `AppDependencies`.
- `AnalyticsRepositoryProtocol.setUserProperty(_:forName:)` — a persistent user property for segmentation; `nil` clears it.

## DiagnosticsLogRepository.swift

- `DiagnosticsLogRepository` — the developer-facing journal: what the app did, in order, written to a file inside the app container. A file rather than a stream because the two ends of diagnostics are not symmetric: on the simulator a Maestro run has to be readable with no UI and no human in the loop (`simctl get_app_container` and the file is there); on a real device there is no container to reach into, and the same file is the only thing that can be handed out. A journal that only streamed to Console would serve neither; the `os.Logger` mirror is a convenience on top, not the mechanism. Compiled out outside DEBUG and DEVELOPMENT: nothing here reaches an App Store build.
- `DiagnosticsLogRepository.maxBytes` — rotated rather than truncated: the run that explains a failure is often the one before the one being looked at.
- `DiagnosticsLogRepository.fileURL` — static so the debug screen can find the journal without injecting the repository: a view taking anything out of the container would break invariant 3, and the path is all it needs.
- `DiagnosticsLogRepository.mirror` — `privacy: .public` is not decoration: `os.Logger` redacts interpolated values by default, and a journal of `<private>` is worse than none because it looks like it worked.
- `DiagnosticsLogRepository.stamp` — timestamps are for machines and for reading side by side with Maestro output, so the locale is pinned. Invariant 5 (on-screen formatting) does not apply, but not because nothing reaches a screen — `DebugScreen` renders the tail of this file in a `Text`. It does not apply because the rule guards against two digit systems meeting on one screen, and `en_US_POSIX` always yields Latin digits: the guarantee `Locale.latinDigits` exists to give, in the same shape as `Clock.dayKeyFormatter`.
- `DiagnosticsLogRepository.writeSessionHeader()` — every launch is marked, because the first question asked of a journal is always "is this from the run I just did".

## FastHistoryRepository.swift

- `FastHistoryRepository` — finished fasts, persisted as one JSON file in Documents, not `UserDefaults`: the list grows without bound and is read as a whole. Records are kept forever; only an explicit delete removes one.
- `FastHistoryRepository` — bytes that do not decode are never written over. A failed read that returned an empty array would let the next `append` put one fresh record where the whole history had been — a loss with nothing to recover from and no sign it happened. So the unreadable file is moved aside first, and if it cannot be moved the repository refuses to write at all.
- `FastHistoryRepository` — the envelope's schema version is read as well as written, and read before the records. That order is the whole of it: a file left by a newer build is not damaged, only younger than this binary, and telling the two apart keeps a TestFlight downgrade from filing someone's history away as corrupt. A newer file is handed over read-only, because this build would write it back in the older shape.
- `FastHistoryRepository` — there is no migration chain yet (its place is marked in `readFile()`), so the promise is narrower than a migration: the old bytes survive, not the old records.
- `HistoryLoadFailure` — why a read did not produce today's records. Raw values are the GA4 `reason` parameter of `history_load_failed`: a fixed list, same rule as `trigger`.
- `HistoryLoadFailure.unreadable` — the file is there and cannot be read at all (disk, permissions).
- `HistoryLoadFailure.decode` — the bytes are not an envelope this build understands.
- `HistoryLoadFailure.futureSchema` — written by a newer build. Records may still come back; writing does not.
- `HistoryLoadFailure.quarantineFailed` — unreadable and immovable. The only copy is still where it was, and the repository has stopped writing to keep it that way.
- `FastHistoryRepository.VersionProbe` — the version on its own. `Envelope` cannot stand in for it: it carries the records too, so a file whose records this build cannot parse fails to decode either way, and the version is exactly what separates "corrupt" from "written by a newer build".
- `FastHistoryRepository.FileState` — what the file turned out to be. Every read and every write goes through it, because the guard's rule — never write on top of bytes that could not be read — is a property of writing, not of loading. One exception, not a user's: the DEBUG hook `wipeFile()` reads through here and then writes anyway, because a suite's baseline is not bytes the guard protects.
- `FastHistoryRepository.FileState.blank` — no file or an empty one: a first launch, not a failure. Nothing is quarantined because there is nothing to lose.
- `FastHistoryRepository.FileState.quarantined` — undecodable bytes, now moved aside; the history path is free again.
- `FastHistoryRepository.FileState.stuck` — undecodable bytes that could not be moved (disk, permissions); the only copy of the user's history is still at `fileURL`.
- `FastHistoryRepository.FileState.readOnly` — an envelope from a newer build. Whatever this build can read is handed over and nothing is written back: the records would go out in the older shape and the newer ones would be gone. Not quarantined — the file is intact, and the build that wrote it can still read it.
- `FastHistoryRepository.FileState.allowsWrite` — a write is allowed unless it would land on data that can be neither read nor kept, or on data a newer build understands better. `.quarantined` allows it precisely because the old bytes are safe.
- `FastHistoryRepository.quarantinePrefix` — quarantined copies are named `fast-history.corrupt-<epoch>.json` in the same folder, so `simctl get_app_container … data` is all it takes to pull them off a device or simulator, and the name says what the file is.
- `FastHistoryRepository.quarantineLimit` — a repeating failure would otherwise fill the container one launch at a time; three copies are enough to show a pattern.
- `FastHistoryRepository.init(directory:onLoadFailure:)` — the directory is a parameter so a unit test can point the repository at a temp folder and exercise the real file behaviour: the decode path is what the guard is about, so a fake would test nothing. `onLoadFailure` is a closure rather than an analytics dependency on purpose: this layer knows that and why a read failed, nothing about the event catalog; what it means is decided where the repository is registered (`AppDependencies`).
- `FastHistoryRepository.replaceAll(_:)` — reads before it overwrites, even though it discards what it read: the read is what puts an unreadable file into quarantine. Without it, wiping (`-uitestReset`) or seeding the history would be the one path that still destroys bytes silently.
- `FastHistoryRepository.readFile()` — one report per failed read, per call, not per lifetime. A failure that keeps happening keeps firing: how often it repeats, and whether on writes as well as launches, is what says how bad it is.
- `FastHistoryRepository.readFile()` — empty data — a zero-byte file is what an interrupted first write leaves; there are no records under it, so quarantining it would only file away emptiness.
- `FastHistoryRepository.readFile()` — `VersionProbe` first — version first, records second. A file from a newer build may well fail to decode into today's `FastRecord`, and reaching the decode before the version would quarantine it as corrupt — destroying, in the name of the guard, the one case the guard cannot tell apart on the bytes alone.
- `FastHistoryRepository.readFile()` — `.readOnly` — whatever this build can still make of the file. Empty is an honest answer: the records exist, this binary cannot read their shape, and with writing off an empty read costs only a bare screen.
- `FastHistoryRepository.readFile()` — migration — when `FastRecord` first changes shape, the upgrade step goes after the future-schema check, on `probe.schemaVersion` below `currentSchemaVersion`. With one version there is nothing to branch on.
- `FastHistoryRepository.quarantining(_:)` — when the move fails, the reason reported is `quarantineFailed` rather than what made the bytes unreadable: only one event goes out per read, and of the two facts that is the one still costing the user their history.
- `FastHistoryRepository.quarantine()` — a rename rather than a copy: a single operation cannot half-finish and leave the caller unable to tell which file is the real one. Returns whether the bytes are now safe.
- `FastHistoryRepository.freeQuarantineURL(now:)` — a counter is appended when the name is taken: two failures inside one second must not make the second overwrite the first one's evidence.
- `FastHistoryRepository.trimQuarantine()` — keeps the newest `quarantineLimit` copies. Sorting by name is sorting by age: the epoch is fixed-width for the next two centuries. Copies made within the same second order arbitrarily, which only decides which of two equally old files goes first.
- `FastHistoryRepository.corruptFixture` — the bytes `-seedHistoryCorrupt` leaves on disk: an envelope cut off mid-record, which is what an interrupted write actually looks like, not random noise. One definition so a flow, a unit test and a hand run corrupt the file the same way.
- `FastHistoryRepository.seedCorruptFile(_:)` — a test hook rather than a repository feature: the protocol speaks only in records, so the failed-decode path — the one the guard exists for — is unreachable through it. Returns the file it wrote so the caller can log where to look.
- `FastHistoryRepository.wipeFile()` — wipes to an empty envelope of the current schema, past the write guard; a test hook for the same reason as the seeders: the guard protects a user's bytes, and a suite's baseline is not that. Needed because `replaceAll([])` honours `allowsWrite`, so once a flow seeds a future-schema file every later baseline wipe would silently do nothing and the next flows would run on the seeded record. `run.sh all` sorts the flow glob as strings (H15 runs before H2-H9), and reinstalling the container hides the leak, so only a full run shows it.
- `FastHistoryRepository.wipeFile()` — reads before it writes, so the quarantine path is kept: undecodable bytes are still moved aside and `onLoadFailure` still fires, as on a normal launch. Beyond `.readOnly` it overrules only `.stuck`; overwriting those bytes is the point here, since the run needs a clean baseline and a simulator container holds nothing under them worth keeping.
- `FastHistoryRepository.futureSchemaFixture` — a well-formed envelope from a schema this build has not shipped: the `readOnly` path, as opposed to `corruptFixture`'s decode/quarantine path. One record with the goal reached, so the read-only history renders like an ordinary one and the only visible difference is that a later write does not change the file.
- `FastHistoryRepository.seedFutureSchemaFile(_:)` — mirrors `seedCorruptFile` for the same reason: a newer-than-this-build envelope is not something the protocol can express.

## HistoryExportRepository.swift

- `HistoryExportRepository` — puts the exported CSV on disk so the system share sheet has a real file to hand over. The mechanism only: what goes in the file is `HistoryExport`, and the decision to write one is the thunk's.
- `HistoryExportRepository.write(csv:fileName:)` — temporary directory, not Documents: the file is a copy made for one share and the app is not its owner. The history already lives in `fast-history.json`, and a second copy in Documents would show up in the user's backups as a stale duplicate. Overwrites an earlier export of the same day; returns `nil` if the write failed.
- `HistoryExportRepository.write(csv:fileName:)` — UTF-8 — the CSV is ASCII by construction (`HistoryExport`), so UTF-8 writes the same bytes and no BOM question arises.

## NotificationRepository.swift

- `NotificationRepository` — a thin wrapper over `NotificationManager` so thunks depend on a protocol, not a singleton.
- `NotificationRepositoryProtocol.enableForegroundPresentation()` — makes scheduled pushes appear while the app is in the foreground; called once at launch, before any notification can be delivered.
- `NotificationRepositoryProtocol.requestAuthorization()` — shows the system permission dialog and returns once the user has answered.
- `NotificationRepositoryProtocol.removeLegacyDailyReminders()` — one-time cleanup of the legacy fixed daily reminders on existing installs.
- `NotificationRepositoryProtocol.scheduleGoalNotification(after:)` — replaces any existing goal-reached push.
- `NotificationRepositoryProtocol.scheduleEatingEndNotification(after:)` — replaces any existing eating-window-closed push.

## ProOfferRepository.swift

- `ProOfferRepository` — the one fact about the offer that outlives a launch: whether the automatic, once-per-install show (T1', see `Features/pro/NOTES.md`) has happened. Nothing else about the offer is persisted on purpose: the plan to show it belongs to the session that finished the fast (`ProState.autoOfferArmed`), so the only thing worth carrying across launches is that the show is spent.
- `ProOfferRepositoryProtocol.markOfferShown()` — idempotent: written from the reduced state rather than from one action, so it lands again on every later Pro action and must not care.

## ReviewRepository.swift

- `ReviewRepository` — native review-request persistence plus the StoreKit call. `ReviewMiddleware` gates every call (lifetime cap, once a day, once a launch) and owns the triggers; this repository remembers the gate state and the pending "next open" fallback.
- `ReviewRepositoryProtocol.canPrompt()` — not shown today and under the lifetime cap.
- `ReviewRepositoryProtocol.markPromptShown()` — records a call: once a day, and it counts toward the cap.
- `ReviewRepositoryProtocol.requestReview(completion:)` — reports `true` only when a `foregroundActive` scene was found and `AppStore.requestReview` was called; Apple still decides whether the panel appears. `false` means nothing was asked, and the caller must not spend an attempt on it.
- `ReviewRepository.requestReview(completion:)` — only a `foregroundActive` scene counts. A request on a scene still `foregroundInactive` — exactly where a cold start sits when the "next open" fallback fires — is dropped by Apple without a trace, and falling back to `scenes.first` would spend a lifetime attempt on it.
- `ReviewRepositoryProtocol.pendingGoalDate()` — the moment of the 3rd completed goal, when the "next open" fallback was armed.
- `ReviewRepository.maxPrompts` — Apple's own 3-per-365-days limit is opaque, so the app stops asking itself after this many attempts.

## StoreRepository.swift

- `StoreRepository` — the whole of StoreKit 2 for this app: one non-consumable, its price, buying, restoring, and being told when it goes away. Everything above this file speaks in `Entitlement` and outcomes and never imports StoreKit.
- `StoreRepository` — verification is deliberately three-valued. `Transaction.currentEntitlements` never throws and returns nothing both when the user did not buy and when this install has not yet reached the store (a fresh install in airplane mode). Collapsing those into "free" tells a paying customer their purchase is gone, so the store is probed separately and "we could not check" is reported as such.
- `PurchaseOutcome.pending` — Ask to Buy: approval pending, no entitlement yet.
- `StoreRepositoryProtocol.refresh()` — resolves what this install owns and what the product costs, in one pass.
- `StoreRepositoryProtocol.restore()` — syncs with the App Store account and re-reads the entitlement. The only path that works with no account of ours on a new device — an App Review requirement for a non-consumable, not a convenience.
- `StoreRepositoryProtocol.entitlementUpdates()` — entitlement changes nobody asked for: an approved Ask to Buy, a purchase on another device, a refund, leaving a Family Sharing group.
- `StoreRepository.Key.verifiedEntitlement` — the last verified verdict. Its absence is meaningful: this install has never had an answer from the store, the only condition under which the entitlement is reported as unknown.
- `StoreRepository.refresh()` — `.found` / `.missing` — the store answered, so an empty entitlement set is the truth about this install whatever was cached before; this is also how a refund or a family member's departure settles.
- `StoreRepository.refresh()` — `.unreachable` — no answer, so a previously verified verdict stands: a purchase already seen on this device must survive a flight, and one already known to be absent does not need re-proving to show the offer.
- `StoreRepository.ownsPro()` — true when a non-revoked, verified transaction for the product is on this device.
- `StoreRepository.restore()` — backing out of the App Store sign-in comes back as `cancelled`, which the reducer treats as "nothing happened" rather than as an error.
- `StoreRepository.entitlementUpdates()` — re-reads rather than trusting the single transaction: a revocation and a purchase arrive through the same door, and only the full set says which side the user ends up on.
- `StoreRepository.ProductLookup.missing` — the store answered and does not know the identifier: a configuration mistake on our side, not the user's connection.
- `StoreRepository.reason(for:)` — maps a StoreKit throw onto the reasons the offer screen can act on; only `network` changes what the user is told, the rest share one body.

## StubStoreRepository.swift

The arguments below are a contract with the Maestro flows; renaming one silently breaks every flow that passes it.

- `StubStoreRepository` — a store that answers from launch arguments instead of from Apple. DEBUG-only, and registered only when `-seedStore` is present, so a normal build has no path to it. It exists because the six states of the offer screen are otherwise unreachable without a driver: StoreKit's local testing configuration is attached to the Xcode scheme, and a simulator launched by `simctl` — how every Maestro flow and screenshot run starts the app — never sees it. It fakes the store's answers and nothing else: entitlement, price and outcome come from the arguments, and every verdict still travels the same actions through the same reducer as the real one.
- `StubStoreRepository.Argument.store` — `-seedStore free|pro|unknown|missing`: what the store answers about this install. `missing` stands for an identifier the store does not know.
- `StubStoreRepository.Argument.price` — `-seedStorePrice "COP 29.900,00"`, deliberately awkward by default so a layout that only survives `$6.99` is caught here rather than in Colombia.
- `StubStoreRepository.Argument.outcome` — `-seedStoreOutcome purchased|pending|cancelled|network|other`: how the next Buy ends.
- `StubStoreRepository.Argument.restore` — `-seedStoreRestore restored|nothing|network|other`.
- `StubStoreRepository.Argument.restoreDelay` — `-seedStoreRestoreDelay N`: milliseconds the next Restore spends in flight, default 0. `restoreStarted` puts the screen in S2, and a stub that answers synchronously never lets that frame render, so the spinner on the Restore path could not be observed.
- `StubStoreRepository.Argument.purchaseDelay` — `-seedStorePurchaseDelay N`: milliseconds the next Buy spends in flight. Default 0, so flows written against the instant answer keep it. Apple's sheet takes real time and `.purchasing` renders while it is up; a synchronous stub never lets that phase reach the screen.
- `StubStoreRepository.Argument.revokeAfter` — `-seedStoreRevokeAfter N`: seconds until the entitlement is taken away, the way a refund or leaving Family Sharing arrives. Edge 6 and edge 17 of the paywall spec have no other door: both hang off an update nobody asked for.
- `StubStoreRepository.Argument.grantAfter` — `-seedStoreGrantAfter N`: seconds until the entitlement arrives through the same unasked-for door. Pairs with `-seedStoreOutcome pending`: that reaches S4 and stops, but the half of Ask to Buy that matters is the approval landing later, with no relaunch, through `Transaction.updates`. Doing that for real needs a second Apple Account, a family organiser and someone to press Approve, so without this argument the transition out of S4 is unreachable locally.
- `StubStoreRepository.refresh()` — `missing` is a verified free (the identifier is our configuration, not the user's entitlement) but leaves the screen with no price, which is the point of being able to seed it.
- `StubStoreRepository.entitlementUpdates()` — the scripted changes in the order their seconds put them, or nothing. Both offsets count from launch, not from each other: `-seedStoreGrantAfter 2 -seedStoreRevokeAfter 5` is Pro at two seconds, gone at five. Ties resolve to the order the arguments are read (grant, then revoke): `sort` is not documented as stable, so the offset index is part of the key.
- `StubStoreRepository.entitlementUpdates()` — `Task.isCancelled` — `try?` swallows the cancellation the sleep throws, so without the check the whole schedule would fire back-to-back on teardown.

## SunnahRepository.swift

- `SunnahRepository.replace(_:)` — capacity — iOS keeps at most 64 pending local notifications per app; reminders are capped at 60 minus the pending requests that are not ours, leaving room for unrelated notifications and the timer's two replaceable pushes.

## TimerPersistenceRepository.swift

- `TimerPersistenceRepository` — stateless, non-reactive `UserDefaults` access for the timer substate. The keys match the earlier `@AppStorage` keys, so existing installs keep their state.
- `TimerPersistenceRepository.Key.stagedElapsed` — the ended fast still on the result screen: its elapsed seconds, with `fastEndTimestamp` the moment it was confirmed to end. Absent on installs from before 1.5.2, which reads as 0 — "nothing ended" — exactly the idle screen those builds relaunched into.
- `TimerPersistenceRepository.Key.legacyPlanIdx` — plan storage before 1.5.0: an index into the four presets. Read once for migration, never written.
- `TimerPersistenceRepository.Key.streakFreezeSpentMonth` — the calendar month ("yyyy-MM") whose protected day is spent. Absent on installs that updated into 1.5.0, which reads as "none spent": the benefit starts available, which is what someone who just bought it expects.
- `TimerPersistenceRepository.load()` — `goalHours` — absent (state written before 1.5.0) reads as 0, which every reader resolves to the current plan: the behaviour of those builds.
- `TimerPersistenceRepositoryProtocol.loadPlanHours()` — the selected plan's fast length in whole hours; `nil` means never saved.
- `TimerPersistenceRepositoryProtocol.loadLastMilestoneShown()` — the highest streak milestone (3/7/14/30) whose card was already shown; 0 means none.
- `TimerPersistenceRepository.loadPlanHours()` — hours first, falling back once to the preset index for installs that updated over a version which stored a plan as a position in a list. The fallback converts and then removes the old key rather than re-reading it every launch: otherwise an install whose owner never opens the plan editor keeps its plan as an index forever, and an index only means something relative to the order of `Plan.presets`, so reordering that array would quietly reinterpret the saved plan on exactly those installs. The key goes either way: an index that cannot be interpreted is not worth keeping.

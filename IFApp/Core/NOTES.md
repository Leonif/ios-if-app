# Core - notes for agents

Why the app's composition root, root state and clock are the way they are. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## AppDependencies.swift

- `AppDependencies.register()` — registers the repositories in the container; called once at launch, before the store is built or any thunk runs.
- `AppDependencies.register()` — `FastHistoryRepository` — the repository finds a load failure; that a failure is worth an analytics event is decided here, in the composition root, so the file layer stays ignorant of the event catalog. The analytics tracker is resolved on the call rather than captured, so registration order does not matter.
- `AppDependencies.register()` — `StoreRepositoryProtocol` — StoreKit's local test configuration lives on the Xcode scheme, so an app launched by `simctl` never has a store to talk to. `-seedStore` puts a scripted `StubStoreRepository` in its place; without the argument the branch is unreachable, and outside DEBUG it does not exist.
- `AppDependencies.register()` — `DiagnosticsLoggerProtocol` — one shared instance, unlike every other registration. The journal owns an open `FileHandle` positioned at the end of the file; a second instance would open its own handle at the same offset and the two would write over each other's lines. There is more than one reader of the protocol (`DiagnosticsMiddleware` and the seed collision warning in `UITestSeed`), so the sharing is load-bearing.

## AppLifecycleAction.swift

- `AppLifecycleAction` — app-level signals that mutate no substate but drive side effects (analytics, review, notifications). Reducers ignore them; middleware reacts.
- `AppLifecycleAction.appBecameActive` — the scene became active (cold start or return from background). Its one consumer is `SunnahMiddleware`, which re-syncs the reminders on it; not a funnel event.
- `AppLifecycleAction.sourceArticleOpened` — `articleID` is the paper's index in `SourceArticle.all`, the same identifier the rows are addressed by.
- `AppLifecycleAction.sourceOriginalOpened` — dispatched from the reader's "read the original" button and nowhere else, and it is the whole tap: the analytics event hangs off it and `SourcesMiddleware` opens its `url`. `OpenExternalLinkThunk` also opens the system Settings, so the event cannot hang off the thunk without counting that as a paper.
- `AppLifecycleAction.sourceArticleClosed` — carries whether the foot of the article had been on screen.
- `AppLifecycleAction.reviewPrompted` — the native `requestReview` went out on an active scene (Apple may or may not show the panel). Never dispatched when there was no scene to ask on.
- `AppLifecycleAction.streakMilestone` — a streak milestone (3/7/14/30 days) was reached and its card shown.
- `AppLifecycleAction.goalScreenSettled` — the goal-reached screen is on display and its moment has finished playing. Sent only from the `goalReached` state; the milestone card hangs off it.
- `AppLifecycleAction.eatingWindowSettled` — the eating window opened by "Start eating window" is on screen, its card has settled, and nothing covers it. Sent only after `TimerAction.eatingStarted`, and only when the one-time offer was not owed; the review prompt hangs off it.
- `AppLifecycleAction.pushAuthorizationResolved` — the user just answered the notification permission dialog. Reducers ignore it; it exists so `NotificationMiddleware` re-runs its sync, because the goal push scheduled on `.started` was rejected while the permission did not yet exist. Not a funnel event.
- `AppLifecycleAction.pushStatusRead(label:)` — the notification permission as just read, carried to `AnalyticsMiddleware`, which writes it as the `push_status` user property. A thunk reads the status but does not log it: analytics is written only from middleware.
- `AppLifecycleAction.fastChained` — a fast was started from the window-closed screen: the chain held.
- `AppLifecycleAction.themeActive` — `dark` is system dark mode; the app follows the system scheme and has no in-app theme toggle.

## ReviewPromptTrigger.swift

- `ReviewPromptTrigger` — what caused a native review request. The raw value is the GA4 `trigger` parameter.
- `ReviewPromptTrigger.fastCompleted` — the eating window was opened after a fast that reached its goal, and its card has settled. The only trigger; the older values `streak_milestone` and `next_open` live on only in historical GA4 data, so a funnel spanning versions must read all three.

## HistoryEntrySource.swift

- `HistoryEntrySource` — which entry point led into the history. The raw value is the GA4 `source` parameter: with several ways in, the event alone cannot say which one works.
- `HistoryEntrySource.streakBadge` — the streak pill in the header, present in every state.
- `HistoryEntrySource.completeCard` — "Saved to your history" in the complete card.
- `HistoryEntrySource.eatingWindow` — "Last fast · 16h 24m" in the eating-window card.
- `HistoryEntrySource.endFastOverlap` — "Open that fast" in the end-fast sheet's refusal: the record standing in the way of a back-dated ending, opened so it can be deleted.

## SunnahEntrySource.swift

- `SunnahEntrySource` — which door led into the Sunnah reminders screen. The raw value is the GA4 `source` parameter, same fixed-list rule as `HistoryEntrySource`: with the screen reachable two ways, the event alone cannot say which one carries it.
- `SunnahEntrySource.planEditor` — the "Sunnah reminders" row in the plan editor (the pencil in the plan pill).
- `SunnahEntrySource.about` — the row in the About IF24 sheet.

## AppState.swift

- `AppState` — single source of truth; each feature owns a substate.
- `AppState.activePlan` — the plan the fast/window cycle in flight runs to: the goal pinned at its start, falling back to the selected plan when nothing is pinned. Everything that means "what is happening right now" derives from this; `planState.plan` stays what the user has selected, which is a different fact.
- `AppState.streak` — the streak as screens must project it. Assembled here rather than on `timerState` because one of its four facts — whether the protected day is owned — is the entitlement, and the timer substate has no business holding a copy of that. Screens read this; nobody builds a `StreakStatus` by hand.
- `AppState.selectedPlanAllowed` — whether the plan in the store may be used under the entitlement now held: the four presets are free, any other length is Pro's. The rule itself is `Plan.allowed(isPro:)`; this is only the question asked about the stored plan, and its one consumer is the fallback in `StartFastThunk` at the next start. The editor deliberately does not read it: the length on the wheel is a draft inside the sheet that reaches the store only if the same rule lets it, so a projection off state would always answer about the previous plan. Both ask the one definition so they cannot drift — and drift here would be silent: a plan confirmed without an offer, then a start that quietly runs to a different goal.

## AppStoreFactory.swift

- `AppStoreFactory.make()` — builds the store: loads persisted state into the initial `AppState`, wires the middlewares and registers the store in the container.
- `AppStoreFactory.make()` — `enableForegroundPresentation()` — first, before anything is loaded or scheduled: a push already due at launch (a window that closed while the app was opening) must find the delegate in place, or iOS drops it while the app is in the foreground.
- `AppStoreFactory.make()` — test hooks — DEBUG-only as a block. `-uitestReset` wipes the timer defaults and the whole history file; a hook that destructive has no business in a store binary, even though a user cannot pass a launch argument. The suite runs on DEBUG builds, so nothing it needs is lost. UI tests launch with `-uitestReset` to start from a clean idle state, and seed timer and review state through the `-seed…` arguments (`UITestSeed`).
- `AppStoreFactory.make()` — `wipeFile()` — not `replaceAll([])`: that is bound by the history write guard, and this branch has to survive a future-schema file left by an earlier flow. It is also the only wipe a `-uitestReset` launch gets: with no `-seed…` argument `UITestSeed.applyIfNeeded` returns before its own.
- `AppStoreFactory.make()` — `FontMetricsDump.runIfNeeded()` — `-dumpFontMetrics` writes a file, so it is a side effect like any other; it lives in `Debug/` for that reason (the named exception to invariant 2 in `ARCHITECTURE.md`) and is merely called from here.
- `AppStoreFactory.make()` — `stagedElapsed` / `fastEndTimestamp` — restored so the result screen survives iOS unloading the app on it. Without them a finished fast relaunches into idle, the eating window is never opened and its closing push never comes.
- `AppStoreFactory.make()` — `autoOfferShown` — the only part of the offer that survives a launch; everything else the automatic trigger needs is session state and starts empty by design.
- `AppStoreFactory.make()` — `droppingLapsedEnding(at:plan:)` — a result screen restored from disk is held only while the window it would open is still current. Decided here, once, on the clock at launch: clearing it in state rather than hiding it on screen keeps every thunk that reads the staged ending — the start that back-dates by it, the undo, the window anchor — from acting on a week-old fast.
- `AppStoreFactory.make()` — `DiagnosticsMiddleware` — inserted first on purpose: an action that wedges a later middleware is already on disk by the time it does.

## Clock.swift

- `Clock` — meant as the one place that reads wall-clock time for thunks, kept out of reducers and views. Not a rule the code follows: about half of the thunks and middlewares that read the clock call `Date()` directly, and `Clock.now()` is a plain wrapper with no substitution point (open question A in `ARCHITECTURE.md`). What is binding is only that reducers never read the clock (invariant 1).
- `Clock.gregorian` — the calendar the app counts days in: Gregorian, in the device's time zone. Named once and reused because the alternative is `Calendar.current`, which on an Arabic device is `islamic-umm-al-qura`: day arithmetic survives that, month arithmetic does not. A month bucket taken from `Calendar.current` and printed with the Gregorian formatter of `Locale.latinDigits` puts a September fast under "أغسطس 2026" — the Gregorian month the Hijri month happened to begin in. Same rule as `Locale.latinDigits` one layer down: every day key, streak and seven-day dot is a Gregorian day, so anything that buckets those days has to agree with them.
- `Clock.gregorian` — computed, not stored: a stored `Calendar` freezes the time zone it was built in, so every caller that asks per use (the history's grouping is asked on each render) follows a zone change. `dayKeyFormatter` does not: it is a `static let` and freezes its zone at first use. That is the formatter's own question, not one this accessor answers for it.
- `Clock.dayKeyFormatter` — streak day keys are a local-calendar date as "yyyy-MM-dd". String-keyed so the persisted value stays readable and time-zone shifts do not reinterpret it.
- `Clock.goalDayKey(fastStart:goalHours:)` — the local day a fast's goal counts toward: the day the goal is crossed (`start + goal`), never the day someone noticed it. The single definition: the live streak (`CelebrateGoalThunk`) and a stored fast (`FastRecord.goalDayKey`) both read it, so a back-dated fast whose goal landed before midnight credits the same day on both screens.
- `Clock.daysBetween(_:_:)` — whole calendar days between two day keys; `nil` if either is not one, negative when `later` is the earlier. Days, not hours: a gap in seconds divided by 86400 gets a DST change wrong twice a year, and "the day after" has to mean the same thing on those two days as on the other 363.
- `Clock.nextDay(_:)` — month and year ends are the calendar's business, not string arithmetic's.
- `Clock.date(forDayKey:)` — parses a persisted streak day without letting the device's selected calendar reinterpret it; the matching formatter is also what created the key.
- `Clock.monthKey(ofDay:)` — taken off the key rather than re-derived from a date: the key's shape is fixed by `dayKeyFormatter`, and a second parse could only disagree with it.

## Container.swift

- `Container` — service locator for dependency injection: `let repo: SomeProtocol = container.inject()`.
- `container` — the global locator; registrations happen once at launch in `AppDependencies.register()`.

## RootReducer.swift

- `rootReducer(state:action:)` — pure and synchronous; delegates each substate to its feature reducer.

## UITestSeed.swift

The launch arguments below are a contract with the Maestro flows in `maestro-flows/` and with the table in `ARCHITECTURE.md`; renaming one silently breaks every flow that passes it.

- `UITestSeed` — seeds timer and review `UserDefaults` from launch arguments so UI tests reach time-dependent screens (goal reached, overtime, review prompt) without waiting 16h or rebooting the simulator to defeat cfprefsd. Offset-based: `-seedElapsed N` means "the fast started N seconds ago", resolved against the clock at launch, so a static Maestro flow stays accurate. A no-op unless a `-seed…` argument is present; DEBUG-only, never compiled into release.
- `UITestSeed.applyIfNeeded(_:)` — any `-seed…` argument first writes a clean baseline (timer, review, offer), then the given values override it, so an unspecified key never leaks state from a previous run. Clearing `plan_hours` falls back to `Plan.default`; `plan_idx` is the key of the plan before it was stored in hours and is cleared too.
- `UITestSeed.applyIfNeeded(_:)` — `-seedElapsed N` — a seeded fast is a fast in flight, so it carries a pinned goal like any other: the default plan, which is what the seeded state would have started from, unless `-seedPlanHours` overrides it.
- `UITestSeed.applyIfNeeded(_:)` — `-seedEatingElapsed N` — the eating window opened N seconds ago, fast not running. N past the window length lands on the window-closed screen; N past the window length + 24h falls through to idle — all derived from this one timestamp. The window's length belongs to the fast that opened it, so the goal is pinned the same way.
- `UITestSeed.applyIfNeeded(_:)` — `-seedPlanHours N` — N is the plan's length in hours (14/16/18/20, or any custom goal in `Plan.range`). It also re-pins the goal of a seeded in-flight cycle, which is what a fast started on that plan would carry. The name differs from the older `-seedPlan N`, which took a position in the preset list, on purpose: `-seedPlan 3` is a valid hours value too, so a flow left unchanged would seed a plausible 3-hour plan. `-seedPlan` is unrecognised, seeds nothing, and the plan falls back to the default.
- `UITestSeed.applyIfNeeded(_:)` — `-seedGoalHours N` — pins the running or eating fast's goal independently of the plan. Applied after `-seedElapsed` and `-seedPlanHours` so it overrides both: it is the only way to construct a fast whose pinned goal disagrees with the selected plan, which the "resume restores the pinned goal, not the plan" scenario needs.
- `UITestSeed.applyIfNeeded(_:)` — `-seedOfferShown 1` — the automatic offer (T1', see `Features/pro/NOTES.md`) has already been spent on this install. Its criterion — shown exactly once, ever, and not again after a dismiss — otherwise needs two qualified fasts inside one launch, and a launch cannot be re-seeded from inside itself. There is deliberately no argument for "armed but not yet shown": the plan to show lives only in the session that finished the fast and is never persisted, so a flow reaches it the way a user does — end a fast past the quality threshold, then open the eating window.
- `UITestSeed.applyIfNeeded(_:)` — `-seedStreak N` / `-seedLastGoalDate D` — the first sets the counter; the last-goal day defaults to today so the badge renders, and the second moves it D days back (D=1 is yesterday, so crossing a goal extends the streak to N+1).
- `UITestSeed.applyIfNeeded(_:)` — `-seedFreezeSpent 1` — this calendar month's protected day is already used up. Its criterion, one freeze per calendar month, needs a second missed day in one month, and a single launch cannot produce the first: spending a freeze takes a goal crossed on a day the flow cannot travel to. Without this argument the second-miss branch is reachable from unit tests only.
- `UITestSeed.applyIfNeeded(_:)` — `-seedFreezeSpent 1` — month charged — the one the app itself would debit for the gap this same seed describes, the month of the missed day, asked of `StreakStatus.freezeMonthCharged(afterGoalOn:)` rather than recomputed, so a seed cannot charge a different month than the rule. Not "the current month": on the 1st and 2nd those differ, and seeding today's would leave the freeze unspent exactly then — a flow green for 29 days a month and red on the other two. With no gap (last goal today or yesterday) there is nothing for a freeze to cover and the argument means today's month. The gap is checked explicitly rather than falling out of a `nil`: `-seedStreak N` alone already writes today into `streak_last_goal_date`, so a fallback keyed on "no last goal" would never run and the month of tomorrow would be charged — next month, on the 31st.
- `UITestSeed.applyIfNeeded(_:)` — `-seedHistoryDaysBack N` — shifts every seeded history record N days further into the past. The seeded block is anchored to the host's wall clock: without a shift the newest record runs "yesterday 20:00 → today ~12:00", so a flow that also seeds an in-flight fast collides with it before ~14:00 local time and runs clean after — testing what time the machine was switched on, red most of the day, which is how a real regression goes unnoticed. A shift rather than an absolute date keeps the records relative to now, so the seven-day dots, the streak and the "days ago" labels keep their meaning. Not applied by default: `IF5_S4_refusal_overlap` is built on the collision on purpose, and a flow that wants determinism asks for it by name.
- `UITestSeed.applyIfNeeded(_:)` — history wipe — history lives in a file, not in defaults, so it is wiped alongside the baseline. Through `wipeFile()` rather than `replaceAll([])`: `replaceAll` honours the history write guard, so a file left `.readOnly` by an earlier flow's `-seedHistoryFutureSchema` would make this wipe, and every `-seedHistory` after it, a silent no-op for the rest of the suite.
- `UITestSeed.applyIfNeeded(_:)` — `-seedHistoryCorrupt` — puts undecodable bytes where the history file goes, so the failed-decode (quarantine) path can be walked from a flow or by hand. Goes through the concrete `FastHistoryRepository` on purpose: the protocol speaks only in records, and a record that fails to decode is not something it can express. The cast is total in practice (the only conformance), and a miss seeds nothing rather than pretending it did.
- `UITestSeed.applyIfNeeded(_:)` — `-seedHistoryFutureSchema` — same reasoning, for the sibling path: a well-formed envelope from a schema this build does not know (`readOnly`), not an undecodable one (quarantine).
- `UITestSeed.warnIfSeededHistoryCollides(_:elapsed:)` — seeded history and a seeded in-flight fast can describe overlapping time, and the app is right to refuse the end (the overlap guard); but a flow that did not mean to exercise the guard cannot tell an overlap from a broken screen — it sees the refusal sheet where it expected a result. So the seeder says it in the diagnostics journal. A journal line, not a crash: a collision is legitimate when a flow wants it (`IF5_S4_refusal_overlap`), so the seeder reports and gets out of the way.
- `UITestSeed.warnIfSeededHistoryCollides(_:elapsed:)` — the overlap is asked of `FastRecord.firstOverlap`, the function the guard itself calls, so the warning cannot disagree with the behaviour it warns about.
- `UITestSeed.warnIfSeededHistoryCollides(_:elapsed:)` — takes the records just written rather than reading them back through `loadAll()`, and is called only from the two branches that write records. Both halves matter: `loadAll()` on the file left by `-seedHistoryCorrupt` would quarantine it and fire `onLoadFailure` inside the seeder, so `H11_history_corrupt_recovers`, the flow that watches the app survive those bytes, would find them already cleaned up and stay green without testing anything.
- `UITestSeed.dailyRecords(count:daysBack:)` — `count` fasts, one a day back from yesterday, with day four skipped so the seven-day dots show a real gap; durations vary between 16h02m and 18h12m so the rows do not look generated.
- `UITestSeed.edgeCaseRecords(daysBack:)` — the data shapes the design has to survive: a fast across midnight, one past 40 hours, one that fell short of its goal, and two on the same day.

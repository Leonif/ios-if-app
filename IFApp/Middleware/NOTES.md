# Middleware - notes for agents

Why the side-effect layer is the way it is. Middleware is handed the state after the reducer; several of them keep a snapshot of the previous state because the fact they need exists only before the action. The order of the list is set in `AppStoreFactory.make()` (see `Core/NOTES.md`). Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## AnalyticsMiddleware.swift

- `AnalyticsMiddleware` — translates actions into funnel events; the single place that decides what gets tracked, so the user journey is auditable.
- `AnalyticsMiddleware.reportedPlan` — the plan last reported as the `current_plan` user property. Tapping the plan that is already selected is not a selection, so it must not re-fire.
- `AnalyticsMiddleware.reportedEntitlement` — the entitlement last written to `pro_status`, so the property is set once per actual change rather than on every action that carries the state along.
- `AnalyticsMiddleware.previousPro` — the Pro substate before the action being handled. The dismissal event needs the trigger the reducer has just cleared, and this snapshot is where it still exists. Same device as `HistoryMiddleware.previousTimer`.
- `AnalyticsMiddleware.previousSunnah` — same device, for `sunnah_enabled`: the fact it hangs off — nothing was scheduled until this write — exists only before the write.
- `AnalyticsMiddleware.armingAwaitingAnswer` — a `settingsChanged` armed a schedule that was not armed before, and the answer saying whether it can be delivered has not arrived. "The reminders were switched on" is an edge, and every control on that screen writes through the same action: both switches and the reminder time emit `settingsChanged`, and the time control is a wheel that emits one per detent. Read as "a write landed on an enabled schedule", the event would count a schedule armed once and nudged by an hour as a dozen armings, and switching off one of two schedules as arming the other. The edge lives in `previousSunnah` and nowhere else.
- `AnalyticsMiddleware.handle(_:)` — `PlanAction` — the state is post-reduce, so `plan` is already the saved choice.
- `AnalyticsMiddleware.handle(_:settings:)` — the Sunnah opt-in: one event per switching-on, split across the two actions it takes to know both halves — which schedule was armed, and whether a reminder can be delivered. The reducer answers every `settingsChanged` with `.checking` while the middleware asks, so the edge is read from `previousSunnah`, and the note it leaves is spent by the delivery answer that follows.
- `AnalyticsMiddleware.handle(_:settings:)` — `.settingsChanged` — switched off before the answer came back clears the note: there is no schedule left for it to describe. A write on a schedule that was already armed (a time moved, a second schedule added, one of two switched off) leaves the note alone rather than assigning `false`: flipping the second switch before the first one's answer arrives is one switching-on, and assigning would swallow the note the first left. The window is one scheduling round trip, or the permission dialog when it is up.
- `AnalyticsMiddleware.handle(_:settings:)` — `.deliveryUpdated` — raised on the answer rather than on the tap, because half of what the event reports is whether a reminder can be delivered, and the permission is known only once read. A `deliveryUpdated` from a refresh, cold start, day change or time-zone change finds no note and is silent. `.denied` is the one delivery state meaning nothing was written; `.failed` is a permission that exists and a schedule that did not take — a different fact, not this parameter's.
- `AnalyticsMiddleware.handle(_:)` — `EndFastAction` — only the refusal is worth a line: how often a real end runs into a saved fast, and how often it is the start-clash kind with no re-pick out of it.
- `AnalyticsMiddleware.handle(_:)` — `HistoryAction.exportFinished` — only a share that went through. Opening the sheet and backing out is not an export, and counting it would inflate the one number the import decision is read off. Saving a fast is already covered by `fast_stopped`, and writing the file is a step on the way, not the act.
- `AnalyticsMiddleware.handle(_:trigger:)` — every offer and purchase event carries `trigger`: at 20-35 shows a month the distribution over entry points is the only thing readable; a conversion rate off 0-1 purchases is not.
- `AnalyticsMiddleware.handle(_:trigger:)` — `.purchasePending` — Ask to Buy is not a purchase and not yet a loss: logged as the reason the attempt did not end in Pro, and may still be approved later.
- `AnalyticsMiddleware.handle(_:trigger:)` — silent cases — reading the entitlement is not a funnel step (the `pro_status` property carries the outcome); a restore that finds nothing is the same non-event; the two notices report something the user did not do. Arming and cancelling the automatic offer are deliberately silent: the funnel counts shows, and a show is `offerOpened`. An armed plan that never fires is not a paywall the user saw, and logging it would put the distribution over triggers out by the whole suppression rate.
- `AnalyticsMiddleware.trigger(after:)` — the entry point to report. The state holds it while the offer is up; on the dismissal the reducer has already cleared it, so the pre-reduce snapshot answers. Restore can run from the About sheet's own button with no offer open, and then neither snapshot holds a door: the trigger is `unknown`, not `manual`. `manual` means a permanent entry the user went looking for, and the newer doors are measured against it, so the "no entry point" fallback has to sit outside it.
- `AnalyticsMiddleware.reportCurrentPlan(_:)` — keeps `current_plan` on the user. Set on cold start too, so reports can be segmented by plan for the majority who never open the editor.

## DiagnosticsMiddleware.swift

- `DiagnosticsMiddleware` — writes the action stream to the diagnostics journal. Logging is a side effect, so it lives in a middleware rather than in the store or the views (invariant 2), and it is the only place that decides what a diagnostic line looks like. It is inserted first in the middleware list so that if a later middleware throws or wedges, the action that led there is already on disk. Compiled out outside DEBUG and DEVELOPMENT.
- `DiagnosticsMiddleware.digest(_:)` — the fields a failing flow is decided by, on one line. Deliberately not the whole `AppState`: a dump of every substate on every action is unreadable when it is needed, and the history array alone would bury the sequence. What is here is what the state machine in `test-scenarios.md` branches on — whether a cycle is in flight, which goal it runs to, and what the entitlement machinery is doing.

## EndFastMiddleware.swift

- `EndFastMiddleware` — runs the correction sheet's thunks for its intents: "End fast" opens the sheet, a chip or a step moves the choice, the primary button confirms it. The payload of the tap (the chip's offset, the step's minutes) travels in the intent unchanged and the thunk still reads the clock itself, so the moment is resolved when the thunk runs, as it was when the view dispatched it. No other middleware matches `is EndFastAction`, and `AnalyticsMiddleware` logs only `.refused`, so the intents reach nothing else.

## HistoryMiddleware.swift

- `HistoryMiddleware` — the single place that decides a finished fast is written; the write itself is `SaveFastRecordThunk`, and a delete is `DeleteFastRecordThunk` (repositories only from thunks, `ARCHITECTURE.md` invariant 17). The decision lives here rather than in the ending thunks so every ending follows one rule: End fast from active or overtime writes a record; Reset discards the fast and writes nothing, which is what the reset confirm sheet promises.
- `HistoryMiddleware.previousTimer` — the timer state before the action being handled. The fast being ended is already gone from the post-reduce state, so the record is built from this snapshot.
- `HistoryMiddleware.handle(action:state:dispatch:)` — `.exportTapped` — the export row's tap; the Pro gate stays in the view (a free user's tap opens the offer instead), so the intent only ever means "write the file". The thunk refuses an empty or busy history itself, so nothing is checked twice here.
- `HistoryMiddleware.minimumDuration` — shorter than a minute is a mis-tap, not a fast.
- `HistoryMiddleware.record(_:dispatch:)` — `.stopped` — trusts the thunk's `elapsed`: it already resolved the clock once. Every other timer action returns: `.reset` discards the fast, and the rest never end a running fast.
- `HistoryMiddleware.record(_:dispatch:)` — `goalHours` — the goal the fast actually ran to, pinned at its start, so a plan change (or a lost entitlement) part-way through cannot relabel it afterwards.

## MealMiddleware.swift

- `MealMiddleware` — runs the last-meal picker's thunks for its intents: a chip, the ribbon's haptic cue, the exact time from the system picker, the confirm, and the closed window that seeds the picker. The haptic cue comes once per snap step while scrubbing; it is still one thunk per cue, as it was from the view, and the intent changes no state, so the store publishes nothing for it. The ribbon's own value stays the plain `scrubbed` action (see `Flows/NOTES.md`, `onScrub`). No other middleware matches `is MealAction`.

## NotificationMiddleware.swift

- `NotificationMiddleware` — keeps the two timer pushes in sync with the timer: the goal-reached push while a fast runs and the eating-window-closed push while a window is open. Re-syncs on every `TimerAction`, `PlanAction` and `AppLifecycleAction`, so anything that can move a deadline or the running state is covered, launch included.
- `NotificationMiddleware.handle(action:state:dispatch:)` — `appOpened` — the two launch thunks are about notifications (clearing the legacy daily reminders and reporting `push_status`), so they start here, next to the other notification work, rather than in `StoreMiddleware`, which owns StoreKit. They are independent and their order does not matter: the cleanup only removes two pending requests by identifier and asks nothing, and the status report only reads the permission.
- `NotificationMiddleware.sync(_:)` — each push is scheduled while its deadline is ahead and cancelled otherwise; idempotent, so it is safe on every relevant action. Uses the goal of the cycle in flight (`activeGoalHours`), not the plan setting: a plan change mid-fast must not move a push that belongs to a fast already under way.

## PersistenceMiddleware.swift

- `PersistenceMiddleware` — persists the timer substate after every timer action, the plan after every plan action, and the spent automatic offer; lives for the whole app lifecycle.
- `PersistenceMiddleware.handle(action:state:dispatch:)` — `ProAction` — written from the reduced state, not from the action that spends it, like the timer: when the one-time offer counts as spent is the reducer's rule and belongs in one place. A second copy here would keep compiling while quietly not persisting a show.

## ReviewMiddleware.swift

- `ReviewMiddleware` — calls the native review request right after a finished fast, gated to at most 3 lifetime calls, once a day and once a launch. One trigger: the user left the result screen through "Start eating window" and the eating window card has settled (`eatingWindowSettled`, which only follows `TimerAction.eatingStarted`). The result has been seen and the task is over — that pause is where the prompt goes.
- `ReviewMiddleware` — the one-time offer (T1') outranks it: when the offer is owed the view gives it the moment and never sends `eatingWindowSettled`, and the next qualified fast tries again.
- `ReviewMiddleware` — the gates are spent, and `review_prompted` logged, only once the native call has gone out on an active scene. No active scene means nothing was asked: the attempt stays unspent and the next qualified fast tries again.
- `ReviewMiddleware.minCompletedSessions` — the first finished fast is too early to ask about the app.
- `ReviewMiddleware.isRequestInFlight` — a native call is out and its result has not come back; the gates are still unspent, so without this a second action would start a second call.
- `ReviewMiddleware.qualifies(_:)` — the fast behind this eating window earned the prompt: it reached its own goal and is at least the second one. Read from the history, not remembered here, so a `.complete` that survived a cold start still counts. The latest record must be the fast that opened this window: the window is anchored to that fast's confirmed end, and the record carries the same end. A fast too short to be recorded (`HistoryMiddleware.minimumDuration`) leaves an older fast as the latest record, and that one must not speak for it. Whether T1' takes the moment instead is not decided here: the view sends `eatingWindowSettled` only when the offer is not owed.
- `ReviewMiddleware.requestReview(trigger:dispatch:)` — the lifetime attempt is spent and the event logged after the call reports it went out on an active scene, never before: there are three attempts in a lifetime, and one burnt on a scene Apple ignores is a prompt the user never saw, counted as shown.

## SourcesMiddleware.swift

- `SourcesMiddleware` — opens the paper behind the reader's "read the original" button. The intent is a lifecycle action because the reader has no state of its own, and the analytics event hangs off the same action, so the event and the opened link cannot drift apart.

## StoreMiddleware.swift

- `StoreMiddleware` — starts everything that talks to the store and calls the store itself nowhere (invariant 17). On `appOpened` it starts `SyncEntitlementThunk`, which outlives any one screen: a refund can land on the idle timer and the offer screen may never be opened.
- `StoreMiddleware.handle(action:state:dispatch:)` — `purchaseTapped`, `restoreTapped` — the Buy and Restore taps (the offer screen and the About sheet) start their attempts here: one owner for everything that talks to the store. The thunks dispatch their own `purchaseStarted` / `restoreStarted`, so these intents are not the start of the attempt and analytics stays silent on them.

## StreakMiddleware.swift

- `StreakMiddleware` — shows the streak milestone card once per threshold (3/7/14/30), after the goal-reached moment has settled (`goalScreenSettled`) so it never covers the seal and sweep.

## SunnahMiddleware.swift

- `SunnahMiddleware` — replacement is serial (each pass awaits the previous task) so an older async scheduling pass cannot restore reminders a newer one cancelled.
- `SunnahMiddleware.handle(action:state:dispatch:)` — `systemSettingsTapped` — the refusal's way out to iOS Settings. It returns before the scheduling pass: opening Settings changes nothing yet, and the permission is re-read when the app becomes active again.
- `SunnahMiddleware.handle(action:state:dispatch:)` — `requestIfUndetermined` — one permission ask for the whole app; the resolved action comes back through this middleware and schedules on the answer.
- `SunnahMiddleware.handle(action:state:dispatch:)` — `deliveryUpdated` dates — the upcoming dates are what was scheduled, not what the calendar holds. With the permission refused nothing was written (`replace([])`), so a list would be a promise the app cannot keep: a screen that reads as configured while no reminder can fire.

## TimerMiddleware.swift

- `TimerMiddleware` — runs the timer's thunks for the timer screen's intents: start, resume, reset, start eating, continue fasting, and the goal moment. One intent per thunk; the three start buttons (idle ring, eating card, history's empty state) share `startFastTapped`, because analytics counts the start off `.started` and never knew which button it came from. Each thunk reads the state as it did before: the intents change nothing in any reducer, so the state the thunk is handed is the one it would have been handed from the view.
- `TimerMiddleware` — the intents are `TimerAction` cases, so every middleware matching `is TimerAction` sees them too: `PersistenceMiddleware` saves the unchanged timer and `NotificationMiddleware` re-syncs the two pushes. Both are idempotent, so the extra pass is harmless; `HistoryMiddleware` records only on `.stopped`.


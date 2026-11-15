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

## HistoryMiddleware.swift

- `HistoryMiddleware` — the single place a finished fast is written. Here rather than in the thunks so every ending follows one rule: End fast from active or overtime writes a record; Reset discards the fast and writes nothing, which is what the reset confirm sheet promises.
- `HistoryMiddleware.previousTimer` — the timer state before the action being handled. The fast being ended is already gone from the post-reduce state, so the record is built from this snapshot.
- `HistoryMiddleware.minimumDuration` — shorter than a minute is a mis-tap, not a fast.
- `HistoryMiddleware.record(_:dispatch:)` — `.stopped` — trusts the thunk's `elapsed`: it already resolved the clock once. Every other timer action returns: `.reset` discards the fast, and the rest never end a running fast.
- `HistoryMiddleware.record(_:dispatch:)` — `goalHours` — the goal the fast actually ran to, pinned at its start, so a plan change (or a lost entitlement) part-way through cannot relabel it afterwards.

## NotificationMiddleware.swift

- `NotificationMiddleware` — keeps the two timer pushes in sync with the timer: the goal-reached push while a fast runs and the eating-window-closed push while a window is open. Re-syncs on every `TimerAction`, `PlanAction` and `AppLifecycleAction`, so anything that can move a deadline or the running state is covered, launch included.
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

## StoreMiddleware.swift

- `StoreMiddleware` — owns the two things about the store that outlive any one screen: the entitlement read at launch, and the listener for changes nobody asked for (an approved Ask to Buy, a purchase on another device, a refund, a family member leaving the group). The listener has to run whenever the app does, not while some screen is up: a refund can land on the idle timer and the offer screen may never be opened. Middleware is the only thing with that lifetime and a dispatch.
- `StoreMiddleware.startListening(dispatch:)` — idempotent: `appOpened` is dispatched once per launch, but a second one must not leave two listeners racing to report the same transaction.

## StreakMiddleware.swift

- `StreakMiddleware` — shows the streak milestone card once per threshold (3/7/14/30), after the goal-reached moment has settled (`goalScreenSettled`) so it never covers the seal and sweep.

## SunnahMiddleware.swift

- `SunnahMiddleware` — replacement is serial (each pass awaits the previous task) so an older async scheduling pass cannot restore reminders a newer one cancelled.
- `SunnahMiddleware.handle(action:state:dispatch:)` — `requestIfUndetermined` — one permission ask for the whole app; the resolved action comes back through this middleware and schedules on the answer.
- `SunnahMiddleware.handle(action:state:dispatch:)` — `deliveryUpdated` dates — the upcoming dates are what was scheduled, not what the calendar holds. With the permission refused nothing was written (`replace([])`), so a list would be a promise the app cannot keep: a screen that reads as configured while no reminder can fire.

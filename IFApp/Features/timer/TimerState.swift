//
//  TimerState.swift
//  IFApp
//
//  Fasting timer substate. Elapsed time is NOT stored — it is derived from
//  `fastStartTimestamp` and the current clock in the view (see TimerProps).
//

import Foundation

/// The streak as the two facts it takes to show it: how long the run is, and the day
/// it was last extended. They travel together on purpose — a screen that carries only
/// the counter cannot apply the missed-day rule, which is how the main screen and the
/// history card came to show two different numbers for one state.
struct StreakStatus: Equatable, Sendable {
    var count: Int = 0
    /// Local day key ("yyyy-MM-dd") of the last goal. nil = no goal ever reached.
    var lastGoalDate: String? = nil
    /// The calendar month ("yyyy-MM") whose protected day is already used up.
    /// nil = none ever. See `freezeCovers(_:)` for which month gets charged.
    var freezeSpentMonth: String? = nil
    /// Whether this install owns the protected day at all — i.e. holds Pro. It is
    /// not stored with the streak; it is handed in by whoever projects the streak
    /// (`AppState.streak`, `TimerAction.goalCelebrated`), because the entitlement has
    /// exactly one home and the streak is not it.
    var ownsFreeze: Bool = false

    /// Whether the protected day can carry a run last extended on `lastGoalDate`
    /// across to a goal reached on `dayKey`.
    ///
    /// Three conditions, and this is the single definition of all three — the
    /// projection below and the reducer that spends the freeze both ask here:
    ///
    /// - **exactly one calendar day was missed** (`dayKey` is two days on from the
    ///   last goal). Two missed days in a row are a hard reset, as before: one
    ///   protected day protects one day;
    /// - **the install owns Pro**. Without it nothing changes — a missed day resets;
    /// - **the month is unspent**. The month charged is the month of the *missed
    ///   day*, not of the goal that follows it: the benefit protects a day, so the
    ///   day being protected is what decides who pays. That is also what makes a day
    ///   missed on the 31st and a day missed on the 1st two different months'
    ///   business, which is the plain reading of "one per calendar month".
    func freezeCovers(_ dayKey: String) -> Bool {
        guard ownsFreeze,
              let lastGoalDate,
              Clock.daysBetween(lastGoalDate, dayKey) == 2,
              let missedDay = Clock.nextDay(lastGoalDate) else { return false }
        return freezeSpentMonth != Clock.monthKey(ofDay: missedDay)
    }

    /// The month a freeze spent on the gap ending at `dayKey` is charged to, or nil
    /// when there is no such gap. Paired with `freezeCovers(_:)` on purpose: the rule
    /// that picks the month is written once, and the reducer that debits it reads the
    /// answer instead of recomputing which day was missed.
    func freezeMonth(coveringGapTo dayKey: String) -> String? {
        guard freezeCovers(dayKey), let lastGoalDate,
              let missedDay = Clock.nextDay(lastGoalDate) else { return nil }
        return Clock.monthKey(ofDay: missedDay)
    }

    /// The number to display: 0 once a day was missed (last goal before yesterday),
    /// unless the protected day still stands between the run and that gap.
    /// The persisted counter itself is only rewritten on the next goal.
    ///
    /// The freeze is applied here, to what is shown, and not only when the next goal
    /// banks it, because the promise sold is that the run does not break — a counter
    /// that drops to 0 for a day and comes back has already broken it in the only
    /// place the user can see. Reading it off `ownsFreeze` as it stands *now* is also
    /// the whole of edge 8: buying Pro during the gap day restores the run it broke,
    /// and buying a day later does not, which is the 24-hour window stated in days.
    func displayed(at now: Date) -> Int {
        guard let lastGoalDate else { return 0 }
        let today = Clock.dayKey(now)
        if lastGoalDate == today || Clock.isDayBefore(lastGoalDate, today) { return count }
        return freezeCovers(today) ? count : 0
    }
}

struct TimerState: Equatable, Sendable {
    /// Epoch seconds when the running fast began. 0 = no running fast.
    var fastStartTimestamp: Double = 0
    /// The goal the fast in flight was started with, in hours. Pinned at `.started`
    /// and carried until the cycle ends, so changing the plan mid-fast — or losing
    /// the Pro entitlement under a custom goal — cannot silently rewrite the goal of
    /// a fast already running, move its push, or flip the `completed` flag it will be
    /// recorded with. 0 = not pinned: state written by a version before this field
    /// (or no cycle in flight), and readers fall back to the current plan, which is
    /// exactly the old behaviour.
    var goalHours: Double = 0
    var isRunning: Bool = false
    /// Elapsed seconds to display while NOT running (paused/staged value). Not persisted.
    var stagedElapsed: TimeInterval = 0
    /// Count of fasts that reached the "completed" threshold — gates the review prompt.
    var completedSessionsCount: Int = 0
    /// Whether the goal-reached moment already fired for the current fast. Persisted so
    /// relaunching mid-overtime restores the steady end-state without replaying it.
    var hasCelebrated: Bool = false
    /// Epoch seconds when the eating window opened. 0 = no window. Length is derived
    /// from the plan (24 − fastHours), not stored.
    var eatingStartTimestamp: Double = 0
    /// Whether an eating window is currently open. Persisted so the window survives relaunch.
    var isEating: Bool = false
    /// Consecutive local-calendar days with the goal reached. Advanced on `goalCelebrated`;
    /// a missed day hard-resets it to 1 on the next goal. What screens *show* is
    /// `streak.displayed(at:)`, not this raw counter.
    var streakCount: Int = 0
    /// Local day key ("yyyy-MM-dd") of the last goal. nil = no goal ever reached.
    var lastGoalDate: String? = nil
    /// The calendar month ("yyyy-MM") whose protected day has been spent, or nil.
    /// One month is enough to store: the allowance is one per month, so the only
    /// question ever asked is whether *this* month's is gone.
    var freezeSpentMonth: String? = nil

    /// The streak fields as one value — the only thing screens should project, so the
    /// missed-day rule is applied once and identically everywhere. `ownsFreeze` comes
    /// from the entitlement, which the timer substate deliberately does not hold;
    /// callers use `AppState.streak` rather than assembling it themselves.
    func streak(ownsFreeze: Bool) -> StreakStatus {
        StreakStatus(count: streakCount,
                     lastGoalDate: lastGoalDate,
                     freezeSpentMonth: freezeSpentMonth,
                     ownsFreeze: ownsFreeze)
    }

    /// The goal of the cycle in flight: the pinned one, or the plan's when nothing is
    /// pinned. The single definition of that fallback — every screen, push, record and
    /// event asks here rather than deciding for itself what "the goal" means.
    func resolvedGoalHours(planHours: Double) -> Double {
        goalHours > 0 ? goalHours : planHours
    }

    /// Where a fast put in flight at `now` has its start: shifted back by whatever is
    /// already staged, so the count carries on instead of restarting at zero.
    ///
    /// Staged time reaches here two ways — a back-dated last meal ahead of the start,
    /// and an ending that was taken back — and both are the same arithmetic. One
    /// definition rather than one per caller: if what counts as elapsed ever grows a
    /// rule (a pause, a segmented count), a second copy would go on compiling with the
    /// old one and only the screen it feeds would be wrong.
    func startTimestamp(at now: Double) -> Double {
        now - stagedElapsed
    }

    /// Epoch seconds when the open eating window closes. The window length is not
    /// stored, so this is the single definition of the close moment — the countdown
    /// card, the window-closed push, the chained fast and the last-meal seed all read
    /// it here. Meaningless while `isEating` is false (`eatingStartTimestamp` is 0).
    ///
    /// It takes the plan rather than a number of hours on purpose. *Why* the window is
    /// that long — the rest of the day left over by the fast — is the plan's rule and
    /// is stated once, in `Plan.windowHours`; here it is arithmetic. And a plan cannot
    /// be confused at the call site with the goal length sitting next to it, which two
    /// interchangeable `Double`s could be: `windowHours: activeGoalHours` would have
    /// compiled and quietly produced a 16-hour window instead of an 8-hour one.
    ///
    /// Pass `AppState.activePlan` — the plan the cycle in flight is running to, not
    /// `planState.plan`, which is merely what the user currently has selected.
    func eatingEndTimestamp(plan: Plan) -> Double {
        eatingStartTimestamp + Double(plan.windowHours) * 3600
    }
}

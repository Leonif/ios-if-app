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

    /// The number to display: 0 once a day was missed (last goal before yesterday).
    /// The persisted counter itself is only rewritten on the next goal.
    func displayed(at now: Date) -> Int {
        guard let lastGoalDate else { return 0 }
        let today = Clock.dayKey(now)
        return (lastGoalDate == today || Clock.isDayBefore(lastGoalDate, today)) ? count : 0
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

    /// The streak fields as one value — the only thing screens should project, so the
    /// missed-day rule is applied once and identically everywhere.
    var streak: StreakStatus { StreakStatus(count: streakCount, lastGoalDate: lastGoalDate) }

    /// The goal of the cycle in flight: the pinned one, or the plan's when nothing is
    /// pinned. The single definition of that fallback — every screen, push, record and
    /// event asks here rather than deciding for itself what "the goal" means.
    func resolvedGoalHours(planHours: Double) -> Double {
        goalHours > 0 ? goalHours : planHours
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

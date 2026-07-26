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

    /// Epoch seconds when the open eating window closes: it runs out the rest of the
    /// 24h day left over after the plan's fast. The window length is not stored, so
    /// this is the single definition of the close moment — the countdown card, the
    /// window-closed push, the chained fast and the last-meal seed all read it here.
    /// Meaningless while `isEating` is false (`eatingStartTimestamp` is 0 then).
    func eatingEndTimestamp(fastHours: Double) -> Double {
        eatingStartTimestamp + (24 - fastHours) * 3600
    }
}

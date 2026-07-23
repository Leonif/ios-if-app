//
//  TimerState.swift
//  IFApp
//
//  Fasting timer substate. Elapsed time is NOT stored — it is derived from
//  `fastStartTimestamp` and the current clock in the view (see TimerProps).
//

import Foundation

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
    /// a missed day hard-resets it to 1 on the next goal. Display treats a stale
    /// `lastGoalDate` (before yesterday) as 0 without touching this counter.
    var streakCount: Int = 0
    /// Local day key ("yyyy-MM-dd") of the last goal. nil = no goal ever reached.
    var lastGoalDate: String? = nil
}

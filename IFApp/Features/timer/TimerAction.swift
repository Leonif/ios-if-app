//
//  TimerAction.swift
//  IFApp
//
//  Feature-namespaced actions. Timestamps are injected by thunks (reducers stay pure).
//

import Foundation
import Redux

enum TimerAction: Action {
    /// Begin a fast. `startTimestamp` already accounts for any staged elapsed time.
    /// `goalHours` is the goal this fast runs to — injected at dispatch and pinned in
    /// state, so it stops following the plan setting once the fast is under way.
    case started(startTimestamp: Double, goalHours: Double)
    /// End a fast. `qualifiesAsCompleted` = the fast reached its goal. Analytics-only:
    /// completed fasts are counted on `goalCelebrated`, not here.
    case stopped(elapsed: TimeInterval, qualifiesAsCompleted: Bool)
    /// Clear everything back to zero. `elapsed` = how long the fast had been running
    /// at the moment of the reset (staged value when it was not running). Analytics-only:
    /// the reducer zeroes everything either way. It travels in the action because the
    /// middleware sees post-reduce state, where the timer is already cleared.
    case reset(elapsed: TimeInterval)
    /// Manual ± adjustment. `runningStartTimestamp` is non-nil only when the fast is running.
    case timeAdjusted(newElapsed: TimeInterval, runningStartTimestamp: Double?)
    /// The goal-reached moment fired for the current fast (marks it so it plays once).
    /// `dayKey` = the local day the goal counts toward (see Clock.dayKey) — injected
    /// at dispatch so the reducer stays pure; a fast crossing midnight credits the
    /// day the goal was actually reached.
    case goalCelebrated(dayKey: String)
    /// Open the eating window. `startTimestamp` = when it opened (usually now).
    case eatingStarted(startTimestamp: Double)
    /// Close the eating window back to idle (window elapsed, or skipped).
    case eatingEnded
}

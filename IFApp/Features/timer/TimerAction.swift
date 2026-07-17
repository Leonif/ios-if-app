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
    case started(startTimestamp: Double)
    /// End a fast. `qualifiesAsCompleted` = the fast reached its goal. Analytics-only:
    /// completed fasts are counted on `goalCelebrated`, not here.
    case stopped(elapsed: TimeInterval, qualifiesAsCompleted: Bool)
    /// Clear everything back to zero.
    case reset
    /// Manual ± adjustment. `runningStartTimestamp` is non-nil only when the fast is running.
    case timeAdjusted(newElapsed: TimeInterval, runningStartTimestamp: Double?)
    /// The goal-reached moment fired for the current fast (marks it so it plays once).
    case goalCelebrated
    /// Open the eating window. `startTimestamp` = when it opened (usually now).
    case eatingStarted(startTimestamp: Double)
    /// Close the eating window back to idle (window elapsed, or skipped).
    case eatingEnded
}

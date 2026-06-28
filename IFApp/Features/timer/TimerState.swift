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
}

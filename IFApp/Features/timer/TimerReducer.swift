//
//  TimerReducer.swift
//  IFApp
//
//  Pure and synchronous. Writes only to TimerState.
//

import Redux

func timerReducer(state: TimerState, action: Action) -> TimerState {
    var newState = state

    switch action as? TimerAction {
    case let .started(startTimestamp):
        newState.fastStartTimestamp = startTimestamp
        newState.isRunning = true

    case let .stopped(elapsed, qualifies):
        newState.isRunning = false
        newState.fastStartTimestamp = 0
        newState.stagedElapsed = elapsed
        if qualifies {
            newState.completedSessionsCount += 1
        }

    case .reset:
        newState.isRunning = false
        newState.fastStartTimestamp = 0
        newState.stagedElapsed = 0

    case let .timeAdjusted(newElapsed, runningStartTimestamp):
        newState.stagedElapsed = newElapsed
        if let runningStartTimestamp {
            newState.fastStartTimestamp = runningStartTimestamp
        }

    case .none:
        break
    }

    return newState
}

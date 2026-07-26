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
        newState.hasCelebrated = false
        // Starting a fast closes any open eating window.
        newState.isEating = false
        newState.eatingStartTimestamp = 0

    case let .stopped(elapsed, _):
        newState.isRunning = false
        newState.fastStartTimestamp = 0
        newState.stagedElapsed = elapsed

    case .reset:
        newState.isRunning = false
        newState.fastStartTimestamp = 0
        newState.stagedElapsed = 0
        newState.hasCelebrated = false
        newState.isEating = false
        newState.eatingStartTimestamp = 0

    case let .timeAdjusted(newElapsed, runningStartTimestamp):
        newState.stagedElapsed = newElapsed
        if let runningStartTimestamp {
            newState.fastStartTimestamp = runningStartTimestamp
        }

    case let .goalCelebrated(dayKey):
        // Idempotent by design: syncGoalMoment is called from two places and props
        // update asynchronously, so the guard lives here rather than in the view.
        // Reaching the goal — not tapping "End fast" — is what completes a fast.
        if !newState.hasCelebrated {
            newState.hasCelebrated = true
            newState.completedSessionsCount += 1
            // Streak: a goal the day after the last one extends it; a gap (or the
            // first goal ever) restarts it at 1 — a missed day is a hard reset.
            // Day keys sort chronologically, so a stamp that is not newer than the
            // last goal leaves the run untouched: the same day again, or an earlier
            // day arriving from a fast back-dated across midnight. Neither can
            // extend a run, and neither may drag it backwards.
            if let last = newState.lastGoalDate {
                if dayKey > last {
                    newState.streakCount = Clock.isDayBefore(last, dayKey) ? newState.streakCount + 1 : 1
                    newState.lastGoalDate = dayKey
                }
            } else {
                newState.streakCount = 1
                newState.lastGoalDate = dayKey
            }
        }

    case let .eatingStarted(startTimestamp):
        // Opening the window clears the finished fast (like reset, but into eating).
        newState.isRunning = false
        newState.fastStartTimestamp = 0
        newState.stagedElapsed = 0
        newState.hasCelebrated = false
        newState.isEating = true
        newState.eatingStartTimestamp = startTimestamp

    case .eatingEnded:
        newState.isEating = false
        newState.eatingStartTimestamp = 0

    case .none:
        break
    }

    return newState
}

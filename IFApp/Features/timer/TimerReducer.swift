//
//  TimerReducer.swift
//  IFApp
//

import Redux

func timerReducer(state: TimerState, action: Action) -> TimerState {
    var newState = state

    switch action as? TimerAction {
    case let .started(startTimestamp, goalHours):
        newState.fastStartTimestamp = startTimestamp
        newState.goalHours = goalHours
        newState.isRunning = true
        newState.hasCelebrated = false
        newState.fastEndTimestamp = 0
        newState.isEating = false
        newState.eatingStartTimestamp = 0

    case let .stopped(elapsed, _, _):
        newState.isRunning = false
        newState.fastEndTimestamp = state.fastStartTimestamp + elapsed
        newState.fastStartTimestamp = 0
        newState.stagedElapsed = elapsed

    case let .stopUndone(startTimestamp):
        newState.isRunning = true
        newState.fastStartTimestamp = startTimestamp
        newState.stagedElapsed = 0
        newState.fastEndTimestamp = 0

    case .reset:
        newState = state.withoutCycle()

    case let .timeAdjusted(newElapsed, runningStartTimestamp):
        newState.stagedElapsed = newElapsed
        if let runningStartTimestamp {
            newState.fastStartTimestamp = runningStartTimestamp
        }

    case let .goalCelebrated(dayKey, ownsFreeze):
        if !newState.hasCelebrated {
            newState.hasCelebrated = true
            newState.completedSessionsCount += 1
            if let last = newState.lastGoalDate {
                if dayKey > last {
                    let streak = state.streak(ownsFreeze: ownsFreeze)
                    if Clock.isDayBefore(last, dayKey) {
                        newState.streakCount += 1
                    } else if let month = streak.freezeMonth(coveringGapTo: dayKey) {
                        newState.streakCount += 1
                        newState.freezeSpentMonth = month
                    } else {
                        newState.streakCount = 1
                    }
                    newState.lastGoalDate = dayKey
                }
            } else {
                newState.streakCount = 1
                newState.lastGoalDate = dayKey
            }
        }

    case let .eatingStarted(startTimestamp):
        newState.isRunning = false
        newState.fastStartTimestamp = 0
        newState.stagedElapsed = 0
        newState.fastEndTimestamp = 0
        newState.hasCelebrated = false
        newState.isEating = true
        newState.eatingStartTimestamp = startTimestamp

    case .eatingEnded:
        newState.isEating = false
        newState.eatingStartTimestamp = 0
        newState.goalHours = 0

    case .startFastTapped, .resumeTapped, .resetTapped, .startEatingTapped,
         .continueFastingTapped, .goalMomentStarted, .none:
        break
    }

    return newState
}

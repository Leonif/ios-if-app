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
    case let .started(startTimestamp, goalHours):
        newState.fastStartTimestamp = startTimestamp
        newState.goalHours = goalHours
        newState.isRunning = true
        newState.hasCelebrated = false
        newState.fastEndTimestamp = 0
        // Starting a fast closes any open eating window.
        newState.isEating = false
        newState.eatingStartTimestamp = 0

    case let .stopped(elapsed, _, _):
        newState.isRunning = false
        // Derived from the payload and the state as it stands, not from the clock:
        // the confirmed end is exactly the start plus what was confirmed as elapsed.
        newState.fastEndTimestamp = state.fastStartTimestamp + elapsed
        newState.fastStartTimestamp = 0
        newState.stagedElapsed = elapsed

    case let .stopUndone(startTimestamp):
        // The exact inverse of `.stopped`, and nothing more. `goalHours` stays pinned
        // (this is the same fast, not a new one), `hasCelebrated` stays as it was (a
        // fast resumed from overtime must not celebrate its goal a second time), and
        // `completedSessionsCount` / the streak are untouched because they are written
        // on reaching the goal, not on ending.
        newState.isRunning = true
        newState.fastStartTimestamp = startTimestamp
        newState.stagedElapsed = 0
        newState.fastEndTimestamp = 0

    case .reset:
        newState.isRunning = false
        newState.fastStartTimestamp = 0
        // The cycle is gone, so its pinned goal goes with it: the next fast starts
        // from the plan as it stands then.
        newState.goalHours = 0
        newState.stagedElapsed = 0
        newState.fastEndTimestamp = 0
        newState.hasCelebrated = false
        newState.isEating = false
        newState.eatingStartTimestamp = 0

    case let .timeAdjusted(newElapsed, runningStartTimestamp):
        newState.stagedElapsed = newElapsed
        if let runningStartTimestamp {
            newState.fastStartTimestamp = runningStartTimestamp
        }

    case let .goalCelebrated(dayKey, ownsFreeze):
        // Idempotent by design: syncGoalMoment is called from two places and props
        // update asynchronously, so the guard lives here rather than in the view.
        // Reaching the goal — not tapping "End fast" — is what completes a fast.
        if !newState.hasCelebrated {
            newState.hasCelebrated = true
            newState.completedSessionsCount += 1
            // Streak: a goal the day after the last one extends it; a gap (or the
            // first goal ever) restarts it at 1 — a missed day is a hard reset,
            // unless Pro's protected day stands in the gap and this month's is still
            // unspent, in which case the run carries on and the month is charged.
            // Day keys sort chronologically, so a stamp that is not newer than the
            // last goal leaves the run untouched: the same day again, or an earlier
            // day arriving from a fast back-dated across midnight. Neither can
            // extend a run, and neither may drag it backwards.
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
        // Opening the window clears the finished fast (like reset, but into eating).
        // `goalHours` deliberately survives: the window's length is the rest of the
        // day left over by the fast that just ended, so it belongs to that goal.
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
        // End of the cycle — nothing is in flight to hold a goal for.
        newState.goalHours = 0

    case .none:
        break
    }

    return newState
}

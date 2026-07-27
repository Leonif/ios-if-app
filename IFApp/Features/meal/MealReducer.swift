//
//  MealReducer.swift
//  IFApp
//

import Redux

func mealReducer(state: MealState, action: Action) -> MealState {
    var newState = state

    switch action as? MealAction {
    case let .initialized(ateDay, ateMin):
        if newState.ateMin < 0 {
            newState.ateDay = ateDay
            newState.ateMin = ateMin
            newState.chipIdx = -1
        }

    case let .scrubbed(minutesAgo, nowMinute):
        // Zero means "now", which is the live value, not a frozen minute-of-day —
        // otherwise a fast started a few minutes later would count from the moment
        // the ribbon happened to be released.
        if minutesAgo <= 0 {
            newState.ateMin = -1
            newState.ateDay = 0
        } else {
            let moment = MealMath.moment(minutesAgo: minutesAgo, nowMinuteOfDay: nowMinute)
            newState.ateDay = moment.ateDay
            newState.ateMin = moment.ateMin
        }
        newState.chipIdx = -1

    case let .chipPicked(idx, minutesAgo, nowMinute):
        if minutesAgo <= 0 {
            newState.ateMin = -1
            newState.ateDay = 0
        } else {
            let moment = MealMath.moment(minutesAgo: minutesAgo, nowMinuteOfDay: nowMinute)
            newState.ateDay = moment.ateDay
            newState.ateMin = moment.ateMin
        }
        newState.chipIdx = idx

    case let .exactTimePicked(ateDay, ateMin):
        newState.ateDay = ateDay
        newState.ateMin = ateMin
        newState.chipIdx = -1

    case .cleared:
        newState.ateMin = -1
        newState.ateDay = 0
        newState.chipIdx = MealChip.justNow.rawValue

    case .none:
        break
    }

    return newState
}

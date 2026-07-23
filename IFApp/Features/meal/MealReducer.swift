//
//  MealReducer.swift
//  IFApp
//

import Redux

func mealReducer(state: MealState, action: Action) -> MealState {
    var newState = state

    switch action as? MealAction {
    case let .initializedToNow(minute):
        if newState.ateMin < 0 {
            newState.ateMin = minute
            newState.ateDay = 0
        }

    case let .initialized(ateDay, ateMin):
        if newState.ateMin < 0 {
            newState.ateDay = ateDay
            newState.ateMin = ateMin
        }

    case let .quickChip(minutesAgo, nowMinute):
        let total = nowMinute - minutesAgo
        if total < 0 {
            newState.ateDay = 1
            newState.ateMin = total + 1440
        } else {
            newState.ateDay = 0
            newState.ateMin = total
        }

    case let .dayStepped(by):
        newState.ateDay = min(6, max(0, newState.ateDay + by))

    case let .timeStepped(by):
        let base = newState.ateMin < 0 ? 0 : newState.ateMin
        newState.ateMin = ((base + by) % 1440 + 1440) % 1440

    case .cleared:
        newState.ateMin = -1
        newState.ateDay = 0

    case .none:
        break
    }

    return newState
}

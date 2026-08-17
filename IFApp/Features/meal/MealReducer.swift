//
//  MealReducer.swift
//  IFApp
//

import Redux

func mealReducer(state: MealState, action: Action) -> MealState {
    var newState = state

    switch action as? MealAction {
    case let .initialized(minutesAgo):
        // Only while nothing has been chosen: a seed must never overwrite an answer.
        if newState.isFresh {
            newState.set(minutesAgo: minutesAgo, chip: -1, via: .seeded)
        }

    case let .scrubbed(minutesAgo):
        newState.set(minutesAgo: minutesAgo, chip: -1, via: .ribbon)

    case let .chipPicked(idx, minutesAgo):
        newState.set(minutesAgo: minutesAgo, chip: idx, via: .chip)

    case let .exactTimePicked(minutesAgo):
        newState.set(minutesAgo: minutesAgo, chip: -1, via: .exact)

    case .cleared:
        newState.set(minutesAgo: 0, chip: MealChip.justNow.rawValue, via: .untouched)

    case .none:
        break
    }

    return newState
}

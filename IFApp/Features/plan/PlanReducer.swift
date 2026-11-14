//
//  PlanReducer.swift
//  IFApp
//

import Redux

func planReducer(state: PlanState, action: Action) -> PlanState {
    var newState = state

    switch action as? PlanAction {
    case let .selected(hours):
        if Plan.range.contains(hours) {
            newState.plan = Plan(hours: hours)
        }
    case .none:
        break
    }

    return newState
}

//
//  PlanReducer.swift
//  IFApp
//

import Redux

func planReducer(state: PlanState, action: Action) -> PlanState {
    var newState = state

    switch action as? PlanAction {
    case let .selected(idx):
        if Plan(rawValue: idx) != nil {
            newState.planIdx = idx
        }
    case .none:
        break
    }

    return newState
}

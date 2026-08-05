//
//  PlanReducer.swift
//  IFApp
//

import Redux

func planReducer(state: PlanState, action: Action) -> PlanState {
    var newState = state

    switch action as? PlanAction {
    case let .selected(hours):
        // Out-of-range values are dropped rather than clamped: they can only come
        // from a caller that is wrong, and silently selecting a neighbouring plan
        // would hide that. Entitlement is not checked here — whether a custom length
        // may be confirmed at all is decided at the point of confirmation, which is
        // where the offer opens instead.
        if Plan.range.contains(hours) {
            newState.plan = Plan(hours: hours)
        }
    case .none:
        break
    }

    return newState
}

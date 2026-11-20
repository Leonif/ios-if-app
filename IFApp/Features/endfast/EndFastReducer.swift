//
//  EndFastReducer.swift
//  IFApp
//

import Foundation
import Redux

func endFastReducer(state: EndFastState, action: Action) -> EndFastState {
    var newState = state

    switch action as? EndFastAction {
    case let .opened(entry, endTimestamp, fastStartTimestamp, earliest, latest):
        newState = EndFastState(
            isOpen: true,
            entry: entry,
            endTimestamp: clamp(endTimestamp, earliest, latest),
            fastStartTimestamp: fastStartTimestamp,
            earliest: earliest,
            latest: latest,
            conflict: nil
        )

    case let .chipPicked(timestamp, latest):
        newState.latest = latest
        newState.endTimestamp = clamp(timestamp, state.earliest, latest)

    case let .timeStepped(byMinutes, latest):
        newState.latest = latest
        newState.endTimestamp = clamp(state.endTimestamp + Double(byMinutes) * 60,
                                      state.earliest, latest)

    case let .refused(conflict, unavoidable):
        newState.conflict = conflict
        newState.conflictUnavoidable = unavoidable

    case .refusalWithdrawn:
        newState.conflict = nil
        newState.conflictUnavoidable = false

    case .closed:
        newState = EndFastState()

    case .openTapped, .chipTapped, .stepTapped, .confirmTapped, .none:
        break
    }

    return newState
}

private func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
    min(max(value, low), max(low, high))
}

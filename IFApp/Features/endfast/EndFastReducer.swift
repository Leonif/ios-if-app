//
//  EndFastReducer.swift
//  IFApp
//
//  Pure and synchronous. Writes only to EndFastState.
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

    case let .refused(conflict):
        newState.conflict = conflict

    case .refusalWithdrawn:
        // The choice survives on purpose: the person is being sent back to change
        // one thing, and handing them a reset picker would make them re-enter the
        // part that was fine.
        newState.conflict = nil

    case .closed:
        newState = EndFastState()

    case .none:
        break
    }

    return newState
}

/// Clamped rather than rejected: a control that refuses to move is the silent "no"
/// the refusal state exists to replace. The bounds are the fast's own start plus a
/// minute at one end and the present moment at the other, so a value outside them is
/// not a choice the sheet can express at all.
private func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
    min(max(value, low), max(low, high))
}

//
//  HistoryReducer.swift
//  IFApp
//
//  Pure and synchronous. Writes only to HistoryState.
//

import Redux

func historyReducer(state: HistoryState, action: Action) -> HistoryState {
    var newState = state

    switch action as? HistoryAction {
    case let .recorded(record):
        newState.records.insert(record, at: 0)

    case let .deleted(id):
        newState.records.removeAll { $0.id == id }

    case .none:
        break
    }

    return newState
}

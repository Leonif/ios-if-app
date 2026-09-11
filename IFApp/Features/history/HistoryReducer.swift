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

    case .exportStarted:
        newState.isExporting = true

    case .exportFailed:
        newState.isExporting = false

    case let .exportPrepared(file):
        newState.isExporting = false
        newState.exportFile = file

    case .exportFinished:
        newState.isExporting = false
        newState.exportFile = nil

    case .none:
        break
    }

    return newState
}

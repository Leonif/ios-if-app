//
//  ResumeFastThunk.swift
//  IFApp
//

import Foundation
import Redux

struct ResumeFastThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let timer = app.timerState
        guard !timer.isRunning, timer.stagedElapsed > 0 else { return }

        if let record = justRecorded(app) {
            dispatch(HistoryAction.deleted(id: record.id))
        }

        let startTimestamp = timer.startTimestamp(at: Date().timeIntervalSince1970)
        dispatch(TimerAction.stopUndone(startTimestamp: startTimestamp))

        dispatch(ProAction.autoOfferCancelled)
    }

    private func justRecorded(_ app: AppState) -> FastRecord? {
        guard let newest = app.historyState.records.first,
              abs(newest.duration - app.timerState.stagedElapsed) < 1
        else { return nil }
        return newest
    }
}

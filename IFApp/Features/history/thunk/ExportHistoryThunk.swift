//
//  ExportHistoryThunk.swift
//  IFApp
//

import Foundation
import Redux

struct ExportHistoryThunk: Thunk {
    private let files: HistoryExportRepositoryProtocol

    init(files: HistoryExportRepositoryProtocol = container.inject()) {
        self.files = files
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        guard let app = state as? AppState else { return }
        let records = app.historyState.records
        guard !records.isEmpty, !app.historyState.isExportBusy else { return }

        dispatch(HistoryAction.exportStarted)

        let name = HistoryExport.fileName(dayKey: Clock.dayKey())
        guard let file = files.write(csv: HistoryExport.csv(records: records), fileName: name) else {
            dispatch(HistoryAction.exportFailed)
            return
        }

        dispatch(HistoryAction.exportPrepared(file: file))
    }
}

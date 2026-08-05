//
//  ExportHistoryThunk.swift
//  IFApp
//
//  Builds the CSV, writes it, and hands the screen a file to share. Both reasons a
//  thunk exists are here at once: the clock is read for the file name's date, and
//  the write is a side effect, so neither may happen in the view or the reducer.
//
//  Nothing is exported for an empty history — the button does not exist there, and
//  this is the second guard rather than the first.
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
        guard !records.isEmpty else { return }

        let name = HistoryExport.fileName(dayKey: Clock.dayKey())
        guard let file = files.write(csv: HistoryExport.csv(records: records), fileName: name) else { return }

        dispatch(HistoryAction.exportPrepared(file: file))
    }
}

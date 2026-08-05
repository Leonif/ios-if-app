//
//  HistoryAction.swift
//  IFApp
//

import Foundation
import Redux

enum HistoryAction: Action {
    /// A finished fast was saved (dispatched by HistoryMiddleware, which owns the
    /// write — the reducer only mirrors it into state).
    case recorded(FastRecord)
    /// The user deleted a record from the history screen.
    case deleted(id: UUID)

    /// The CSV has been written and the share sheet can open on it (dispatched by
    /// `ExportHistoryThunk`, which owns the write).
    case exportPrepared(file: URL)
    /// The share sheet closed. `shared` is false when the user backed out of it,
    /// and only a true here is an export that happened — cancelling is not an event.
    case exportFinished(shared: Bool)
}

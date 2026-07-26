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
}

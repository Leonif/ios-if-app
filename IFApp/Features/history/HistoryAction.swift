//
//  HistoryAction.swift
//  IFApp
//

import Foundation
import Redux

enum HistoryAction: Action {
    case recorded(FastRecord)
    case deleted(id: UUID)

    case exportTapped
    case exportStarted
    case exportFailed
    case exportPrepared(file: URL)
    case exportFinished(shared: Bool)
}

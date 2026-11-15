//
//  HistoryState.swift
//  IFApp
//

import Foundation

struct HistoryState: Equatable, Sendable {
    var records: [FastRecord] = []

    var latestRecord: FastRecord? {
        records.max(by: { $0.endTimestamp < $1.endTimestamp })
    }

    var exportFile: URL? = nil
    var isExporting = false

    var isExportBusy: Bool { isExporting || exportFile != nil }
}

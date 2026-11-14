//
//  HistoryState.swift
//  IFApp
//

import Foundation

struct HistoryState: Equatable, Sendable {
    var records: [FastRecord] = []

    var exportFile: URL? = nil
    var isExporting = false

    var isExportBusy: Bool { isExporting || exportFile != nil }
}

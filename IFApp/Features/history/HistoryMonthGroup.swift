//
//  HistoryMonthGroup.swift
//  IFApp
//

import Foundation

struct HistoryMonthGroup: Identifiable, Equatable {
    let id: String
    let month: Date
    let records: [FastRecord]

    var totalHours: Int {
        Int(records.reduce(0) { $0 + $1.duration } / 3600)
    }
}

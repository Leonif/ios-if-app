//
//  HistoryDay.swift
//  IFApp
//

import Foundation

struct HistoryDay: Identifiable, Equatable {
    let date: Date
    let reachedGoal: Bool
    var id: String { Clock.dayKey(date) }
}

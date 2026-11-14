//
//  HistoryLoadFailure.swift
//  IFApp
//

enum HistoryLoadFailure: String {
    case unreadable
    case decode
    case futureSchema = "future_schema"
    case quarantineFailed = "quarantine_failed"
}

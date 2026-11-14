//
//  PaywallTrigger.swift
//  IFApp
//

enum PaywallTrigger: String, Equatable, Sendable {
    case fastFinished = "fast_finished"
    case planCustom = "plan_custom"
    case streakBreak = "streak_break"
    case manual
    case historyExport = "history_export"
    case home
    case unknown
}

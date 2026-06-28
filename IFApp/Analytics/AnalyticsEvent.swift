//
//  AnalyticsEvent.swift
//  IFApp
//
//  The product's funnel event catalog. One place to see everything we track,
//  so the analysis of "where does the user drop off" maps to named events.
//  Names are snake_case (Firebase convention, <= 40 chars).
//

import Foundation

enum AnalyticsEvent {
    /// App launched / foregrounded into use.
    case appOpened
    /// User started a fast.
    case fastStarted
    /// User ended a fast. `completed` = reached the qualifying threshold (8h).
    case fastStopped(durationSeconds: Int, completed: Bool, stage: String)
    /// User reset the timer (a drop-off signal — gave up before finishing).
    case fastReset
    /// User nudged the elapsed time (manual ± correction).
    case timeAdjusted
    /// User opened the scientific Sources screen.
    case sourcesOpened
    /// The in-app review prompt was shown.
    case reviewPrompted

    var name: String {
        switch self {
        case .appOpened: return "app_opened"
        case .fastStarted: return "fast_started"
        case .fastStopped: return "fast_stopped"
        case .fastReset: return "fast_reset"
        case .timeAdjusted: return "time_adjusted"
        case .sourcesOpened: return "sources_opened"
        case .reviewPrompted: return "review_prompted"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case let .fastStopped(durationSeconds, completed, stage):
            return [
                "duration_seconds": durationSeconds,
                "duration_hours": durationSeconds / 3600,
                "completed": completed,
                "stage": stage,
            ]
        case .appOpened, .fastStarted, .fastReset, .timeAdjusted, .sourcesOpened, .reviewPrompted:
            return [:]
        }
    }
}

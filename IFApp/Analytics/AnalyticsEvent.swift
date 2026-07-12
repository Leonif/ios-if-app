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
    /// User started a fast. `goalHours` = the chosen plan's fasting window.
    case fastStarted(goalHours: Double)
    /// User ended a fast. `completed` = reached the qualifying threshold (8h).
    case fastStopped(durationSeconds: Int, completed: Bool, stage: String)
    /// User reset the timer (a drop-off signal — gave up before finishing).
    case fastReset
    /// User nudged the elapsed time (manual ± correction).
    case timeAdjusted
    /// User confirmed the Last-meal picker. `backdated` = started in the past
    /// (logged a real meal time) vs fresh "now"; `minutesAgo` = how far back.
    case lastMealLogged(backdated: Bool, minutesAgo: Int)
    /// User opened the scientific Sources screen.
    case sourcesOpened
    /// The in-app review prompt was shown.
    case reviewPrompted
    /// User tapped the positive CTA on the review prompt (went to write-review).
    case reviewCtaTapped
    /// The appearance the app is being used in. `dark` = system dark mode.
    /// Fires on screen appear and on live theme switches — count *users* per
    /// `theme` value to see which appearance the audience actually uses.
    case themeActive(dark: Bool)

    var name: String {
        switch self {
        case .appOpened: return "app_opened"
        case .fastStarted: return "fast_started"
        case .fastStopped: return "fast_stopped"
        case .fastReset: return "fast_reset"
        case .timeAdjusted: return "time_adjusted"
        case .lastMealLogged: return "last_meal_logged"
        case .sourcesOpened: return "sources_opened"
        case .reviewPrompted: return "review_prompted"
        case .reviewCtaTapped: return "review_cta_tapped"
        case .themeActive: return "theme_active"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case let .fastStarted(goalHours):
            return ["goal_hours": goalHours]
        case let .fastStopped(durationSeconds, completed, stage):
            return [
                "duration_seconds": durationSeconds,
                "duration_hours": durationSeconds / 3600,
                "completed": completed,
                "stage": stage,
            ]
        case let .lastMealLogged(backdated, minutesAgo):
            return [
                "backdated": backdated,
                "minutes_ago": minutesAgo,
            ]
        case let .themeActive(dark):
            return ["theme": dark ? "dark" : "light"]
        case .appOpened, .fastReset, .timeAdjusted, .sourcesOpened, .reviewPrompted, .reviewCtaTapped:
            return [:]
        }
    }
}

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
    /// User ended a fast. `completed` = the fast had reached its goal.
    case fastStopped(durationSeconds: Int, completed: Bool, stage: String)
    /// The fast reached its goal (the goal-reached moment fired). `goalHours` = plan window.
    case goalReached(goalHours: Double)
    /// User reset the timer (a drop-off signal — gave up before finishing).
    case fastReset
    /// User opened the eating window from the complete screen.
    case eatingWindowStarted
    /// User started the next fast from the window-closed screen (the chain held).
    /// Accompanies `fast_started`.
    case fastChained
    /// User nudged the elapsed time (manual ± correction).
    case timeAdjusted
    /// User confirmed the Last-meal picker. `backdated` = started in the past
    /// (logged a real meal time) vs fresh "now"; `minutesAgo` = how far back.
    case lastMealLogged(backdated: Bool, minutesAgo: Int)
    /// User opened the scientific Sources screen.
    case sourcesOpened
    /// The native `requestReview` was called. `trigger` = what caused it
    /// ("streak_milestone" / "next_open"). Apple may or may not show the panel.
    case reviewPrompted(trigger: String)
    /// A streak milestone card was shown. `days` = the threshold (3/7/14/30).
    case streakMilestone(days: Int)
    /// The appearance the app is being used in. `dark` = system dark mode.
    /// Fires on screen appear and on live theme switches — count *users* per
    /// `theme` value to see which appearance the audience actually uses.
    case themeActive(dark: Bool)

    var name: String {
        switch self {
        case .appOpened: return "app_opened"
        case .fastStarted: return "fast_started"
        case .fastStopped: return "fast_stopped"
        case .goalReached: return "goal_reached"
        case .fastReset: return "fast_reset"
        case .eatingWindowStarted: return "eating_window_started"
        case .fastChained: return "fast_chained"
        case .timeAdjusted: return "time_adjusted"
        case .lastMealLogged: return "last_meal_logged"
        case .sourcesOpened: return "sources_opened"
        case .reviewPrompted: return "review_prompted"
        case .streakMilestone: return "streak_milestone"
        case .themeActive: return "theme_active"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case let .fastStarted(goalHours):
            return ["goal_hours": goalHours]
        case let .goalReached(goalHours):
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
        case let .reviewPrompted(trigger):
            return ["trigger": trigger]
        case let .streakMilestone(days):
            return ["days": days]
        case .appOpened, .fastReset, .eatingWindowStarted, .fastChained, .timeAdjusted, .sourcesOpened:
            return [:]
        }
    }
}

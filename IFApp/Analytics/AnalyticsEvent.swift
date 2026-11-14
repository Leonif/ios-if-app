//
//  AnalyticsEvent.swift
//  IFApp
//

import Foundation

private func code(_ value: Int, width: Int) -> String {
    String(format: "%0\(width)d", value)
}

enum AnalyticsEvent {
    case appOpened
    case fastStarted(goalHours: Double)
    case fastStopped(durationSeconds: Int, completed: Bool, stage: String, backdatedMinutes: Int)
    case fastStopUndone
    case goalReached(goalHours: Double)
    case fastReset(elapsedMinutes: Int)
    case eatingWindowStarted
    case fastChained
    case timeAdjusted
    case endFastRefused(unavoidable: Bool)
    case lastMealLogged(backdated: Bool, minutesAgo: Int, inputMethod: String)
    case sourcesOpened
    case sourceArticleOpened(articleID: Int)
    case sourceOriginalOpened(articleID: Int)
    case sourceArticleClosed(articleID: Int, reachedEnd: Bool)
    case sunnahOpened(source: String)
    case sunnahEnabled(mode: String, pushAllowed: Bool)
    case historyOpened(source: String)
    case historyRecordDeleted
    case historyExported
    case historyLoadFailed(reason: String)
    case reviewPrompted(trigger: String)
    case streakMilestone(days: Int)
    case planSelected(plan: String, goalHours: Int)
    case planConfirmed(plan: String, goalHours: Int)
    case paywallShown(trigger: String)
    case paywallDismissed(trigger: String)
    case purchaseStarted(trigger: String, product: String)
    case purchaseCompleted(trigger: String, product: String)
    case purchaseFailed(trigger: String, reason: String)
    case restoreCompleted
    case themeActive(dark: Bool)

    var name: String {
        switch self {
        case .appOpened: return "app_opened"
        case .fastStarted: return "fast_started"
        case .fastStopped: return "fast_stopped"
        case .fastStopUndone: return "fast_stop_undone"
        case .goalReached: return "goal_reached"
        case .fastReset: return "fast_reset"
        case .eatingWindowStarted: return "eating_window_started"
        case .fastChained: return "fast_chained"
        case .timeAdjusted: return "time_adjusted"
        case .endFastRefused: return "end_fast_refused"
        case .lastMealLogged: return "last_meal_logged"
        case .sourcesOpened: return "sources_opened"
        case .sourceArticleOpened: return "source_article_opened"
        case .sourceOriginalOpened: return "source_original_opened"
        case .sourceArticleClosed: return "source_article_closed"
        case .sunnahOpened: return "sunnah_opened"
        case .sunnahEnabled: return "sunnah_enabled"
        case .historyOpened: return "history_opened"
        case .historyRecordDeleted: return "history_record_deleted"
        case .historyExported: return "history_exported"
        case .historyLoadFailed: return "history_load_failed"
        case .reviewPrompted: return "review_prompted"
        case .streakMilestone: return "streak_milestone"
        case .planSelected: return "plan_selected"
        case .planConfirmed: return "plan_confirmed"
        case .paywallShown: return "paywall_shown"
        case .paywallDismissed: return "paywall_dismissed"
        case .purchaseStarted: return "purchase_started"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseFailed: return "purchase_failed"
        case .restoreCompleted: return "restore_completed"
        case .themeActive: return "theme_active"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case let .fastStarted(goalHours):
            return ["goal_hours": code(Int(goalHours.rounded()), width: 2)]
        case let .goalReached(goalHours):
            return ["goal_hours": code(Int(goalHours.rounded()), width: 2)]
        case let .fastStopped(durationSeconds, completed, stage, backdatedMinutes):
            return [
                "duration_seconds": durationSeconds,
                "duration_hours": code(durationSeconds / 3600, width: 3),
                "completed": completed ? "true" : "false",
                "stage": stage,
                "end_backdated_minutes": code(backdatedMinutes, width: 4),
            ]
        case let .fastReset(elapsedMinutes):
            return ["elapsed_minutes": code(elapsedMinutes, width: 4)]
        case let .lastMealLogged(backdated, minutesAgo, inputMethod):
            return [
                "backdated": backdated ? "true" : "false",
                "minutes_ago": code(minutesAgo, width: 4),
                "input_method": inputMethod,
            ]
        case let .themeActive(dark):
            return ["theme": dark ? "dark" : "light"]
        case let .endFastRefused(unavoidable):
            return ["unavoidable": unavoidable ? "1" : "0"]
        case let .reviewPrompted(trigger):
            return ["trigger": trigger]
        case let .streakMilestone(days):
            return ["days": code(days, width: 2)]
        case let .historyOpened(source):
            return ["source": source]
        case let .sunnahOpened(source):
            return ["source": source]
        case let .sourceArticleOpened(articleID), let .sourceOriginalOpened(articleID):
            return ["article": code(articleID, width: 2)]
        case let .sourceArticleClosed(articleID, reachedEnd):
            return [
                "article": code(articleID, width: 2),
                "reached_end": reachedEnd ? "true" : "false",
            ]
        case let .sunnahEnabled(mode, pushAllowed):
            return [
                "mode": mode,
                "push_allowed": pushAllowed ? "true" : "false",
            ]
        case let .historyLoadFailed(reason):
            return ["reason": reason]
        case let .planSelected(plan, goalHours),
             let .planConfirmed(plan, goalHours):
            return [
                "plan": plan,
                "goal_hours": code(goalHours, width: 2),
            ]
        case let .paywallShown(trigger), let .paywallDismissed(trigger):
            return ["trigger": trigger]
        case let .purchaseStarted(trigger, product),
             let .purchaseCompleted(trigger, product):
            return [
                "trigger": trigger,
                "product": product,
            ]
        case let .purchaseFailed(trigger, reason):
            return [
                "trigger": trigger,
                "reason": reason,
            ]
        case .appOpened, .eatingWindowStarted, .fastChained, .timeAdjusted, .sourcesOpened,
             .historyRecordDeleted, .historyExported, .restoreCompleted, .fastStopUndone:
            return [:]
        }
    }
}

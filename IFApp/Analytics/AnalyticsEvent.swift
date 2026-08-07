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
    /// User ended a fast. `completed` = the fast had reached its goal. `stage` = the
    /// phase the fast was in, as a stable code (`fed`/`sugar`/`fat`/`ketosis`/
    /// `autophagy`) — never the displayed label, which differs per locale and makes
    /// the dimension impossible to group.
    case fastStopped(durationSeconds: Int, completed: Bool, stage: String)
    /// The user took an ending back from the result screen. No parameters: the one
    /// question it answers is whether the undo earns its place, and that is a count.
    ///
    /// Note for analysis: the `fast_stopped` it undoes has already fired and stays in
    /// the counters, so cancelled endings have to be subtracted or `fast_stopped` reads
    /// high.
    case fastStopUndone
    /// The fast reached its goal (the goal-reached moment fired). `goalHours` = plan window.
    case goalReached(goalHours: Double)
    /// User reset the timer. `elapsedMinutes` = whole minutes from the start of the
    /// fast to the reset. That number is the whole point of the event: minutes mean
    /// the user was fixing a wrong start time, hours mean they abandoned the fast.
    /// Read as a distribution over buckets, never as an average.
    case fastReset(elapsedMinutes: Int)
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
    /// User opened the fasting history screen. `source` = which entry point
    /// ("streak_badge" / "complete_card" / "eating_window").
    case historyOpened(source: String)
    /// User deleted a record from the history (swipe + confirm).
    case historyRecordDeleted
    /// The history was handed to the share sheet as a CSV. No parameters at all —
    /// deliberately, because a parameter would need a custom definition registered in
    /// GA4 before submit and none of them would change the one decision this event
    /// exists to inform: whether an import is ever worth building. A cancelled share
    /// does not fire it.
    case historyExported
    /// The native `requestReview` was called. `trigger` = what caused it
    /// ("streak_milestone" / "next_open"). Apple may or may not show the panel.
    case reviewPrompted(trigger: String)
    /// A streak milestone card was shown. `days` = the threshold (3/7/14/30).
    case streakMilestone(days: Int)
    /// User picked a fasting plan in the plan editor. `plan` = the ratio label
    /// ("16:8"), `goalHours` = that plan's fasting window. Pairs with the
    /// `current_plan` user property, which carries the same value persistently.
    case planSelected(plan: String, goalHours: Int)
    /// The plan editor was closed, carrying whatever plan the user settled on —
    /// fired even when nothing was touched. `plan_selected` says what was tried
    /// on, this says what was kept, so the plan mix counts off this one.
    case planConfirmed(plan: String, goalHours: Int)
    /// The offer screen was shown. `trigger` = which entry point led here
    /// ("fast_finished" / "plan_custom" / "streak_break" / "manual"). At 20-35 shows a
    /// month this event is read as a distribution over triggers, never as a rate.
    case paywallShown(trigger: String)
    /// The offer screen was closed without a purchase.
    case paywallDismissed(trigger: String)
    /// The Buy button was tapped and Apple's sheet was asked for.
    case purchaseStarted(trigger: String, product: String)
    case purchaseCompleted(trigger: String, product: String)
    /// The attempt ended without Pro. `reason` = "cancelled" / "network" / "pending"
    /// / "other" — "pending" is Ask to Buy, which may still be approved later.
    case purchaseFailed(trigger: String, reason: String)
    /// Restore purchases brought the entitlement back.
    case restoreCompleted
    /// The appearance the app is being used in. `dark` = system dark mode.
    /// Fires on screen appear and on live theme switches — count *users* per
    /// `theme` value to see which appearance the audience actually uses.
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
        case .lastMealLogged: return "last_meal_logged"
        case .sourcesOpened: return "sources_opened"
        case .historyOpened: return "history_opened"
        case .historyRecordDeleted: return "history_record_deleted"
        case .historyExported: return "history_exported"
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
        case let .fastReset(elapsedMinutes):
            return ["elapsed_minutes": elapsedMinutes]
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
        case let .historyOpened(source):
            return ["source": source]
        case let .planSelected(plan, goalHours),
             let .planConfirmed(plan, goalHours):
            return [
                "plan": plan,
                "goal_hours": goalHours,
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

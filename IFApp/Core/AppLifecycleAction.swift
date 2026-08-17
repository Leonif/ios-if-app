//
//  AppLifecycleAction.swift
//  IFApp
//
//  Lightweight app-level signals that don't mutate any substate but drive
//  side effects (analytics). Reducers ignore them; middleware reacts.
//

import Redux

/// What caused a native review request. The raw value is the GA4 `trigger` param.
enum ReviewPromptTrigger: String {
    /// Right after the streak milestone card was closed.
    case streakMilestone = "streak_milestone"
    /// Fallback: next app open ≥4h after the 3rd completed goal (no streak-3).
    case nextOpen = "next_open"
}

/// Which of the three entry points led into the history. The raw value is the GA4
/// `source` param: with three ways in, the event alone can't say which one works.
enum HistoryEntrySource: String {
    /// The streak pill in the header — present in every state.
    case streakBadge = "streak_badge"
    /// "Saved to your history" in the complete card.
    case completeCard = "complete_card"
    /// "Last fast · 16h 24m" in the eating-window card.
    case eatingWindow = "eating_window"
    /// "Open that fast" in the end-fast sheet's refusal: the record standing in the
    /// way of a back-dated ending, opened so it can be deleted.
    case endFastOverlap = "end_fast_overlap"
}

enum AppLifecycleAction: Action {
    case appOpened
    /// The scene became active — cold start or return from background.
    /// Drives the pending "next open" review fallback; not a funnel event.
    case appBecameActive
    case sourcesOpened
    /// The fasting history screen was opened, and from where.
    case historyOpened(source: HistoryEntrySource)
    /// The native `requestReview` was called (Apple may or may not show the panel).
    case reviewPrompted(trigger: ReviewPromptTrigger)
    /// A streak milestone (3/7/14/30 days) was reached and its card shown.
    case streakMilestone(days: Int)
    /// The goal-reached screen is on display and its moment has finished playing.
    /// Only ever sent from the `goalReached` state — the milestone card hangs off it.
    case goalScreenSettled
    /// The user just answered the notification permission dialog. Reducers ignore
    /// it; it exists so NotificationMiddleware re-runs its sync — the goal push
    /// scheduled on `.started` was rejected while permission did not yet exist.
    /// Not a funnel event.
    case pushAuthorizationResolved
    case lastMealLogged(backdated: Bool, minutesAgo: Int, inputMethod: String)
    /// A fast was started from the window-closed screen — the chain held.
    case fastChained
    /// The app is being viewed in a given appearance. `dark` = system dark mode
    /// (the app follows the system scheme, it has no in-app theme toggle).
    case themeActive(dark: Bool)
}

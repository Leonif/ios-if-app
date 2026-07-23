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

enum AppLifecycleAction: Action {
    case appOpened
    /// The scene became active — cold start or return from background.
    /// Drives the pending "next open" review fallback; not a funnel event.
    case appBecameActive
    case sourcesOpened
    /// The native `requestReview` was called (Apple may or may not show the panel).
    case reviewPrompted(trigger: ReviewPromptTrigger)
    /// A streak milestone (3/7/14/30 days) was reached and its card shown.
    case streakMilestone(days: Int)
    /// The goal-reached screen is on display and its moment has finished playing.
    /// Only ever sent from the `goalReached` state — the milestone card hangs off it.
    case goalScreenSettled
    case lastMealLogged(backdated: Bool, minutesAgo: Int)
    /// The app is being viewed in a given appearance. `dark` = system dark mode
    /// (the app follows the system scheme, it has no in-app theme toggle).
    case themeActive(dark: Bool)
}

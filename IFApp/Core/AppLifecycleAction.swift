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

/// Which door led into the Sunnah reminders screen. The raw value is the GA4
/// `source` param, same fixed-list rule as `HistoryEntrySource`: with the screen
/// reachable two ways, the event alone cannot say which one carries it.
enum SunnahEntrySource: String {
    /// The "Sunnah reminders" row in the plan editor — the pencil in the plan pill.
    case planEditor = "plan_editor"
    /// The row in the About IF24 sheet.
    case about
}

enum AppLifecycleAction: Action {
    case appOpened
    /// The scene became active — cold start or return from background.
    /// Drives the pending "next open" review fallback; not a funnel event.
    case appBecameActive
    case sourcesOpened
    /// One of the bundled papers was opened in the reader. `articleID` = its index in
    /// `SourceArticle.all`, the same identifier the rows are addressed by.
    case sourceArticleOpened(articleID: Int)
    /// The reader's "read the original" link was followed out to the paper.
    ///
    /// Dispatched from that button and nowhere else. `OpenExternalLinkThunk` opens the
    /// privacy policy and the system Settings as well, so the event cannot hang off
    /// the thunk without counting those as papers.
    case sourceOriginalOpened(articleID: Int)
    /// The reader was closed, and whether the foot of the article had been on screen.
    case sourceArticleClosed(articleID: Int, reachedEnd: Bool)
    /// The Sunnah reminders screen was opened, and from where.
    case sunnahOpened(source: SunnahEntrySource)
    /// The fasting history screen was opened, and from where.
    case historyOpened(source: HistoryEntrySource)
    /// The native `requestReview` went out on an active scene (Apple may or may not
    /// show the panel). Never dispatched when there was no scene to ask on.
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

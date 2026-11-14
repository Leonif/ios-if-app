//
//  AppLifecycleAction.swift
//  IFApp
//

import Redux

enum ReviewPromptTrigger: String {
    case streakMilestone = "streak_milestone"
    case nextOpen = "next_open"
}

enum HistoryEntrySource: String {
    case streakBadge = "streak_badge"
    case completeCard = "complete_card"
    case eatingWindow = "eating_window"
    case endFastOverlap = "end_fast_overlap"
}

enum SunnahEntrySource: String {
    case planEditor = "plan_editor"
    case about
}

enum AppLifecycleAction: Action {
    case appOpened
    case appBecameActive
    case sourcesOpened
    case sourceArticleOpened(articleID: Int)
    case sourceOriginalOpened(articleID: Int)
    case sourceArticleClosed(articleID: Int, reachedEnd: Bool)
    case sunnahOpened(source: SunnahEntrySource)
    case historyOpened(source: HistoryEntrySource)
    case reviewPrompted(trigger: ReviewPromptTrigger)
    case streakMilestone(days: Int)
    case goalScreenSettled
    case pushAuthorizationResolved
    case lastMealLogged(backdated: Bool, minutesAgo: Int, inputMethod: String)
    case fastChained
    case themeActive(dark: Bool)
}

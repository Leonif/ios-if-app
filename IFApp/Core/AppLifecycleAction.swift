//
//  AppLifecycleAction.swift
//  IFApp
//

import Foundation
import Redux

enum AppLifecycleAction: Action {
    case appOpened
    case appBecameActive
    case sourcesOpened
    case sourceArticleOpened(articleID: Int)
    case sourceOriginalOpened(articleID: Int, url: URL)
    case sourceArticleClosed(articleID: Int, reachedEnd: Bool)
    case sunnahOpened(source: SunnahEntrySource)
    case historyOpened(source: HistoryEntrySource)
    case reviewPrompted(trigger: ReviewPromptTrigger)
    case streakMilestone(days: Int)
    case goalScreenSettled
    case eatingWindowSettled
    case pushAuthorizationResolved
    case pushStatusRead(label: String)
    case lastMealLogged(backdated: Bool, minutesAgo: Int, inputMethod: String)
    case fastChained
    case themeActive(dark: Bool)
}

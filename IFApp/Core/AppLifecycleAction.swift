//
//  AppLifecycleAction.swift
//  IFApp
//
//  Lightweight app-level signals that don't mutate any substate but drive
//  side effects (analytics). Reducers ignore them; middleware reacts.
//

import Redux

enum AppLifecycleAction: Action {
    case appOpened
    case sourcesOpened
    case reviewPrompted
    case reviewCtaTapped
    case lastMealLogged(backdated: Bool, minutesAgo: Int)
    /// The app is being viewed in a given appearance. `dark` = system dark mode
    /// (the app follows the system scheme, it has no in-app theme toggle).
    case themeActive(dark: Bool)
}

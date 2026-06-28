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
}

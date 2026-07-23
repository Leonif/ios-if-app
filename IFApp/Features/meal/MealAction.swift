//
//  MealAction.swift
//  IFApp
//
//  Clock-dependent values (nowMinuteOfDay) are injected by thunks; the reducer stays pure.
//

import Redux

enum MealAction: Action {
    /// Seed ateMin to the current minute-of-day when the picker opens, if still unset.
    case initializedToNow(minuteOfDay: Int)
    /// Seed the control to a specific past moment (the window-closed default), if still unset.
    case initialized(ateDay: Int, ateMin: Int)
    /// Quick chip: 30 / 60 / 120 minutes ago, relative to the current clock.
    case quickChip(minutesAgo: Int, nowMinuteOfDay: Int)
    /// Date stepper. +1 = older day, -1 = newer day (clamped 0...6).
    case dayStepped(by: Int)
    /// Time stepper, ±minutes, wraps within a day.
    case timeStepped(by: Int)
    /// Back to "now / fresh".
    case cleared
}

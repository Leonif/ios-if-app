//
//  SunnahReducer.swift
//  IFApp
//

import Foundation
import Redux

func sunnahReducer(state: SunnahState, action: Action) -> SunnahState {
    guard let action = action as? SunnahAction else { return state }
    var next = state
    switch action {
    case .settingsChanged(var settings):
        settings.minuteOfDay = SunnahSettings.clamped(minuteOfDay: settings.minuteOfDay)
        next.settings = settings
        next.delivery = .resolve(enabled: settings.enabled, otherwise: .checking)
    case .refresh, .systemSettingsTapped: break
    case .deliveryUpdated(let delivery, let dates):
        next.delivery = delivery
        next.upcoming = dates
    }
    return next
}

//
//  SunnahAction.swift
//  IFApp
//

import Foundation
import Redux

enum SunnahAction: Action {
    case settingsChanged(SunnahSettings)
    case refresh
    case systemSettingsTapped(url: URL)
    case deliveryUpdated(SunnahState.Delivery, dates: [Date])
}

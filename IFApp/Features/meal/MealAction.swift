//
//  MealAction.swift
//  IFApp
//

import Foundation
import Redux

enum MealAction: Action {
    case initialized(minutesAgo: Int)
    case scrubbed(minutesAgo: Int)
    case chipPicked(idx: Int, minutesAgo: Int)
    case exactTimePicked(minutesAgo: Int)
    case cleared
    case pickerOpened
    case pickerDismissed
    case pickerConfirmed
    case chipTapped(MealChip)
    case scrubFeedbackRequested(MealScrubFeedback)
    case exactTimeChosen(Date)
    case confirmTapped
    case windowClosedShown
}

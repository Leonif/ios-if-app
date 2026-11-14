//
//  MealAction.swift
//  IFApp
//

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
}

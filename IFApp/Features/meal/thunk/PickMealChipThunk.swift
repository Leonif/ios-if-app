//
//  PickMealChipThunk.swift
//  IFApp
//

import UIKit
import Redux

struct PickMealChipThunk: Thunk {
    let chip: MealChip

    init(_ chip: MealChip) { self.chip = chip }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        let nowMinute = Clock.minuteOfDay()
        let minutesAgo: Int
        switch chip {
        case .justNow: minutesAgo = 0
        case .oneHour: minutesAgo = 60
        case .threeHours: minutesAgo = 180
        case .lastNight: minutesAgo = Self.lastNightMinutesAgo(nowMinuteOfDay: nowMinute)
        }

        dispatch(MealAction.chipPicked(idx: chip.rawValue, minutesAgo: minutesAgo))
        await MainActor.run { UISelectionFeedbackGenerator().selectionChanged() }
    }

    static func lastNightMinutesAgo(nowMinuteOfDay: Int) -> Int {
        let sinceEvening = ((nowMinuteOfDay - MealChip.lastNightMinuteOfDay) % 1440 + 1440) % 1440
        return sinceEvening < MealChip.lastNightFloor ? sinceEvening + 1440 : sinceEvening
    }
}

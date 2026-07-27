//
//  PickMealChipThunk.swift
//  IFApp
//
//  Applies a quick chip. Three of them are fixed offsets; "Last night" is the one
//  that needs the clock, and it resolves the same way at every hour of the day.
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

        dispatch(MealAction.chipPicked(idx: chip.rawValue,
                                       minutesAgo: minutesAgo,
                                       nowMinuteOfDay: nowMinute))
        await MainActor.run { UISelectionFeedbackGenerator().selectionChanged() }
    }

    /// The most recent 9 PM that has already passed — one rule for all 24 hours, no
    /// night-time branch. At 3 AM that is yesterday evening, which is what both the
    /// person still awake and the person who just woke up mean by "last night".
    ///
    /// The one guard: right after 9 PM the nearest past evening is *tonight*, minutes
    /// ago, and calling that "last night" would be nonsense — so it steps back a day.
    static func lastNightMinutesAgo(nowMinuteOfDay: Int) -> Int {
        let sinceEvening = ((nowMinuteOfDay - MealChip.lastNightMinuteOfDay) % 1440 + 1440) % 1440
        return sinceEvening < MealChip.lastNightFloor ? sinceEvening + 1440 : sinceEvening
    }
}

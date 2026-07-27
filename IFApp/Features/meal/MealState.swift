//
//  MealState.swift
//  IFApp
//
//  The last-meal picker's single source of truth. `ateMin = -1` means
//  "now / starting fresh" (no back-date yet) — and it stays that way while the
//  sheet is open, so an untouched picker keeps meaning *now* however long the user
//  looks at it, instead of freezing on the minute it was opened.
//

struct MealState: Equatable, Sendable {
    var ateDay: Int = 0          // days ago, 0...7 (7 = the hard back-date limit)
    var ateMin: Int = -1         // minute-of-day 0...1439, -1 = now/fresh
    /// Which quick chip reads as selected, -1 = none. The chips are a separate
    /// source of truth from the value: landing on 60 minutes by dragging the ribbon
    /// is not the same act as tapping "1h", and only the tap should light a pill up.
    var chipIdx: Int = MealChip.justNow.rawValue

    var isFresh: Bool { ateMin < 0 }
}

/// The quick chips, in row order. All but `lastNight` are fixed offsets from now;
/// `lastNight` resolves against the clock in `PickMealChipThunk`.
enum MealChip: Int, CaseIterable {
    case justNow = 0
    case oneHour = 1
    case threeHours = 2
    case lastNight = 3

    /// The evening the "Last night" chip means: the most recent 9 PM that has passed.
    static let lastNightMinuteOfDay = 21 * 60
    /// Below this the "last night" reading is absurd (it is tonight, minutes ago), so
    /// the chip steps back one more evening.
    static let lastNightFloor = 30
}

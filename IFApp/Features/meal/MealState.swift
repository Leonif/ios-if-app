//
//  MealState.swift
//  IFApp
//
//  The last-meal picker's single source of truth.
//
//  It stores the **distance** the user chose — "forty minutes ago" — and not the
//  wall-clock moment that distance resolves to. That is the whole reason the state
//  looks like this, so it is worth stating plainly:
//
//  The question on screen is "how long ago did you eat", the ribbon is a distance,
//  and the chips are distances. Turning a distance into a moment needs to know what
//  "now" is, and the only correct "now" is the one at the instant the fast is
//  actually started — which is `ConfirmLastMealThunk`, not the instant the finger
//  left the ribbon. Storing the moment meant resolving it early, against a clock
//  read somewhere up in the view, and that is exactly how the picker used to jump
//  into the future across midnight: the day offset was computed against one "now"
//  and read back against another.
//
//  Keeping the distance also keeps `MealAction` free of time entirely, so the
//  reducer needs no injected clock (invariant 1) and the view has no reason to read
//  one into a payload (invariant 6). `(ateDay, ateMin)` is still how the value is
//  *displayed*; it is derived on the spot by `MealMath.moment`.
//

struct MealState: Equatable, Sendable {
    /// Minutes since the meal. 0 means "now / starting fresh" — the live moment,
    /// which stays live however long the sheet is open, instead of freezing on the
    /// minute it was opened.
    private(set) var minutesAgo: Int = 0

    /// Which quick chip reads as selected, -1 = none. The chips are a separate
    /// source of truth from the value: landing on 60 minutes by dragging the ribbon
    /// is not the same act as tapping "1h", and only the tap should light a pill up.
    private(set) var chipIdx: Int = MealChip.justNow.rawValue

    /// How the current value got there. Carried into `last_meal_logged` so the
    /// scale can be retuned against how people actually answer.
    private(set) var inputMethod: MealInputMethod = .untouched

    var isFresh: Bool { minutesAgo == 0 }

    /// The one place the value changes. All four ways of answering the question go
    /// through it, so the clamp and the chip/input bookkeeping cannot drift apart
    /// between them.
    mutating func set(minutesAgo: Int, chip: Int, via method: MealInputMethod) {
        self.minutesAgo = MealMath.clamped(minutesAgo)
        // A value clamped to zero is "now" however it was reached, and "now" is not
        // a back-date — so it reports as untouched rather than as a ribbon answer.
        self.inputMethod = self.minutesAgo == 0 && method == .ribbon ? .untouched : method
        chipIdx = chip
    }
}

/// How the picker's value was entered. A GA4 dimension, so the raw values are fixed
/// ASCII and never localized.
///
/// The card asks for three — chip, ribbon, exact — and those are the three ways a
/// person answers. The other two are the states that are none of them: `untouched`
/// is a sheet confirmed as it stood, `seeded` is a value the app itself put there
/// from the closed eating window. Folding either into one of the three would report
/// taps that never happened, which is the same class of error that made `backdated`
/// unreadable for a month.
enum MealInputMethod: String, Equatable, Sendable {
    case untouched
    case seeded
    case chip
    case ribbon
    case exact
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

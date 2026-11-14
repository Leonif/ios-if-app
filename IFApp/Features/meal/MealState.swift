//
//  MealState.swift
//  IFApp
//

struct MealState: Equatable, Sendable {
    private(set) var minutesAgo: Int = 0

    private(set) var chipIdx: Int = MealChip.justNow.rawValue

    private(set) var inputMethod: MealInputMethod = .untouched

    private var restorePoint: Snapshot?

    private struct Snapshot: Equatable, Sendable {
        let minutesAgo: Int
        let chipIdx: Int
        let inputMethod: MealInputMethod
    }

    var isFresh: Bool { minutesAgo == 0 }

    mutating func set(minutesAgo: Int, chip: Int, via method: MealInputMethod) {
        self.minutesAgo = MealMath.clamped(minutesAgo)
        self.inputMethod = self.minutesAgo == 0 && method == .ribbon ? .untouched : method
        chipIdx = chip
    }

    mutating func markPickerOpened() {
        restorePoint = Snapshot(minutesAgo: minutesAgo, chipIdx: chipIdx, inputMethod: inputMethod)
    }

    mutating func revertToRestorePoint() {
        guard let restorePoint else { return }
        minutesAgo = restorePoint.minutesAgo
        chipIdx = restorePoint.chipIdx
        inputMethod = restorePoint.inputMethod
        self.restorePoint = nil
    }

    mutating func forgetRestorePoint() {
        restorePoint = nil
    }
}

enum MealInputMethod: String, Equatable, Sendable {
    case untouched
    case seeded
    case chip
    case ribbon
    case exact
}

enum MealChip: Int, CaseIterable {
    case justNow = 0
    case oneHour = 1
    case threeHours = 2
    case lastNight = 3

    static let lastNightMinuteOfDay = 21 * 60
    static let lastNightFloor = 30
}

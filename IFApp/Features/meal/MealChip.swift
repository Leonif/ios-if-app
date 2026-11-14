//
//  MealChip.swift
//  IFApp
//

enum MealChip: Int, CaseIterable {
    case justNow = 0
    case oneHour = 1
    case threeHours = 2
    case lastNight = 3

    static let lastNightMinuteOfDay = 21 * 60
    static let lastNightFloor = 30
}

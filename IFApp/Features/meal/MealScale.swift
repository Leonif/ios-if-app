//
//  MealScale.swift
//  IFApp
//

import Foundation

enum MealScale {
    static let snapStep = 1

    static let pitch: CGFloat = 4

    static let maxMinutes = 10080

    static let stepMinutes: [Int] = Array(0...maxMinutes)

    static var length: CGFloat { CGFloat(maxMinutes) * pitch }

    static func step(at minutes: Int) -> Int { 15 }

    static func position(ofMinutes minutes: Int) -> CGFloat {
        CGFloat(min(maxMinutes, max(0, minutes))) * pitch
    }

    static func snappedMinutes(atPosition p: CGFloat) -> Int {
        let clamped = max(0, min(length, p))
        return Int((clamped / pitch).rounded())
    }

    static func snap(_ minutes: Int) -> Int {
        min(maxMinutes, max(0, minutes))
    }

    // MARK: - Tick classification

    enum Tick {
        case minor
        case hour
        case day
    }

    static func tick(at minutes: Int) -> Tick {
        if minutes > 0 && minutes % 1440 == 0 { return .day }
        if minutes % 60 == 0 { return .hour }
        return .minor
    }

    static func labelKind(at minutes: Int) -> LabelKind? {
        if minutes == 0 { return .now }
        if minutes % 1440 == 0 { return .days(minutes / 1440) }
        if minutes % 60 == 0 { return .hours(minutes / 60) }
        return nil
    }

    enum LabelKind: Equatable {
        case now
        case hours(Int)
        case days(Int)
    }
}

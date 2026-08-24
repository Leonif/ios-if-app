//
//  MealScale.swift
//  IFApp
//
//  Geometry of the last-meal ribbon: how "minutes ago" maps to points on a strip
//  that is longer than the screen. Pure math, no view types.
//
//  The strip is a native-style drum: one minute per detent across the whole domain.
//  Precision and reach stop fighting each other — a slow drag lands any exact minute,
//  and a hard flick carries through hours on momentum, the way a system wheel does.
//  This replaces the earlier four-band scale, where the step coarsened to 30 or 60
//  minutes far from now and a round time like 20:50 fell between two ticks and could
//  not be landed (owner, 24.08 — "spin harder, get there faster, like the native
//  drum"). Retuning the feel is `pitch` here plus the momentum in the ribbon.
//

import Foundation

enum MealScale {
    /// Minutes per snap detent. One, everywhere — the whole point of the drum.
    static let snapStep = 1

    /// Points per minute. Constant across the whole strip. Small, because reach is
    /// carried by fling momentum, not by fitting the domain on one screen.
    static let pitch: CGFloat = 4

    /// The hard floor of the domain: the app does not back-date further than 7 days.
    static let maxMinutes = 10080

    /// Minutes-ago at every snap detent, index 0 = now. With a one-minute step the
    /// index *is* the minute, so `stepMinutes[i] == i`; kept as an array because the
    /// ribbon walks it by visible index when it draws.
    static let stepMinutes: [Int] = Array(0...maxMinutes)

    /// Full length of the strip in points.
    static var length: CGFloat { CGFloat(maxMinutes) * pitch }

    /// The VoiceOver adjustment step — deliberately coarser than the one-minute snap,
    /// so swiping the whole domain by assistive gesture stays usable (a minute at a
    /// time would be ten thousand swipes).
    static func step(at minutes: Int) -> Int { 15 }

    /// Distance from "now" in points. Linear: one minute is `pitch` points everywhere.
    static func position(ofMinutes minutes: Int) -> CGFloat {
        CGFloat(min(maxMinutes, max(0, minutes))) * pitch
    }

    /// Nearest snap value to a ribbon offset in points.
    static func snappedMinutes(atPosition p: CGFloat) -> Int {
        let clamped = max(0, min(length, p))
        return Int((clamped / pitch).rounded())
    }

    /// Nearest snap value to a minutes-ago value — already on the one-minute grid, so
    /// only the domain clamp is left to apply.
    static func snap(_ minutes: Int) -> Int {
        min(maxMinutes, max(0, minutes))
    }

    // MARK: Tick classification

    enum Tick {
        case minor      // a plain minute
        case hour       // on the hour
        case day        // a whole multiple of 24h from now
    }

    static func tick(at minutes: Int) -> Tick {
        if minutes > 0 && minutes % 1440 == 0 { return .day }
        if minutes % 60 == 0 { return .hour }
        return .minor
    }

    /// Which ticks carry a printed label: every hour, every day beyond 24h (whole days
    /// read as days, "1d" not "24h"). Only ~an hour of strip is on screen at once, so
    /// hourly labels are legible rather than crowded. Returns nil for the unlabelled
    /// majority.
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

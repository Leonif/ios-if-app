//
//  MealScale.swift
//  IFApp
//
//  Geometry of the last-meal ribbon: how "minutes ago" maps to points on a strip
//  that is longer than the screen. Pure math, no view types.
//
//  The point of the ribbon (over a fixed scale that fits the whole domain on screen)
//  is that the pitch is constant: one snap step is 6pt everywhere, so "40 minutes
//  ago" and "yesterday at eight" cost the same finger precision. What changes with
//  distance is how much time a step is worth.
//

import Foundation

enum MealScale {
    /// Snap resolution by distance: (upper bound in minutes ago, step in minutes).
    ///
    /// Retuning the scale is editing these four pairs and nothing else: pitch, tick
    /// heights, label thinning and the ribbon length all derive from this table.
    ///
    /// No longer a placeholder in its busiest band. The card's own acceptance
    /// criterion is that any moment inside twelve hours is reachable in one
    /// unbroken gesture, and at a 15-minute step twelve hours measured 432pt against
    /// the ~300pt a thumb sweeps comfortably — so the criterion could not be met by
    /// dragging, only by flinging, and a fling could not be aimed. At 30 minutes
    /// twelve hours is 324pt and the criterion holds.
    ///
    /// The band that was coarsened is the one that carries the traffic: the first
    /// `minutes_ago` sample (GA4, 19-21.08.2026, n=22) puts 12 of 22 answers between
    /// three and twelve hours, median 4.5h. Precision is what that band needs least —
    /// someone who ate "about five hours ago" does not distinguish 4:45 from 5:00 —
    /// and reach is what it needs most.
    ///
    /// The 12-24h band keeps its own row even though its step now equals the one
    /// above it. Collapsing them would draw the same ribbon and lose the four bands
    /// the design speaks in, which is the surface the next retune edits.
    static let bands: [(upper: Int, step: Int)] = [
        (180, 5),       // 0-3h    — 5 minutes
        (720, 30),      // 3-12h   — 30 minutes
        (1440, 30),     // 12-24h  — 30 minutes
        (10080, 60),    // 1-7d    — 1 hour
    ]

    /// Points per snap step. Constant across bands by design.
    static let pitch: CGFloat = 6

    /// The hard floor of the domain: the app does not back-date further than 7 days.
    static var maxMinutes: Int { bands[bands.count - 1].upper }

    /// Minutes-ago at every snap step, index 0 = now.
    static let stepMinutes: [Int] = {
        var out = [0]
        var lower = 0
        for band in bands {
            var m = lower + band.step
            while m <= band.upper {
                out.append(m)
                m += band.step
            }
            lower = band.upper
        }
        return out
    }()

    /// Full length of the strip in points.
    static var length: CGFloat { CGFloat(stepMinutes.count - 1) * pitch }

    /// The snap step in force at `minutes` — also the VoiceOver adjustment step.
    static func step(at minutes: Int) -> Int {
        for band in bands where minutes < band.upper { return band.step }
        return bands[bands.count - 1].step
    }

    /// Distance from "now" in points. Interpolates inside a band, so a value off the
    /// snap grid (one typed into the exact-time picker) sits between two ticks
    /// instead of being silently rounded.
    static func position(ofMinutes minutes: Int) -> CGFloat {
        let m = min(maxMinutes, max(0, minutes))
        var steps: CGFloat = 0
        var lower = 0
        for band in bands {
            if m <= band.upper {
                return (steps + CGFloat(m - lower) / CGFloat(band.step)) * pitch
            }
            steps += CGFloat(band.upper - lower) / CGFloat(band.step)
            lower = band.upper
        }
        return steps * pitch
    }

    /// Nearest snap value to a ribbon offset in points.
    static func snappedMinutes(atPosition p: CGFloat) -> Int {
        let clamped = max(0, min(length, p))
        let idx = Int((clamped / pitch).rounded())
        return stepMinutes[min(stepMinutes.count - 1, max(0, idx))]
    }

    /// Nearest snap value to a minutes-ago value.
    static func snap(_ minutes: Int) -> Int {
        snappedMinutes(atPosition: position(ofMinutes: minutes))
    }

    // MARK: Tick classification

    enum Tick {
        case minor      // one snap step
        case hour       // on the hour
        case day        // a whole multiple of 24h from now
    }

    static func tick(at minutes: Int) -> Tick {
        if minutes > 0 && minutes % 1440 == 0 { return .day }
        if minutes % 60 == 0 { return .hour }
        return .minor
    }

    /// Which ticks carry a printed label: every hour up to 3h, every 3h up to 12h,
    /// every 6h up to 24h, every day beyond. Whole days always read as days ("1d",
    /// not "24h"). Returns nil for the unlabelled majority.
    static func labelKind(at minutes: Int) -> LabelKind? {
        if minutes == 0 { return .now }
        if minutes % 1440 == 0 { return .days(minutes / 1440) }
        if minutes <= 180 { return minutes % 60 == 0 ? .hours(minutes / 60) : nil }
        if minutes <= 720 { return minutes % 180 == 0 ? .hours(minutes / 60) : nil }
        if minutes <= 1440 { return minutes % 360 == 0 ? .hours(minutes / 60) : nil }
        return nil
    }

    enum LabelKind: Equatable {
        case now
        case hours(Int)
        case days(Int)
    }
}

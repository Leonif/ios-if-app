//
//  Plan.swift
//  IFApp
//
//  A fasting plan is its fast length in whole hours — the four presets are just the
//  values that ship unlocked, not a closed set. It stopped being an enum in 1.5.0,
//  when a Pro custom goal made any length from 1 to 23 possible; storing a position
//  in a list cannot express "17 hours", and every label derived from that position
//  had to be written out case by case.
//
//  A plan states durations and nothing else. The invented wall-clock window the
//  presets used to print ("12:00 - 8:00 PM") went out with the card that carried
//  it: this app runs on anchors, so the only true value is how long, and the live
//  goal time is computed from fastStart + fastHours.
//

struct Plan: Equatable, Hashable, Sendable {
    /// Fast length in whole hours. Always within `Plan.range`.
    let hours: Int

    /// The lengths the picker offers. 24 is deliberately outside it: at a 24h goal the
    /// eating window degenerates to zero and the fast → window → fast chain the app is
    /// built on stops existing. Anyone who wants a full day sets 23 and keeps going —
    /// reaching the goal does not stop the timer (see the overtime state).
    static let range = 1...23

    init(hours: Int) {
        self.hours = Plan.range.clamped(to: hours)
    }

    /// The plan a goal in hours belongs to. Goals are whole hours everywhere they are
    /// produced (the four presets and a picker of whole hours), so this is exact.
    init(goalHours: Double) {
        self.init(hours: Int(goalHours.rounded()))
    }

    var fastHours: Double { Double(hours) }

    /// Hours of eating left in the day. Never zero — that is what `range` buys.
    ///
    /// The single definition of "the eating window is what the fast leaves of the
    /// day": the ratio label, the window shown in the editor and the moment the
    /// window closes all come from here. Written in one place because the label and
    /// the close moment drifting apart would be silent — "17:7" over a window that
    /// runs six hours looks perfectly normal on both screens.
    var windowHours: Int { 24 - hours }

    /// "16:8" — fast hours to eating hours. Computed rather than written out, so a
    /// custom 17h plan reads "17:7" the same way a preset does. Not localised on
    /// purpose: it is a pair of numerals, and Western digits are pinned app-wide.
    var ratioLabel: String { "\(hours):\(windowHours)" }

    /// Whether this is one of the four lengths that are free for everyone.
    var isPreset: Bool { Plan.presets.contains(self) }

    /// The value that goes into GA4 (`plan_selected` / `plan_confirmed` /
    /// `current_plan`). Presets keep their ratio so the existing breakdown survives;
    /// custom goals collapse into `custom:17` rather than spraying the dimension with
    /// one label per hour.
    var analyticsLabel: String { isPreset ? ratioLabel : "custom:\(hours)" }

    /// The free plan this one falls back to when the entitlement goes away. Nearest
    /// by length, and downwards on a tie — a goal the user cannot reach is a worse
    /// answer than one they overshoot. Only ever reached from a custom length: a
    /// preset returns itself.
    var nearestPreset: Plan {
        Plan.presets.min { a, b in
            let (da, db) = (abs(a.hours - hours), abs(b.hours - hours))
            return da == db ? a.hours < b.hours : da < db
        } ?? .default
    }

    var goalLabel: String {
        "Goal · \(hours)h"
    }

    /// The four plans available without Pro, in the order the segmented control
    /// shows them.
    static let presets: [Plan] = [Plan(hours: 14), Plan(hours: 16), Plan(hours: 18), Plan(hours: 20)]

    static let `default` = Plan(hours: 16)
}

private extension ClosedRange where Bound == Int {
    func clamped(to value: Int) -> Int { Swift.min(upperBound, Swift.max(lowerBound, value)) }
}

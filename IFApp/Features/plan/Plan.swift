//
//  Plan.swift
//  IFApp
//

struct Plan: Equatable, Hashable, Sendable {
    let hours: Int

    static let range = 1...23

    init(hours: Int) {
        self.hours = Plan.range.clamped(to: hours)
    }

    init(goalHours: Double) {
        self.init(hours: Int(goalHours.rounded()))
    }

    var fastHours: Double { Double(hours) }

    var windowHours: Int { 24 - hours }

    var ratioLabel: String { "\(hours):\(windowHours)" }

    var isPreset: Bool { Plan.presets.contains(self) }

    func allowed(isPro: Bool) -> Bool { isPro || isPreset }

    var analyticsLabel: String { isPreset ? ratioLabel : "custom:\(hours)" }

    var nearestPreset: Plan {
        Plan.presets.min { a, b in
            let (da, db) = (abs(a.hours - hours), abs(b.hours - hours))
            return da == db ? a.hours < b.hours : da < db
        } ?? .default
    }

    var goalLabel: String {
        "Goal · \(hours)h"
    }

    static let presets: [Plan] = [Plan(hours: 14), Plan(hours: 16), Plan(hours: 18), Plan(hours: 20)]

    static let `default` = Plan(hours: 16)
}

private extension ClosedRange where Bound == Int {
    func clamped(to value: Int) -> Int { Swift.min(upperBound, Swift.max(lowerBound, value)) }
}

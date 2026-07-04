//
//  PhaseCopy.swift
//  IFApp
//
//  Editorial copy. English for now; localization is a later pass.
//

import Foundation

enum PhaseCopy {
    static var idle: String { strings.Editorial.idle }
    static var complete: String { strings.Editorial.complete }

    static func editorial(for phase: Phase) -> String {
        switch phase {
        case .fed: return strings.Editorial.fed
        case .sugar: return strings.Editorial.sugar
        case .fat: return strings.Editorial.fat
        case .ketosis: return strings.Editorial.ketosis
        case .autophagy: return strings.Editorial.autophagy
        }
    }

    /// "Autophagy begins in 2h 36m"
    static func nextPhaseChip(next: Phase, secondsToNext: TimeInterval) -> String {
        let total = max(0, Int(secondsToNext))
        let h = total / 3600, m = (total / 60) % 60
        let when = h > 0 ? strings.Duration.hmShort(h, m) : strings.Duration.minutes(m)
        return strings.Editorial.beginsIn(next.label, when)
    }
}

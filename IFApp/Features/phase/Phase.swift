//
//  Phase.swift
//  IFApp
//
//  The "Verdant" metabolic phases. Phase + fraction are derived from elapsed time
//  vs the plan's fast length (the four ring phases occupy quarters of the goal;
//  Autophagy is the completed/looped state past 100%).
//

import SwiftUI

enum Phase: Int, CaseIterable {
    case fed, sugar, fat, ketosis, autophagy

    /// Verdant spectrum — ring gradient, timeline bars, center dot.
    var color: Color {
        switch self {
        case .fed: return Color(hex: "#E7C36A")
        case .sugar: return Color(hex: "#BFC06A")
        case .fat: return Color(hex: "#8DBE7C")
        case .ketosis: return Color(hex: "#56AC8E")
        case .autophagy: return Color(hex: "#4C9DB4")
        }
    }

    var label: String {
        switch self {
        case .fed: return strings.Phase.fed
        case .sugar: return strings.Phase.sugar
        case .fat: return strings.Phase.fat
        case .ketosis: return strings.Phase.ketosis
        case .autophagy: return strings.Phase.autophagy
        }
    }

    /// The value that goes into GA4 (`fast_stopped.stage`). Deliberately not `label`:
    /// the label is translated, so the same phase arrived as a different value per
    /// locale and the dimension could not be grouped at all. Stable English codes,
    /// written out rather than derived from `rawValue`, so reordering the cases
    /// cannot silently rewrite history.
    var analyticsValue: String {
        switch self {
        case .fed: return "fed"
        case .sugar: return "sugar"
        case .fat: return "fat"
        case .ketosis: return "ketosis"
        case .autophagy: return "autophagy"
        }
    }

    /// The value that goes into the exported CSV's `phase` column. Same rule as
    /// `analyticsValue` — a fixed, unlocalised ASCII literal, never `label` — but a
    /// **different list**, and deliberately not shared with it.
    ///
    /// `analyticsValue` is a GA4 dimension whose values were registered against
    /// existing data: renaming `fed` to `satiety` there would split one phase across
    /// two values in every report ever run. The CSV list is the one product wrote
    /// down (decision 14.2) and it names the metabolic state rather than the ring
    /// colour. Two of the five even agree by accident; that is not a reason to fold
    /// them, because a change on either side must not travel to the other.
    ///
    /// Wrong values here are worse than wrong values in telemetry: a file that has
    /// already left the phone cannot be corrected afterwards.
    var exportValue: String {
        switch self {
        case .fed: return "satiety"
        case .sugar: return "glucose"
        case .fat: return "fat_burning"
        case .ketosis: return "ketosis"
        case .autophagy: return "autophagy"
        }
    }

    /// The four phases shown on the ring (Autophagy is the completed state).
    static let ringPhases: [Phase] = [.fed, .sugar, .fat, .ketosis]
}

/// Derived progress snapshot for a given elapsed time and plan goal.
struct PhaseProgress: Equatable {
    let fraction: Double        // elapsed / goal, 0...1 (display clamps)
    let phase: Phase
    let isComplete: Bool
    /// Phase that begins next (nil once Autophagy is reached).
    let nextPhase: Phase?
    /// Seconds until the next phase boundary (0 if complete).
    let secondsToNext: TimeInterval

    static func compute(elapsed: TimeInterval, goalHours: Double) -> PhaseProgress {
        let goal = max(1, goalHours * 3600)
        let raw = elapsed / goal

        if raw >= 1 {
            return PhaseProgress(fraction: 1, phase: .autophagy, isComplete: true,
                                 nextPhase: nil, secondsToNext: 0)
        }

        let quarter = goal / 4
        let index = min(3, max(0, Int(raw * 4)))
        let phase = Phase.ringPhases[index]
        let next = Phase(rawValue: index + 1)   // .sugar/.fat/.ketosis/.autophagy
        let nextBoundary = Double(index + 1) * quarter
        return PhaseProgress(
            fraction: max(0, raw),
            phase: phase,
            isComplete: false,
            nextPhase: next,
            secondsToNext: max(0, nextBoundary - elapsed)
        )
    }
}

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
        case .fed: return "Fed"
        case .sugar: return "Sugar"
        case .fat: return "Fat"
        case .ketosis: return "Ketosis"
        case .autophagy: return "Autophagy"
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

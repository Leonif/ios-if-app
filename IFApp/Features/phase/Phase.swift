//
//  Phase.swift
//  IFApp
//

import SwiftUI

enum Phase: Int, CaseIterable {
    case fed, sugar, fat, ketosis, autophagy

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

    var analyticsValue: String {
        switch self {
        case .fed: return "fed"
        case .sugar: return "sugar"
        case .fat: return "fat"
        case .ketosis: return "ketosis"
        case .autophagy: return "autophagy"
        }
    }

    var exportValue: String {
        switch self {
        case .fed: return "satiety"
        case .sugar: return "glucose"
        case .fat: return "fat_burning"
        case .ketosis: return "ketosis"
        case .autophagy: return "autophagy"
        }
    }

    static let ringPhases: [Phase] = [.fed, .sugar, .fat, .ketosis]
}

struct PhaseProgress: Equatable {
    let fraction: Double
    let phase: Phase
    let isComplete: Bool
    let nextPhase: Phase?
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
        let next = Phase(rawValue: index + 1)
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

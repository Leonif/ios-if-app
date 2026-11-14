//
//  PhaseProgress.swift
//  IFApp
//

import Foundation

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

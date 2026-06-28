//
//  PhaseCopy.swift
//  IFApp
//
//  Editorial copy. English for now; localization is a later pass.
//

import Foundation

enum PhaseCopy {
    static let idle = "Start whenever you're ready, or log your last meal to pick up a fast already in progress."
    static let complete = "Fast complete. Your eating window is open. Refuel gently."

    static func editorial(for phase: Phase) -> String {
        switch phase {
        case .fed:
            return "Still digesting. Insulin is up and your body is storing the energy from your last meal."
        case .sugar:
            return "Glucose is easing down. Your body is leaning on its glycogen stores for fuel."
        case .fat:
            return "Glycogen is running low. Fat is becoming your main source of energy."
        case .ketosis:
            return "Ketones are climbing. You're well into fat-burning now."
        case .autophagy:
            return "Deep in the fast. Autophagy is recycling what your cells no longer need."
        }
    }

    /// "Autophagy begins in 2h 36m"
    static func nextPhaseChip(next: Phase, secondsToNext: TimeInterval) -> String {
        let total = max(0, Int(secondsToNext))
        let h = total / 3600, m = (total / 60) % 60
        let when = h > 0 ? "\(h)h \(m)m" : "\(m)m"
        return "\(next.label) begins in \(when)"
    }
}

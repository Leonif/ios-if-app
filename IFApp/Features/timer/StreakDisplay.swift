//
//  StreakDisplay.swift
//  IFApp
//

enum StreakDisplay: Equatable, Sendable {
    case alive(Int)
    case justEnded(Int, lastGoalDate: String)
    case none

    var count: Int {
        switch self {
        case .alive(let days), .justEnded(let days, _): return days
        case .none: return 0
        }
    }

    var hasEnded: Bool {
        if case .justEnded = self { return true }
        return false
    }

    var lastGoalDate: String? {
        if case .justEnded(_, let dayKey) = self { return dayKey }
        return nil
    }
}

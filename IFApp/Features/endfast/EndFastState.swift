//
//  EndFastState.swift
//  IFApp
//

import Foundation

struct EndFastState: Equatable, Sendable {
    static let nearGoalThresholdMinutes = 15

    static let overtimeNeutralThreshold: TimeInterval = 24 * 3600

    static let minimumFastDuration: TimeInterval = 60

    static let stepMinutes = 15

    var isOpen = false
    var entry: EndFastEntry = .ordinary
    var endTimestamp: Double = 0
    var fastStartTimestamp: Double = 0
    var earliest: Double = 0
    var latest: Double = 0
    var conflict: FastRecord?

    var conflictUnavoidable = false

    var stage: EndFastStage {
        if conflict != nil { return .refusal }
        switch entry {
        case .ordinary: return .picker
        case .nearGoal: return .nearGoal
        case .overtime: return .overtime
        }
    }

    var showsStepper: Bool { stage == .picker || stage == .overtime }

}

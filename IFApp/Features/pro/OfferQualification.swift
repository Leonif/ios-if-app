//
//  OfferQualification.swift
//  IFApp
//

import Foundation

enum OfferQualification {
    static let minimumGoalFraction = 0.5

    static func qualifies(elapsed: TimeInterval, goalHours: Double) -> Bool {
        goalHours > 0 && elapsed >= goalHours * 3600 * minimumGoalFraction
    }
}

//
//  Pro.swift
//  IFApp
//

import Foundation

enum ProCatalog {
    static let productID = "if24.pro.lifetime"
}

enum Entitlement: String, Equatable, Sendable {
    case pro
    case free
    case unknown

    var isLocked: Bool { self != .pro }

    var analyticsValue: String { rawValue }
}

enum OfferQualification {
    static let minimumGoalFraction = 0.5

    static func qualifies(elapsed: TimeInterval, goalHours: Double) -> Bool {
        goalHours > 0 && elapsed >= goalHours * 3600 * minimumGoalFraction
    }
}

enum PaywallTrigger: String, Equatable, Sendable {
    case fastFinished = "fast_finished"
    case planCustom = "plan_custom"
    case streakBreak = "streak_break"
    case manual
    case historyExport = "history_export"
    case home
    case unknown
}

enum PurchaseFailure: String, Equatable, Hashable, Sendable {
    case cancelled
    case network
    case pending
    case other
}

struct ProProductInfo: Equatable, Sendable {
    let id: String
    let displayPrice: String
}

enum EntitlementSource: Equatable, Hashable, Sendable {
    case purchased
    case restored
    case approved
}

enum PurchasePhase: Equatable, Sendable {
    case idle
    case purchasing
    case awaitingApproval
    case failed(PurchaseFailure)
    case granted(EntitlementSource)

    var outlivesOffer: Bool { self == .awaitingApproval }
}

enum ProNotice: Equatable, Sendable {
    case entitlementRevoked
    case goalChanged(fallbackHours: Int)
}

enum OfferState: Equatable, Hashable, Sendable {
    case offer
    case purchasing
    case failed(PurchaseFailure)
    case awaitingApproval
    case unverified
    case granted(EntitlementSource)
}

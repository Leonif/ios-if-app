//
//  PurchasePhase.swift
//  IFApp
//

enum PurchasePhase: Equatable, Sendable {
    case idle
    case purchasing
    case awaitingApproval
    case failed(PurchaseFailure)
    case granted(EntitlementSource)

    var outlivesOffer: Bool { self == .awaitingApproval }
}

//
//  OfferState.swift
//  IFApp
//

enum OfferState: Equatable, Hashable, Sendable {
    case offer
    case purchasing
    case failed(PurchaseFailure)
    case awaitingApproval
    case unverified
    case granted(EntitlementSource)
}

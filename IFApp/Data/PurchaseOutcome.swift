//
//  PurchaseOutcome.swift
//  IFApp
//

enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    case pending
    case cancelled
    case failed(PurchaseFailure)
}

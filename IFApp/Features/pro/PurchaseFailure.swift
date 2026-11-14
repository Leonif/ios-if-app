//
//  PurchaseFailure.swift
//  IFApp
//

enum PurchaseFailure: String, Equatable, Hashable, Sendable {
    case cancelled
    case network
    case pending
    case other
}

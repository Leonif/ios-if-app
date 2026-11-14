//
//  RestoreOutcome.swift
//  IFApp
//

enum RestoreOutcome: Equatable, Sendable {
    case restored
    case nothingToRestore
    case failed(PurchaseFailure)
}

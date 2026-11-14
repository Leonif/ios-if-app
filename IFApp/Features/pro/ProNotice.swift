//
//  ProNotice.swift
//  IFApp
//

enum ProNotice: Equatable, Sendable {
    case entitlementRevoked
    case goalChanged(fallbackHours: Int)
}

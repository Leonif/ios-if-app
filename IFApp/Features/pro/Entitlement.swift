//
//  Entitlement.swift
//  IFApp
//

enum Entitlement: String, Equatable, Sendable {
    case pro
    case free
    case unknown

    var isLocked: Bool { self != .pro }

    var analyticsValue: String { rawValue }
}

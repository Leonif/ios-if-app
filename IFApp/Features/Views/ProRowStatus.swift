//
//  ProRowStatus.swift
//  IFApp
//

enum ProRowStatus: Equatable {
    case inactive
    case active
    case awaitingApproval
    case notCheckedYet

    var label: String {
        switch self {
        case .inactive: return strings.Pro.statusInactive
        case .active: return strings.Pro.statusActive
        case .awaitingApproval: return strings.Pro.statusAwaiting
        case .notCheckedYet: return strings.Pro.statusUnverified
        }
    }

    var opensOffer: Bool { self != .active }
}

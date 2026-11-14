//
//  Phase.swift
//  IFApp
//

import SwiftUI

enum Phase: Int, CaseIterable {
    case fed, sugar, fat, ketosis, autophagy

    var color: Color {
        switch self {
        case .fed: return Color(hex: "#E7C36A")
        case .sugar: return Color(hex: "#BFC06A")
        case .fat: return Color(hex: "#8DBE7C")
        case .ketosis: return Color(hex: "#56AC8E")
        case .autophagy: return Color(hex: "#4C9DB4")
        }
    }

    var label: String {
        switch self {
        case .fed: return strings.Phase.fed
        case .sugar: return strings.Phase.sugar
        case .fat: return strings.Phase.fat
        case .ketosis: return strings.Phase.ketosis
        case .autophagy: return strings.Phase.autophagy
        }
    }

    var analyticsValue: String {
        switch self {
        case .fed: return "fed"
        case .sugar: return "sugar"
        case .fat: return "fat"
        case .ketosis: return "ketosis"
        case .autophagy: return "autophagy"
        }
    }

    var exportValue: String {
        switch self {
        case .fed: return "satiety"
        case .sugar: return "glucose"
        case .fat: return "fat_burning"
        case .ketosis: return "ketosis"
        case .autophagy: return "autophagy"
        }
    }

    static let ringPhases: [Phase] = [.fed, .sugar, .fat, .ketosis]
}

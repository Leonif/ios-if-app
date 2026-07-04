//
//  Plan.swift
//  IFApp
//
//  The four fasting plans. Eating-window strings match the design handoff
//  (illustrative); the live goal time is computed from fastStart + fastHours.
//

enum Plan: Int, CaseIterable {
    case p14_10, p16_8, p18_6, p20_4

    var fastHours: Double {
        switch self {
        case .p14_10: return 14
        case .p16_8: return 16
        case .p18_6: return 18
        case .p20_4: return 20
        }
    }

    var ratioLabel: String {
        switch self {
        case .p14_10: return "14:10"
        case .p16_8: return "16:8"
        case .p18_6: return "18:6"
        case .p20_4: return "20:4"
        }
    }

    /// Eating window text shown in the plan editor (handoff copy).
    var windowLabel: String {
        switch self {
        case .p14_10: return strings.Window.p14_10
        case .p16_8: return strings.Window.p16_8
        case .p18_6: return strings.Window.p18_6
        case .p20_4: return strings.Window.p20_4
        }
    }

    var goalLabel: String {
        "Goal · \(Int(fastHours))h"
    }

    static let `default`: Plan = .p16_8
}

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
        case .p14_10: return "10:00 AM - 8:00 PM"
        case .p16_8: return "12:00 - 8:00 PM"
        case .p18_6: return "2:00 - 8:00 PM"
        case .p20_4: return "4:00 - 8:00 PM"
        }
    }

    var goalLabel: String {
        "Goal · \(Int(fastHours))h"
    }

    static let `default`: Plan = .p16_8
}

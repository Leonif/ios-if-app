//
//  PlanState.swift
//  IFApp
//

struct PlanState: Equatable, Sendable {
    var planIdx: Int = Plan.default.rawValue

    var plan: Plan { Plan(rawValue: planIdx) ?? .default }
}

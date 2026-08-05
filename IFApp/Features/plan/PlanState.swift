//
//  PlanState.swift
//  IFApp
//

struct PlanState: Equatable, Sendable {
    /// The selected plan. Stored as the value itself rather than a position in a list:
    /// a custom goal has no position.
    var plan: Plan = .default
}

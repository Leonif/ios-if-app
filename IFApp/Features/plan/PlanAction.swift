//
//  PlanAction.swift
//  IFApp
//

import Redux

enum PlanAction: Action {
    /// A plan was chosen, by its fast length in hours — a preset tap and a custom
    /// goal are the same event, they differ only in the value.
    case selected(hours: Int)
}

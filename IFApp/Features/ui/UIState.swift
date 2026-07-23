//
//  UIState.swift
//  IFApp
//
//  Presentation flags kept in the store so sheet state is part of the single
//  source of truth (matches the handoff's `editing` / `mealOpen`).
//

struct UIState: Equatable, Sendable {
    var planEditorOpen: Bool = false
    var mealPickerOpen: Bool = false
    var streakMilestoneOpen: Bool = false
    var resetConfirmOpen: Bool = false
}

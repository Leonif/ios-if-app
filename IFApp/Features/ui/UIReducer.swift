//
//  UIReducer.swift
//  IFApp
//

import Redux

func uiReducer(state: UIState, action: Action) -> UIState {
    var newState = state

    switch action as? UIAction {
    case .planEditorOpened: newState.planEditorOpen = true
    case .planEditorClosed: newState.planEditorOpen = false
    case .mealPickerOpened: newState.mealPickerOpen = true
    case .mealPickerClosed: newState.mealPickerOpen = false
    case .streakMilestoneOpened: newState.streakMilestoneOpen = true
    case .streakMilestoneClosed: newState.streakMilestoneOpen = false
    case .resetConfirmOpened: newState.resetConfirmOpen = true
    case .resetConfirmClosed: newState.resetConfirmOpen = false
    case .none: break
    }

    return newState
}

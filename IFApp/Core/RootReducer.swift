//
//  RootReducer.swift
//  IFApp
//
//  Pure, synchronous. Delegates each substate to its feature reducer.
//

import Redux

func rootReducer(state: AppState, action: Action) -> AppState {
    var newState = state
    newState.timerState = timerReducer(state: state.timerState, action: action)
    newState.planState = planReducer(state: state.planState, action: action)
    newState.mealState = mealReducer(state: state.mealState, action: action)
    newState.uiState = uiReducer(state: state.uiState, action: action)
    newState.historyState = historyReducer(state: state.historyState, action: action)
    newState.proState = proReducer(state: state.proState, action: action)
    return newState
}

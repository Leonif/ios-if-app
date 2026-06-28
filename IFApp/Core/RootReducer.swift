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
    return newState
}

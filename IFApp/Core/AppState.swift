//
//  AppState.swift
//  IFApp
//
//  Single source of truth. Each feature owns a substate.
//

struct AppState: Equatable, Sendable {
    var timerState = TimerState()
    var planState = PlanState()
    var mealState = MealState()
    var uiState = UIState()
    var historyState = HistoryState()
}

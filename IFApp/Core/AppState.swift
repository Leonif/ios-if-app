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
    var proState = ProState()

    /// The plan the fast/window cycle currently in flight is running to — the goal
    /// pinned at its start, falling back to the selected plan when nothing is pinned.
    /// Everything that means "what is happening right now" derives from this;
    /// `planState.plan` stays what the user has *selected*, which is a different fact.
    var activePlan: Plan {
        Plan(goalHours: timerState.resolvedGoalHours(planHours: planState.plan.fastHours))
    }

    var activeGoalHours: Double { activePlan.fastHours }
}

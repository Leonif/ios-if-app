//
//  AppState.swift
//  IFApp
//

struct AppState: Equatable, Sendable {
    var timerState = TimerState()
    var planState = PlanState()
    var mealState = MealState()
    var endFastState = EndFastState()
    var uiState = UIState()
    var historyState = HistoryState()
    var proState = ProState()
    var sunnahState = SunnahState()

    var activePlan: Plan {
        Plan(goalHours: timerState.resolvedGoalHours(planHours: planState.plan.fastHours))
    }

    var activeGoalHours: Double { activePlan.fastHours }

    var streak: StreakStatus { timerState.streak(ownsFreeze: proState.isPro) }

    var selectedPlanAllowed: Bool {
        planState.plan.allowed(isPro: proState.isPro)
    }
}

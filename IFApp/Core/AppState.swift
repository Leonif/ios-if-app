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

    /// Whether the plan the user has *selected* may be used under the entitlement they
    /// currently hold: the four presets are free, any other length is Pro's.
    ///
    /// One definition because two places act on this in opposite directions — the
    /// editor opens the offer when it is false, the next fast falls back to the
    /// nearest preset — and both would still compile if only one of them moved. The
    /// gate drifting apart is silent: the plan gets confirmed without an offer, and
    /// then the start quietly runs to a different goal.
    var selectedPlanAllowed: Bool {
        proState.isPro || planState.plan.isPreset
    }
}

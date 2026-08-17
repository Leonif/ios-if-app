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

    /// The streak as screens must project it. It is assembled here rather than on
    /// `timerState` because one of its four facts — whether the protected day is
    /// owned — is the entitlement, and the timer substate has no business holding a
    /// copy of that. Screens read this; nobody builds a `StreakStatus` by hand.
    var streak: StreakStatus { timerState.streak(ownsFreeze: proState.isPro) }

    /// Whether the plan **in the store** may be used under the entitlement now held:
    /// the four presets are free, any other length is Pro's.
    ///
    /// The rule itself is `Plan.allowed(isPro:)`; this is only the question asked
    /// about the stored plan, and its one consumer is the fallback in
    /// `StartFastThunk` at the next start. The editor deliberately does not read it:
    /// the length on the wheel is a draft inside the sheet and never reaches the
    /// store unless the same rule lets it, so a projection off state would always
    /// answer about the previous plan. Both ask the one definition, so it cannot drift —
    /// and drifting here is silent: a plan confirmed without an offer, and then a
    /// start that quietly runs to a different goal.
    var selectedPlanAllowed: Bool {
        planState.plan.allowed(isPro: proState.isPro)
    }
}

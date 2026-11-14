//
//  AppState+OfferPhase.swift
//  IFApp
//

extension AppState {
    func offerPhase(at now: Double) -> Phase {
        switch timerState.screenState(at: now, plan: activePlan) {
        case .eating, .eatingOver:
            return .fat
        case .idle, .active, .goalReached, .complete:
            return PhaseProgress.compute(elapsed: timerState.elapsed(at: now), goalHours: activeGoalHours).phase
        }
    }
}

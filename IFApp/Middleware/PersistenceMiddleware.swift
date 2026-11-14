//
//  PersistenceMiddleware.swift
//  IFApp
//

import Redux

final class PersistenceMiddleware: Middleware {
    private let repo: TimerPersistenceRepositoryProtocol
    private let offer: ProOfferRepositoryProtocol

    init(repo: TimerPersistenceRepositoryProtocol = container.inject(),
         offer: ProOfferRepositoryProtocol = container.inject()) {
        self.repo = repo
        self.offer = offer
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard let app = state as? AppState else { return }
        switch action {
        case is TimerAction:
            let timer = app.timerState
            repo.save(
                fastStartTimestamp: timer.fastStartTimestamp,
                goalHours: timer.goalHours,
                isRunning: timer.isRunning,
                completedSessions: timer.completedSessionsCount,
                hasCelebrated: timer.hasCelebrated,
                eatingStartTimestamp: timer.eatingStartTimestamp,
                isEating: timer.isEating,
                stagedElapsed: timer.stagedElapsed,
                fastEndTimestamp: timer.fastEndTimestamp,
                streakCount: timer.streakCount,
                lastGoalDate: timer.lastGoalDate,
                freezeSpentMonth: timer.freezeSpentMonth
            )
        case is PlanAction:
            repo.savePlanHours(app.planState.plan.hours)
        case is ProAction:
            if app.proState.autoOfferShown { offer.markOfferShown() }
        default:
            break
        }
    }
}

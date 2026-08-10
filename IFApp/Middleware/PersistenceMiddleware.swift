//
//  PersistenceMiddleware.swift
//  IFApp
//
//  Persists the timer substate after every timer action. Lives the whole app lifecycle.
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
                streakCount: timer.streakCount,
                lastGoalDate: timer.lastGoalDate
            )
        case is PlanAction:
            repo.savePlanHours(app.planState.plan.hours)
        case is ProAction:
            // Written from the reduced state, not from the action that spends it, for
            // the same reason the timer above is: *when* the one-time offer counts as
            // spent is the reducer's rule and belongs in one place. A second copy of
            // it here would keep compiling while quietly not persisting a show.
            if app.proState.autoOfferShown { offer.markOfferShown() }
        default:
            break
        }
    }
}

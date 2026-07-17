//
//  PersistenceMiddleware.swift
//  IFApp
//
//  Persists the timer substate after every timer action. Lives the whole app lifecycle.
//

import Redux

final class PersistenceMiddleware: Middleware {
    private let repo: TimerPersistenceRepositoryProtocol

    init(repo: TimerPersistenceRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard let app = state as? AppState else { return }
        switch action {
        case is TimerAction:
            let timer = app.timerState
            repo.save(
                fastStartTimestamp: timer.fastStartTimestamp,
                isRunning: timer.isRunning,
                completedSessions: timer.completedSessionsCount,
                hasCelebrated: timer.hasCelebrated,
                eatingStartTimestamp: timer.eatingStartTimestamp,
                isEating: timer.isEating
            )
        case is PlanAction:
            repo.savePlanIdx(app.planState.planIdx)
        default:
            break
        }
    }
}

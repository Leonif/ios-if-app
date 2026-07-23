//
//  StreakMiddleware.swift
//  IFApp
//
//  Shows the streak milestone card: once per threshold (3/7/14/30), after the
//  goal-reached moment has settled so it never covers the seal & sweep.
//

import Redux

final class StreakMiddleware: Middleware {
    private let milestones = [3, 7, 14, 30]
    private let repo: TimerPersistenceRepositoryProtocol

    init(repo: TimerPersistenceRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard case AppLifecycleAction.goalScreenSettled = action,
              let app = state as? AppState else { return }

        let streak = app.timerState.streakCount
        guard milestones.contains(streak), streak > repo.loadLastMilestoneShown() else { return }

        repo.saveLastMilestoneShown(streak)
        dispatch(UIAction.streakMilestoneOpened)
        dispatch(AppLifecycleAction.streakMilestone(days: streak))
    }
}

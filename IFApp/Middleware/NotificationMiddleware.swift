//
//  NotificationMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class NotificationMiddleware: Middleware {
    private let repo: NotificationRepositoryProtocol

    init(repo: NotificationRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard let app = state as? AppState else { return }
        switch action {
        case is TimerAction, is PlanAction, is AppLifecycleAction:
            sync(app)
        default:
            break
        }
    }

    private func sync(_ app: AppState) {
        let timer = app.timerState
        let goalHours = app.activeGoalHours
        let now = Clock.now().timeIntervalSince1970

        if timer.isRunning {
            let secondsUntilGoal = timer.fastStartTimestamp + goalHours * 3600 - now
            if secondsUntilGoal > 0 {
                repo.scheduleGoalNotification(after: secondsUntilGoal)
            } else {
                repo.cancelGoalNotification()
            }
        } else {
            repo.cancelGoalNotification()
        }

        if timer.isEating {
            let secondsUntilClose = timer.eatingEndTimestamp(plan: app.activePlan) - now
            if secondsUntilClose > 0 {
                repo.scheduleEatingEndNotification(after: secondsUntilClose)
            } else {
                repo.cancelEatingEndNotification()
            }
        } else {
            repo.cancelEatingEndNotification()
        }
    }
}

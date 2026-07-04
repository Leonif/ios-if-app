//
//  NotificationMiddleware.swift
//  IFApp
//
//  Keeps the single goal-reached local push in sync with the timer. Reacts to
//  anything that can move the goal time or running state (start/stop/reset/adjust,
//  back-dated meal, plan change) plus app launch, then schedules or cancels.
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

    /// Schedules the goal push when a fast is running and the goal is still ahead;
    /// otherwise cancels it. Idempotent, so it's safe to call on every relevant action.
    private func sync(_ app: AppState) {
        let timer = app.timerState
        guard timer.isRunning else {
            repo.cancelGoalNotification()
            return
        }

        let goalHours = (Plan(rawValue: app.planState.planIdx) ?? .default).fastHours
        let goalTimestamp = timer.fastStartTimestamp + goalHours * 3600
        let secondsUntilGoal = goalTimestamp - Clock.now().timeIntervalSince1970

        if secondsUntilGoal > 0 {
            repo.scheduleGoalNotification(after: secondsUntilGoal)
        } else {
            repo.cancelGoalNotification()
        }
    }
}

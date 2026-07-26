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

    /// Keeps the goal push (running fast) and the eating-window push (open window) in
    /// sync with the timer. Each is scheduled while its deadline is still ahead and
    /// cancelled otherwise. Idempotent, so it's safe to call on every relevant action.
    private func sync(_ app: AppState) {
        let timer = app.timerState
        let plan = Plan(rawValue: app.planState.planIdx) ?? .default
        let now = Clock.now().timeIntervalSince1970

        // Goal push while a fast is running.
        if timer.isRunning {
            let secondsUntilGoal = timer.fastStartTimestamp + plan.fastHours * 3600 - now
            if secondsUntilGoal > 0 {
                repo.scheduleGoalNotification(after: secondsUntilGoal)
            } else {
                repo.cancelGoalNotification()
            }
        } else {
            repo.cancelGoalNotification()
        }

        // Eating-window-closed push while a window is open.
        if timer.isEating {
            let secondsUntilClose = timer.eatingEndTimestamp(fastHours: plan.fastHours) - now
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

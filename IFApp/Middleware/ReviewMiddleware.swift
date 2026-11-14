//
//  ReviewMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class ReviewMiddleware: Middleware {
    private let repo: ReviewRepositoryProtocol
    private let fallbackGoalCount = 3
    private let fallbackDelay: TimeInterval = 4 * 3600
    private var didRequestReviewThisLaunch = false
    private var isRequestInFlight = false

    init(repo: ReviewRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        if case UIAction.streakMilestoneClosed = action {
            requestReview(trigger: .streakMilestone, dispatch: dispatch)
            return
        }

        if case TimerAction.goalCelebrated = action, let app = state as? AppState {
            if app.timerState.completedSessionsCount == fallbackGoalCount,
               app.timerState.streakCount != 3 {
                repo.setPendingGoal(Date())
            }
            return
        }

        if case AppLifecycleAction.appBecameActive = action {
            guard let goalAt = repo.pendingGoalDate(),
                  Date().timeIntervalSince(goalAt) >= fallbackDelay else { return }
            requestReview(trigger: .nextOpen, dispatch: dispatch) { [repo] didAsk in
                if didAsk { repo.clearPendingGoal() }
            }
        }
    }

    private func requestReview(trigger: ReviewPromptTrigger,
                               dispatch: DispatchFunction,
                               completion: ((Bool) -> Void)? = nil) {
        guard !didRequestReviewThisLaunch, !isRequestInFlight, repo.canPrompt() else {
            completion?(false)
            return
        }
        isRequestInFlight = true
        repo.requestReview { [weak self] didAsk in
            guard let self else { return }
            self.isRequestInFlight = false
            guard didAsk else {
                completion?(false)
                return
            }
            self.didRequestReviewThisLaunch = true
            self.repo.markPromptShown()
            dispatch(AppLifecycleAction.reviewPrompted(trigger: trigger))
            completion?(true)
        }
    }
}

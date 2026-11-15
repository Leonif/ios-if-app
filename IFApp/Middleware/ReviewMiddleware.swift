//
//  ReviewMiddleware.swift
//  IFApp
//

import Foundation
import Redux

final class ReviewMiddleware: Middleware {
    private let repo: ReviewRepositoryProtocol
    private static let minCompletedSessions = 2
    private var didRequestReviewThisLaunch = false
    private var isRequestInFlight = false

    init(repo: ReviewRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard case AppLifecycleAction.eatingWindowSettled = action,
              let app = state as? AppState,
              Self.qualifies(app) else { return }
        requestReview(trigger: .fastCompleted, dispatch: dispatch)
    }

    private static func qualifies(_ app: AppState) -> Bool {
        guard let last = app.historyState.latestRecord,
              abs(last.endTimestamp - app.timerState.eatingStartTimestamp) < 1,
              last.goalReached else { return false }
        return app.timerState.completedSessionsCount >= minCompletedSessions
    }

    private func requestReview(trigger: ReviewPromptTrigger, dispatch: DispatchFunction) {
        guard !didRequestReviewThisLaunch, !isRequestInFlight, repo.canPrompt() else { return }
        isRequestInFlight = true
        repo.requestReview { [weak self] didAsk in
            guard let self else { return }
            self.isRequestInFlight = false
            guard didAsk else { return }
            self.didRequestReviewThisLaunch = true
            self.repo.markPromptShown()
            dispatch(AppLifecycleAction.reviewPrompted(trigger: trigger))
        }
    }
}

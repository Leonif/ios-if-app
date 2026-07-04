//
//  ReviewMiddleware.swift
//  IFApp
//
//  Gates the in-app review prompt: only after a qualifying completed session,
//  past the threshold, and at most once per app launch.
//

import Redux

final class ReviewMiddleware: Middleware {
    private let repo: ReviewRepositoryProtocol
    private let completedSessionsThreshold = 2
    private var didRequestReviewThisLaunch = false

    init(repo: ReviewRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        guard case TimerAction.stopped(_, let qualifies) = action, qualifies,
              let app = state as? AppState else { return }

        guard !didRequestReviewThisLaunch,
              app.timerState.completedSessionsCount >= completedSessionsThreshold,
              repo.canPrompt() else { return }

        didRequestReviewThisLaunch = true
        repo.markPromptShown()
        dispatch(UIAction.reviewPromptOpened)
        dispatch(AppLifecycleAction.reviewPrompted)
    }
}

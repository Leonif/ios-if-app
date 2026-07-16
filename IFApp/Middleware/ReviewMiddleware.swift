//
//  ReviewMiddleware.swift
//  IFApp
//
//  Gates the in-app review prompt: only on the settled goal-reached screen,
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
        // The signal itself means the goal was reached — no extra qualification needed.
        guard case AppLifecycleAction.goalScreenSettled = action,
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

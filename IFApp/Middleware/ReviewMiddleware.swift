//
//  ReviewMiddleware.swift
//  IFApp
//
//  Calls the native review request at moments of accumulated pride, gated to at
//  most 3 lifetime calls, 1/day, 1/launch. Two triggers:
//    1. The streak milestone card was just closed (streak 3/7/14/30).
//    2. Fallback for the 3rd completed goal without a streak-3: arm a pending
//       flag, then request on the next app open ≥4h after that goal — so the
//       prompt lands on a fresh session, not on top of the goal moment.
//
//  The gates are spent — and `review_prompted` is logged — only once the native
//  call has actually gone out on an active scene. No active scene means nothing
//  was asked: the attempt stays unspent and we try again another time.
//

import Foundation
import Redux

final class ReviewMiddleware: Middleware {
    private let repo: ReviewRepositoryProtocol
    /// The completed-goal count that arms the "next open" fallback.
    private let fallbackGoalCount = 3
    /// The fallback waits this long after the goal, so an open driven by the
    /// goal push itself never triggers the prompt.
    private let fallbackDelay: TimeInterval = 4 * 3600
    private var didRequestReviewThisLaunch = false
    /// A native call is out and its result has not come back yet — the gates are
    /// still unspent, so without this a second action would start a second call.
    private var isRequestInFlight = false

    init(repo: ReviewRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        // Trigger 1: the milestone card was closed — the reward is complete,
        // the prompt follows the positive moment instead of replacing it.
        if case UIAction.streakMilestoneClosed = action {
            requestReview(trigger: .streakMilestone, dispatch: dispatch)
            return
        }

        // Fallback arming: the 3rd goal ever, but not on a streak-3 (the state
        // here is post-reduce, so the counters already include this goal).
        if case TimerAction.goalCelebrated = action, let app = state as? AppState {
            if app.timerState.completedSessionsCount == fallbackGoalCount,
               app.timerState.streakCount != 3 {
                repo.setPendingGoal(Date())
            }
            return
        }

        // Trigger 2: app open (cold start or foreground) ≥4h after the armed goal.
        if case AppLifecycleAction.appBecameActive = action {
            guard let goalAt = repo.pendingGoalDate(),
                  Date().timeIntervalSince(goalAt) >= fallbackDelay else { return }
            requestReview(trigger: .nextOpen, dispatch: dispatch) { [repo] didAsk in
                // The arming survives a launch that had no active scene to ask on.
                if didAsk { repo.clearPendingGoal() }
            }
        }
    }

    /// Applies the gates and, when they pass, calls the native request.
    ///
    /// The lifetime attempt is spent and the event logged **after** the call reports
    /// that it went out on an active scene, never before: there are three attempts in
    /// a lifetime, and one burnt on a scene Apple ignores is a prompt the user never
    /// saw counted as shown. `completion` gets what the call reported.
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

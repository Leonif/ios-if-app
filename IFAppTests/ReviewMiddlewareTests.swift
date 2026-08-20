//
//  ReviewMiddlewareTests.swift
//  IFAppTests
//
//  There are three review prompts in a lifetime, and until 1.5.1 one of them was
//  spent before anyone knew whether the request would go out. `markPromptShown`
//  and `review_prompted` ran the moment the gates passed; the native call was
//  made afterwards, asynchronously, and dropped by Apple whenever it landed on a
//  scene that was not `foregroundActive` — which is exactly where the "next open"
//  fallback lands on a cold start. The attempt was gone, the funnel said "shown",
//  and the user saw nothing.
//
//  These tests state the fix as a rule: nothing is spent and nothing is logged
//  until the call reports that it actually went out.
//

import XCTest
import Redux
@testable import IFApp

final class ReviewMiddlewareTests: XCTestCase {

    /// Stands in for the real repository, with the one thing that mattered made
    /// explicit: whether the native call found a scene to ask on.
    private final class RepoFake: ReviewRepositoryProtocol {
        /// What `requestReview` reports back — false = there was no active scene.
        var callGoesOut = true
        var promptsShown = 0
        var pendingGoal: Date?
        var clearedPendingGoal = false
        private(set) var requestCalls = 0
        /// The real repository answers through `Task { @MainActor }`, never in the
        /// caller's frame. Setting this holds the answer so a test can act in the
        /// window where the call is out and its result has not come back.
        var holdsTheAnswer = false
        private var heldCompletion: ((Bool) -> Void)?

        func canPrompt() -> Bool { true }
        func markPromptShown() { promptsShown += 1 }
        func requestReview(completion: @escaping (Bool) -> Void) {
            requestCalls += 1
            if holdsTheAnswer { heldCompletion = completion } else { completion(callGoesOut) }
        }

        /// Delivers a held answer, the way the main-actor hop eventually would.
        func answerNow() {
            let completion = heldCompletion
            heldCompletion = nil
            completion?(callGoesOut)
        }
        func pendingGoalDate() -> Date? { pendingGoal }
        func setPendingGoal(_ date: Date) { pendingGoal = date }
        func clearPendingGoal() {
            clearedPendingGoal = true
            pendingGoal = nil
        }
    }

    /// Collects what the middleware dispatched, which is where `review_prompted`
    /// is born — `AnalyticsMiddleware` only forwards it.
    private func recordingDispatch(into box: Box) -> DispatchFunction {
        DispatchFunction(dispatchAction: { box.actions.append($0) }, dispatchThunk: { _ in })
    }

    private final class Box { var actions: [Action] = [] }

    private func promptedTriggers(_ box: Box) -> [ReviewPromptTrigger] {
        box.actions.compactMap {
            if case let AppLifecycleAction.reviewPrompted(trigger) = $0 { return trigger }
            return nil
        }
    }

    /// The defect. The fallback is due, the gates pass — but there is no active
    /// scene, so nothing was asked. Nothing may be spent for it either.
    func testNoActiveSceneSpendsNothingAndLogsNothing() {
        let repo = RepoFake()
        repo.callGoesOut = false
        repo.pendingGoal = Date(timeIntervalSinceNow: -5 * 3600)
        let middleware = ReviewMiddleware(repo: repo)
        let box = Box()

        middleware.handle(action: AppLifecycleAction.appBecameActive,
                          state: AppState(),
                          dispatch: recordingDispatch(into: box))

        XCTAssertEqual(repo.requestCalls, 1, "the request is still attempted")
        XCTAssertEqual(repo.promptsShown, 0, "no attempt is spent on a call that never went out")
        XCTAssertTrue(promptedTriggers(box).isEmpty, "and the funnel is not told we prompted")
        XCTAssertFalse(repo.clearedPendingGoal, "the arming survives for the next open")
    }

    /// The same trigger when the call does go out: this is the one that costs an
    /// attempt, and the only one the funnel hears about.
    func testCallThatGoesOutSpendsTheAttemptAndLogsOnce() {
        let repo = RepoFake()
        repo.pendingGoal = Date(timeIntervalSinceNow: -5 * 3600)
        let middleware = ReviewMiddleware(repo: repo)
        let box = Box()

        middleware.handle(action: AppLifecycleAction.appBecameActive,
                          state: AppState(),
                          dispatch: recordingDispatch(into: box))

        XCTAssertEqual(repo.promptsShown, 1)
        XCTAssertEqual(promptedTriggers(box), [.nextOpen])
        XCTAssertTrue(repo.clearedPendingGoal, "the fallback is done with")
    }

    /// A cold start hits both: `onAppear` fires while the scene is still settling,
    /// the `scenePhase` change follows once it is active. The first must not
    /// consume the once-per-launch gate, or the second — the real one — is blocked.
    func testAttemptWithoutASceneDoesNotBlockTheNextOneInTheSameLaunch() {
        let repo = RepoFake()
        repo.callGoesOut = false
        repo.pendingGoal = Date(timeIntervalSinceNow: -5 * 3600)
        let middleware = ReviewMiddleware(repo: repo)
        let box = Box()

        middleware.handle(action: AppLifecycleAction.appBecameActive,
                          state: AppState(),
                          dispatch: recordingDispatch(into: box))
        repo.callGoesOut = true
        middleware.handle(action: AppLifecycleAction.appBecameActive,
                          state: AppState(),
                          dispatch: recordingDispatch(into: box))

        XCTAssertEqual(repo.requestCalls, 2)
        XCTAssertEqual(repo.promptsShown, 1, "exactly one attempt, spent on the call that went out")
        XCTAssertEqual(promptedTriggers(box), [.nextOpen])
    }

    /// The window the gates are not spent in yet. The native call is asynchronous,
    /// so between "asked" and "answered" every gate still reads as open — and both
    /// `appBecameActive` and a closed milestone card can land inside it. One call
    /// at a time, or one attempt buys two requests.
    func testSecondActionWhileACallIsInFlightDoesNotStartASecondCall() {
        let repo = RepoFake()
        repo.holdsTheAnswer = true
        repo.pendingGoal = Date(timeIntervalSinceNow: -5 * 3600)
        let middleware = ReviewMiddleware(repo: repo)
        let box = Box()
        let dispatch = recordingDispatch(into: box)

        middleware.handle(action: AppLifecycleAction.appBecameActive,
                          state: AppState(), dispatch: dispatch)
        // The answer has not come back yet — the milestone card closes right now.
        middleware.handle(action: UIAction.streakMilestoneClosed,
                          state: AppState(), dispatch: dispatch)
        XCTAssertEqual(repo.requestCalls, 1, "the second action must not ask again")

        repo.answerNow()

        XCTAssertEqual(repo.promptsShown, 1)
        XCTAssertEqual(promptedTriggers(box), [.nextOpen], "the trigger is the one that asked")
    }

    /// And the launch gate still holds once a call has gone out: the milestone
    /// trigger cannot add a second prompt on top of it.
    func testSecondPromptInTheSameLaunchIsRefusedAfterOneWentOut() {
        let repo = RepoFake()
        let middleware = ReviewMiddleware(repo: repo)
        let box = Box()

        middleware.handle(action: UIAction.streakMilestoneClosed,
                          state: AppState(),
                          dispatch: recordingDispatch(into: box))
        middleware.handle(action: UIAction.streakMilestoneClosed,
                          state: AppState(),
                          dispatch: recordingDispatch(into: box))

        XCTAssertEqual(repo.promptsShown, 1)
        XCTAssertEqual(promptedTriggers(box), [.streakMilestone])
    }
}

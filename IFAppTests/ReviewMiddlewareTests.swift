//
//  ReviewMiddlewareTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class ReviewMiddlewareTests: XCTestCase {

    private final class RepoFake: ReviewRepositoryProtocol {
        var callGoesOut = true
        var promptsShown = 0
        var pendingGoal: Date?
        var clearedPendingGoal = false
        private(set) var requestCalls = 0
        var holdsTheAnswer = false
        private var heldCompletion: ((Bool) -> Void)?

        func canPrompt() -> Bool { true }
        func markPromptShown() { promptsShown += 1 }
        func requestReview(completion: @escaping (Bool) -> Void) {
            requestCalls += 1
            if holdsTheAnswer { heldCompletion = completion } else { completion(callGoesOut) }
        }

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

    func testSecondActionWhileACallIsInFlightDoesNotStartASecondCall() {
        let repo = RepoFake()
        repo.holdsTheAnswer = true
        repo.pendingGoal = Date(timeIntervalSinceNow: -5 * 3600)
        let middleware = ReviewMiddleware(repo: repo)
        let box = Box()
        let dispatch = recordingDispatch(into: box)

        middleware.handle(action: AppLifecycleAction.appBecameActive,
                          state: AppState(), dispatch: dispatch)
        middleware.handle(action: UIAction.streakMilestoneClosed,
                          state: AppState(), dispatch: dispatch)
        XCTAssertEqual(repo.requestCalls, 1, "the second action must not ask again")

        repo.answerNow()

        XCTAssertEqual(repo.promptsShown, 1)
        XCTAssertEqual(promptedTriggers(box), [.nextOpen], "the trigger is the one that asked")
    }

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

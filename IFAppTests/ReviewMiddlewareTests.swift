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
        var gatesOpen = true
        var promptsShown = 0
        private(set) var requestCalls = 0
        var holdsTheAnswer = false
        private var heldCompletion: ((Bool) -> Void)?

        func canPrompt() -> Bool { gatesOpen }
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
    }

    private final class Box { var actions: [Action] = [] }

    private func recordingDispatch(into box: Box) -> DispatchFunction {
        DispatchFunction(dispatchAction: { box.actions.append($0) }, dispatchThunk: { _ in })
    }

    private func promptedTriggers(_ box: Box) -> [ReviewPromptTrigger] {
        box.actions.compactMap {
            if case let AppLifecycleAction.reviewPrompted(trigger) = $0 { return trigger }
            return nil
        }
    }

    private func record(duration: TimeInterval, goalHours: Double = 16,
                        endedAgo: TimeInterval = 0) -> FastRecord {
        let end = Date().timeIntervalSince1970 - endedAgo
        return FastRecord(id: UUID(),
                          startTimestamp: end - duration,
                          endTimestamp: end,
                          goalHours: goalHours,
                          planLabel: Plan(goalHours: goalHours).ratioLabel)
    }

    private func settledState(completed: Int = 2,
                              records: [FastRecord]? = nil) -> AppState {
        var state = AppState()
        state.timerState.completedSessionsCount = completed
        state.timerState.isEating = true
        state.historyState = HistoryState(records: records ?? [
            record(duration: 17 * 3600),
            record(duration: 12 * 3600, endedAgo: 86_400),
        ])
        state.timerState.eatingStartTimestamp = state.historyState.latestRecord?.endTimestamp
            ?? Date().timeIntervalSince1970
        return state
    }

    private func settle(_ middleware: ReviewMiddleware, _ state: AppState, _ box: Box) {
        middleware.handle(action: AppLifecycleAction.eatingWindowSettled,
                          state: state, dispatch: recordingDispatch(into: box))
    }

    // MARK: - The trigger

    func testAQualifiedFastAsksOnceAsFastCompleted() {
        let repo = RepoFake()
        let box = Box()

        settle(ReviewMiddleware(repo: repo), settledState(), box)

        XCTAssertEqual(repo.requestCalls, 1)
        XCTAssertEqual(repo.promptsShown, 1)
        XCTAssertEqual(promptedTriggers(box), [.fastCompleted])
        XCTAssertEqual(ReviewPromptTrigger.fastCompleted.rawValue, "fast_completed")
    }

    func testAFastEndedBeforeItsGoalDoesNotAsk() {
        let repo = RepoFake()
        let box = Box()
        let state = settledState(records: [
            record(duration: 20 * 3600, endedAgo: 86_400),
            record(duration: 10 * 3600),
        ])

        settle(ReviewMiddleware(repo: repo), state, box)

        XCTAssertEqual(repo.requestCalls, 0)
        XCTAssertTrue(promptedTriggers(box).isEmpty)
    }

    func testTheRecordsOwnGoalIsTheBar() {
        let repo = RepoFake()
        let state = settledState(records: [record(duration: 13 * 3600, goalHours: 12)])

        settle(ReviewMiddleware(repo: repo), state, Box())

        XCTAssertEqual(repo.requestCalls, 1)
    }

    func testTheFirstFinishedFastDoesNotAsk() {
        let repo = RepoFake()
        let state = settledState(completed: 1, records: [record(duration: 17 * 3600)])

        settle(ReviewMiddleware(repo: repo), state, Box())

        XCTAssertEqual(repo.requestCalls, 0)
    }

    func testAnEmptyHistoryDoesNotAsk() {
        let repo = RepoFake()

        settle(ReviewMiddleware(repo: repo), settledState(records: []), Box())

        XCTAssertEqual(repo.requestCalls, 0)
    }

    func testTheMiddlewareDoesNotJudgeTheOffer() {
        let repo = RepoFake()
        var state = settledState()
        state.proState.entitlement = .free
        state.proState.product = ProProductInfo(id: ProCatalog.productID, displayPrice: "$6.99")
        state.proState.autoOfferArmed = true
        XCTAssertTrue(state.proState.autoOfferPending, "precondition: the offer reads as owed")

        settle(ReviewMiddleware(repo: repo), state, Box())

        XCTAssertEqual(repo.requestCalls, 1, "one decision-maker: the signal itself means 'ask'")
    }

    func testAFastTooShortToRecordDoesNotBorrowAnOlderOne() {
        let repo = RepoFake()
        var state = settledState()
        state.historyState = HistoryState(records: [record(duration: 17 * 3600, endedAgo: 86_400)])
        state.timerState.eatingStartTimestamp = Date().timeIntervalSince1970

        settle(ReviewMiddleware(repo: repo), state, Box())

        XCTAssertEqual(repo.requestCalls, 0)
    }

    func testAProUserIsAsked() {
        let repo = RepoFake()
        var state = settledState()
        state.proState.entitlement = .pro

        settle(ReviewMiddleware(repo: repo), state, Box())

        XCTAssertEqual(repo.requestCalls, 1)
    }

    func testNoOtherActionAsks() {
        let repo = RepoFake()
        let middleware = ReviewMiddleware(repo: repo)
        let state = settledState()
        let actions: [Action] = [
            UIAction.streakMilestoneClosed,
            AppLifecycleAction.appBecameActive,
            AppLifecycleAction.goalScreenSettled,
            TimerAction.goalCelebrated(dayKey: "2026-11-14", ownsFreeze: false),
            TimerAction.eatingStarted(startTimestamp: Date().timeIntervalSince1970),
        ]

        for action in actions {
            middleware.handle(action: action, state: state, dispatch: recordingDispatch(into: Box()))
        }

        XCTAssertEqual(repo.requestCalls, 0)
    }

    // MARK: - Gates

    func testClosedGatesAskNothing() {
        let repo = RepoFake()
        repo.gatesOpen = false
        let box = Box()

        settle(ReviewMiddleware(repo: repo), settledState(), box)

        XCTAssertEqual(repo.requestCalls, 0)
        XCTAssertTrue(promptedTriggers(box).isEmpty)
    }

    func testNoActiveSceneSpendsNothingAndLogsNothing() {
        let repo = RepoFake()
        repo.callGoesOut = false
        let box = Box()

        settle(ReviewMiddleware(repo: repo), settledState(), box)

        XCTAssertEqual(repo.requestCalls, 1, "the request is still attempted")
        XCTAssertEqual(repo.promptsShown, 0, "no attempt is spent on a call that never went out")
        XCTAssertTrue(promptedTriggers(box).isEmpty, "and the funnel is not told we prompted")
    }

    func testAttemptWithoutASceneDoesNotBlockTheNextOneInTheSameLaunch() {
        let repo = RepoFake()
        repo.callGoesOut = false
        let box = Box()
        let middleware = ReviewMiddleware(repo: repo)

        settle(middleware, settledState(), box)
        repo.callGoesOut = true
        settle(middleware, settledState(), box)

        XCTAssertEqual(repo.requestCalls, 2)
        XCTAssertEqual(repo.promptsShown, 1, "exactly one attempt, spent on the call that went out")
        XCTAssertEqual(promptedTriggers(box), [.fastCompleted])
    }

    func testSecondMomentWhileACallIsInFlightDoesNotStartASecondCall() {
        let repo = RepoFake()
        repo.holdsTheAnswer = true
        let box = Box()
        let middleware = ReviewMiddleware(repo: repo)

        settle(middleware, settledState(), box)
        settle(middleware, settledState(), box)
        XCTAssertEqual(repo.requestCalls, 1, "the second moment must not ask again")

        repo.answerNow()

        XCTAssertEqual(repo.promptsShown, 1)
        XCTAssertEqual(promptedTriggers(box), [.fastCompleted])
    }

    func testSecondPromptInTheSameLaunchIsRefusedAfterOneWentOut() {
        let repo = RepoFake()
        let box = Box()
        let middleware = ReviewMiddleware(repo: repo)

        settle(middleware, settledState(), box)
        settle(middleware, settledState(), box)

        XCTAssertEqual(repo.requestCalls, 1)
        XCTAssertEqual(repo.promptsShown, 1)
        XCTAssertEqual(promptedTriggers(box), [.fastCompleted])
    }
}

final class ReviewRepositoryTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "ReviewRepositoryTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testTheLifetimeCapRefuses() {
        defaults.set(3, forKey: "review_prompt_count")
        XCTAssertFalse(ReviewRepository(defaults: defaults).canPrompt())
    }

    func testOnePromptADay() {
        let repo = ReviewRepository(defaults: defaults)
        XCTAssertTrue(repo.canPrompt())
        repo.markPromptShown()
        XCTAssertFalse(repo.canPrompt())
        XCTAssertEqual(defaults.integer(forKey: "review_prompt_count"), 1)
    }

    func testTheLegacyPendingGoalKeyIsRemovedOnStart() {
        defaults.set(Date(), forKey: "review_pending_goal_at")
        _ = ReviewRepository(defaults: defaults)
        XCTAssertNil(defaults.object(forKey: "review_pending_goal_at"))
    }
}

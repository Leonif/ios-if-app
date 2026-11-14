//
//  AnalyticsTriggerTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class AnalyticsTriggerTests: XCTestCase {

    private final class RepoSpy: AnalyticsRepositoryProtocol {
        var events: [AnalyticsEvent] = []
        func log(_ event: AnalyticsEvent) { events.append(event) }
        func setUserProperty(_ value: String?, forName name: String) {}

        var lastTrigger: String? {
            events.reversed()
                .compactMap { $0.parameters["trigger"] as? String }
                .first
        }
    }

    private let noDispatch = DispatchFunction(dispatchAction: { _ in }, dispatchThunk: { _ in })

    private func send(_ action: Action, state: AppState, to middleware: AnalyticsMiddleware) {
        middleware.handle(action: action, state: state, dispatch: noDispatch)
    }

    func testRestoreFailedWithNoOfferOpenReportsUnknown() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        let state = AppState()
        XCTAssertNil(state.proState.trigger)

        send(ProAction.restoreFailed(.network), state: state, to: middleware)

        XCTAssertEqual(repo.lastTrigger, PaywallTrigger.unknown.rawValue)
        XCTAssertNotEqual(repo.lastTrigger, PaywallTrigger.manual.rawValue)
    }

    func testOfferOpenedFromAPermanentEntryStillReportsManual() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        var state = AppState()
        state.proState.trigger = .manual

        send(ProAction.offerOpened(trigger: .manual), state: state, to: middleware)

        XCTAssertEqual(repo.lastTrigger, PaywallTrigger.manual.rawValue)
    }

    func testTheLockedExportReportsItsOwnDoor() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        var state = AppState()
        state.proState.trigger = .historyExport

        send(ProAction.offerOpened(trigger: .historyExport), state: state, to: middleware)

        XCTAssertEqual(repo.lastTrigger, "history_export")
        XCTAssertNotEqual(repo.lastTrigger, PaywallTrigger.manual.rawValue)
    }

    func testTriggerVocabularyIsFixed() {
        XCTAssertEqual(
            Set([PaywallTrigger.fastFinished, .planCustom, .streakBreak, .manual,
                 .home, .historyExport, .unknown].map(\.rawValue)),
            ["fast_finished", "plan_custom", "streak_break", "manual",
             "home", "history_export", "unknown"]
        )
    }
}

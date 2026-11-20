//
//  AnalyticsTriggerTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class AnalyticsTriggerTests: XCTestCase {

    private final class TrackerSpy: AnalyticsTrackerProtocol {
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
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        let state = AppState()
        XCTAssertNil(state.proState.trigger)

        send(ProAction.restoreFailed(.network), state: state, to: middleware)

        XCTAssertEqual(tracker.lastTrigger, PaywallTrigger.unknown.rawValue)
        XCTAssertNotEqual(tracker.lastTrigger, PaywallTrigger.manual.rawValue)
    }

    func testOfferOpenedFromAPermanentEntryStillReportsManual() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        var state = AppState()
        state.proState.trigger = .manual

        send(ProAction.offerOpened(trigger: .manual), state: state, to: middleware)

        XCTAssertEqual(tracker.lastTrigger, PaywallTrigger.manual.rawValue)
    }

    func testTheLockedExportReportsItsOwnDoor() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        var state = AppState()
        state.proState.trigger = .historyExport

        send(ProAction.offerOpened(trigger: .historyExport), state: state, to: middleware)

        XCTAssertEqual(tracker.lastTrigger, "history_export")
        XCTAssertNotEqual(tracker.lastTrigger, PaywallTrigger.manual.rawValue)
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

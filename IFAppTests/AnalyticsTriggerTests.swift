//
//  AnalyticsTriggerTests.swift
//  IFAppTests
//
//  The `trigger` parameter is the one number 1.5.x is read by: how many people came
//  into the offer through each door, and in particular how the new home-screen door
//  compares with the permanent ones. That comparison is only possible while every
//  value on the parameter means one thing.
//
//  It did not. `manual` was both its own door — the Pro row in About IF24, the locked
//  export in History — and the fallback for "no offer was open, so nobody can say
//  which door this was". A restore run from the About sheet's own button landed on
//  the second reading and was counted as the first, padding the column the new door
//  has to be measured against with events that are not entries at all.
//
//  These two tests are the fix stated as a rule: the fallback is `unknown`, and
//  `manual` still means what it always meant.
//

import XCTest
import Redux
@testable import IFApp

final class AnalyticsTriggerTests: XCTestCase {

    /// Records what reached the gateway. Only the parameters matter here; the events'
    /// own shape is `AnalyticsEventTests`' business.
    private final class RepoSpy: AnalyticsRepositoryProtocol {
        var events: [AnalyticsEvent] = []
        func log(_ event: AnalyticsEvent) { events.append(event) }
        func setUserProperty(_ value: String?, forName name: String) {}

        /// The `trigger` of the last event that carries one.
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

    /// The defect. Restore is offered in two places, and the one in About IF24 is not
    /// behind the offer at all — no `offerOpened` precedes it, so neither the state
    /// nor the middleware's pre-reduce snapshot holds an entry point. A failure there
    /// used to be filed under `manual`.
    func testRestoreFailedWithNoOfferOpenReportsUnknown() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        // No offer has ever been opened in this launch: `trigger` is nil, and it is
        // nil in the previous action's state too, because there was none.
        let state = AppState()
        XCTAssertNil(state.proState.trigger)

        send(ProAction.restoreFailed(.network), state: state, to: middleware)

        XCTAssertEqual(repo.lastTrigger, PaywallTrigger.unknown.rawValue)
        XCTAssertNotEqual(repo.lastTrigger, PaywallTrigger.manual.rawValue)
    }

    /// The other half, and the reason the first one is worth a test: `manual` is not
    /// being retired, it is being given back its own meaning. Opening the offer from
    /// a permanent entry still reports it.
    func testOfferOpenedFromAPermanentEntryStillReportsManual() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        // Post-reduce state, which is what a middleware sees: the reducer has already
        // recorded the door.
        var state = AppState()
        state.proState.trigger = .manual

        send(ProAction.offerOpened(trigger: .manual), state: state, to: middleware)

        XCTAssertEqual(repo.lastTrigger, PaywallTrigger.manual.rawValue)
    }
}

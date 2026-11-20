//
//  SunnahAnalyticsTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class SunnahAnalyticsTests: XCTestCase {

    private final class TrackerSpy: AnalyticsTrackerProtocol {
        var events: [AnalyticsEvent] = []
        func log(_ event: AnalyticsEvent) { events.append(event) }
        func setUserProperty(_ value: String?, forName name: String) {}

        func named(_ name: String) -> [AnalyticsEvent] { events.filter { $0.name == name } }
        func modes(of name: String) -> [String] {
            named(name).compactMap { $0.parameters["mode"] as? String }
        }
    }

    private let noDispatch = DispatchFunction(dispatchAction: { _ in }, dispatchThunk: { _ in })

    private func send(_ action: Action, state: AppState, to middleware: AnalyticsMiddleware) {
        middleware.handle(action: action, state: state, dispatch: noDispatch)
    }

    private var disarmed: AppState {
        var state = AppState()
        state.sunnahState.delivery = .off
        return state
    }

    private func arming(weekly: Bool = true, whiteDays: Bool = false) -> AppState {
        var state = AppState()
        state.sunnahState.settings.weekly = weekly
        state.sunnahState.settings.whiteDays = whiteDays
        state.sunnahState.delivery = .checking
        return state
    }

    private func settled(_ delivery: SunnahState.Delivery,
                         weekly: Bool = true, whiteDays: Bool = false) -> AppState {
        var state = arming(weekly: weekly, whiteDays: whiteDays)
        state.sunnahState.delivery = delivery
        return state
    }

    private func arm(weekly: Bool = true, whiteDays: Bool = false,
                     answer: SunnahState.Delivery = .scheduled,
                     on middleware: AnalyticsMiddleware) {
        send(SunnahAction.refresh, state: disarmed, to: middleware)
        let armed = arming(weekly: weekly, whiteDays: whiteDays)
        send(SunnahAction.settingsChanged(armed.sunnahState.settings), state: armed, to: middleware)
        send(SunnahAction.deliveryUpdated(answer, dates: []),
             state: settled(answer, weekly: weekly, whiteDays: whiteDays), to: middleware)
    }

    // MARK: - sunnah_opened

    func testEachDoorIntoTheScreenReportsItself() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)
        let state = AppState()

        send(AppLifecycleAction.sunnahOpened(source: .planEditor), state: state, to: middleware)
        send(AppLifecycleAction.sunnahOpened(source: .about), state: state, to: middleware)

        XCTAssertEqual(tracker.named("sunnah_opened").compactMap { $0.parameters["source"] as? String },
                       ["plan_editor", "about"])
    }

    // MARK: - sunnah_enabled — the event itself

    func testArmingAScheduleReportsTheModeAndThePermission() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        arm(on: middleware)

        let enabled = tracker.named("sunnah_enabled")
        XCTAssertEqual(enabled.count, 1)
        XCTAssertEqual(enabled.first?.parameters["mode"] as? String, "weekly")
        XCTAssertEqual(enabled.first?.parameters["push_allowed"] as? String, "true")
    }

    func testArmingWithNotificationsRefusedReportsThePermissionAsMissing() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        arm(weekly: false, whiteDays: true, answer: .denied, on: middleware)

        let enabled = tracker.named("sunnah_enabled")
        XCTAssertEqual(enabled.count, 1)
        XCTAssertEqual(enabled.first?.parameters["mode"] as? String, "white_days")
        XCTAssertEqual(enabled.first?.parameters["push_allowed"] as? String, "false")
    }

    func testBothSwitchesReportOneEventInTheCombinedMode() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        arm(weekly: true, whiteDays: true, on: middleware)

        XCTAssertEqual(tracker.modes(of: "sunnah_enabled"), ["both"])
    }

    // MARK: - sunnah_enabled — everything that must stay silent

    func testARefreshOverASettledScheduleIsSilent() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        send(SunnahAction.refresh, state: settled(.scheduled), to: middleware)
        send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
             state: settled(.scheduled), to: middleware)

        XCTAssertTrue(tracker.named("sunnah_enabled").isEmpty)
    }

    func testASecondAnswerToTheSameArmingDoesNotReportTwice() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        arm(on: middleware)
        send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
             state: settled(.scheduled), to: middleware)

        XCTAssertEqual(tracker.named("sunnah_enabled").count, 1)
    }

    func testMovingTheReminderTimeOnAnArmedScheduleReportsNothingNew() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        arm(on: middleware)
        for _ in 0..<3 {
            var moved = arming()
            moved.sunnahState.settings.minuteOfDay += 60
            send(SunnahAction.settingsChanged(moved.sunnahState.settings), state: moved, to: middleware)
            send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
                 state: settled(.scheduled), to: middleware)
        }

        XCTAssertEqual(tracker.named("sunnah_enabled").count, 1)
    }

    func testAddingTheSecondScheduleToARunningOneReportsNothingNew() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        arm(weekly: true, on: middleware)
        let both = arming(weekly: true, whiteDays: true)
        send(SunnahAction.settingsChanged(both.sunnahState.settings), state: both, to: middleware)
        send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
             state: settled(.scheduled, weekly: true, whiteDays: true), to: middleware)

        XCTAssertEqual(tracker.modes(of: "sunnah_enabled"), ["weekly"])
    }

    func testASecondSwitchFlippedBeforeTheAnswerStillReportsOneArming() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        send(SunnahAction.refresh, state: disarmed, to: middleware)
        let first = arming(weekly: true)
        send(SunnahAction.settingsChanged(first.sunnahState.settings), state: first, to: middleware)
        let second = arming(weekly: true, whiteDays: true)
        send(SunnahAction.settingsChanged(second.sunnahState.settings), state: second, to: middleware)
        send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
             state: settled(.scheduled, weekly: true, whiteDays: true), to: middleware)

        XCTAssertEqual(tracker.modes(of: "sunnah_enabled"), ["both"])
    }

    func testSwitchingEverythingOffBeforeTheAnswerCancelsTheArming() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        send(SunnahAction.refresh, state: disarmed, to: middleware)
        let armed = arming()
        send(SunnahAction.settingsChanged(armed.sunnahState.settings), state: armed, to: middleware)
        send(SunnahAction.settingsChanged(SunnahSettings()), state: disarmed, to: middleware)
        send(SunnahAction.deliveryUpdated(.off, dates: []), state: disarmed, to: middleware)

        XCTAssertTrue(tracker.named("sunnah_enabled").isEmpty)
    }

    func testSwitchingOffOneOfTwoSchedulesIsNotAnArming() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        arm(weekly: true, whiteDays: true, on: middleware)
        let halved = arming(weekly: false, whiteDays: true)
        send(SunnahAction.settingsChanged(halved.sunnahState.settings), state: halved, to: middleware)
        send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
             state: settled(.scheduled, weekly: false, whiteDays: true), to: middleware)

        XCTAssertEqual(tracker.modes(of: "sunnah_enabled"), ["both"])
    }

    func testTurningTheRemindersOffReportsNothing() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        arm(on: middleware)
        send(SunnahAction.settingsChanged(SunnahSettings()), state: disarmed, to: middleware)
        send(SunnahAction.deliveryUpdated(.off, dates: []), state: disarmed, to: middleware)

        XCTAssertEqual(tracker.named("sunnah_enabled").count, 1)
    }

    func testReArmingTheSameModeAfterSwitchingOffReportsAgain() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        arm(on: middleware)
        send(SunnahAction.settingsChanged(SunnahSettings()), state: disarmed, to: middleware)
        send(SunnahAction.deliveryUpdated(.off, dates: []), state: disarmed, to: middleware)
        arm(on: middleware)

        XCTAssertEqual(tracker.modes(of: "sunnah_enabled"), ["weekly", "weekly"])
    }

    func testOnlyAnArmedScheduleReachesTheCheckingState() {
        var armed = SunnahSettings()
        armed.weekly = true
        XCTAssertEqual(
            sunnahReducer(state: SunnahState(), action: SunnahAction.settingsChanged(armed)).delivery,
            .checking
        )
        XCTAssertEqual(
            sunnahReducer(state: SunnahState(delivery: .scheduled),
                          action: SunnahAction.settingsChanged(SunnahSettings())).delivery,
            .off
        )
    }

    // MARK: - the mode vocabulary

    func testModeVocabularyIsFixed() {
        func mode(weekly: Bool, whiteDays: Bool) -> String {
            var settings = SunnahSettings()
            settings.weekly = weekly
            settings.whiteDays = whiteDays
            return settings.analyticsMode
        }
        XCTAssertEqual(mode(weekly: true, whiteDays: false), "weekly")
        XCTAssertEqual(mode(weekly: false, whiteDays: true), "white_days")
        XCTAssertEqual(mode(weekly: true, whiteDays: true), "both")
        XCTAssertEqual(mode(weekly: false, whiteDays: false), "off")
        XCTAssertEqual(SunnahEntrySource.planEditor.rawValue, "plan_editor")
        XCTAssertEqual(SunnahEntrySource.about.rawValue, "about")
    }
}

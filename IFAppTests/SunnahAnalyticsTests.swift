//
//  SunnahAnalyticsTests.swift
//  IFAppTests
//
//  The Sunnah screen shipped with no events at all: the release's one free headline
//  feature could not be told apart from a feature nobody opened. Two events close
//  that, and both have a condition that is easy to write and easy to get wrong.
//
//  `sunnah_opened` has to keep its two doors apart — the whole reason the second door
//  was added is the suspicion that the first one is never found.
//
//  `sunnah_enabled` has to fire once per switching-on, and every control on that
//  screen writes through one action: the two toggles and the reminder time all emit
//  `SunnahAction.settingsChanged`, and `deliveryUpdated` is raised by a cold start, a
//  foreground, a day change and a time-zone change as well. So the event hangs off an
//  *edge* — nothing scheduled before the write, something scheduled after it — and
//  that edge exists in exactly one place, the middleware's snapshot of the previous
//  state. These tests are the edge stated as a rule, and half of them are the traps:
//  a time nudged, a second schedule added, one of two switched off. Counted as
//  "a write landed on an enabled schedule" every one of them is a false arming, and
//  GA4 backfills nothing.
//

import XCTest
import Redux
@testable import IFApp

final class SunnahAnalyticsTests: XCTestCase {

    private final class RepoSpy: AnalyticsRepositoryProtocol {
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

    /// Nothing scheduled — the state the app is in before anyone touches the screen,
    /// and the one the reducer resolves a disabled settings blob back to.
    private var disarmed: AppState {
        var state = AppState()
        state.sunnahState.delivery = .off
        return state
    }

    /// The state the reducer leaves behind on a write that arms: settings on, delivery
    /// provisional while the middleware goes and asks.
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

    /// One write over a disarmed state, then its delivery answer — the whole of what
    /// happens when someone flips the first switch. The leading `refresh` is not
    /// decoration: the middleware's snapshot of "how things stood before" is taken
    /// from the previous action it saw, so a test that never sent one would be
    /// asserting against `nil` rather than against a disarmed screen.
    private func arm(weekly: Bool = true, whiteDays: Bool = false,
                     answer: SunnahState.Delivery = .scheduled,
                     on middleware: AnalyticsMiddleware) {
        send(SunnahAction.refresh, state: disarmed, to: middleware)
        let armed = arming(weekly: weekly, whiteDays: whiteDays)
        send(SunnahAction.settingsChanged(armed.sunnahState.settings), state: armed, to: middleware)
        send(SunnahAction.deliveryUpdated(answer, dates: []),
             state: settled(answer, weekly: weekly, whiteDays: whiteDays), to: middleware)
    }

    // MARK: sunnah_opened

    func testEachDoorIntoTheScreenReportsItself() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)
        let state = AppState()

        send(AppLifecycleAction.sunnahOpened(source: .planEditor), state: state, to: middleware)
        send(AppLifecycleAction.sunnahOpened(source: .about), state: state, to: middleware)

        XCTAssertEqual(repo.named("sunnah_opened").compactMap { $0.parameters["source"] as? String },
                       ["plan_editor", "about"])
    }

    // MARK: sunnah_enabled — the event itself

    /// The happy path, and the shape of the parameters: the mode as a fixed code, the
    /// permission as text rather than as a `Bool` that would reach GA4 as a number.
    func testArmingAScheduleReportsTheModeAndThePermission() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        arm(on: middleware)

        let enabled = repo.named("sunnah_enabled")
        XCTAssertEqual(enabled.count, 1)
        XCTAssertEqual(enabled.first?.parameters["mode"] as? String, "weekly")
        XCTAssertEqual(enabled.first?.parameters["push_allowed"] as? String, "true")
    }

    /// The cohort the second parameter exists for: the schedule is on and no reminder
    /// can ever be delivered. Nothing on the event says this is an error, because it
    /// is not one — it is a fact about the permission ask.
    func testArmingWithNotificationsRefusedReportsThePermissionAsMissing() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        arm(weekly: false, whiteDays: true, answer: .denied, on: middleware)

        let enabled = repo.named("sunnah_enabled")
        XCTAssertEqual(enabled.count, 1)
        XCTAssertEqual(enabled.first?.parameters["mode"] as? String, "white_days")
        XCTAssertEqual(enabled.first?.parameters["push_allowed"] as? String, "false")
    }

    /// Both switches flipped before the first answer comes back is one switching-on in
    /// a third mode, not two events.
    func testBothSwitchesReportOneEventInTheCombinedMode() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        arm(weekly: true, whiteDays: true, on: middleware)

        XCTAssertEqual(repo.modes(of: "sunnah_enabled"), ["both"])
    }

    // MARK: sunnah_enabled — everything that must stay silent

    /// A refresh — a cold start, a foreground, a day change, a retry — produces the
    /// same `deliveryUpdated` with nobody having touched anything. Counted there, the
    /// event would report an arming on every launch of every user who ever turned the
    /// feature on.
    func testARefreshOverASettledScheduleIsSilent() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        send(SunnahAction.refresh, state: settled(.scheduled), to: middleware)
        send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
             state: settled(.scheduled), to: middleware)

        XCTAssertTrue(repo.named("sunnah_enabled").isEmpty)
    }

    /// The second answer to one arming — the permission dialog resolves and the
    /// middleware schedules again — is the same arming, not a second one.
    func testASecondAnswerToTheSameArmingDoesNotReportTwice() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        arm(on: middleware)
        send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
             state: settled(.scheduled), to: middleware)

        XCTAssertEqual(repo.named("sunnah_enabled").count, 1)
    }

    /// Moving the reminder time writes through the same action as flipping a switch,
    /// and the control that does it is a wheel that writes once per detent. A schedule
    /// armed once and then nudged by an hour is one arming.
    func testMovingTheReminderTimeOnAnArmedScheduleReportsNothingNew() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        arm(on: middleware)
        for _ in 0..<3 {
            var moved = arming()
            moved.sunnahState.settings.minuteOfDay += 60
            send(SunnahAction.settingsChanged(moved.sunnahState.settings), state: moved, to: middleware)
            send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
                 state: settled(.scheduled), to: middleware)
        }

        XCTAssertEqual(repo.named("sunnah_enabled").count, 1)
    }

    /// Adding a second schedule to one already running is not a switching-on: the
    /// reminders were already on. Read the other way the event would count the same
    /// person once per schedule they ever added.
    func testAddingTheSecondScheduleToARunningOneReportsNothingNew() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        arm(weekly: true, on: middleware)
        let both = arming(weekly: true, whiteDays: true)
        send(SunnahAction.settingsChanged(both.sunnahState.settings), state: both, to: middleware)
        send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
             state: settled(.scheduled, weekly: true, whiteDays: true), to: middleware)

        XCTAssertEqual(repo.modes(of: "sunnah_enabled"), ["weekly"])
    }

    /// The other sign of the same error. The note an arming leaves is spent by the
    /// delivery answer, and the answer can be slow — a scheduling round trip, or the
    /// whole length of the permission dialog, during which nothing is dispatched. A
    /// second switch flipped inside that window writes again; clearing the note there
    /// would swallow the switching-on entirely, and the event would be silent for
    /// exactly the people who turned both schedules on at once.
    func testASecondSwitchFlippedBeforeTheAnswerStillReportsOneArming() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        send(SunnahAction.refresh, state: disarmed, to: middleware)
        let first = arming(weekly: true)
        send(SunnahAction.settingsChanged(first.sunnahState.settings), state: first, to: middleware)
        // No answer yet — the middleware is still reading the permission.
        let second = arming(weekly: true, whiteDays: true)
        send(SunnahAction.settingsChanged(second.sunnahState.settings), state: second, to: middleware)
        send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
             state: settled(.scheduled, weekly: true, whiteDays: true), to: middleware)

        XCTAssertEqual(repo.modes(of: "sunnah_enabled"), ["both"])
    }

    /// ...and switching everything back off inside that same window cancels it: there
    /// is no schedule left for the answer to describe.
    func testSwitchingEverythingOffBeforeTheAnswerCancelsTheArming() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        send(SunnahAction.refresh, state: disarmed, to: middleware)
        let armed = arming()
        send(SunnahAction.settingsChanged(armed.sunnahState.settings), state: armed, to: middleware)
        send(SunnahAction.settingsChanged(SunnahSettings()), state: disarmed, to: middleware)
        send(SunnahAction.deliveryUpdated(.off, dates: []), state: disarmed, to: middleware)

        XCTAssertTrue(repo.named("sunnah_enabled").isEmpty)
    }

    /// The sharpest of the traps. Switching one of two schedules *off* leaves the
    /// settings enabled and writes the same action — read as "a write landed on an
    /// enabled schedule" it reports arming the survivor, so disarming half the feature
    /// would be counted as turning it on.
    func testSwitchingOffOneOfTwoSchedulesIsNotAnArming() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        arm(weekly: true, whiteDays: true, on: middleware)
        let halved = arming(weekly: false, whiteDays: true)
        send(SunnahAction.settingsChanged(halved.sunnahState.settings), state: halved, to: middleware)
        send(SunnahAction.deliveryUpdated(.scheduled, dates: []),
             state: settled(.scheduled, weekly: false, whiteDays: true), to: middleware)

        XCTAssertEqual(repo.modes(of: "sunnah_enabled"), ["both"])
    }

    /// Turning the reminders off is not an arming either — and it does not even reach
    /// the delivery branch, because the reducer resolves a disabled schedule straight
    /// to `.off`.
    func testTurningTheRemindersOffReportsNothing() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        arm(on: middleware)
        send(SunnahAction.settingsChanged(SunnahSettings()), state: disarmed, to: middleware)
        send(SunnahAction.deliveryUpdated(.off, dates: []), state: disarmed, to: middleware)

        XCTAssertEqual(repo.named("sunnah_enabled").count, 1)
    }

    /// ...and switching it back on afterwards is a second switching-on, even in the
    /// same mode. The edge is the fact, not the value.
    func testReArmingTheSameModeAfterSwitchingOffReportsAgain() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        arm(on: middleware)
        send(SunnahAction.settingsChanged(SunnahSettings()), state: disarmed, to: middleware)
        send(SunnahAction.deliveryUpdated(.off, dates: []), state: disarmed, to: middleware)
        arm(on: middleware)

        XCTAssertEqual(repo.modes(of: "sunnah_enabled"), ["weekly", "weekly"])
    }

    /// The reducer's half of the same story, asserted where it lives: a disabled
    /// settings blob never reaches `.checking`, so the delivery branch above is only
    /// ever entered over a schedule that exists.
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

    // MARK: the mode vocabulary

    /// Raw values, guarded like `MealInputMethod`'s: they are a GA4 dimension, and a
    /// rename compiles silently while cutting the report in two.
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

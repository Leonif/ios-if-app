//
//  IntentAnalyticsTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class IntentAnalyticsTests: XCTestCase {
    private final class TrackerSpy: AnalyticsTrackerProtocol {
        var events: [AnalyticsEvent] = []
        func log(_ event: AnalyticsEvent) { events.append(event) }
        func setUserProperty(_ value: String?, forName name: String) {}
    }

    private let noDispatch = DispatchFunction(dispatchAction: { _ in }, dispatchThunk: { _ in })

    func testTapIntentsLogNothing() throws {
        let settings = try XCTUnwrap(URL(string: "app-settings:"))
        let intents: [Action] = [ProAction.purchaseTapped, ProAction.restoreTapped,
                                 HistoryAction.exportTapped, SunnahAction.systemSettingsTapped(url: settings),
                                 TimerAction.startFastTapped, TimerAction.resumeTapped,
                                 TimerAction.resetTapped, TimerAction.startEatingTapped,
                                 TimerAction.continueFastingTapped, TimerAction.goalMomentStarted,
                                 MealAction.chipTapped(.oneHour), MealAction.scrubFeedbackRequested(.step),
                                 MealAction.exactTimeChosen(Date(timeIntervalSince1970: 0)),
                                 MealAction.confirmTapped, MealAction.windowClosedShown,
                                 EndFastAction.openTapped, EndFastAction.chipTapped(.minutesAgo(30)),
                                 EndFastAction.stepTapped(minutes: 5), EndFastAction.confirmTapped]
        for intent in intents {
            let tracker = TrackerSpy()
            AnalyticsMiddleware(tracker: tracker).handle(action: intent, state: AppState(), dispatch: noDispatch)
            XCTAssertTrue(tracker.events.isEmpty, "\(intent)")
        }
    }

    func testReadTheOriginalLogsOnce() {
        let tracker = TrackerSpy()
        let article = SourceArticle.all[3]
        AnalyticsMiddleware(tracker: tracker).handle(
            action: AppLifecycleAction.sourceOriginalOpened(articleID: 3, url: article.url),
            state: AppState(), dispatch: noDispatch)
        XCTAssertEqual(tracker.events.map(\.name), ["source_original_opened"])
    }
}

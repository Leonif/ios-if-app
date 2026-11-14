//
//  AnalyticsEventTests.swift
//  IFAppTests
//

import XCTest
@testable import IFApp

final class AnalyticsEventTests: XCTestCase {
    private static let catalog: [AnalyticsEvent] = [
        .appOpened,
        .fastStarted(goalHours: 16),
        .fastStopped(durationSeconds: 57_600, completed: true, stage: "ketosis", backdatedMinutes: 0),
        .fastStopUndone,
        .goalReached(goalHours: 8),
        .fastReset(elapsedMinutes: 45),
        .eatingWindowStarted,
        .fastChained,
        .timeAdjusted,
        .lastMealLogged(backdated: true, minutesAgo: 7, inputMethod: "ribbon"),
        .sourcesOpened,
        .sourceArticleOpened(articleID: 2),
        .sourceOriginalOpened(articleID: 2),
        .sourceArticleClosed(articleID: 2, reachedEnd: true),
        .sunnahOpened(source: "about"),
        .sunnahEnabled(mode: "white_days", pushAllowed: false),
        .historyOpened(source: "streak_badge"),
        .historyRecordDeleted,
        .historyExported,
        .historyLoadFailed(reason: "decode"),
        .reviewPrompted(trigger: "next_open"),
        .streakMilestone(days: 7),
        .planSelected(plan: "16:8", goalHours: 16),
        .planConfirmed(plan: "custom:17", goalHours: 17),
        .paywallShown(trigger: "manual"),
        .paywallDismissed(trigger: "manual"),
        .purchaseStarted(trigger: "manual", product: "pro"),
        .purchaseCompleted(trigger: "manual", product: "pro"),
        .purchaseFailed(trigger: "manual", reason: "cancelled"),
        .restoreCompleted,
        .themeActive(dark: true),
    ]

    private static let numericOnPurpose: Set<String> = ["duration_seconds"]

    func testEveryBreakdownParameterIsAString() {
        for event in Self.catalog {
            for (key, value) in event.parameters where !Self.numericOnPurpose.contains(key) {
                XCTAssertTrue(
                    value is String,
                    "\(event.name).\(key) is \(type(of: value)), not String — "
                    + "a GA4 custom dimension reads the string field only"
                )
            }
        }
    }

    func testNumbersAreZeroPaddedToASortableWidth() {
        XCTAssertEqual(
            AnalyticsEvent.fastStarted(goalHours: 8).parameters["goal_hours"] as? String, "08"
        )
        XCTAssertEqual(
            AnalyticsEvent.fastStarted(goalHours: 16).parameters["goal_hours"] as? String, "16"
        )
        XCTAssertEqual(
            AnalyticsEvent.planSelected(plan: "16:8", goalHours: 16)
                .parameters["goal_hours"] as? String, "16"
        )
        XCTAssertEqual(
            AnalyticsEvent.fastReset(elapsedMinutes: 45).parameters["elapsed_minutes"] as? String,
            "0045"
        )
        XCTAssertEqual(
            AnalyticsEvent.lastMealLogged(backdated: true, minutesAgo: 7, inputMethod: "ribbon")
                .parameters["minutes_ago"] as? String, "0007"
        )
        XCTAssertEqual(
            AnalyticsEvent.streakMilestone(days: 7).parameters["days"] as? String, "07"
        )
        XCTAssertEqual(
            AnalyticsEvent.sourceArticleOpened(articleID: 3).parameters["article"] as? String,
            "03"
        )
        let stopped = AnalyticsEvent.fastStopped(
            durationSeconds: 57_600, completed: true, stage: "ketosis", backdatedMinutes: 150
        ).parameters
        XCTAssertEqual(stopped["duration_hours"] as? String, "016")
        XCTAssertEqual(stopped["completed"] as? String, "true")
        XCTAssertEqual(stopped["duration_seconds"] as? Int, 57_600)
        XCTAssertEqual(stopped["end_backdated_minutes"] as? String, "0150")
    }

    func testCatalogIsFullyCovered() {
        let names = Self.catalog.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "duplicate sample in the catalog")
        XCTAssertEqual(
            names.count, 31,
            "AnalyticsEvent gained or lost a case — add its sample to `catalog` and "
            + "update this count"
        )
    }
}

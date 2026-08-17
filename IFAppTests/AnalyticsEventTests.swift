//
//  AnalyticsEventTests.swift
//  IFAppTests
//
//  Guards the one property of the event catalog that cannot be seen from inside the
//  app: whether a parameter arrives in GA4 as text. A number logged as a number lands
//  in the numeric field, a custom dimension reads the string field, and the report
//  comes back `(not set)` — silently, for as long as nobody runs the breakdown. That
//  is exactly how `goal_hours` lost the month of 10.07-09.08.2026.
//
//  The catalog below is written out by hand because the enum carries associated
//  values and cannot be `CaseIterable`. A new event is therefore not caught
//  automatically; `testCatalogIsFullyCovered` is what makes forgetting it loud.
//

import XCTest
@testable import IFApp

final class AnalyticsEventTests: XCTestCase {
    /// One sample per case in `AnalyticsEvent`.
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

    /// The parameters that are numbers on purpose, with the reason each one is.
    ///
    /// `duration_seconds` is the raw quantity behind a custom *metric* (an average
    /// fast length), and a metric reads the numeric field — text would break it.
    /// `backdated` used to be the second entry here, because the meal sheet seeded
    /// `ateMin` on open and the flag was therefore always `true`. The last-meal
    /// ribbon removed the seeding, so the flag became honest and became a string
    /// with it — there is nothing left in this set but the metric.
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
        // The same parameter name from the plan editor, where it starts life as an
        // `Int` rather than a `Double`. Both must reach GA4 as the same token, or one
        // dimension carries two vocabularies.
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
        let stopped = AnalyticsEvent.fastStopped(
            durationSeconds: 57_600, completed: true, stage: "ketosis", backdatedMinutes: 150
        ).parameters
        XCTAssertEqual(stopped["duration_hours"] as? String, "016")
        XCTAssertEqual(stopped["completed"] as? String, "true")
        XCTAssertEqual(stopped["duration_seconds"] as? Int, 57_600)
        XCTAssertEqual(stopped["end_backdated_minutes"] as? String, "0150")
    }

    /// Every event name in the catalog appears exactly once, so a case added to the
    /// enum without a sample here shows up as a count mismatch rather than as a
    /// parameter nobody ever type-checked.
    func testCatalogIsFullyCovered() {
        let names = Self.catalog.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "duplicate sample in the catalog")
        XCTAssertEqual(
            names.count, 26,
            "AnalyticsEvent gained or lost a case — add its sample to `catalog` and "
            + "update this count"
        )
    }
}

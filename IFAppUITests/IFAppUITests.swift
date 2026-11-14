//
//  IFAppUITests.swift
//  IFAppUITests
//

import XCTest

final class IFAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFastingClickThrough() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset", "-suppressPushPrompt"]
        app.launch()

        let start = app.buttons["timer.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 15),
                      "Start button should exist on the idle screen")
        attach(app, "1-idle")

        start.tap()

        let endFast = app.buttons["timer.endFast"]
        XCTAssertTrue(endFast.waitForExistence(timeout: 5),
                      "End fast button should appear once a fast is running")
        attach(app, "2-active")

        endFast.tap()

        let reset = app.buttons["timer.reset"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5),
                      "Reset button should appear on the complete screen")
        attach(app, "3-complete")

        reset.tap()

        XCTAssertTrue(start.waitForExistence(timeout: 5),
                      "Start button should return to the idle screen after reset")
        attach(app, "4-idle-again")
    }

    func testEatingOverContinue() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedEatingElapsed", "28920"]
        app.launch()

        let cont = app.buttons["eatingOver.continueFasting"]
        XCTAssertTrue(cont.waitForExistence(timeout: 15),
                      "Continue fasting button should exist on the window-closed screen")
        attach(app, "eating-over")

        cont.tap()

        let endFast = app.buttons["timer.endFast"]
        XCTAssertTrue(endFast.waitForExistence(timeout: 5),
                      "Continue fasting should start a fast (active screen)")
        attach(app, "eating-over-continued")
    }

    func testEatingOverSkip() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedEatingElapsed", "28920"]
        app.launch()

        let skip = app.buttons["eatingOver.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 15),
                      "Skip button should exist on the window-closed screen")
        skip.tap()

        XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout: 5),
                      "Skip should return to the idle screen")
        attach(app, "eating-over-skipped")
    }

    func testEatingOverTimeout() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedEatingElapsed", String(28800 + 25 * 3600)]
        app.launch()

        XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout: 15),
                      "A long-elapsed window should land on idle")
        XCTAssertFalse(app.buttons["eatingOver.continueFasting"].exists,
                       "The window-closed screen should not appear after the 24h timeout")
        attach(app, "eating-over-timeout-idle")
    }

    func testStreakMilestone() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedStreak", "3", "-showStreakMilestone"]
        app.launch()

        let close = app.buttons["streak.milestone.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 15),
                      "Milestone card close button should appear")
        XCTAssertTrue(app.staticTexts["streak.milestone.title"].exists,
                      "Milestone card title should appear")
        attach(app, "streak-milestone")

        close.tap()
        XCTAssertTrue(close.waitForNonExistence(timeout: 3),
                      "Milestone card should close after Keep going")
    }

    func testStreakBadge() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedStreak", "3"]
        app.launch()

        XCTAssertTrue(app.buttons["streak.badge"].waitForExistence(timeout: 15),
                      "Streak badge should render with a seeded streak")
        attach(app, "streak-badge")
    }

    func testHistoryNoEntryWithoutRecords() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset"]
        app.launch()

        XCTAssertTrue(app.buttons["timer.sources"].waitForExistence(timeout: 15),
                      "Timer screen should be up")
        XCTAssertFalse(app.buttons["streak.badge"].exists,
                       "With no records there is no way into the history")
        attach(app, "history-no-entry")
    }

    func testHistoryEntryWithoutStreak() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedHistory", "5"]
        app.launch()

        let entry = app.buttons["streak.badge"]
        XCTAssertTrue(entry.waitForExistence(timeout: 15),
                      "The pill should show with records and no streak")
        attach(app, "streak-badge-zero")
        entry.tap()

        XCTAssertTrue(app.otherElements["history.summary"].waitForExistence(timeout: 5),
                      "The pill should open the history")
    }

    func testHistorySeeded() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedHistory", "7", "-seedStreak", "6", "-seedLastGoalDate", "1"]
        app.launch()

        let entry = app.buttons["streak.badge"]
        XCTAssertTrue(entry.waitForExistence(timeout: 15), "Streak pill should open the history")
        entry.tap()

        XCTAssertTrue(app.otherElements["history.summary"].waitForExistence(timeout: 5),
                      "Summary card should render with seeded records")
        attach(app, "history-week")

        let row = app.otherElements["history.row"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Records should render as rows")
        row.tap()
        attach(app, "history-expanded")

        app.buttons["history.back"].tap()
        XCTAssertTrue(app.buttons["streak.badge"].waitForExistence(timeout: 5),
                      "Back should return to the timer screen")
    }

    func testHistoryEdgeCases() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedHistoryEdge", "-seedStreak", "4", "-seedLastGoalDate", "1"]
        app.launch()

        app.buttons["streak.badge"].tap()
        XCTAssertTrue(app.otherElements["history.summary"].waitForExistence(timeout: 5),
                      "Summary card should render with seeded edge-case records")
        attach(app, "history-edge")
    }

    func testSources() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset"]
        app.launch()

        let sources = app.buttons["timer.sources"]
        XCTAssertTrue(sources.waitForExistence(timeout: 15), "Sources button should exist")
        sources.tap()

        XCTAssertTrue(app.staticTexts["Scientific Sources"].waitForExistence(timeout: 5)
                      || app.scrollViews.firstMatch.waitForExistence(timeout: 5),
                      "Sources screen should open")
        attach(app, "sources")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

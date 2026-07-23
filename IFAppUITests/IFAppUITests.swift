//
//  IFAppUITests.swift
//  IFAppUITests
//
//  Click-through UI test for the fasting flow. Launches with "-uitestReset" for a
//  clean idle state, then drives idle -> active -> end, attaching a screenshot at
//  each state. Run per locale to eyeball localized layout:
//    xcodebuild test -scheme IFAppUITests -testLanguage de -testRegion DE ...
//

import XCTest

final class IFAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// idle -> Start -> active -> End fast -> idle, screenshotting each state.
    func testFastingClickThrough() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset"]
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

        // Ending a fast stages the elapsed time and lands on the "complete" screen.
        let reset = app.buttons["timer.reset"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5),
                      "Reset button should appear on the complete screen")
        attach(app, "3-complete")

        reset.tap()

        XCTAssertTrue(start.waitForExistence(timeout: 5),
                      "Start button should return to the idle screen after reset")
        attach(app, "4-idle-again")
    }

    /// Force-shows the streak milestone card (with a seeded 3-day streak) and closes it.
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

    /// A seeded 3-day streak renders the flame badge on the idle screen.
    func testStreakBadge() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedStreak", "3"]
        app.launch()

        XCTAssertTrue(app.otherElements["streak.badge"].waitForExistence(timeout: 15)
                      || app.staticTexts["streak.badge"].waitForExistence(timeout: 3),
                      "Streak badge should render with a seeded streak")
        attach(app, "streak-badge")
    }

    /// Opens the redesigned Scientific Sources screen and screenshots it.
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

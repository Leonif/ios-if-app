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

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

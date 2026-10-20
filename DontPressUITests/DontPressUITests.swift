import XCTest

/// These tests were written but have NOT been run in this repository's authoring
/// environment (no macOS/Xcode). Run them with the command in README.md.
final class DontPressUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(reset: Bool = true, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMode"] + (reset ? ["-UITestReset"] : []) + extra
        app.launch()
        return app
    }

    private func value(_ app: XCUIApplication, _ id: String) -> String {
        app.descendants(matching: .any)[id].firstMatch.value as? String ?? ""
    }

    func testLaunchShowsAccessibleButtonAndInitialStats() {
        let app = launch()
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        XCTAssertEqual(button.label, "Don't press")
        XCTAssertTrue(button.isHittable)
        XCTAssertEqual(value(app, "currentRun"), "0")
        XCTAssertEqual(value(app, "personalBest"), "0")
        XCTAssertEqual(value(app, "totalPresses"), "0")
        XCTAssertFalse(app.buttons["shareButton"].isEnabled, "nothing to share before the first press")
    }

    func testTapIncrementsAllCountersAndChangesReaction() {
        let app = launch()
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        let before = app.staticTexts["reactionLabel"].label
        button.tap()
        XCTAssertEqual(value(app, "currentRun"), "1")
        XCTAssertEqual(value(app, "personalBest").prefix(1), "1")
        XCTAssertEqual(value(app, "totalPresses"), "1")
        XCTAssertNotEqual(app.staticTexts["reactionLabel"].label, before)
    }

    func testRapidTappingCountsEveryTap() {
        let app = launch()
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<25 { button.tap() }
        XCTAssertEqual(value(app, "currentRun"), "25")
        XCTAssertEqual(value(app, "totalPresses"), "25")
    }

    func testBestAndTotalSurviveRelaunchButRunResets() {
        var app = launch()
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<3 { button.tap() }
        app.terminate()

        app = launch(reset: false)
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(value(app, "currentRun"), "0")
        XCTAssertTrue(value(app, "personalBest").hasPrefix("3"))
        XCTAssertTrue(value(app, "totalPresses").hasPrefix("3"))
    }

    func testBackgroundingDoesNotResetRun() {
        let app = launch()
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap(); button.tap()
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(value(app, "currentRun"), "2")
    }

    func testSharePresentsSystemSheetAndCancelKeepsStats() {
        let app = launch()
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap(); button.tap()

        let share = app.buttons["shareButton"]
        XCTAssertTrue(share.isEnabled)
        share.tap()

        let sheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 10), "system share sheet should appear")

        // Dismiss without sharing (the Close control is localized; fall back to tapping above the sheet).
        let close = app.buttons["Close"]
        if close.exists { close.tap() } else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap() }
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 5))

        XCTAssertEqual(value(app, "currentRun"), "2")
        XCTAssertTrue(value(app, "personalBest").hasPrefix("2"))
        XCTAssertTrue(value(app, "totalPresses").hasPrefix("2"))
    }

    func testHugeNumbersKeepLayoutIntact() {
        let app = launch(extra: ["-UITestSeedBest", "9223372036854775000", "-UITestSeedTotal", "9223372036854775000"])
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        XCTAssertTrue(button.isHittable)
        let frame = app.windows.firstMatch.frame
        for id in ["currentRun", "personalBest", "totalPresses"] {
            let tile = app.descendants(matching: .any)[id].firstMatch
            XCTAssertTrue(tile.exists, id)
            XCTAssertTrue(frame.contains(tile.frame), "\(id) must stay on screen")
        }
        button.tap()
        XCTAssertEqual(value(app, "currentRun"), "1")
    }
}

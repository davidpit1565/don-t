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
        let before = app.staticTexts["reactionLabel"].firstMatch.label
        button.tap()
        XCTAssertEqual(value(app, "currentRun"), "1")
        XCTAssertEqual(value(app, "personalBest").prefix(1), "1")
        XCTAssertEqual(value(app, "totalPresses"), "1")
        XCTAssertNotEqual(app.staticTexts["reactionLabel"].firstMatch.label, before)
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

        // The share sheet is system UI; match its known container or its Close control.
        let sheet = app.otherElements["ActivityListView"]
        let close = app.buttons["Close"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 10) || close.waitForExistence(timeout: 2), "system share sheet should appear")

        // Dismiss without sharing (the Close control is localized; fall back to tapping above the sheet).
        if close.exists { close.tap() } else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap() }
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 5))

        XCTAssertEqual(value(app, "currentRun"), "2")
        XCTAssertTrue(value(app, "personalBest").hasPrefix("2"))
        XCTAssertTrue(value(app, "totalPresses").hasPrefix("2"))
    }

    func testCollectionShowsLockedAndUnlockedStylesAndSelectionSticks() {
        let app = launch(extra: ["-UITestSeedBest", "60", "-UITestSeedTotal", "80"])
        XCTAssertTrue(app.buttons["collectionButton"].waitForExistence(timeout: 5))
        app.buttons["collectionButton"].tap()

        let classic = app.buttons["theme-classic"]
        XCTAssertTrue(classic.waitForExistence(timeout: 5))
        XCTAssertEqual(classic.value as? String, "Selected")
        XCTAssertTrue(app.buttons["theme-cobalt"].isEnabled, "best 60 unlocks Blue Mistake")
        XCTAssertTrue(app.buttons["theme-stealth"].isEnabled, "best 60 unlocks Stealth")
        XCTAssertFalse(app.buttons["theme-gold"].isEnabled, "total 80 keeps Gold locked")
        XCTAssertFalse(app.buttons["theme-radioactive"].isEnabled, "best 60 keeps Radioactive locked")

        app.buttons["theme-cobalt"].tap()
        XCTAssertEqual(app.buttons["theme-cobalt"].value as? String, "Selected")
        app.buttons["collectionDone"].tap()

        // relaunch without reset: the choice persists
        app.terminate()
        let again = launch(reset: false)
        XCTAssertTrue(again.buttons["collectionButton"].waitForExistence(timeout: 5))
        again.buttons["collectionButton"].tap()
        XCTAssertEqual(again.buttons["theme-cobalt"].value as? String, "Selected")
    }

    func testUnlockBannerAppearsOnFirstPress() {
        let app = launch()
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        XCTAssertTrue(app.staticTexts["unlockBanner"].waitForExistence(timeout: 3) || app.otherElements["unlockBanner"].exists)
        XCTAssertEqual(value(app, "currentRun"), "1")
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

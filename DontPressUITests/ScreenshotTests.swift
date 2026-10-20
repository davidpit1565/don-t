import XCTest

/// Captures real simulator screenshots as test attachments (exported by CI).
final class ScreenshotTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "-UITestReset"] + extra
        app.launch()
        return app
    }

    func testCaptureScreens() {
        let app = launch()
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        shot(app, "01-launch")

        for _ in 0..<12 { button.tap() }
        shot(app, "02-run-12")

        for _ in 0..<13 { button.tap() }   // 25th press crosses a milestone
        shot(app, "03-milestone-25")

        app.buttons["shareButton"].tap()
        sleep(3)
        shot(app, "04-share-sheet")
    }

    func testCaptureLargeNumbers() {
        let app = launch(["-UITestSeedBest", "9223372036854775000", "-UITestSeedTotal", "9223372036854775000"])
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 10))
        shot(app, "05-large-numbers")
    }

    func testCaptureAccessibilityTextSize() {
        let app = launch(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"])
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 10))
        app.buttons["pressButton"].tap()
        shot(app, "06-accessibility-xl")
    }
}

import XCTest

/// Captures real simulator screenshots as test attachments (exported by CI).
final class ScreenshotTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func shot(_ app: XCUIApplication, _ name: String) {
        Thread.sleep(forTimeInterval: 0.8)   // let number/banner animations settle
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

        for _ in 0..<10 { button.tap() }
        shot(app, "02a-unlock-10")
        for _ in 0..<2 { button.tap() }
        shot(app, "02-run-12")

        for _ in 0..<13 { button.tap() }   // 25th press crosses a milestone
        shot(app, "03-milestone-25")

        for _ in 0..<15 { button.tap() }   // 40
        shot(app, "03b-run-40")
        for _ in 0..<35 { button.tap() }   // 75
        shot(app, "03c-run-75")
        for _ in 0..<35 { button.tap() }   // 110
        shot(app, "03d-run-110")

        app.buttons["shareButton"].tap()
        sleep(3)
        shot(app, "04-share-sheet")
    }

    func testCaptureCollectionAndThemes() {
        var app = launch(["-UITestSeedBest", "120", "-UITestSeedTotal", "800"])
        XCTAssertTrue(app.buttons["collectionButton"].waitForExistence(timeout: 10))
        app.buttons["collectionButton"].tap()
        XCTAssertTrue(app.buttons["theme-gold"].waitForExistence(timeout: 5))
        shot(app, "09-collection")
        app.buttons["theme-radioactive"].tap()      // locked at best 120: opens the Pro offer
        XCTAssertTrue(app.buttons["proRestore"].waitForExistence(timeout: 5))
        shot(app, "12-pro-offer")
        app.buttons["proClose"].tap()
        XCTAssertTrue(app.buttons["theme-gold"].waitForExistence(timeout: 5))
        app.buttons["theme-gold"].tap()
        app.buttons["collectionDone"].tap()
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 5))
        app.buttons["pressButton"].tap()
        shot(app, "10-theme-gold")

        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["-UITestMode"]
        app.launch()
        app.buttons["collectionButton"].tap()
        app.buttons["theme-cobalt"].tap()
        app.buttons["collectionDone"].tap()
        for _ in 0..<5 { app.buttons["pressButton"].tap() }
        shot(app, "11-theme-cobalt")
    }

    /// Real Pro offer with the product loaded from DontPress.storekit (price visible).
    func testCaptureProOfferWithPrice() {
        let app = launch(["-UITestSeedBest", "5", "-UITestSeedTotal", "5"])
        XCTAssertTrue(app.buttons["collectionButton"].waitForExistence(timeout: 10))
        app.buttons["collectionButton"].tap()
        XCTAssertTrue(app.buttons["theme-gold"].waitForExistence(timeout: 5))
        app.buttons["theme-gold"].tap()                    // locked: opens the Pro offer
        let buy = app.buttons["proBuy"]
        XCTAssertTrue(buy.waitForExistence(timeout: 5))
        let loaded = NSPredicate(format: "label CONTAINS 'Unlock Pro'")
        expectation(for: loaded, evaluatedWith: buy)
        waitForExpectations(timeout: 20)                   // fails if StoreKit never supplies a price
        shot(app, "iap-review")
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

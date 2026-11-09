import XCTest

/// Captures real simulator screenshots as test attachments (exported by CI).
final class ScreenshotTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func shot(_ app: XCUIApplication, _ name: String, settle: TimeInterval = 0.8) {
        Thread.sleep(forTimeInterval: settle)   // let number/banner animations settle
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

    /// The main screen must fit on one screen without scrolling (any iPhone size).
    func testEverythingFitsOnOneScreen() {
        let app = launch(["-UITestSeedBest", "1234", "-UITestSeedTotal", "98765"])
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 10))
        for _ in 0..<3 { app.buttons["pressButton"].tap() }
        XCTAssertEqual(app.scrollViews.count, 0, "no ScrollView: nothing may need scrolling")
        let window = app.windows.firstMatch.frame
        for id in ["collectionButton", "pressButton", "currentRun", "personalBest", "totalPresses", "shareButton", "privacyLink", "supportLink"] {
            let element = app.descendants(matching: .any)[id].firstMatch
            XCTAssertTrue(element.exists, id)
            XCTAssertTrue(window.contains(element.frame), "\(id) must be fully on screen: \(element.frame) vs \(window)")
        }
        let button = app.buttons["pressButton"].frame
        XCTAssertGreaterThanOrEqual(button.width, 140, "button must stay large")
        shot(app, "fit")
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

    // MARK: - 1.1 captures (toys, set-pieces, daily, Reactiondex, collection)

    /// Any element by accessibility identifier, whatever its type (rows combine their children).
    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func value(of element: XCUIElement) -> String {
        (element.value as? String) ?? ""
    }

    /// Waits for `element`'s label to satisfy `predicate`, polling briefly. Never fails the test.
    @discardableResult
    private func waitForLabel(_ element: XCUIElement, timeout: TimeInterval, _ predicate: (String) -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists, predicate(element.label) { return true }
            Thread.sleep(forTimeInterval: 0.15)
        } while Date() < deadline
        return false
    }

    /// Swipes the Collection list up (gently) until `target` is hittable. Returns whether it is.
    @discardableResult
    private func scrollTo(_ target: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) -> Bool {
        var swipes = 0
        while !(target.exists && target.isHittable) && swipes < maxSwipes {
            app.swipeUp(velocity: .slow)
            swipes += 1
        }
        return target.exists && target.isHittable
    }

    private func openCollection(_ app: XCUIApplication) {
        let collection = app.buttons["collectionButton"]
        XCTAssertTrue(collection.waitForExistence(timeout: 10))
        collection.tap()
        _ = app.buttons["collectionDone"].waitForExistence(timeout: 5)
    }

    func testCaptureV11Egg() {
        let app = launch(["-UITestPro"])
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 10))
        let picker = app.buttons["toyPicker.egg"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        let egg = element(app, "eggToy")
        XCTAssertTrue(egg.waitForExistence(timeout: 5))

        // Hatching takes 5...9 taps, so 4 taps always leaves a cracked, unhatched egg.
        for _ in 0..<4 { egg.tap() }
        shot(app, "v11-egg-crack")

        // Tap until it hatches; stop on the hatching tap (another tap would start a new egg).
        var taps = 0
        while !value(of: egg).hasPrefix("Hatched") && taps < 12 {
            egg.tap()
            taps += 1
        }
        let reaction = element(app, "reactionLabel")
        waitForLabel(reaction, timeout: 3) { $0.localizedCaseInsensitiveContains("hatched") }
        shot(app, "v11-egg-hatch")   // the creature stays up for ~4 s
    }

    func testCaptureV11Pinata() {
        let app = launch(["-UITestPro", "-UITestSeedTotal", "5000"])
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 10))
        let picker = app.buttons["toyPicker.pinata"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        let pinata = element(app, "pinataToy")
        XCTAssertTrue(pinata.waitForExistence(timeout: 5))

        // It bursts after 12...25 hits; 4 hits always leave it swinging.
        for _ in 0..<4 { pinata.tap() }
        shot(app, "v11-pinata")

        var taps = 0
        while !value(of: pinata).hasPrefix("Burst") && taps < 26 {
            pinata.tap()
            taps += 1
        }
        shot(app, "v11-pinata-burst")   // the prize stays up for ~3.5 s
    }

    func testCaptureV11Balloon() {
        let app = launch(["-UITestPro"])
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 10))
        let picker = app.buttons["toyPicker.balloon"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        let balloon = element(app, "balloonToy")
        XCTAssertTrue(balloon.waitForExistence(timeout: 5))

        // Popping takes 6...14 taps, so 5 taps always leaves it inflated (~67%).
        for _ in 0..<5 { balloon.tap() }
        shot(app, "v11-balloon")

        var taps = 0
        while value(of: balloon) != "Popped" && taps < 14 {
            balloon.tap()
            taps += 1
        }
        shot(app, "v11-balloon-pop", settle: 0.3)   // the pop clears itself after ~2.5 s
    }

    func testCaptureV11SetPieces() {
        let app = launch()
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        // 25: "The Getaway". Its caption runs for ~2.6 s; the last line lands at ~1.15 s.
        for _ in 0..<25 { button.tap() }
        let caption = element(app, "setPieceCaption")
        if caption.waitForExistence(timeout: 3) {
            waitForLabel(caption, timeout: 1.5) { $0.contains("nowhere") }
            shot(app, "v11-setpiece-25", settle: 0.2)
        } else {
            // Timing on slow CI hosts: keep the frame for inspection rather than failing the suite.
            shot(app, "v11-setpiece-25", settle: 0)
        }
        Thread.sleep(forTimeInterval: 2.0)   // let the getaway finish before the next milestone

        // 50: "Lockdown". The lock card is up for ~2.4 s.
        for _ in 0..<25 { button.tap() }
        let lockCard = element(app, "setPieceLockCard")
        if lockCard.waitForExistence(timeout: 3) {
            shot(app, "v11-setpiece-50-lock", settle: 0.4)
        } else {
            shot(app, "v11-setpiece-50-lock", settle: 0)
        }
    }

    func testCaptureV11DailyAndReactiondex() {
        let app = launch()
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        // Seed: some daily progress and a few dozen discovered reaction lines.
        for _ in 0..<40 { button.tap() }
        Thread.sleep(forTimeInterval: 1.5)   // let the 25 set-piece and banners clear

        openCollection(app)
        let daily = element(app, "dailyRow")
        XCTAssertTrue(daily.waitForExistence(timeout: 5))
        daily.tap()
        _ = element(app, "dailyTitle").waitForExistence(timeout: 5)
        shot(app, "v11-daily")
        if app.buttons["dailyDone"].waitForExistence(timeout: 3) { app.buttons["dailyDone"].tap() }

        let dexRow = element(app, "reactiondexRow")
        _ = dexRow.waitForExistence(timeout: 2)
        scrollTo(dexRow, in: app)   // last sections of a List are created lazily
        XCTAssertTrue(dexRow.waitForExistence(timeout: 5))
        dexRow.tap()
        _ = element(app, "reactiondexMeter").waitForExistence(timeout: 5)
        shot(app, "v11-reactiondex")
    }

    func testCaptureV11Collection() {
        let app = launch(["-UITestSeedBest", "120", "-UITestSeedTotal", "800"])
        openCollection(app)
        XCTAssertTrue(app.buttons["collectionDone"].exists)
        // Bring the app-icon section into view when it is below the fold; fine if it is not found.
        let icon = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'appIcon-'")).firstMatch
        scrollTo(icon, in: app, maxSwipes: 3)
        shot(app, "v11-collection")
    }
}


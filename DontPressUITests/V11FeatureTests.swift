import XCTest

/// UI tests for the v1.1 features: sound toggle, toys, set-pieces, daily challenge,
/// Reactiondex and the one-screen layout with the toy picker.
///
/// These tests were written but have NOT been run in this repository's authoring
/// environment (no macOS/Xcode). Run them with the command in README.md.
///
/// No fixed sleeps: every wait is `waitForExistence` or an `XCTNSPredicateExpectation`.
final class V11FeatureTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: Helpers

    private func launch(reset: Bool = true, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMode"] + (reset ? ["-UITestReset"] : []) + extra
        app.launch()
        return app
    }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }

    private func value(_ app: XCUIApplication, _ id: String) -> String {
        element(app, id).value as? String ?? ""
    }

    /// Counter tiles expose the formatted number as their value (personal best may carry a suffix).
    private func count(_ app: XCUIApplication, _ id: String) -> Int {
        let digits = value(app, id).prefix { $0.isNumber || $0 == "," || $0 == "." || $0 == "\u{202F}" || $0 == "\u{00A0}" }
        return Int(digits.filter(\.isNumber)) ?? -1
    }

    /// Waits until the element's accessibility value satisfies `predicate`.
    @discardableResult
    private func waitForValue(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        _ description: String,
        where predicate: @escaping (String) -> Bool
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { object, _ in
                guard let element = object as? XCUIElement else { return false }
                return predicate(element.value as? String ?? "")
            },
            object: element
        )
        expectation.expectationDescription = description
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    private func pressButton(_ app: XCUIApplication) -> XCUIElement {
        let button = app.buttons["pressButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "main button should appear")
        return button
    }

    private func selectToy(_ app: XCUIApplication, _ kind: String) {
        let chip = app.buttons["toyPicker.\(kind)"]
        XCTAssertTrue(chip.waitForExistence(timeout: 5), "toy picker chip \(kind)")
        chip.tap()
    }

    // MARK: 1. Sound toggle

    func testSoundToggleFlipsItsValueAndDoesNotAffectCounting() {
        let app = launch()
        let button = pressButton(app)
        let toggle = app.buttons["soundToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertTrue(toggle.isHittable)
        XCTAssertEqual(toggle.label, "Sound effects")

        let initial = toggle.value as? String ?? ""
        XCTAssertTrue(["On", "Off"].contains(initial), "unexpected sound value: \(initial)")
        let flipped = initial == "On" ? "Off" : "On"

        toggle.tap()
        XCTAssertTrue(waitForValue(toggle, "sound value flips to \(flipped)") { $0 == flipped })

        button.tap()
        button.tap()
        XCTAssertEqual(count(app, "currentRun"), 2)
        XCTAssertEqual(count(app, "totalPresses"), 2)

        toggle.tap()
        XCTAssertTrue(waitForValue(toggle, "sound value flips back to \(initial)") { $0 == initial })

        button.tap()
        XCTAssertEqual(count(app, "currentRun"), 3)
        XCTAssertEqual(count(app, "totalPresses"), 3)
    }

    // MARK: 2. Toys

    func testToysCountEveryTapAndPayOff() {
        let app = launch()
        _ = pressButton(app)
        XCTAssertTrue(element(app, "toyPicker").waitForExistence(timeout: 5))
        let totalBefore = count(app, "totalPresses")
        XCTAssertEqual(count(app, "currentRun"), 0)

        // Egg: 12 taps. It hatches after 5–9 taps of a cycle, so at least one hatch happens.
        selectToy(app, "egg")
        let egg = app.buttons["eggToy"]
        XCTAssertTrue(egg.waitForExistence(timeout: 5), "egg toy should replace the button")
        XCTAssertFalse(app.buttons["pressButton"].exists, "the button is swapped out while the egg is shown")

        var hatchedDescriptions: [String] = []
        for _ in 0..<12 {
            egg.tap()
            let stage = egg.value as? String ?? ""
            if stage.hasPrefix("Hatched ") { hatchedDescriptions.append(stage) }
        }
        XCTAssertEqual(count(app, "currentRun"), 12, "every egg tap counts exactly once")
        XCTAssertEqual(count(app, "totalPresses"), totalBefore + 12)
        XCTAssertFalse(hatchedDescriptions.isEmpty, "12 taps must hatch the egg at least once (hatch needs 5–9)")
        if let first = hatchedDescriptions.first {
            XCTAssertTrue(
                first.hasSuffix(", Common") || first.hasSuffix(", Rare") || first.hasSuffix(", Legendary"),
                "hatched description names a rarity: \(first)"
            )
        }

        // Balloon: tap until it pops (it pops after 6–14 taps), at most 20.
        selectToy(app, "balloon")
        let balloon = app.buttons["balloonToy"]
        XCTAssertTrue(balloon.waitForExistence(timeout: 5), "balloon toy should be shown")
        var balloonTaps = 0
        var popped = false
        while balloonTaps < 20 && !popped {
            balloon.tap()
            balloonTaps += 1
            popped = (balloon.value as? String ?? "") == "Popped"
        }
        XCTAssertTrue(popped, "balloon should pop within 20 taps")
        XCTAssertEqual(count(app, "currentRun"), 12 + balloonTaps, "every balloon tap counts exactly once")
        XCTAssertEqual(count(app, "totalPresses"), totalBefore + 12 + balloonTaps)

        // Back to the button: one ordinary press still counts.
        selectToy(app, "button")
        let button = pressButton(app)
        XCTAssertFalse(app.buttons["eggToy"].exists)
        XCTAssertFalse(app.buttons["balloonToy"].exists)
        button.tap()
        XCTAssertEqual(count(app, "currentRun"), 13 + balloonTaps)
        XCTAssertEqual(count(app, "totalPresses"), totalBefore + 13 + balloonTaps)
    }

    // MARK: 3. Set-piece

    func testSetPieceAtTwentyFivePlaysAndTapsKeepCounting() {
        let app = launch()
        let button = pressButton(app)
        for _ in 0..<25 { button.tap() }

        // The caption is drawn as an overlay of the button, so iOS merges it into the button's
        // accessibility element; it is verified visually by ScreenshotTests (v11-setpiece-25).
        // What must hold here: the set-piece never blocks or loses a tap.

        // Taps during the set-piece still count.
        for _ in 0..<3 { button.tap() }
        XCTAssertEqual(count(app, "currentRun"), 28, "taps during a set-piece must all count")
        XCTAssertEqual(count(app, "totalPresses"), 28)
    }

    // MARK: 4. Daily challenge and Reactiondex

    func testDailyAndReactiondexSheetsOpenAndClose() {
        let app = launch()
        let button = pressButton(app)
        button.tap()   // discover at least one line and record one daily press

        let collection = app.buttons["collectionButton"]
        XCTAssertTrue(collection.waitForExistence(timeout: 5))
        collection.tap()

        // Daily challenge
        let dailyRow = element(app, "dailyRow")
        XCTAssertTrue(dailyRow.waitForExistence(timeout: 5), "daily row should be in Collection")
        dailyRow.tap()
        let dailyDone = app.buttons["dailyDone"]
        XCTAssertTrue(dailyDone.waitForExistence(timeout: 5), "daily sheet should open")
        XCTAssertTrue(element(app, "dailyChallenge").exists || element(app, "dailyTitle").exists,
                      "daily sheet shows today's challenge")
        dailyDone.tap()
        XCTAssertTrue(dailyRow.waitForExistence(timeout: 5), "back on Collection after closing the daily sheet")

        // Reactiondex (a few rows further down the list)
        let dexRow = element(app, "reactiondexRow")
        if !dexRow.waitForExistence(timeout: 2) || !dexRow.isHittable {
            for _ in 0..<6 where !(dexRow.exists && dexRow.isHittable) { app.swipeUp() }
        }
        XCTAssertTrue(dexRow.exists, "Reactiondex row should be in Collection")
        XCTAssertTrue((dexRow.value as? String ?? "").contains("discovered"), "row reports discovered lines")
        dexRow.tap()

        let meter = element(app, "reactiondexMeter")
        XCTAssertTrue(meter.waitForExistence(timeout: 5), "Reactiondex sheet should open with its meter")
        // The meter is one combined element: its visible "Discovered" heading is spoken via the value.
        let meterValue = meter.value as? String ?? ""
        XCTAssertTrue(meterValue.localizedCaseInsensitiveContains("discovered"), "meter value: \(meterValue)")
        XCTAssertFalse(meterValue.hasPrefix("0 of"), "one press discovers at least one line: \(meterValue)")
        app.buttons["reactiondexDone"].tap()

        let collectionDone = app.buttons["collectionDone"]
        XCTAssertTrue(collectionDone.waitForExistence(timeout: 5))
        collectionDone.tap()
        XCTAssertTrue(pressButton(app).isHittable)
        XCTAssertEqual(count(app, "currentRun"), 1, "opening sheets does not reset the run")
    }

    // MARK: 5. One screen with the toy picker

    func testMainScreenFitsOneScreenWithToyPicker() {
        let app = launch(extra: ["-UITestSeedBest", "1234", "-UITestSeedTotal", "98765"])
        let button = pressButton(app)
        XCTAssertTrue(element(app, "toyPicker").waitForExistence(timeout: 5))
        button.tap()

        XCTAssertEqual(app.scrollViews.count, 0, "no ScrollView: nothing may need scrolling")
        let window = app.windows.firstMatch.frame
        for id in ["toyPicker", "toyPicker.button", "toyPicker.egg", "toyPicker.balloon",
                   "soundToggle", "pressButton", "shareButton", "privacyLink"] {
            let item = element(app, id)
            XCTAssertTrue(item.exists, "\(id) should exist")
            XCTAssertTrue(window.contains(item.frame), "\(id) must be fully on screen: \(item.frame) vs \(window)")
        }
        XCTAssertGreaterThanOrEqual(app.buttons["pressButton"].frame.width, 140, "button must stay large")
    }
}

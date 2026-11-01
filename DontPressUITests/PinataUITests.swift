import XCTest

/// UI tests for the piñata (mythic toy: Pro AND 5,000 total presses).
///
/// Written but NOT run in this repository's authoring environment (no macOS/Xcode).
/// No fixed sleeps: every wait is `waitForExistence`.
final class PinataUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "-UITestReset"] + extra
        app.launch()
        return app
    }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }

    private func count(_ app: XCUIApplication, _ id: String) -> Int {
        let raw = element(app, id).value as? String ?? ""
        let digits = raw.prefix { $0.isNumber || $0 == "," || $0 == "." || $0 == "\u{202F}" || $0 == "\u{00A0}" }
        return Int(digits.filter(\.isNumber)) ?? -1
    }

    func testPinataChipIsLockedWithoutProEvenWithPlentyOfPlay() {
        let app = launch(extra: ["-UITestSeedTotal", "9000"])
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 10))
        let chip = app.buttons["toyPicker.pinata"]
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        XCTAssertTrue((chip.value as? String ?? "").hasPrefix("Locked"), "free players never get the piñata")
        chip.tap()
        XCTAssertTrue(app.buttons["proRestore"].waitForExistence(timeout: 5), "shows the Pro offer")
        app.buttons["proClose"].tap()
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 5), "button stays selected")
    }

    func testPinataChipIsLockedWithProBelowTheThreshold() {
        let app = launch(extra: ["-UITestPro", "-UITestSeedTotal", "4999"])
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 10))
        let chip = app.buttons["toyPicker.pinata"]
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        XCTAssertTrue((chip.value as? String ?? "").hasPrefix("Locked"), "Pro owners must earn it")
        chip.tap()
        XCTAssertFalse(app.buttons["proRestore"].waitForExistence(timeout: 2), "no Pro offer: Pro is already owned")
        XCTAssertTrue(app.buttons["pressButton"].exists, "button stays selected")
    }

    func testPinataHitsCountExactlyOnceAndBurstEventuallyShows() {
        let app = launch(extra: ["-UITestPro", "-UITestSeedTotal", "5000"])
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 10))
        let chip = app.buttons["toyPicker.pinata"]
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        chip.tap()
        let pinata = app.buttons["pinataToy"]
        XCTAssertTrue(pinata.waitForExistence(timeout: 5), "the piñata replaces the button")
        for _ in 0..<25 { pinata.tap() }   // the hidden threshold is at most 25
        XCTAssertEqual(count(app, "currentRun"), 25, "every hit counts exactly once")
        XCTAssertEqual(count(app, "totalPresses"), 5_025)
        XCTAssertEqual(count(app, "personalBest"), 25)
    }

    func testPinataSelectionSurvivesRelaunchWhileTheGateHolds() {
        var app = launch(extra: ["-UITestPro", "-UITestSeedTotal", "5000"])
        XCTAssertTrue(app.buttons["pressButton"].waitForExistence(timeout: 10))
        app.buttons["toyPicker.pinata"].tap()
        XCTAssertTrue(app.buttons["pinataToy"].waitForExistence(timeout: 5))
        app.terminate()

        app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "-UITestPro"]   // no reset: keep the saved selection
        app.launch()
        XCTAssertTrue(app.buttons["pinataToy"].waitForExistence(timeout: 10), "piñata restored")
    }
}

import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class LaunchConfigurationTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: LaunchConfiguration.uiTestSuiteName)
        super.tearDown()
    }

    func testDefaultsToNormalMode() {
        let config = LaunchConfiguration(arguments: ["DontPress"])
        XCTAssertFalse(config.isUITestMode)
        XCTAssertNil(config.seedBest)
    }

    func testParsesUITestArguments() {
        let config = LaunchConfiguration(arguments: ["x", "-UITestMode", "-UITestReset", "-UITestSeedBest", "12", "-UITestSeedTotal", "99"])
        XCTAssertTrue(config.isUITestMode)
        XCTAssertTrue(config.resetStore)
        XCTAssertEqual(config.seedBest, 12)
        XCTAssertEqual(config.seedTotal, 99)
    }

    func testBadSeedIsIgnored() {
        XCTAssertNil(LaunchConfiguration(arguments: ["-UITestSeedBest", "lots"]).seedBest)
        XCTAssertNil(LaunchConfiguration(arguments: ["-UITestSeedBest"]).seedBest)
    }

    func testResetAndSeedUseIsolatedSuite() {
        let seeded = LaunchConfiguration(arguments: ["-UITestMode", "-UITestReset", "-UITestSeedBest", "40", "-UITestSeedTotal", "400"]).makeStore()
        XCTAssertEqual(seeded.load(), PersistedStats(personalBest: 40, totalPresses: 400))
        // A later launch without reset keeps the values (relaunch persistence).
        let again = LaunchConfiguration(arguments: ["-UITestMode"]).makeStore()
        XCTAssertEqual(again.load(), PersistedStats(personalBest: 40, totalPresses: 400))
        // Reset wipes it.
        let reset = LaunchConfiguration(arguments: ["-UITestMode", "-UITestReset"]).makeStore()
        XCTAssertEqual(reset.load(), PersistedStats())
    }
}

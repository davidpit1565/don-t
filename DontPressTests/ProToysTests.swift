import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

/// Pro gates the Egg and the Balloon; the big button is always free.
final class ProToysTests: XCTestCase {
    func testOnlyTheButtonIsFree() {
        XCTAssertFalse(ToyKind.button.requiresPro)
        XCTAssertTrue(ToyKind.egg.requiresPro)
        XCTAssertTrue(ToyKind.balloon.requiresPro)
    }

    func testProToysCannotBeSelectedWithoutPro() {
        MainActor.assumeIsolated {
            let model = HomeViewModel(service: PressService(store: InMemoryStatsStore()))
            XCTAssertFalse(model.selectToy(.egg))
            XCTAssertFalse(model.selectToy(.balloon))
            XCTAssertEqual(model.toys.selectedKind, .button)
            XCTAssertTrue(model.selectToy(.button))
        }
    }

    func testProUnlocksToysAndLosingProFallsBackToTheButton() {
        MainActor.assumeIsolated {
            let store = InMemoryStatsStore()
            let model = HomeViewModel(service: PressService(store: store))
            model.setPro(true)
            XCTAssertTrue(model.selectToy(.balloon))
            XCTAssertEqual(model.toys.selectedKind, .balloon)
            model.setPro(false)   // refund / revoked
            XCTAssertEqual(model.toys.selectedKind, .button)
            XCTAssertEqual(store.loadSelectedToyID(), "button")
        }
    }

    func testSavedProToyWithoutProStartsOnTheButton() {
        MainActor.assumeIsolated {
            let store = InMemoryStatsStore()
            store.saveSelectedToyID("egg")
            let model = HomeViewModel(service: PressService(store: store))
            XCTAssertEqual(model.toys.selectedKind, .button)
        }
    }

    func testUITestProFlagIsDebugOnlyAndNeedsUITestMode() {
        XCTAssertFalse(LaunchConfiguration(arguments: ["-UITestPro"]).forcePro, "needs -UITestMode")
        let config = LaunchConfiguration(arguments: ["-UITestMode", "-UITestReset", "-UITestPro"])
        XCTAssertTrue(config.forcePro)
        XCTAssertTrue(config.makeStore().loadIsPro())
        UserDefaults.standard.removePersistentDomain(forName: LaunchConfiguration.uiTestSuiteName)
    }
}

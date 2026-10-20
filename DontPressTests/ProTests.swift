import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class ProTests: XCTestCase {
    private let fresh = PressStats()

    func testProUnlocksEveryStyleWithoutAnyPlay() {
        for theme in ButtonTheme.all { XCTAssertTrue(theme.isUnlocked(for: fresh, isPro: true)) }
        XCTAssertEqual(ButtonTheme.all.filter { $0.isUnlocked(for: fresh, isPro: false) }, [.classic])
    }

    func testResolveHonoursProChoice() {
        XCTAssertEqual(ButtonTheme.resolve(id: "gold", stats: fresh, isPro: true), .gold)
        XCTAssertEqual(ButtonTheme.resolve(id: "gold", stats: fresh, isPro: false), .classic)
    }

    func testEntitlementCachePersistsAndBadTypesReadFalse() {
        let defaults = makeIsolatedDefaults(self)
        let store = UserDefaultsStatsStore(defaults: defaults)
        XCTAssertFalse(store.loadIsPro())
        store.saveIsPro(true)
        XCTAssertTrue(UserDefaultsStatsStore(defaults: defaults).loadIsPro())
        defaults.set("yes please", forKey: UserDefaultsStatsStore.proKey)
        XCTAssertFalse(store.loadIsPro())
    }

    func testViewModelProUnlocksSelectsAndPersists() {
        MainActor.assumeIsolated {
            let store = InMemoryStatsStore()
            let model = HomeViewModel(service: PressService(store: store))
            model.selectTheme(.gold)
            XCTAssertEqual(model.selectedTheme, .classic, "locked before Pro")
            model.setPro(true)
            XCTAssertTrue(model.themeStatuses.allSatisfy(\.isUnlocked))
            model.selectTheme(.gold)
            XCTAssertEqual(model.selectedTheme, .gold)

            let relaunched = HomeViewModel(service: PressService(store: store))
            XCTAssertTrue(relaunched.isPro)
            XCTAssertEqual(relaunched.selectedTheme, .gold)
        }
    }

    func testRefundOrExpiredEntitlementFallsBackToClassic() {
        MainActor.assumeIsolated {
            let store = InMemoryStatsStore()
            let model = HomeViewModel(service: PressService(store: store))
            model.setPro(true)
            model.selectTheme(.radioactive)
            model.setPro(false)
            XCTAssertEqual(model.selectedTheme, .classic)
            XCTAssertEqual(store.loadThemeID(), "classic")
            XCTAssertFalse(HomeViewModel(service: PressService(store: store)).isPro)
        }
    }

    func testProDoesNotChangeCountingAndSuppressesStyleBanner() {
        MainActor.assumeIsolated {
            let store = InMemoryStatsStore(PersistedStats(personalBest: 9, totalPresses: 9))
            let model = HomeViewModel(service: PressService(store: store), reactions: ReactionEngine(random: scripted([50, 0, 1])))
            model.setPro(true)
            for _ in 0..<10 { model.press() }
            XCTAssertEqual(model.stats, PressStats(currentRun: 10, personalBest: 10, totalPresses: 19))
            XCTAssertTrue(model.unlockMessage?.contains("Double Digits") == true, "achievements still unlock")
            XCTAssertFalse(model.unlockMessage?.contains("button style") == true, "styles are already unlocked by Pro")
        }
    }

    func testSettingTheSameProValueIsANoOp() {
        MainActor.assumeIsolated {
            let model = HomeViewModel(service: PressService(store: InMemoryStatsStore()))
            model.setPro(false)
            XCTAssertFalse(model.isPro)
            XCTAssertEqual(model.selectedTheme, .classic)
        }
    }
}

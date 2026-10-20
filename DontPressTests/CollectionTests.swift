import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class CollectionTests: XCTestCase {
    private func stats(best: Int = 0, total: Int = 0) -> PressStats {
        PressStats(currentRun: 0, personalBest: best, totalPresses: total)
    }

    func testCatalogsAreWellFormed() {
        XCTAssertGreaterThanOrEqual(Achievement.all.count, 10)
        XCTAssertEqual(Set(Achievement.all.map(\.id)).count, Achievement.all.count)
        XCTAssertEqual(Set(Achievement.all.map(\.title)).count, Achievement.all.count)
        XCTAssertEqual(Set(ButtonTheme.all.map(\.id)).count, ButtonTheme.all.count)
        XCTAssertGreaterThanOrEqual(ButtonTheme.all.count, 4)
        XCTAssertEqual(ButtonTheme.all.first, .classic)
        XCTAssertEqual(ButtonTheme.classic.rule, .always)
    }

    func testNothingUnlockedAtZeroExceptClassic() {
        XCTAssertTrue(Achievement.all.allSatisfy { !$0.rule.isMet(by: stats()) })
        XCTAssertEqual(ButtonTheme.all.filter { $0.isUnlocked(for: stats()) }, [.classic])
    }

    func testRuleBoundaries() {
        XCTAssertFalse(UnlockRule.bestRun(10).isMet(by: stats(best: 9)))
        XCTAssertTrue(UnlockRule.bestRun(10).isMet(by: stats(best: 10)))
        XCTAssertFalse(UnlockRule.totalPresses(100).isMet(by: stats(total: 99)))
        XCTAssertTrue(UnlockRule.totalPresses(100).isMet(by: stats(total: 100)))
        XCTAssertTrue(UnlockRule.totalPresses(10_000).isMet(by: stats(total: Int.max)))
    }

    func testNewlyUnlockedFiresOnlyOnTheCrossing() {
        let first = Achievement.newlyUnlocked(before: stats(), after: stats(best: 1, total: 1)).map(\.id)
        XCTAssertEqual(first, ["first-press"])
        XCTAssertTrue(Achievement.newlyUnlocked(before: stats(best: 1, total: 1), after: stats(best: 2, total: 2)).isEmpty)
        let ten = Achievement.newlyUnlocked(before: stats(best: 9, total: 9), after: stats(best: 10, total: 10)).map(\.id)
        XCTAssertEqual(ten, ["run-10"])
        // a jump over several thresholds reports each exactly once
        let jump = Achievement.newlyUnlocked(before: stats(best: 9, total: 9), after: stats(best: 60, total: 600)).map(\.id)
        XCTAssertEqual(Set(jump), ["run-10", "run-25", "run-50", "total-100", "total-500"])
    }

    func testProgressForLockedItems() {
        let p = UnlockRule.bestRun(50).progress(for: stats(best: 20))
        XCTAssertEqual(p?.current, 20)
        XCTAssertEqual(p?.target, 50)
        XCTAssertEqual(UnlockRule.bestRun(50).progress(for: stats(best: 500))?.current, 50, "capped at target")
        XCTAssertNil(UnlockRule.always.progress(for: stats()))
    }

    func testResolveFallsBackToClassic() {
        XCTAssertEqual(ButtonTheme.resolve(id: nil, stats: stats(best: 500, total: 9999)), .classic)
        XCTAssertEqual(ButtonTheme.resolve(id: "nonsense", stats: stats(best: 500)), .classic)
        XCTAssertEqual(ButtonTheme.resolve(id: "gold", stats: stats(best: 5)), .classic, "locked choice is not honoured")
        XCTAssertEqual(ButtonTheme.resolve(id: "gold", stats: stats(total: 500)), .gold)
    }

    func testThemeChoicePersistsAndIgnoresUnknownStoredTypes() {
        let defaults = makeIsolatedDefaults(self)
        let store = UserDefaultsStatsStore(defaults: defaults)
        XCTAssertNil(store.loadThemeID())
        store.saveThemeID("cobalt")
        XCTAssertEqual(UserDefaultsStatsStore(defaults: defaults).loadThemeID(), "cobalt")
        defaults.set(42, forKey: UserDefaultsStatsStore.themeKey)
        XCTAssertNil(store.loadThemeID(), "wrong type reads as missing")
    }

    func testViewModelSelectsOnlyUnlockedThemesAndRestoresThem() {
        MainActor.assumeIsolated {
            let store = InMemoryStatsStore(PersistedStats(personalBest: 12, totalPresses: 12))
            let model = HomeViewModel(service: PressService(store: store), reactions: ReactionEngine(random: scripted([50, 0])))
            XCTAssertEqual(model.selectedTheme, .classic)
            model.selectTheme(.gold)                     // locked
            XCTAssertEqual(model.selectedTheme, .classic)
            model.selectTheme(.cobalt)                   // unlocked by best 12
            XCTAssertEqual(model.selectedTheme, .cobalt)
            XCTAssertEqual(model.themeStatuses.filter(\.isSelected).map(\.theme), [.cobalt])

            let relaunched = HomeViewModel(service: PressService(store: store))
            XCTAssertEqual(relaunched.selectedTheme, .cobalt)
        }
    }

    func testPressingShowsUnlockBannerOnceAndStatsStayExact() {
        MainActor.assumeIsolated {
            let store = InMemoryStatsStore(PersistedStats(personalBest: 5, totalPresses: 99))
            let spy = SpyHaptics()
            let model = HomeViewModel(service: PressService(store: store), reactions: ReactionEngine(random: scripted([50, 0, 1])), haptics: spy)
            model.press()                                // total 100 -> "Habit Forming"
            XCTAssertEqual(model.stats.totalPresses, 100)
            XCTAssertEqual(model.stats.currentRun, 1)
            XCTAssertTrue(model.unlockMessage?.contains("Habit Forming") == true)
            XCTAssertEqual(spy.milestoneCount, 1)
            model.dismissUnlockMessage()
            model.press()
            XCTAssertNil(model.unlockMessage, "no repeat on later presses")
            XCTAssertEqual(model.stats.totalPresses, 101)
        }
    }

    func testBannerMentionsNewButtonStyle() {
        MainActor.assumeIsolated {
            let store = InMemoryStatsStore(PersistedStats(personalBest: 9, totalPresses: 9))
            let model = HomeViewModel(service: PressService(store: store), reactions: ReactionEngine(random: scripted([50, 0, 1])))
            for _ in 0..<10 { model.press() }            // run reaches 10
            XCTAssertTrue(model.unlockMessage?.contains("Blue Mistake") == true)
            XCTAssertEqual(model.unlockedAchievementCount, model.achievementStatuses.filter(\.isUnlocked).count)
        }
    }
}

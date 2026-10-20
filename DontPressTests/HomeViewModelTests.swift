import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class HomeViewModelTests: XCTestCase {
    /// XCTest runs test methods on the main thread; this keeps the class free of
    /// `@MainActor` so swift-corelibs-xctest (Linux) can discover the tests too.
    private func onMain(_ body: @MainActor () -> Void) { MainActor.assumeIsolated(body) }

    @MainActor private func makeModel(store: StatsStoring = InMemoryStatsStore(), haptics: HapticFeedback? = nil) -> HomeViewModel {
        HomeViewModel(service: PressService(store: store), reactions: ReactionEngine(random: scripted([50, 0, 1])), haptics: haptics)
    }

    func testInitialState() {
        onMain {
            let model = makeModel()
            XCTAssertEqual(model.stats, PressStats())
            XCTAssertEqual(model.reactionText, ReactionCatalog.idle)
            XCTAssertNil(model.shareContent)
            XCTAssertFalse(model.isAtPersonalBest)
        }
    }

    func testPressUpdatesStatsAndReaction() {
        onMain {
            let model = makeModel()
            model.press()
            XCTAssertEqual(model.stats, PressStats(currentRun: 1, personalBest: 1, totalPresses: 1))
            XCTAssertNotEqual(model.reactionText, ReactionCatalog.idle)
            XCTAssertTrue(model.isAtPersonalBest)
            XCTAssertEqual(model.shareContent?.countText.isEmpty, false)
        }
    }

    func testRapidPressesCountExactlyAndHapticsFireOncePerPress() {
        onMain {
            let spy = SpyHaptics()
            let model = makeModel(haptics: spy)
            for _ in 0..<9 { model.press() }
            XCTAssertEqual(model.stats.currentRun, 9)
            XCTAssertEqual(model.pressCount, 9)
            XCTAssertEqual(spy.pressCount, 9)
            XCTAssertEqual(spy.milestoneCount, 0)
            model.press() // 10th crosses the first milestone
            XCTAssertEqual(spy.milestoneCount, 1)
            XCTAssertEqual(spy.pressCount, 9, "milestone press uses the stronger haptic instead")
            XCTAssertEqual(model.reactionText, ReactionCatalog.milestones[10]?.text)
            model.press()
            XCTAssertEqual(spy.milestoneCount, 1, "not repeated on later presses")
        }
    }

    func testHapticsPreparedOnInit() {
        onMain {
            let spy = SpyHaptics()
            _ = makeModel(haptics: spy)
            XCTAssertEqual(spy.prepareCount, 1)
        }
    }

    func testNotAtBestWhenBelowStoredBest() {
        onMain {
            let model = makeModel(store: InMemoryStatsStore(PersistedStats(personalBest: 5, totalPresses: 5)))
            model.press()
            XCTAssertFalse(model.isAtPersonalBest)
            XCTAssertEqual(model.stats.personalBest, 5)
        }
    }

    func testTyingAnOlderBestIsNotANewPersonalBest() {
        onMain {
            let model = makeModel(store: InMemoryStatsStore(PersistedStats(personalBest: 2, totalPresses: 2)))
            model.press()
            model.press()   // ties the stored best of 2
            XCTAssertFalse(model.isAtPersonalBest)
            model.press()   // 3 beats it
            XCTAssertTrue(model.isAtPersonalBest)
            XCTAssertEqual(model.stats.personalBest, 3)
        }
    }

    func testReadingShareContentDoesNotChangeStats() {
        onMain {
            let model = makeModel()
            model.press()
            let before = model.stats
            _ = model.shareContent
            _ = model.shareContent
            XCTAssertEqual(model.stats, before, "sharing / cancelling cannot alter statistics")
        }
    }
}

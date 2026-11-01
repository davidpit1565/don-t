import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

/// Toys unlock with Pro OR by reaching a total-press threshold (ProgressionRules).
final class ProgressionRulesTests: XCTestCase {
    private func stats(total: Int) -> PressStats { PressStats(currentRun: 0, personalBest: 0, totalPresses: total) }

    func testThresholdsAreReachable() {
        XCTAssertEqual(ProgressionRules.eggTotalPresses, 300)
        XCTAssertEqual(ProgressionRules.balloonTotalPresses, 1_500)
        XCTAssertEqual(ProgressionRules.playThreshold(for: .egg), 300)
        XCTAssertEqual(ProgressionRules.playThreshold(for: .balloon), 1_500)
        XCTAssertEqual(ProgressionRules.playThreshold(for: .button), 0)
        XCTAssertLessThan(ProgressionRules.eggTotalPresses, ProgressionRules.balloonTotalPresses)
    }

    func testEveryKindHasAStateAndUnlistedKindsAreProOnly() {
        for kind in ToyKind.allCases where kind != .pinata {
            if ProgressionRules.playThreshold(for: kind) == nil {
                XCTAssertEqual(ProgressionRules.unlockState(for: kind, stats: stats(total: 0), isPro: false),
                               .locked(progress: 0, target: 0), "\(kind) without a threshold is Pro-only")
                XCTAssertEqual(ProgressionRules.unlockState(for: kind, stats: stats(total: .max), isPro: false),
                               .locked(progress: 0, target: 0))
                XCTAssertEqual(ProgressionRules.fractionToUnlock(for: kind, stats: stats(total: .max)), 0)
            }
            XCTAssertTrue(ProgressionRules.unlockState(for: kind, stats: stats(total: 0), isPro: true).isUnlocked)
        }
    }

    func testPinataNeedsProAndPlay() {
        let t = PinataGate.minTotalPresses
        XCTAssertFalse(ProgressionRules.unlockState(for: .pinata, stats: stats(total: .max), isPro: false).isUnlocked)
        XCTAssertFalse(ProgressionRules.unlockState(for: .pinata, stats: stats(total: t - 1), isPro: true).isUnlocked)
        XCTAssertTrue(ProgressionRules.unlockState(for: .pinata, stats: stats(total: t), isPro: true).isUnlocked)
    }

    func testButtonIsAlwaysFree() {
        XCTAssertEqual(ProgressionRules.unlockState(for: .button, stats: stats(total: 0), isPro: false), .unlocked(by: .play))
        XCTAssertEqual(ProgressionRules.fractionToUnlock(for: .button, stats: stats(total: 0)), 1)
    }

    func testEggBoundary() {
        XCTAssertEqual(ProgressionRules.unlockState(for: .egg, stats: stats(total: 0), isPro: false), .locked(progress: 0, target: 300))
        XCTAssertEqual(ProgressionRules.unlockState(for: .egg, stats: stats(total: 299), isPro: false), .locked(progress: 299, target: 300))
        XCTAssertEqual(ProgressionRules.unlockState(for: .egg, stats: stats(total: 300), isPro: false), .unlocked(by: .play))
        XCTAssertEqual(ProgressionRules.unlockState(for: .egg, stats: stats(total: 301), isPro: false), .unlocked(by: .play))
    }

    func testBalloonBoundary() {
        XCTAssertEqual(ProgressionRules.unlockState(for: .balloon, stats: stats(total: 1_499), isPro: false), .locked(progress: 1_499, target: 1_500))
        XCTAssertEqual(ProgressionRules.unlockState(for: .balloon, stats: stats(total: 1_500), isPro: false), .unlocked(by: .play))
    }

    func testOnlyTotalPressesCount() {
        let runOnly = PressStats(currentRun: 5_000, personalBest: 5_000, totalPresses: 10)
        XCTAssertEqual(ProgressionRules.unlockState(for: .egg, stats: runOnly, isPro: false), .locked(progress: 10, target: 300))
    }

    func testProBypassAndPlayTakesPrecedence() {
        XCTAssertEqual(ProgressionRules.unlockState(for: .balloon, stats: stats(total: 0), isPro: true), .unlocked(by: .pro))
        XCTAssertEqual(ProgressionRules.unlockState(for: .egg, stats: stats(total: 300), isPro: true), .unlocked(by: .play))
    }

    func testSaturationAndNegativeValues() {
        XCTAssertEqual(ProgressionRules.unlockState(for: .balloon, stats: stats(total: .max), isPro: false), .unlocked(by: .play))
        XCTAssertEqual(ProgressionRules.fractionToUnlock(for: .balloon, stats: stats(total: .max)), 1)
        XCTAssertEqual(ProgressionRules.unlockState(for: .egg, stats: stats(total: -5), isPro: false), .locked(progress: 0, target: 300))
        XCTAssertEqual(ProgressionRules.fractionToUnlock(for: .egg, stats: stats(total: -5)), 0)
        XCTAssertEqual(ProgressionRules.newlyUnlockedByPlay(before: stats(total: .max), after: stats(total: .max)), [])
        XCTAssertEqual(ProgressionRules.newlyUnlockedByPlay(before: stats(total: -1), after: stats(total: .max)), [.egg, .balloon])
    }

    func testFraction() {
        XCTAssertEqual(ProgressionRules.fractionToUnlock(for: .egg, stats: stats(total: 0)), 0)
        XCTAssertEqual(ProgressionRules.fractionToUnlock(for: .egg, stats: stats(total: 150)), 0.5, accuracy: 1e-9)
        XCTAssertEqual(ProgressionRules.fractionToUnlock(for: .egg, stats: stats(total: 299)), 299.0 / 300.0, accuracy: 1e-9)
        XCTAssertEqual(ProgressionRules.fractionToUnlock(for: .egg, stats: stats(total: 300)), 1)
        XCTAssertEqual(ProgressionRules.fractionToUnlock(for: .egg, stats: stats(total: 9_999)), 1)
    }

    func testCrossingIsReportedExactlyOnce() {
        XCTAssertEqual(ProgressionRules.newlyUnlockedByPlay(before: stats(total: 298), after: stats(total: 299)), [])
        XCTAssertEqual(ProgressionRules.newlyUnlockedByPlay(before: stats(total: 299), after: stats(total: 300)), [.egg])
        XCTAssertEqual(ProgressionRules.newlyUnlockedByPlay(before: stats(total: 300), after: stats(total: 301)), [])
        XCTAssertEqual(ProgressionRules.newlyUnlockedByPlay(before: stats(total: 1_499), after: stats(total: 1_500)), [.balloon])
        XCTAssertEqual(ProgressionRules.newlyUnlockedByPlay(before: stats(total: 0), after: stats(total: 1)), [], "the free button is never news")
    }

    func testLabels() {
        let locked = ToyUnlockState.locked(progress: 123, target: 300)
        XCTAssertEqual(ProgressionRules.progressLabel(for: locked), "123/300")
        XCTAssertEqual(ProgressionRules.accessibilityValue(for: locked), "Locked. 123 of 300 presses, or unlock with Pro")
        XCTAssertNil(ProgressionRules.progressLabel(for: .unlocked(by: .pro)))
        XCTAssertNil(ProgressionRules.progressLabel(for: .locked(progress: 0, target: 0)))
        XCTAssertEqual(ProgressionRules.accessibilityValue(for: .locked(progress: 0, target: 0)), "Locked. Included with Pro")
        XCTAssertEqual(ProgressionRules.accessibilityValue(for: .unlocked(by: .play)), "")
        XCTAssertNil(ProgressionRules.unlockMessage(for: []))
        XCTAssertEqual(ProgressionRules.unlockMessage(for: [.egg]), "New toy, earned by pressing: Egg")
    }

    // MARK: HomeViewModel wiring

    @MainActor
    private func makeModel(store: InMemoryStatsStore) -> HomeViewModel {
        HomeViewModel(service: PressService(store: store))
    }

    private func store(total: Int) -> InMemoryStatsStore {
        InMemoryStatsStore(PersistedStats(personalBest: 0, totalPresses: total))
    }

    func testModelUnlocksEggAtThresholdWithBannerOnce() {
        MainActor.assumeIsolated {
            let model = makeModel(store: store(total: 298))
            XCTAssertFalse(model.isToyUnlocked(.egg))
            XCTAssertFalse(model.selectToy(.egg))
            model.press()                                  // 299
            XCTAssertFalse(model.isToyUnlocked(.egg))
            XCTAssertEqual(model.toyUnlockState(.egg), .locked(progress: 299, target: 300))
            XCTAssertFalse(model.unlockMessage?.contains("Egg") ?? false)
            model.press()                                  // 300: the crossing
            XCTAssertTrue(model.isToyUnlocked(.egg))
            XCTAssertEqual(model.toyUnlockState(.egg), .unlocked(by: .play))
            XCTAssertTrue(model.unlockMessage?.contains("New toy, earned by pressing: Egg") ?? false)
            model.dismissUnlockMessage()
            model.press()                                  // 301: no repeat
            XCTAssertFalse(model.unlockMessage?.contains("Egg") ?? false)
            XCTAssertTrue(model.selectToy(.egg))
            XCTAssertEqual(model.toys.selectedKind, .egg)
            XCTAssertFalse(model.isToyUnlocked(.balloon))
            XCTAssertFalse(model.selectToy(.balloon))
        }
    }

    func testCrossingDoesNotRepeatAfterRelaunch() {
        MainActor.assumeIsolated {
            let shared = store(total: 299)
            let first = makeModel(store: shared)
            first.press()
            XCTAssertTrue(first.unlockMessage?.contains("Egg") ?? false)
            let second = makeModel(store: shared)          // cold relaunch; total 300 persisted
            XCTAssertTrue(second.isToyUnlocked(.egg))
            second.press()
            XCTAssertFalse(second.unlockMessage?.contains("Egg") ?? false)
        }
    }

    func testCountingIsUnaffectedByProgression() {
        MainActor.assumeIsolated {
            let shared = store(total: 295)
            let model = makeModel(store: shared)
            for _ in 0..<10 { model.press() }
            XCTAssertEqual(model.stats.currentRun, 10)
            XCTAssertEqual(model.stats.totalPresses, 305)
            XCTAssertEqual(shared.load().totalPresses, 305)
        }
    }

    func testProDoesNotAnnouncePlayUnlocks() {
        MainActor.assumeIsolated {
            let model = makeModel(store: store(total: 299))
            model.setPro(true)
            model.press()
            XCTAssertFalse(model.unlockMessage?.contains("New toy") ?? false)
        }
    }

    func testToyEarnedByPlaySurvivesLosingProAndRelaunch() {
        MainActor.assumeIsolated {
            let shared = store(total: 300)
            let model = makeModel(store: shared)
            model.setPro(true)
            XCTAssertTrue(model.selectToy(.egg))
            model.setPro(false)
            XCTAssertEqual(model.toys.selectedKind, .egg, "the egg was earned by play, so it stays")
            XCTAssertFalse(model.selectToy(.balloon))
            let relaunched = makeModel(store: shared)
            XCTAssertEqual(relaunched.toys.selectedKind, .egg)
        }
    }

    func testBalloonSelectedViaProFallsBackWhenProIsLostBelowThreshold() {
        MainActor.assumeIsolated {
            let shared = store(total: 300)
            let model = makeModel(store: shared)
            model.setPro(true)
            XCTAssertTrue(model.selectToy(.balloon))
            model.setPro(false)
            XCTAssertEqual(model.toys.selectedKind, .button)
        }
    }
}

import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class PressServiceTests: XCTestCase {
    func testInitialValuesAreZero() {
        let service = PressService(store: InMemoryStatsStore())
        XCTAssertEqual(service.stats, PressStats(currentRun: 0, personalBest: 0, totalPresses: 0))
    }

    func testEachPressIncrementsExactlyOnce() {
        let service = PressService(store: InMemoryStatsStore())
        let result = service.registerPress()
        XCTAssertEqual(result.stats, PressStats(currentRun: 1, personalBest: 1, totalPresses: 1))
        XCTAssertEqual(service.stats, result.stats)
    }

    func testRapidPressesCountEveryPress() {
        let service = PressService(store: InMemoryStatsStore())
        for _ in 0..<1_000 { service.registerPress() }
        XCTAssertEqual(service.stats, PressStats(currentRun: 1_000, personalBest: 1_000, totalPresses: 1_000))
    }

    func testPersonalBestFollowsRunAndFlagsNewBest() {
        let service = PressService(store: InMemoryStatsStore(PersistedStats(personalBest: 2, totalPresses: 10)))
        XCTAssertFalse(service.registerPress().isNewPersonalBest) // 1 < 2
        XCTAssertFalse(service.registerPress().isNewPersonalBest) // 2 == 2
        let third = service.registerPress()                       // 3 > 2
        XCTAssertTrue(third.isNewPersonalBest)
        XCTAssertEqual(third.stats.personalBest, 3)
        XCTAssertEqual(third.stats.totalPresses, 13)
    }

    func testPersistenceAcrossServiceRecreationStartsFreshRun() {
        let store = InMemoryStatsStore()
        let first = PressService(store: store)
        for _ in 0..<7 { first.registerPress() }

        let relaunched = PressService(store: store)
        XCTAssertEqual(relaunched.stats.currentRun, 0, "cold launch must start a fresh run")
        XCTAssertEqual(relaunched.stats.personalBest, 7)
        XCTAssertEqual(relaunched.stats.totalPresses, 7)

        relaunched.registerPress()
        XCTAssertEqual(relaunched.stats, PressStats(currentRun: 1, personalBest: 7, totalPresses: 8))
    }

    func testPersistenceThroughUserDefaults() {
        let defaults = makeIsolatedDefaults(self)
        let first = PressService(store: UserDefaultsStatsStore(defaults: defaults))
        for _ in 0..<5 { first.registerPress() }
        let second = PressService(store: UserDefaultsStatsStore(defaults: defaults))
        XCTAssertEqual(second.stats, PressStats(currentRun: 0, personalBest: 5, totalPresses: 5))
    }

    // MARK: Invalid stored data

    func testMissingValuesReadAsZero() {
        let store = UserDefaultsStatsStore(defaults: makeIsolatedDefaults(self))
        XCTAssertEqual(store.load(), PersistedStats())
    }

    func testCorruptValuesReadAsZero() {
        let defaults = makeIsolatedDefaults(self)
        defaults.set("banana", forKey: UserDefaultsStatsStore.bestKey)
        defaults.set(-40, forKey: UserDefaultsStatsStore.totalKey)
        XCTAssertEqual(UserDefaultsStatsStore(defaults: defaults).load(), PersistedStats())

        defaults.set([1, 2, 3], forKey: UserDefaultsStatsStore.bestKey)
        defaults.set(Data([0x01]), forKey: UserDefaultsStatsStore.totalKey)
        XCTAssertEqual(UserDefaultsStatsStore(defaults: defaults).load(), PersistedStats())
    }

    func testServiceRecoversFromCorruptStoreAndKeepsCounting() {
        let defaults = makeIsolatedDefaults(self)
        defaults.set("oops", forKey: UserDefaultsStatsStore.totalKey)
        let service = PressService(store: UserDefaultsStatsStore(defaults: defaults))
        service.registerPress()
        XCTAssertEqual(service.stats, PressStats(currentRun: 1, personalBest: 1, totalPresses: 1))
    }

    func testNegativeIsNeverWritten() {
        let defaults = makeIsolatedDefaults(self)
        let store = UserDefaultsStatsStore(defaults: defaults)
        store.save(PersistedStats(personalBest: -5, totalPresses: -9))
        XCTAssertEqual(store.load(), PersistedStats())
    }

    // MARK: Large values

    func testCountersSaturateInsteadOfOverflowing() {
        let store = InMemoryStatsStore(PersistedStats(personalBest: Int.max - 1, totalPresses: Int.max - 1))
        let service = PressService(store: store)
        service.registerPress()
        XCTAssertEqual(service.stats.totalPresses, Int.max - 1 + 1)
        service.registerPress()
        XCTAssertEqual(service.stats.totalPresses, Int.max, "saturates, does not trap")
        service.registerPress()
        XCTAssertEqual(service.stats.totalPresses, Int.max)
        XCTAssertGreaterThanOrEqual(service.stats.personalBest, 0)
    }

    func testSaturatingIncrementHelper() {
        XCTAssertEqual(5.saturatingIncremented(), 6)
        XCTAssertEqual(Int.max.saturatingIncremented(), Int.max)
        XCTAssertEqual((-3).saturatingIncremented(), 1, "negative input is treated as zero")
        XCTAssertEqual(5.saturatingIncremented(by: -2), 5, "negative amounts are ignored")
    }

    // MARK: Milestones

    func testMilestoneFiresOnceAtEachCrossing() {
        let service = PressService(store: InMemoryStatsStore())
        var hits: [Int] = []
        for _ in 0..<1_100 {
            if let milestone = service.registerPress().milestone { hits.append(milestone) }
        }
        XCTAssertEqual(hits, [10, 25, 50, 100, 250, 500, 1000])
    }

    func testMilestoneNotRepeatedAfterRelaunchWithHighBest() {
        let store = InMemoryStatsStore(PersistedStats(personalBest: 500, totalPresses: 500))
        let service = PressService(store: store)
        var hits: [Int] = []
        for _ in 0..<10 { if let m = service.registerPress().milestone { hits.append(m) } }
        XCTAssertEqual(hits, [10], "milestones belong to the current run")
    }

    func testMilestoneCrossedHelper() {
        XCTAssertNil(Milestone.crossed(from: 0, to: 9))
        XCTAssertEqual(Milestone.crossed(from: 9, to: 10), 10)
        XCTAssertNil(Milestone.crossed(from: 10, to: 11))
        XCTAssertEqual(Milestone.crossed(from: 0, to: 30), 25, "highest crossed wins")
    }
}

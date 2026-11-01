import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

/// The mythic toy: a piñata that needs Pro AND 5,000 total presses.
final class PinataToyTests: XCTestCase {
    private func onMain(_ body: @MainActor () -> Void) { MainActor.assumeIsolated(body) }

    // MARK: ToyKind

    func testPinataKindIsProAndTitled() {
        XCTAssertTrue(ToyKind.pinata.requiresPro)
        XCTAssertEqual(ToyKind.pinata.title, "Piñata")
        XCTAssertEqual(ToyKind.resolve(id: "pinata"), .pinata)
        XCTAssertTrue(ToyKind.allCases.contains(.pinata))
        XCTAssertEqual(PinataToy.kind, .pinata)
    }

    // MARK: State machine

    func testBurstsAtDrawnThresholdAndIsDeterministic() {
        // Threshold offset 3 -> 15 hits. Then rarity roll 50 -> common, index 2 -> pebble.
        var pinata = PinataToy(random: scripted([3, 50, 2, 0, 10, 0]))
        XCTAssertEqual(pinata.hitsToBurst, 15)
        XCTAssertEqual(pinata.stage, .swinging)
        XCTAssertEqual(pinata.tension, 0)
        XCTAssertFalse(pinata.isBurst)

        for n in 1..<15 {
            XCTAssertNil(pinata.tap(), "no payoff before the threshold (hit \(n))")
            XCTAssertEqual(pinata.tapsThisCycle, n)
            XCTAssertFalse(pinata.isResolved)
            XCTAssertLessThan(pinata.tension, 1)
        }
        let prize = pinata.tap()
        XCTAssertEqual(prize?.id, "pebble")
        XCTAssertEqual(pinata.stage, .burst(PinataPrizeCatalog.prize(id: "pebble")!))
        XCTAssertTrue(pinata.isBurst)
        XCTAssertEqual(pinata.tension, 1)

        var replay = PinataToy(random: scripted([3, 50, 2, 0, 10, 0]))
        var replayed: PinataPrize?
        for _ in 0..<15 { replayed = replay.tap() ?? replayed }
        XCTAssertEqual(replayed?.id, "pebble", "same seed, same prize")
    }

    func testHitThresholdStaysInsideRangeAndCoversIt() {
        var seen = Set<Int>()
        for value in 0..<60 {
            let pinata = PinataToy(random: scripted([value]))
            XCTAssertTrue(PinataToy.hitRange.contains(pinata.hitsToBurst), "offset \(value) gave \(pinata.hitsToBurst)")
            seen.insert(pinata.hitsToBurst)
        }
        XCTAssertEqual(seen, Set(PinataToy.hitRange), "every value in the range is reachable")
        XCTAssertEqual(PinataToy.hitRange, 12...25)
    }

    func testStagesProgressInOrder() {
        var pinata = PinataToy(random: scripted([8, 50, 0])) // 20 hits
        var seen: [PinataStage] = [pinata.stage]
        for _ in 0..<20 {
            _ = pinata.tap()
            if pinata.stage != seen.last { seen.append(pinata.stage) }
        }
        XCTAssertEqual(Array(seen.prefix(3)), [.swinging, .dented, .cracked])
        XCTAssertEqual(seen.count, 4)
        if case .burst = seen.last! {} else { XCTFail("ends burst, got \(seen.last!)") }
    }

    func testSwingDirectionAlternatesPerHit() {
        var pinata = PinataToy(random: scripted([13]))
        XCTAssertEqual(pinata.swingDirection, 1)
        _ = pinata.tap()
        XCTAssertEqual(pinata.swingDirection, -1)
        _ = pinata.tap()
        XCTAssertEqual(pinata.swingDirection, 1)
    }

    func testTapOnBurstPinataStartsFreshCycleWithoutWastingTheTap() {
        var pinata = PinataToy(random: scripted([0, 50, 0, 0, 50, 1])) // 12 hits, then again 12 hits
        for _ in 0..<12 { _ = pinata.tap() }
        XCTAssertTrue(pinata.isBurst)
        XCTAssertNil(pinata.tap())
        XCTAssertFalse(pinata.isBurst)
        XCTAssertEqual(pinata.tapsThisCycle, 1, "the tap on the burst piñata is the first hit of the next one")
        XCTAssertEqual(pinata.stage, .swinging)
    }

    func testResetReturnsToSwingingWithFreshThreshold() {
        var pinata = PinataToy(random: scripted([0, 50, 0, 7]))
        for _ in 0..<12 { _ = pinata.tap() }
        XCTAssertTrue(pinata.isResolved)
        pinata.reset()
        XCTAssertFalse(pinata.isResolved)
        XCTAssertEqual(pinata.tapsThisCycle, 0)
        XCTAssertEqual(pinata.tension, 0)
        XCTAssertEqual(pinata.hitsToBurst, 19, "re-drawn from the injected random")
    }

    func testAvoidsDroppingTheSamePrizeTwiceInARow() {
        // Rarity roll 50 -> common each time, index always 0: the second burst must skip the first prize.
        var pinata = PinataToy(random: scripted([0, 50, 0]))
        var prizes: [String] = []
        for _ in 0..<36 { if let prize = pinata.tap() { prizes.append(prize.id) } }
        XCTAssertEqual(prizes.count, 3)
        XCTAssertNotEqual(prizes[0], prizes[1])
        XCTAssertNotEqual(prizes[1], prizes[2])
    }

    // MARK: Prize catalog

    func testPrizeCatalogIsCuratedAndUnique() {
        let all = PinataPrizeCatalog.all
        XCTAssertGreaterThanOrEqual(all.count, 10)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count, "ids unique")
        XCTAssertEqual(Set(all.map(\.name)).count, all.count, "names unique")
        for rarity in PinataPrizeRarity.allCases {
            XCTAssertFalse(PinataPrizeCatalog.prizes(of: rarity).isEmpty, "\(rarity) has at least one prize")
        }
        for prize in all {
            XCTAssertFalse(prize.name.isEmpty)
            XCTAssertFalse(prize.line.isEmpty)
            XCTAssertTrue(prize.burstLine.contains(prize.name))
            XCTAssertTrue(prize.burstLine.hasSuffix(prize.line))
        }
        XCTAssertNil(PinataPrizeCatalog.prize(id: "nothing"))
    }

    func testRarityRollBoundaries() {
        XCTAssertEqual(PinataPrizeRarity.forRoll(0), .legendary)
        XCTAssertEqual(PinataPrizeRarity.forRoll(PinataPrizeRarity.legendaryPercent - 1), .legendary)
        XCTAssertEqual(PinataPrizeRarity.forRoll(PinataPrizeRarity.legendaryPercent), .rare)
        XCTAssertEqual(PinataPrizeRarity.forRoll(PinataPrizeRarity.legendaryPercent + PinataPrizeRarity.rarePercent - 1), .rare)
        XCTAssertEqual(PinataPrizeRarity.forRoll(PinataPrizeRarity.legendaryPercent + PinataPrizeRarity.rarePercent), .common)
        XCTAssertEqual(PinataPrizeRarity.forRoll(99), .common)
    }

    func testDrawPicksWithinRolledTier() {
        XCTAssertEqual(PinataPrizeCatalog.draw(random: scripted([0, 0])).rarity, .legendary)
        XCTAssertEqual(PinataPrizeCatalog.draw(random: scripted([10, 1])).rarity, .rare)
        XCTAssertEqual(PinataPrizeCatalog.draw(random: scripted([99, 99])).rarity, .common)
    }

    // MARK: Gate

    func testGateMatrix() {
        let threshold = PinataGate.minTotalPresses
        XCTAssertEqual(threshold, 5_000)
        // Not Pro: never, however much play.
        XCTAssertFalse(PinataGate.isUnlocked(totalPresses: 0, isPro: false))
        XCTAssertFalse(PinataGate.isUnlocked(totalPresses: 4_999, isPro: false))
        XCTAssertFalse(PinataGate.isUnlocked(totalPresses: 5_000, isPro: false))
        XCTAssertFalse(PinataGate.isUnlocked(totalPresses: 1_000_000, isPro: false))
        // Pro: only with the play.
        XCTAssertFalse(PinataGate.isUnlocked(totalPresses: 0, isPro: true))
        XCTAssertFalse(PinataGate.isUnlocked(totalPresses: 4_999, isPro: true))
        XCTAssertTrue(PinataGate.isUnlocked(totalPresses: 5_000, isPro: true))
        XCTAssertTrue(PinataGate.isUnlocked(totalPresses: 5_001, isPro: true))
        XCTAssertTrue(PinataGate.isUnlocked(totalPresses: Int.max, isPro: true))
    }

    func testGateProgressAndText() {
        XCTAssertEqual(PinataGate.progress(totalPresses: -5), 0)
        XCTAssertEqual(PinataGate.progress(totalPresses: 0), 0)
        XCTAssertEqual(PinataGate.progress(totalPresses: 1_250), 0.25, accuracy: 0.0001)
        XCTAssertEqual(PinataGate.progress(totalPresses: 5_000), 1)
        XCTAssertEqual(PinataGate.progress(totalPresses: 99_999), 1, "clamped")

        let en = Locale(identifier: "en_US")
        XCTAssertEqual(PinataGate.progressText(totalPresses: 1_200, isPro: false, locale: en), "1,200/5,000 · Pro")
        XCTAssertEqual(PinataGate.progressText(totalPresses: 1_200, isPro: true, locale: en), "1,200/5,000")
        XCTAssertEqual(PinataGate.progressText(totalPresses: 0, isPro: false, locale: en), "0/5,000 · Pro")
        XCTAssertEqual(PinataGate.progressText(totalPresses: 9_000, isPro: false, locale: en), "5,000/5,000 · Pro", "clamped to the threshold")
        XCTAssertEqual(PinataGate.progressText(totalPresses: -3, isPro: true, locale: en), "0/5,000")
    }

    func testGateNewlyUnlockedOnlyOnTheCrossingPressWithPro() {
        XCTAssertTrue(PinataGate.newlyUnlocked(before: 4_999, after: 5_000, isPro: true))
        XCTAssertFalse(PinataGate.newlyUnlocked(before: 4_999, after: 5_000, isPro: false))
        XCTAssertFalse(PinataGate.newlyUnlocked(before: 5_000, after: 5_001, isPro: true))
        XCTAssertFalse(PinataGate.newlyUnlocked(before: 4_998, after: 4_999, isPro: true))
    }

    // MARK: HomeViewModel gate

    private func model(totalPresses: Int, isPro: Bool, store: InMemoryStatsStore? = nil, random: [Int] = [0]) -> HomeViewModel {
        let store = store ?? InMemoryStatsStore(PersistedStats(personalBest: 0, totalPresses: totalPresses))
        store.saveIsPro(isPro)
        let service = PressService(store: store)
        let toys = MainActor.assumeIsolated { ToySession(store: store, random: scripted(random)) }
        return MainActor.assumeIsolated { HomeViewModel(service: service, toys: toys) }
    }

    func testModelGateMatrix() {
        onMain {
            XCTAssertFalse(model(totalPresses: 0, isPro: false).isToyUnlocked(.pinata))
            XCTAssertFalse(model(totalPresses: 4_999, isPro: false).isToyUnlocked(.pinata))
            XCTAssertFalse(model(totalPresses: 5_000, isPro: false).isToyUnlocked(.pinata))
            XCTAssertFalse(model(totalPresses: 50_000, isPro: false).isToyUnlocked(.pinata))
            XCTAssertFalse(model(totalPresses: 0, isPro: true).isToyUnlocked(.pinata))
            XCTAssertFalse(model(totalPresses: 4_999, isPro: true).isToyUnlocked(.pinata))
            XCTAssertTrue(model(totalPresses: 5_000, isPro: true).isToyUnlocked(.pinata))
            XCTAssertTrue(model(totalPresses: 5_001, isPro: true).isToyUnlocked(.pinata))
            // The other toys are untouched by the play threshold.
            let pro = model(totalPresses: 0, isPro: true)
            XCTAssertTrue(pro.isToyUnlocked(.egg))
            XCTAssertTrue(pro.isToyUnlocked(.balloon))
            XCTAssertTrue(pro.isToyUnlocked(.button))
        }
    }

    func testLockedPinataCannotBeSelected() {
        onMain {
            let free = model(totalPresses: 9_000, isPro: false)
            XCTAssertFalse(free.selectToy(.pinata))
            XCTAssertEqual(free.toys.selectedKind, .button)

            let proWithoutPlay = model(totalPresses: 4_999, isPro: true)
            XCTAssertFalse(proWithoutPlay.selectToy(.pinata))
            XCTAssertEqual(proWithoutPlay.toys.selectedKind, .button)

            let earned = model(totalPresses: 5_000, isPro: true)
            XCTAssertTrue(earned.selectToy(.pinata))
            XCTAssertEqual(earned.toys.selectedKind, .pinata)
        }
    }

    func testCrossingTheThresholdWhilePlayingUnlocksAndAnnouncesOnce() {
        onMain {
            let model = model(totalPresses: 4_999, isPro: true)
            XCTAssertFalse(model.isToyUnlocked(.pinata))
            model.press()
            XCTAssertEqual(model.stats.totalPresses, 5_000)
            XCTAssertTrue(model.isToyUnlocked(.pinata))
            XCTAssertTrue(model.unlockMessage?.contains("Piñata") ?? false, "got \(String(describing: model.unlockMessage))")
            model.dismissUnlockMessage()
            model.press()
            XCTAssertFalse(model.unlockMessage?.contains("Piñata") ?? false, "announced only on the crossing press")
        }
    }

    func testCrossingTheThresholdWithoutProDoesNotAnnounce() {
        onMain {
            let model = model(totalPresses: 4_999, isPro: false)
            model.press()
            XCTAssertFalse(model.isToyUnlocked(.pinata))
            XCTAssertFalse(model.unlockMessage?.contains("Piñata") ?? false)
        }
    }

    func testProgressTextComesFromTheModelStats() {
        onMain {
            let model = model(totalPresses: 1_200, isPro: false)
            XCTAssertTrue(model.pinataProgressText.hasSuffix("· Pro"))
            XCTAssertTrue(model.pinataProgressText.contains("5"))
        }
    }

    // MARK: Saved-selection fallback

    func testSavedPinataWithoutProFallsBackToTheButton() {
        onMain {
            let store = InMemoryStatsStore(PersistedStats(personalBest: 0, totalPresses: 9_000))
            store.saveSelectedToyID("pinata")
            let model = model(totalPresses: 9_000, isPro: false, store: store)
            XCTAssertEqual(model.toys.selectedKind, .button)
            XCTAssertEqual(store.loadSelectedToyID(), "button")
        }
    }

    func testSavedPinataWithProButNotEnoughPlayFallsBackToTheButton() {
        onMain {
            let store = InMemoryStatsStore(PersistedStats(personalBest: 0, totalPresses: 4_999))
            store.saveSelectedToyID("pinata")
            let model = model(totalPresses: 4_999, isPro: true, store: store)
            XCTAssertEqual(model.toys.selectedKind, .button)
        }
    }

    func testSavedPinataWithBothGatesMetIsRestored() {
        onMain {
            let store = InMemoryStatsStore(PersistedStats(personalBest: 0, totalPresses: 5_000))
            store.saveSelectedToyID("pinata")
            let model = model(totalPresses: 5_000, isPro: true, store: store)
            XCTAssertEqual(model.toys.selectedKind, .pinata)
        }
    }

    func testLosingProWhileThePinataIsSelectedFallsBackToTheButton() {
        onMain {
            let store = InMemoryStatsStore(PersistedStats(personalBest: 0, totalPresses: 6_000))
            let model = model(totalPresses: 6_000, isPro: true, store: store)
            XCTAssertTrue(model.selectToy(.pinata))
            model.setPro(false)
            XCTAssertEqual(model.toys.selectedKind, .button)
            XCTAssertEqual(store.loadSelectedToyID(), "button")
            // Buying Pro again does not silently re-select it; the player picks it.
            model.setPro(true)
            XCTAssertEqual(model.toys.selectedKind, .button)
            XCTAssertTrue(model.isToyUnlocked(.pinata))
        }
    }

    // MARK: Counting through pressToy

    func testPressToyCountsExactlyOncePerHitAndSurfacesThePrize() {
        onMain {
            let store = InMemoryStatsStore(PersistedStats(personalBest: 0, totalPresses: 5_000))
            let spy = SpyHaptics()
            let service = PressService(store: store)
            store.saveIsPro(true)
            // Session draw order: egg, balloon, piñata thresholds (0 -> 12 hits); then rarity 50 -> common; index 0 -> sock.
            let toys = ToySession(store: store, random: scripted([0, 0, 0, 50, 0]))
            let model = HomeViewModel(service: service, haptics: spy, toys: toys)
            XCTAssertTrue(model.selectToy(.pinata))

            for hit in 1...11 {
                model.pressToy()
                XCTAssertEqual(model.stats.currentRun, hit)
                XCTAssertEqual(model.stats.totalPresses, 5_000 + hit)
                XCTAssertFalse(model.toys.pinata.isBurst)
            }
            model.pressToy()
            XCTAssertEqual(model.stats.currentRun, 12)
            XCTAssertEqual(model.stats.totalPresses, 5_012)
            XCTAssertEqual(model.stats.personalBest, 12)
            XCTAssertTrue(model.toys.pinata.isBurst)
            XCTAssertEqual(model.toys.pinata.prize?.id, "sock")
            XCTAssertEqual(model.reactionText, PinataPrizeCatalog.prize(id: "sock")!.burstLine)
            XCTAssertEqual(model.toys.payoffCount, 1)
            XCTAssertGreaterThanOrEqual(spy.milestoneCount, 1, "a burst gets the stronger haptic")
            XCTAssertEqual(spy.pressCount + spy.milestoneCount, 13, "12 presses (one of them a milestone at 10) + 1 burst")

            // The hit on the burst piñata starts the next one and still counts exactly once.
            model.pressToy()
            XCTAssertEqual(model.stats.currentRun, 13)
            XCTAssertFalse(model.toys.pinata.isBurst)
            XCTAssertEqual(model.toys.pinata.tapsThisCycle, 1)

            // Persisted across service recreation.
            XCTAssertEqual(store.load().totalPresses, 5_013)
            XCTAssertEqual(store.loadDiscoveredPinataPrizeIDs(), ["sock"])
        }
    }

    func testRapidHitsNeverDoubleCount() {
        onMain {
            let store = InMemoryStatsStore(PersistedStats(personalBest: 0, totalPresses: 5_000))
            store.saveIsPro(true)
            let toys = ToySession(store: store, random: scripted([0]))   // always 12 hits
            let model = HomeViewModel(service: PressService(store: store), toys: toys)
            XCTAssertTrue(model.selectToy(.pinata))
            for _ in 0..<500 { model.pressToy() }
            XCTAssertEqual(model.stats.currentRun, 500)
            XCTAssertEqual(model.stats.totalPresses, 5_500)
            XCTAssertEqual(model.pressCount, 500)
            // 500 hits at 12 per piñata: 41 bursts, with the 42nd piñata 8 hits in.
            XCTAssertEqual(model.toys.payoffCount, 41)
            XCTAssertEqual(model.toys.pinata.tapsThisCycle, 8)
        }
    }

    // MARK: Session persistence of prizes

    func testSessionRecordsAndPersistsDiscoveredPrizes() {
        onMain {
            let store = InMemoryStatsStore()
            // 12 hits -> legendary (roll 0), index 0 -> deed. Then 12 hits -> legendary again, must pick the other.
            let session = ToySession(store: store, random: scripted([0, 0, 0]))
            session.select(.pinata)
            XCTAssertTrue(session.discoveredPrizes.isEmpty)
            var lines: [String] = []
            for _ in 0..<24 { if let line = session.tapSelected() { lines.append(line) } }
            XCTAssertEqual(lines.count, 2)
            XCTAssertEqual(session.discoveredPrizeIDs, ["deed", "pinata"])
            XCTAssertEqual(store.loadDiscoveredPinataPrizeIDs(), ["deed", "pinata"])
            XCTAssertTrue(session.isDiscovered(PinataPrizeCatalog.prize(id: "deed")!))
            XCTAssertFalse(session.isDiscovered(PinataPrizeCatalog.prize(id: "sock")!))

            let reloaded = ToySession(store: store)
            XCTAssertEqual(reloaded.discoveredPrizeIDs, ["deed", "pinata"])
            XCTAssertEqual(reloaded.discoveredPrizes.map(\.id), ["deed", "pinata"])
        }
    }

    func testSessionIgnoresUnknownStoredPrizeIDs() {
        onMain {
            let store = InMemoryStatsStore()
            store.saveDiscoveredPinataPrizeIDs(["sock", "unicorn", ""])
            let session = ToySession(store: store)
            XCTAssertEqual(session.discoveredPrizeIDs, ["sock"])
        }
    }

    func testSessionClearPayoffResetsTheBurstPinata() {
        onMain {
            let session = ToySession(store: InMemoryStatsStore(), random: scripted([0]))
            session.select(.pinata)
            for _ in 0..<12 { _ = session.tapSelected() }
            XCTAssertTrue(session.pinata.isResolved)
            session.clearPayoff()
            XCTAssertFalse(session.pinata.isResolved)
            XCTAssertEqual(session.pinata.tapsThisCycle, 0)
        }
    }

    func testUserDefaultsStoreRoundTripsPrizesAndTreatsWrongTypesAsEmpty() {
        let defaults = makeIsolatedDefaults(self)
        let store = UserDefaultsStatsStore(defaults: defaults)
        XCTAssertEqual(store.loadDiscoveredPinataPrizeIDs(), [])
        store.saveDiscoveredPinataPrizeIDs(["spork", "sock"])
        XCTAssertEqual(UserDefaultsStatsStore(defaults: defaults).loadDiscoveredPinataPrizeIDs(), ["spork", "sock"])
        defaults.set(42, forKey: UserDefaultsStatsStore.pinataPrizesKey)
        XCTAssertEqual(store.loadDiscoveredPinataPrizeIDs(), [])
        defaults.set("sock", forKey: UserDefaultsStatsStore.pinataPrizesKey)
        XCTAssertEqual(store.loadDiscoveredPinataPrizeIDs(), [])
        store.saveSelectedToyID("pinata")
        XCTAssertEqual(ToyKind.resolve(id: store.loadSelectedToyID()), .pinata)
    }
}

import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class TapToyTests: XCTestCase {
    // MARK: ToyKind

    func testToyKindResolvesUnknownToButton() {
        XCTAssertEqual(ToyKind.resolve(id: nil), .button)
        XCTAssertEqual(ToyKind.resolve(id: "spaceship"), .button)
        XCTAssertEqual(ToyKind.resolve(id: "egg"), .egg)
        XCTAssertEqual(ToyKind.resolve(id: "balloon"), .balloon)
        XCTAssertEqual(ToyKind.resolve(id: "pinata"), .pinata)
        XCTAssertEqual(ToyKind.allCases.count, 4)
    }

    // MARK: Egg

    func testEggHatchesAtDrawnThresholdAndIsDeterministic() {
        // First draw: threshold offset 2 -> 7 taps. Then rarity roll 50 -> common, index 3 -> Sir Crumb.
        var egg = EggToy(random: scripted([2, 50, 3, 0, 10, 0]))
        XCTAssertEqual(egg.tapsToHatch, 7)
        XCTAssertEqual(egg.stage, .intact)
        XCTAssertEqual(egg.tension, 0)

        for n in 1..<7 {
            XCTAssertNil(egg.tap(), "no payoff before the threshold (tap \(n))")
            XCTAssertEqual(egg.tapsThisCycle, n)
            XCTAssertFalse(egg.isResolved)
        }
        let creature = egg.tap()
        XCTAssertEqual(creature?.id, "sircrumb")
        XCTAssertEqual(egg.stage, .hatched(CreatureCatalog.creature(id: "sircrumb")!))
        XCTAssertTrue(egg.isResolved)
        XCTAssertEqual(egg.tension, 1)

        var replay = EggToy(random: scripted([2, 50, 3, 0, 10, 0]))
        var replayed: Creature?
        for _ in 0..<7 { replayed = replay.tap() ?? replayed }
        XCTAssertEqual(replayed?.id, "sircrumb", "same seed, same hatch")
    }

    func testEggStagesProgressInOrder() {
        var egg = EggToy(random: scripted([4, 50, 0])) // 9 taps to hatch
        var seen: [EggStage] = [egg.stage]
        for _ in 0..<9 {
            _ = egg.tap()
            if egg.stage != seen.last { seen.append(egg.stage) }
        }
        XCTAssertEqual(Array(seen.prefix(4)), [.intact, .hairline, .cracked, .shaking])
        if case .hatched = seen.last! {} else { XCTFail("ends hatched, got \(seen.last!)") }
    }

    func testEggThresholdStaysInsideRange() {
        for value in 0..<40 {
            let egg = EggToy(random: scripted([value]))
            XCTAssertTrue(EggToy.hatchTapRange.contains(egg.tapsToHatch), "offset \(value) gave \(egg.tapsToHatch)")
        }
    }

    func testTapOnHatchedEggStartsFreshCycleWithoutWastingTheTap() {
        var egg = EggToy(random: scripted([0, 50, 0, 0, 50, 1])) // 5 taps, then again 5 taps
        for _ in 0..<5 { _ = egg.tap() }
        XCTAssertTrue(egg.isResolved)
        XCTAssertNil(egg.tap())
        XCTAssertFalse(egg.isResolved)
        XCTAssertEqual(egg.tapsThisCycle, 1, "the tap that dismisses the creature is the first tap of the next egg")
        XCTAssertEqual(egg.stage, .hairline)
    }

    func testEggResetReturnsToIntact() {
        var egg = EggToy(random: scripted([0, 50, 0]))
        for _ in 0..<5 { _ = egg.tap() }
        egg.reset()
        XCTAssertEqual(egg.stage, .intact)
        XCTAssertEqual(egg.tapsThisCycle, 0)
        XCTAssertFalse(egg.isResolved)
    }

    func testEggAvoidsHatchingTheSameCreatureTwiceInARow() {
        // Always roll common + index 0: the second hatch must skip the first creature.
        var egg = EggToy(random: scripted([0, 50, 0]))
        var hatched: [String] = []
        for _ in 0..<10 { if let c = egg.tap() { hatched.append(c.id) } }
        XCTAssertEqual(hatched.count, 2)
        XCTAssertNotEqual(hatched[0], hatched[1])
    }

    // MARK: Creature catalog

    func testCreatureCatalogIsCuratedAndUnique() {
        XCTAssertGreaterThanOrEqual(CreatureCatalog.all.count, 12)
        XCTAssertEqual(Set(CreatureCatalog.all.map(\.id)).count, CreatureCatalog.all.count, "ids unique")
        XCTAssertEqual(Set(CreatureCatalog.all.map(\.name)).count, CreatureCatalog.all.count, "names unique")
        for rarity in CreatureRarity.allCases {
            XCTAssertFalse(CreatureCatalog.creatures(of: rarity).isEmpty, "\(rarity) tier has creatures")
        }
        for creature in CreatureCatalog.all {
            XCTAssertFalse(creature.line.isEmpty)
            XCTAssertLessThanOrEqual(creature.line.count, 60, "\(creature.name) line fits the reaction area")
            XCTAssertEqual(creature.line.last.map { ".!?".contains($0) }, true, "\(creature.name) line ends a sentence")
        }
    }

    func testRarityRollBoundaries() {
        XCTAssertEqual(CreatureRarity.forRoll(0), .legendary)
        XCTAssertEqual(CreatureRarity.forRoll(4), .legendary)
        XCTAssertEqual(CreatureRarity.forRoll(5), .rare)
        XCTAssertEqual(CreatureRarity.forRoll(29), .rare)
        XCTAssertEqual(CreatureRarity.forRoll(30), .common)
        XCTAssertEqual(CreatureRarity.forRoll(99), .common)
    }

    func testDrawPicksWithinRolledTier() {
        let legendary = CreatureCatalog.draw(random: scripted([0, 0]))
        XCTAssertEqual(legendary.rarity, .legendary)
        let rare = CreatureCatalog.draw(random: scripted([10, 1]))
        XCTAssertEqual(rare.rarity, .rare)
        let common = CreatureCatalog.draw(random: scripted([99, 99]))
        XCTAssertEqual(common.rarity, .common)
    }

    // MARK: Balloon

    func testBalloonPopsAtHiddenThresholdAndIsDeterministic() {
        var balloon = BalloonToy(random: scripted([3, 4, 0])) // threshold 9, punchline index 4
        XCTAssertEqual(balloon.popThreshold, 9)
        XCTAssertEqual(balloon.tension, 0)
        var lastTension = 0.0
        for n in 1..<9 {
            XCTAssertNil(balloon.tap(), "no pop before the threshold (tap \(n))")
            XCTAssertGreaterThan(balloon.tension, lastTension, "tension rises every tap")
            XCTAssertLessThan(balloon.tension, 1, "tension never reveals the pop")
            lastTension = balloon.tension
        }
        XCTAssertEqual(balloon.tap(), BalloonPunchlines.all[4])
        XCTAssertTrue(balloon.isPopped)
        XCTAssertEqual(balloon.tension, 1)
        XCTAssertEqual(balloon.accessibilityDescription, "Popped")

        var replay = BalloonToy(random: scripted([3, 4, 0]))
        var line: String?
        for _ in 0..<9 { line = replay.tap() ?? line }
        XCTAssertEqual(line, BalloonPunchlines.all[4])
    }

    func testBalloonThresholdStaysInsideRange() {
        for value in 0..<40 {
            let balloon = BalloonToy(random: scripted([value]))
            XCTAssertTrue(BalloonToy.popTapRange.contains(balloon.popThreshold))
        }
    }

    func testTapOnPoppedBalloonStartsFreshCycleWithoutWastingTheTap() {
        var balloon = BalloonToy(random: scripted([0, 0, 0, 0]))
        for _ in 0..<6 { _ = balloon.tap() }
        XCTAssertTrue(balloon.isPopped)
        XCTAssertNil(balloon.tap())
        XCTAssertFalse(balloon.isPopped)
        XCTAssertEqual(balloon.tapsThisCycle, 1)
        XCTAssertEqual(balloon.accessibilityDescription, "Inflated 20 percent")
    }

    func testBalloonAvoidsRepeatingAPunchline() {
        var balloon = BalloonToy(random: scripted([0]))  // threshold 6, always index 0
        var lines: [String] = []
        for _ in 0..<12 { if let l = balloon.tap() { lines.append(l) } }
        XCTAssertEqual(lines.count, 2)
        XCTAssertNotEqual(lines[0], lines[1])
    }

    func testPunchlinesAreCurated() {
        XCTAssertGreaterThanOrEqual(BalloonPunchlines.all.count, 10)
        XCTAssertEqual(Set(BalloonPunchlines.all).count, BalloonPunchlines.all.count)
    }

    // MARK: Session

    private func onMain(_ body: @MainActor () -> Void) { MainActor.assumeIsolated(body) }

    func testSessionDefaultsToButtonAndPersistsSelection() {
        onMain {
            let store = InMemoryStatsStore()
            let session = ToySession(store: store)
            XCTAssertEqual(session.selectedKind, .button)
            XCTAssertNil(session.tapSelected(), "the plain button has no toy payoff")

            session.select(.egg)
            XCTAssertEqual(store.loadSelectedToyID(), "egg")
            XCTAssertEqual(ToySession(store: store).selectedKind, .egg, "selection survives recreation")
        }
    }

    func testSessionRecordsAndPersistsDiscoveredCreatures() {
        onMain {
            let store = InMemoryStatsStore()
            // Draw order: egg threshold (0 -> 5 taps), balloon threshold, hatch rarity roll (50 -> common), index 3.
            let session = ToySession(store: store, random: scripted([0, 5, 50, 3, 0, 0, 10, 1]))
            session.select(.egg)
            var payoffs: [String] = []
            for _ in 0..<5 { if let line = session.tapSelected() { payoffs.append(line) } }
            XCTAssertEqual(payoffs, [CreatureCatalog.creature(id: "sircrumb")!.hatchLine])
            XCTAssertEqual(session.payoffCount, 1)
            XCTAssertEqual(session.discoveredCreatureIDs, ["sircrumb"])
            XCTAssertEqual(store.loadDiscoveredCreatureIDs(), ["sircrumb"])
            XCTAssertTrue(session.isDiscovered(CreatureCatalog.creature(id: "sircrumb")!))

            let relaunched = ToySession(store: store)
            XCTAssertEqual(relaunched.discoveredCreatures.map(\.id), ["sircrumb"])
        }
    }

    func testSessionIgnoresUnknownStoredCreatureIDs() {
        onMain {
            let store = InMemoryStatsStore()
            store.saveDiscoveredCreatureIDs(["blorp", "not-a-creature"])
            XCTAssertEqual(ToySession(store: store).discoveredCreatureIDs, ["blorp"])
        }
    }

    func testSessionClearPayoffResetsOnlyResolvedToys() {
        onMain {
            let session = ToySession(store: InMemoryStatsStore(), random: scripted([0]))
            session.select(.balloon)
            for _ in 0..<6 { session.tapSelected() }
            XCTAssertTrue(session.balloon.isPopped)
            session.clearPayoff()
            XCTAssertFalse(session.balloon.isPopped)
            XCTAssertEqual(session.balloon.tapsThisCycle, 0)
            XCTAssertEqual(session.egg.stage, .intact)
        }
    }

    func testUserDefaultsStoreRoundTripsToyValuesAndTreatsWrongTypesAsDefaults() {
        let defaults = makeIsolatedDefaults(self)
        let store = UserDefaultsStatsStore(defaults: defaults)
        XCTAssertNil(store.loadSelectedToyID())
        XCTAssertEqual(store.loadDiscoveredCreatureIDs(), [])

        store.saveSelectedToyID("balloon")
        store.saveDiscoveredCreatureIDs(["nib", "ulp"])
        let reopened = UserDefaultsStatsStore(defaults: defaults)
        XCTAssertEqual(reopened.loadSelectedToyID(), "balloon")
        XCTAssertEqual(reopened.loadDiscoveredCreatureIDs(), ["nib", "ulp"])

        defaults.set(7, forKey: UserDefaultsStatsStore.toyKey)
        defaults.set("nib", forKey: UserDefaultsStatsStore.creaturesKey)
        XCTAssertNil(store.loadSelectedToyID(), "wrong type reads as missing")
        XCTAssertEqual(store.loadDiscoveredCreatureIDs(), [], "wrong type reads as empty")
    }

    // MARK: HomeViewModel hook

    func testPressToyCountsExactlyOncePerTapAndSurfacesPayoff() {
        onMain {
            let spy = SpyHaptics()
            let store = InMemoryStatsStore()
            let service = PressService(store: store)
            let toys = ToySession(store: store, random: scripted([0]))   // balloon pops on tap 6
            let model = HomeViewModel(service: service, reactions: ReactionEngine(random: scripted([50, 0, 1])), haptics: spy, toys: toys)
            model.toys.select(.balloon)

            for _ in 0..<5 { model.pressToy() }
            XCTAssertEqual(model.stats, PressStats(currentRun: 5, personalBest: 5, totalPresses: 5))
            XCTAssertFalse(model.toys.balloon.isPopped)
            XCTAssertEqual(model.pressCount, 5)

            model.pressToy()
            XCTAssertEqual(model.stats.currentRun, 6, "the pop tap is counted once like any other")
            XCTAssertTrue(model.toys.balloon.isPopped)
            XCTAssertEqual(model.reactionText, model.toys.balloon.punchline)
            XCTAssertTrue(BalloonPunchlines.all.contains(model.reactionText))
            // press 1 (achievement) and press 6 (pop) use the stronger haptic
            XCTAssertEqual(spy.milestoneCount, 2)
            XCTAssertEqual(spy.pressCount, 5)

            model.toys.select(.button)
            model.pressToy()
            XCTAssertEqual(model.stats.currentRun, 7)
            XCTAssertEqual(model.toys.balloon.tapsThisCycle, 6, "the plain button does not touch toy state")
        }
    }

    func testModelBuildsToySessionFromTheServiceStore() {
        onMain {
            let store = InMemoryStatsStore()
            store.saveSelectedToyID("egg")
            store.saveIsPro(true)   // the egg is a Pro toy
            let model = HomeViewModel(service: PressService(store: store))
            XCTAssertEqual(model.toys.selectedKind, .egg)
        }
    }
}

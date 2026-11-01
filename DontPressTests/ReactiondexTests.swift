import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class StoryCatalogTests: XCTestCase {
    private var everyLine: [Reaction] {
        ReactionCatalog.all + Array(ReactionCatalog.milestones.values)
            + Array(StoryCatalog.beats.values) + Array(StoryCatalog.secrets.values) + [StoryCatalog.ending]
    }

    func testAllLinesUniqueAndShort() {
        let all = everyLine
        XCTAssertEqual(Set(all.map(\.id)).count, all.count, "ids unique")
        XCTAssertEqual(Set(all.map(\.text)).count, all.count, "texts unique")
        for line in all {
            XCTAssertFalse(line.text.trimmingCharacters(in: .whitespaces).isEmpty)
            XCTAssertLessThanOrEqual(line.text.count, 80, line.text)
        }
    }

    func testExpansionAddsAtLeastSixtyLines() {
        XCTAssertGreaterThanOrEqual(ReactionCatalog.extended.count, 60)
        XCTAssertGreaterThanOrEqual(ReactionCatalog.all.count, 96 + 60)
        for tier in ReactionTier.allCases {
            XCTAssertFalse(ReactionCatalog.extended.filter { $0.tier == tier && $0.isRare }.isEmpty, "\(tier)")
        }
    }

    func testStoryArcHasTwelveBeatsAvoidingMilestonesAndSecrets() {
        XCTAssertEqual(StoryCatalog.beats.count, 12)
        for run in StoryCatalog.beats.keys {
            XCTAssertNil(Milestone.crossed(from: run - 1, to: run), "beat \(run) collides with a milestone")
            XCTAssertNil(StoryCatalog.secrets[run])
            XCTAssertNotEqual(run, StoryCatalog.endingRun)
            XCTAssertEqual(StoryCatalog.beats[run]?.tier, ReactionTier.tier(forPress: run))
        }
        XCTAssertEqual(StoryCatalog.orderedBeats.map(\.id), (1...12).map { String(format: "story-%02d", $0) })
    }

    func testSecretAndEndingTriggers() {
        for run in [13, 42, 69, 100, 111, 404] {
            let special = StoryCatalog.special(forRun: run)
            XCTAssertEqual(special?.kind, .secret, "\(run)")
            XCTAssertEqual(special?.reaction.id, "secret-\(run)")
            XCTAssertEqual(StoryCatalog.runCount(forSpecialID: "secret-\(run)"), run)
        }
        XCTAssertEqual(StoryCatalog.special(forRun: 1000), SpecialReaction(reaction: StoryCatalog.ending, kind: .ending))
        XCTAssertEqual(StoryCatalog.endingName, "The Long Press Home")
        XCTAssertEqual(StoryCatalog.special(forRun: 5)?.kind, .story)
        for run in [0, -1, 1, 10, 12, 14, 41, 43, 99, 101, 999, 1001, Int.max] {
            XCTAssertNil(StoryCatalog.special(forRun: run), "\(run)")
        }
        XCTAssertEqual(StoryCatalog.supersededMilestones, [100, 1000])
    }

    func testSpecialLinesOverrideMilestonesAndNormalLines() {
        var engine = ReactionEngine(random: scripted([50, 0]))
        XCTAssertEqual(engine.storyAwareReaction(forRun: 10, milestone: 10).id, "milestone-10")
        XCTAssertEqual(engine.storyAwareReaction(forRun: 100, milestone: 100).id, "secret-100")
        XCTAssertEqual(engine.storyAwareReaction(forRun: 1000, milestone: 1000).id, StoryCatalog.ending.id)
        XCTAssertEqual(engine.storyAwareReaction(forRun: 13, milestone: nil).id, "secret-13")
        XCTAssertEqual(engine.storyAwareReaction(forRun: 3, milestone: nil).tier, .mild)
    }

    func testFullRunNeverRepeatsBackToBackAndTellsStoryInOrder() {
        var engine = ReactionEngine(random: { _ in 0 }) // worst case for repetition
        var previous: String?
        var storySeen: [String] = []
        for run in 1...1_200 {
            let line = engine.storyAwareReaction(forRun: run, milestone: Milestone.crossed(from: run - 1, to: run))
            XCTAssertNotEqual(line.id, previous, "repeat at \(run)")
            previous = line.id
            if line.id.hasPrefix("story-") { storySeen.append(line.id) }
        }
        XCTAssertEqual(storySeen, StoryCatalog.orderedBeats.map(\.id), "each beat once, in order")
    }

    func testStoryLinesAreNotInTheRandomPool() {
        let poolIDs = Set(ReactionCatalog.all.map(\.id))
        for line in StoryCatalog.beats.values { XCTAssertFalse(poolIDs.contains(line.id)) }
        for line in StoryCatalog.secrets.values { XCTAssertFalse(poolIDs.contains(line.id)) }
        XCTAssertFalse(poolIDs.contains(StoryCatalog.ending.id))
    }
}

final class ReactiondexTests: XCTestCase {
    private func onMain(_ body: @MainActor () -> Void) { MainActor.assumeIsolated(body) }

    func testInitiallyEmpty() {
        let dex = Reactiondex()
        XCTAssertEqual(dex.discoveredCount, 0)
        XCTAssertEqual(dex.rareFoundCount, 0)
        XCTAssertGreaterThanOrEqual(dex.totalCount, 120)
        XCTAssertEqual(dex.entries.count, dex.totalCount)
        XCTAssertTrue(dex.entries.allSatisfy { !$0.isDiscovered })
        XCTAssertFalse(dex.hasReachedEnding)
    }

    func testCollectiblesUniqueAndCompleteExceptSupersededMilestones() {
        let ids = Reactiondex.collectibles.map(\.reaction.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertFalse(Reactiondex.collectibleIDs.contains("milestone-100"))
        XCTAssertFalse(Reactiondex.collectibleIDs.contains("milestone-1000"))
        XCTAssertTrue(Reactiondex.collectibleIDs.contains("milestone-10"))
        XCTAssertEqual(Reactiondex.collectibles.filter { $0.kind == .story }.count, 12)
        XCTAssertEqual(Reactiondex.collectibles.filter { $0.kind == .secret }.count, 6)
        XCTAssertEqual(Reactiondex.collectibles.filter { $0.kind == .ending }.count, 1)
        XCTAssertFalse(Reactiondex.collectibleIDs.contains(ReactionCatalog.fallback.id))
    }

    func testRecordReportsNewOnlyOnce() {
        var dex = Reactiondex()
        XCTAssertTrue(dex.record("mild-01"))
        XCTAssertFalse(dex.record("mild-01"))
        XCTAssertEqual(dex.discoveredCount, 1)
        XCTAssertFalse(dex.record("not-a-line"))
        XCTAssertFalse(dex.record(ReactionCatalog.fallback.id))
        XCTAssertEqual(dex.discoveredCount, 1)
    }

    func testUnknownAndDuplicateStoredIDsAreIgnored() {
        let dex = Reactiondex(discoveredIDs: ["mild-01", "mild-01", "gone-forever", "", "secret-42"])
        XCTAssertEqual(dex.discoveredCount, 2)
        XCTAssertEqual(dex.persistableIDs, ["mild-01", "secret-42"])
    }

    func testPerTierKindAndRareProgress() {
        var dex = Reactiondex()
        dex.record("mild-01")
        dex.record("mild-rare-01")
        dex.record("secret-13")       // concern tier, rare
        dex.record("story-01")        // sarcasm tier
        dex.record(StoryCatalog.ending.id)
        let mildTotal = Reactiondex.collectibles.filter { $0.reaction.tier == .mild }.count
        XCTAssertEqual(dex.progress(for: .mild), ReactiondexProgress(discovered: 2, total: mildTotal))
        XCTAssertEqual(dex.progress(for: .concern).discovered, 1)
        XCTAssertEqual(dex.progress(for: .sarcasm).discovered, 1)
        XCTAssertEqual(dex.progress(for: .secret), ReactiondexProgress(discovered: 1, total: 6))
        XCTAssertEqual(dex.progress(for: .story), ReactiondexProgress(discovered: 1, total: 12))
        XCTAssertEqual(dex.rareFoundCount, 3)
        XCTAssertTrue(dex.hasReachedEnding)
        let tierSum = ReactionTier.allCases.map { dex.progress(for: $0).total }.reduce(0, +)
        XCTAssertEqual(tierSum, dex.totalCount, "every collectible belongs to exactly one tier")
        XCTAssertEqual(dex.progress, ReactiondexProgress(discovered: 5, total: dex.totalCount))
    }

    func testUserDefaultsPersistenceAndCorruptValues() {
        let defaults = makeIsolatedDefaults(self)
        let store = UserDefaultsStatsStore(defaults: defaults)
        XCTAssertEqual(store.loadDiscoveredReactionIDs(), [])
        store.saveDiscoveredReactionIDs(["b", "a", "a"])
        XCTAssertEqual(UserDefaultsStatsStore(defaults: defaults).loadDiscoveredReactionIDs(), ["a", "b"])

        defaults.set(42, forKey: UserDefaultsStatsStore.discoveredReactionsKey)
        XCTAssertEqual(store.loadDiscoveredReactionIDs(), [])
        defaults.set("mild-01", forKey: UserDefaultsStatsStore.discoveredReactionsKey)
        XCTAssertEqual(store.loadDiscoveredReactionIDs(), [])
        defaults.set([1, 2], forKey: UserDefaultsStatsStore.discoveredReactionsKey)
        XCTAssertEqual(store.loadDiscoveredReactionIDs(), [])
    }

    func testInMemoryStoreDeduplicates() {
        let store = InMemoryStatsStore()
        store.saveDiscoveredReactionIDs(["x", "x", "y"])
        XCTAssertEqual(store.loadDiscoveredReactionIDs(), ["x", "y"])
    }

    func testViewModelRecordsEachPressAndFlagsNewDiscoveries() {
        onMain {
            let store = InMemoryStatsStore()
            let model = HomeViewModel(service: PressService(store: store), reactions: ReactionEngine(random: scripted([50, 0, 1])))
            XCTAssertFalse(model.isNewDiscovery)
            model.press()
            XCTAssertTrue(model.isNewDiscovery)
            XCTAssertEqual(model.reactiondex.discoveredCount, 1)
            XCTAssertEqual(store.loadDiscoveredReactionIDs().count, 1)
            for _ in 0..<12 { model.press() }
            XCTAssertEqual(model.reactionText, StoryCatalog.secrets[13]?.text)
            XCTAssertTrue(model.reactiondex.isDiscovered("secret-13"))
            XCTAssertTrue(model.reactiondex.isDiscovered("story-01"))
            XCTAssertTrue(model.reactiondex.isDiscovered("milestone-10"))
            XCTAssertEqual(model.stats.currentRun, 13, "discovery never affects counting")

            // A new process restores discoveries but not the run.
            let relaunched = HomeViewModel(service: PressService(store: store))
            XCTAssertEqual(relaunched.reactiondex, model.reactiondex)
            XCTAssertEqual(relaunched.stats.currentRun, 0)
        }
    }

    func testRepeatedLineIsNotNew() {
        onMain {
            // The first press always shows a mild line; seed it as already discovered.
            let store = InMemoryStatsStore()
            store.saveDiscoveredReactionIDs(ReactionCatalog.all.filter { $0.tier == .mild }.map(\.id))
            let model = HomeViewModel(service: PressService(store: store), reactions: ReactionEngine(random: scripted([50, 0, 1])))
            model.press()
            XCTAssertFalse(model.isNewDiscovery)
        }
    }

    func testReachingTheEndingInOneRun() {
        onMain {
            let spy = SpyHaptics()
            let model = HomeViewModel(service: PressService(store: InMemoryStatsStore()), reactions: ReactionEngine(random: scripted([50, 3, 7])), haptics: spy)
            for _ in 0..<1_000 { model.press() }
            XCTAssertEqual(model.reactionText, StoryCatalog.ending.text)
            XCTAssertTrue(model.reactiondex.hasReachedEnding)
            XCTAssertEqual(model.reactiondex.progress(for: .story).discovered, 12)
            XCTAssertEqual(model.reactiondex.progress(for: .secret).discovered, 6)
            XCTAssertEqual(spy.pressCount + spy.milestoneCount, 1_000, "exactly one haptic per press")
        }
    }
}

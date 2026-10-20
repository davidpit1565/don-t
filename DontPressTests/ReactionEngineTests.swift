import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class ReactionEngineTests: XCTestCase {
    func testAtLeastEightyCuratedReactions() {
        XCTAssertGreaterThanOrEqual(ReactionCatalog.all.count, 80)
    }

    func testCatalogIsCleanAndUnique() {
        let all = ReactionCatalog.all + Array(ReactionCatalog.milestones.values)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count, "ids unique")
        XCTAssertEqual(Set(all.map(\.text)).count, all.count, "texts unique")
        for reaction in all {
            XCTAssertFalse(reaction.text.trimmingCharacters(in: .whitespaces).isEmpty)
            XCTAssertLessThanOrEqual(reaction.text.count, 80, "short enough for two lines: \(reaction.text)")
        }
    }

    func testEveryTierHasEnoughCommonAndSomeRareLines() {
        for tier in ReactionTier.allCases {
            let inTier = ReactionCatalog.all.filter { $0.tier == tier }
            XCTAssertGreaterThanOrEqual(inTier.filter { !$0.isRare }.count, 8, "\(tier)")
            XCTAssertFalse(inTier.filter(\.isRare).isEmpty, "\(tier) has rare lines")
        }
    }

    func testEveryMilestoneHasALine() {
        for threshold in Milestone.thresholds {
            XCTAssertNotNil(ReactionCatalog.milestones[threshold], "\(threshold)")
        }
    }

    func testTierRanges() {
        let expectations: [(Int, ReactionTier)] = [
            (1, .mild), (3, .mild), (4, .sarcasm), (10, .sarcasm), (11, .concern), (25, .concern),
            (26, .absurd), (50, .absurd), (51, .dramatic), (100, .dramatic), (101, .legendary), (5_000, .legendary),
            (Int.max, .legendary), (0, .mild), (-4, .mild),
        ]
        for (count, tier) in expectations {
            XCTAssertEqual(ReactionTier.tier(forPress: count), tier, "press \(count)")
        }
    }

    func testReactionComesFromTheMatchingTier() {
        var engine = ReactionEngine(random: scripted([50, 3, 7, 1]))
        for count in [1, 5, 12, 30, 60, 150] {
            XCTAssertEqual(engine.reaction(forPress: count).tier, ReactionTier.tier(forPress: count))
        }
    }

    func testNeverImmediatelyRepeats() {
        // A "random" that always picks index 0 would repeat forever without avoidance.
        var engine = ReactionEngine(random: { _ in 0 })
        var previous: String?
        for _ in 0..<50 {
            let id = engine.reaction(forPress: 2).id
            XCTAssertNotEqual(id, previous)
            previous = id
        }
    }

    func testNeverRepeatsWithSystemRandomness() {
        var engine = ReactionEngine()
        var last: String?
        for _ in 0..<2_000 {
            let id = engine.reaction(forPress: 30).id
            XCTAssertNotEqual(id, last)
            last = id
        }
    }

    func testRareLinesAreDeterministicallyReachable() {
        // random(100) == 0 < 12 → rare pool; then index 0.
        var engine = ReactionEngine(random: scripted([0, 0]))
        XCTAssertTrue(engine.reaction(forPress: 2).isRare)
        // random(100) == 50 ≥ 12 → common pool.
        var common = ReactionEngine(random: scripted([50, 0]))
        XCTAssertFalse(common.reaction(forPress: 2).isRare)
    }

    func testSameScriptGivesSameSequence() {
        var a = ReactionEngine(random: scripted([40, 3, 55, 9, 71, 2]))
        var b = ReactionEngine(random: scripted([40, 3, 55, 9, 71, 2]))
        for press in 1...40 { XCTAssertEqual(a.reaction(forPress: press), b.reaction(forPress: press)) }
    }

    func testOutOfRangeRandomIsClamped() {
        var engine = ReactionEngine(random: { _ in 10_000 })
        XCTAssertFalse(engine.reaction(forPress: 1).text.isEmpty)
        var negative = ReactionEngine(random: { _ in -5 })
        XCTAssertFalse(negative.reaction(forPress: 1).text.isEmpty)
    }

    func testMilestoneReactionIsRemembered() {
        var engine = ReactionEngine(random: scripted([50, 0]))
        let line = engine.reaction(forMilestone: 10)
        XCTAssertEqual(line.id, "milestone-10")
        XCTAssertEqual(engine.lastReactionID, "milestone-10")
    }

    func testEmptyCatalogFallsBack() {
        var engine = ReactionEngine(catalog: [])
        XCTAssertEqual(engine.reaction(forPress: 1), ReactionCatalog.fallback)
    }
}

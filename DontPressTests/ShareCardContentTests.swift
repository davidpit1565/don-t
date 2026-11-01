import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class ShareCardContentTests: XCTestCase {
    private let us = Locale(identifier: "en_US")

    func testNothingToShareAtZero() {
        XCTAssertNil(ShareCardContent.make(personalBest: 0, locale: us))
        XCTAssertNil(ShareCardContent.make(personalBest: -3, locale: us))
    }

    func testContentUsesTheRealPersonalBest() throws {
        let content = try XCTUnwrap(ShareCardContent.make(personalBest: 847, locale: us))
        XCTAssertEqual(content.title, "DON'T PRESS")
        XCTAssertEqual(content.caption, "PERSONAL BEST")
        XCTAssertEqual(content.countText, "847")
        XCTAssertEqual(content.unitText, "PRESSES")
        XCTAssertEqual(content.quote, "“You were told not to.”")
        XCTAssertEqual(content.footnote, "“Officially unnecessary. Impressively committed.”")
    }

    func testSingularUnit() throws {
        XCTAssertEqual(try XCTUnwrap(ShareCardContent.make(personalBest: 1, locale: us)).unitText, "PRESS")
    }

    func testGroupingAndHugeValues() throws {
        XCTAssertEqual(try XCTUnwrap(ShareCardContent.make(personalBest: 1_234_567, locale: us)).countText, "1,234,567")
        XCTAssertEqual(ShareCardContent.formatCount(Int.max, locale: us), "9,223,372,036,854,775,807")
    }

    func testEveryBandHasLinesAndNoWorldRankingClaims() throws {
        for best in [1, 9, 10, 24, 25, 49, 50, 99, 100, 499, 500, 999, 1_000, 10_000] {
            // v2: every piece of text on the card is checked, including title, streak and signature line.
            let content = try XCTUnwrap(ShareCardContent.make(
                personalBest: best, totalPresses: best * 30, dayNumber: 312, streak: 7,
                signatureLine: ReactionCatalog.all.last?.text, locale: us
            ))
            XCTAssertFalse(content.quote.isEmpty)
            XCTAssertFalse(content.footnote.isEmpty)
            let text = content.allText.joined(separator: " ").lowercased()
            for banned in ["world", "global", "rank", "#1", "top ", "best in", "leaderboard", "http", "www.", "apps.apple.com"] {
                XCTAssertFalse(text.contains(banned), "\(best): \(banned)")
            }
        }
        for level in RarityTitle.levels {
            for banned in ["world", "global", "rank", "#1", "top "] {
                XCTAssertFalse(level.title.lowercased().contains(banned))
            }
        }
    }

    // MARK: v2

    func testV2DefaultsKeepTheCardMinimal() throws {
        let content = try XCTUnwrap(ShareCardContent.make(personalBest: 847, locale: us))
        XCTAssertNil(content.dayText)
        XCTAssertNil(content.streakText)
        XCTAssertNil(content.totalText)
        XCTAssertNil(content.signatureLine)
        XCTAssertEqual(content.callToAction, "Can you beat my 847?")
        XCTAssertEqual(content.storeHint, "Search DontPress on the App Store")
        XCTAssertEqual(content.rarityTitle, "Unstoppable Nuisance")
    }

    func testV2FullContent() throws {
        let content = try XCTUnwrap(ShareCardContent.make(
            personalBest: 30, totalPresses: 1_234, dayNumber: 312, streak: 7,
            signatureLine: "The button would like a word.", locale: us
        ))
        XCTAssertEqual(content.rarityTitle, "Professional Disobeyer")   // total 1,234 outranks run 30
        XCTAssertEqual(content.dayText, "DAY 312")
        XCTAssertEqual(content.streakText, "7-DAY STREAK")
        XCTAssertEqual(content.totalText, "1,234 TOTAL PRESSES")
        XCTAssertEqual(content.signatureLine, "“The button would like a word.”")
        XCTAssertEqual(content.callToAction, "Can you beat my 30?")
        XCTAssertTrue(content.accessibilityDescription.contains("Professional Disobeyer"))
        XCTAssertTrue(content.accessibilityDescription.contains("7-day streak"))
    }

    func testV2OptionalPartsAreDroppedWhenMeaningless() throws {
        let content = try XCTUnwrap(ShareCardContent.make(
            personalBest: 5, totalPresses: 2, dayNumber: 0, streak: 0, signatureLine: "", locale: us
        ))
        XCTAssertNil(content.dayText, "no day before the epoch")
        XCTAssertNil(content.streakText)
        XCTAssertNil(content.signatureLine)
        XCTAssertEqual(content.totalText, "5 TOTAL PRESSES", "total can never be below the best run")
    }

    func testRarityTitleThresholds() {
        XCTAssertEqual(RarityTitle.title(bestRun: 1, total: 1), "Casual Offender")
        XCTAssertEqual(RarityTitle.title(bestRun: 0, total: 0), "Casual Offender")
        XCTAssertEqual(RarityTitle.title(bestRun: 10, total: 10), "Repeat Offender")
        XCTAssertEqual(RarityTitle.title(bestRun: 25, total: 25), "Certified Menace")
        XCTAssertEqual(RarityTitle.title(bestRun: 3, total: 250), "Certified Menace")
        XCTAssertEqual(RarityTitle.title(bestRun: Int.max, total: Int.max), "Mythical Menace")
        XCTAssertEqual(Set(RarityTitle.levels.map(\.title)).count, RarityTitle.levels.count)
    }

    func testHugeValuesFormatOnTheCard() throws {
        let content = try XCTUnwrap(ShareCardContent.make(personalBest: Int.max, totalPresses: Int.max, dayNumber: Int.max, streak: Int.max, locale: us))
        XCTAssertEqual(content.countText, "9,223,372,036,854,775,807")
        XCTAssertEqual(content.callToAction, "Can you beat my 9,223,372,036,854,775,807?")
    }

    func testDailyShareContentHasNoSpoilers() throws {
        let challenge = DailyChallenge(day: DayStamp(index: DailyChallenge.epoch.index + 311), kind: .exactly(13))
        func snapshot(_ presses: Int, streak: Int = 3) -> DailySnapshot {
            DailySnapshot(challenge: challenge, pressesToday: presses, result: challenge.evaluate(presses: presses),
                          streak: streak, bestStreak: streak, hasFreeze: true, isRelyingOnFreeze: false)
        }
        XCTAssertNil(DailyShareContent.make(snapshot: snapshot(0), locale: us), "nothing to share before playing")

        let won = try XCTUnwrap(DailyShareContent.make(snapshot: snapshot(13), locale: us))
        XCTAssertEqual(won.dayText, "DAILY #312")
        XCTAssertEqual(won.resultTitle, "CHALLENGE COMPLETE")
        XCTAssertEqual(won.streakText, "3-DAY STREAK")
        let lost = try XCTUnwrap(DailyShareContent.make(snapshot: snapshot(14, streak: 0), locale: us))
        XCTAssertEqual(lost.resultTitle, "CHALLENGE FAILED")
        XCTAssertNil(lost.streakText)

        for content in [won, lost] {
            let text = content.allText.joined(separator: " ").lowercased()
            XCTAssertFalse(text.contains("13"), "the target must not leak")
            XCTAssertFalse(text.contains("14"))
            XCTAssertFalse(text.contains(challenge.title.lowercased()))
            for banned in ["world", "global", "rank", "#1 ", "top ", "http"] {
                XCTAssertFalse(text.contains(banned), banned)
            }
        }
    }

    func testAccessibilityDescriptionMentionsCount() throws {
        let content = try XCTUnwrap(ShareCardContent.make(personalBest: 12, locale: us))
        XCTAssertTrue(content.accessibilityDescription.contains("12 presses"))
    }
}

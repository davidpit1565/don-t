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
            let content = try XCTUnwrap(ShareCardContent.make(personalBest: best, locale: us))
            XCTAssertFalse(content.quote.isEmpty)
            XCTAssertFalse(content.footnote.isEmpty)
            let text = (content.quote + content.footnote).lowercased()
            for banned in ["world", "global", "rank", "#1", "top "] {
                XCTAssertFalse(text.contains(banned), "\(best): \(banned)")
            }
        }
    }

    func testAccessibilityDescriptionMentionsCount() throws {
        let content = try XCTUnwrap(ShareCardContent.make(personalBest: 12, locale: us))
        XCTAssertTrue(content.accessibilityDescription.contains("12 presses"))
    }
}

#if canImport(UIKit)
import XCTest
@testable import DontPress

/// Renders the real share card with ImageRenderer and checks the produced image.
final class ShareCardRenderTests: XCTestCase {
    func testShareCardRendersPortraitImageAndAttachesIt() throws {
        let content = try XCTUnwrap(ShareCardContent.make(personalBest: 847, locale: Locale(identifier: "en_US")))
        let image = try XCTUnwrap(MainActor.assumeIsolated { ShareImageRenderer.render(content) })
        XCTAssertEqual(image.size.width, 1080, accuracy: 0.5)
        XCTAssertEqual(image.size.height, 1350, accuracy: 0.5)

        let png = try XCTUnwrap(image.pngData())
        XCTAssertGreaterThan(png.count, 10_000, "image should not be blank")
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = "07-share-card-847"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testHugeCountStillRenders() throws {
        let content = try XCTUnwrap(ShareCardContent.make(personalBest: Int.max, locale: Locale(identifier: "en_US")))
        let image = try XCTUnwrap(MainActor.assumeIsolated { ShareImageRenderer.render(content) })
        XCTAssertEqual(image.size.height, 1350, accuracy: 0.5)
        let attachment = XCTAttachment(data: try XCTUnwrap(image.pngData()), uniformTypeIdentifier: "public.png")
        attachment.name = "08-share-card-huge"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testFullV2CardWithHugeNumbersRenders() throws {
        let content = try XCTUnwrap(ShareCardContent.make(
            personalBest: Int.max, totalPresses: Int.max, dayNumber: 9_999, streak: Int.max,
            signatureLine: "One thousand. Officially unnecessary. Impressively committed.",
            locale: Locale(identifier: "en_US")
        ))
        let image = try XCTUnwrap(MainActor.assumeIsolated { ShareImageRenderer.render(content) })
        XCTAssertEqual(image.size.width, 1080, accuracy: 0.5)
        XCTAssertEqual(image.size.height, 1350, accuracy: 0.5)
        let attachment = XCTAttachment(data: try XCTUnwrap(image.pngData()), uniformTypeIdentifier: "public.png")
        attachment.name = "09-share-card-v2-full"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testDailyNoSpoilerCardRenders() throws {
        let challenge = DailyChallenge(day: DayStamp(index: DailyChallenge.epoch.index + 311), kind: .exactly(13))
        let snapshot = DailySnapshot(challenge: challenge, pressesToday: 13, result: .success,
                                     streak: 12, bestStreak: 12, hasFreeze: true, isRelyingOnFreeze: false)
        let content = try XCTUnwrap(DailyShareContent.make(snapshot: snapshot, locale: Locale(identifier: "en_US")))
        let image = try XCTUnwrap(MainActor.assumeIsolated { ShareImageRenderer.render(content) })
        XCTAssertEqual(image.size.width, 1080, accuracy: 0.5)
        XCTAssertEqual(image.size.height, 1350, accuracy: 0.5)
        let attachment = XCTAttachment(data: try XCTUnwrap(image.pngData()), uniformTypeIdentifier: "public.png")
        attachment.name = "10-share-card-daily"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
#endif

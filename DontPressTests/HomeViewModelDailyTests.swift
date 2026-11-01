import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

/// The daily/streak hook in HomeViewModel observes presses but never changes counting.
final class HomeViewModelDailyTests: XCTestCase {
    private func onMain(_ body: @MainActor () -> Void) { MainActor.assumeIsolated(body) }

    func testWithoutTrackerNothingChanges() {
        onMain {
            let model = HomeViewModel(service: PressService(store: InMemoryStatsStore()))
            model.press()
            XCTAssertNil(model.daily)
            XCTAssertNil(model.dailyShareContent)
            XCTAssertNil(model.shareContent?.dayText)
        }
    }

    func testPressFeedsDailyTrackerAndShareCard() {
        onMain {
            let store = InMemoryStatsStore()
            let clock = dailyTestDate(2026, 3, 10)
            let tracker = DailyTracker(store: store, calendar: { dailyTestCalendar("UTC") }, now: { clock })
            let model = HomeViewModel(service: PressService(store: store), reactions: ReactionEngine(random: scripted([50, 0, 1])), daily: tracker)
            XCTAssertEqual(model.daily?.pressesToday, 0)

            for _ in 0..<5 { model.press() }
            XCTAssertEqual(model.stats, PressStats(currentRun: 5, personalBest: 5, totalPresses: 5), "counting unchanged")
            XCTAssertEqual(model.daily?.pressesToday, 5)
            XCTAssertEqual(model.daily?.streak, 1)
            XCTAssertNotNil(tracker.signatureReaction)

            let card = model.shareContent
            XCTAssertEqual(card?.dayText, "DAY \(DailyChallenge(date: clock, calendar: dailyTestCalendar()).dayNumber)")
            XCTAssertEqual(card?.streakText, "1-DAY STREAK")
            XCTAssertNotNil(card?.signatureLine)
            XCTAssertNotNil(model.dailyShareContent)
        }
    }

    func testCompletingTheChallengeShowsAMessageOnce() {
        onMain {
            let store = InMemoryStatsStore()
            // Find a day in March 2026 with an "exactly" challenge.
            let day = (1...31).map { dailyTestDate(2026, 3, $0) }.first {
                if case .exactly = DailyChallenge(date: $0, calendar: dailyTestCalendar()).kind { return true }
                return false
            }!
            let tracker = DailyTracker(store: store, calendar: { dailyTestCalendar("UTC") }, now: { day })
            let model = HomeViewModel(service: PressService(store: store), daily: tracker)
            let target = model.daily!.challenge.target
            for _ in 0..<(target - 1) { model.press() }
            model.dismissUnlockMessage()
            model.press()
            XCTAssertEqual(model.daily?.result, .success)
            XCTAssertTrue(model.unlockMessage?.contains("Daily challenge complete") ?? false)
            model.dismissUnlockMessage()
            model.press()
            XCTAssertEqual(model.daily?.result, .fail)
            XCTAssertFalse(model.unlockMessage?.contains("Daily challenge complete") ?? false)
        }
    }
}

import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

/// The Pro-nudge hooks observe presses but never change counting, and never show during tapping.
final class HomeViewModelNudgeTests: XCTestCase {
    private func onMain(_ body: @MainActor () -> Void) { MainActor.assumeIsolated(body) }

    private final class Clock { var now = Date(timeIntervalSince1970: 1_800_000_000) }

    @MainActor private func makeModel(clock: Clock, store: InMemoryStatsStore = InMemoryStatsStore(), launches: Int = 4,
                                      daily: DailyTracker? = nil) -> HomeViewModel {
        let nudges = ProNudgeScheduler(store: store, clock: { clock.now })
        for _ in 0..<launches { nudges.registerLaunch() }
        return HomeViewModel(service: PressService(store: store), daily: daily, nudges: nudges)
    }

    func testWithoutSchedulerNothingHappens() {
        onMain {
            let model = HomeViewModel(service: PressService(store: InMemoryStatsStore()))
            model.offerProMoment(.dailyChallengeCompleted)
            model.checkForNudge()
            model.showProNudge(for: .buttonStyle)
            XCTAssertNil(model.pendingNudge)
        }
    }

    func testMomentWaitsForTappingToStopAndCountingIsExact() {
        onMain {
            let clock = Clock()
            let model = makeModel(clock: clock)
            model.offerProMoment(.toyUnlockedByPlay(.egg))
            for _ in 0..<200 {
                model.press()
                model.checkForNudge() // even if the view asked mid-tapping
                XCTAssertNil(model.pendingNudge)
                clock.now += 0.05
            }
            XCTAssertEqual(model.stats, PressStats(currentRun: 200, personalBest: 200, totalPresses: 200))
            clock.now += 3
            model.checkForNudge()
            XCTAssertEqual(model.pendingNudge?.moment, .toyUnlockedByPlay(.egg))
            // Pressing with the card visible still counts exactly once per press.
            model.press()
            XCTAssertEqual(model.stats.totalPresses, 201)
        }
    }

    func testDailyCompletionOffersAMoment() {
        onMain {
            let store = InMemoryStatsStore()
            let day = (1...31).map { dailyTestDate(2026, 3, $0) }.first {
                if case .exactly = DailyChallenge(date: $0, calendar: dailyTestCalendar()).kind { return true }
                return false
            }!
            let clock = Clock()
            let tracker = DailyTracker(store: store, calendar: { dailyTestCalendar("UTC") }, now: { day })
            let model = makeModel(clock: clock, store: store, daily: tracker)
            let target = model.daily!.challenge.target
            for _ in 0..<target { model.press() }
            XCTAssertEqual(model.daily?.result, .success)
            clock.now += 3
            model.checkForNudge()
            XCTAssertEqual(model.pendingNudge?.moment, .dailyChallengeCompleted)
        }
    }

    func testNotNowAndOptOutCloseTheCard() {
        onMain {
            let clock = Clock()
            let store = InMemoryStatsStore()
            let model = makeModel(clock: clock, store: store)
            model.offerProMoment(.dailyChallengeCompleted)
            model.checkForNudge()
            XCTAssertNotNil(model.pendingNudge)
            model.nudgeNotNow()
            XCTAssertNil(model.pendingNudge)
            XCTAssertEqual(store.proNudgeState.notNowCount, 1)

            model.showProNudge(for: .appIcon)
            XCTAssertTrue(model.pendingNudge?.isUserInitiated ?? false)
            model.nudgeOptOut()
            XCTAssertNil(model.pendingNudge)
            XCTAssertTrue(store.proNudgeState.optedOut)

            model.showProNudge(for: .toy(.balloon))
            XCTAssertNotNil(model.pendingNudge, "locked taps still explain Pro after opting out")
            model.nudgeSeePro()
            XCTAssertNil(model.pendingNudge)
        }
    }

    func testBecomingProClearsAndBlocksNudges() {
        onMain {
            let clock = Clock()
            let model = makeModel(clock: clock)
            model.showProNudge(for: .buttonStyle)
            XCTAssertNotNil(model.pendingNudge)
            model.setPro(true)
            XCTAssertNil(model.pendingNudge)
            model.offerProMoment(.dailyChallengeCompleted)
            model.checkForNudge()
            model.showProNudge(for: .buttonStyle)
            XCTAssertNil(model.pendingNudge)
        }
    }

    func testExistingCardIsNeverReplacedAutomatically() {
        onMain {
            let clock = Clock()
            let model = makeModel(clock: clock)
            model.showProNudge(for: .appIcon)
            let shown = model.pendingNudge
            model.offerProMoment(.dailyChallengeCompleted)
            model.checkForNudge()
            XCTAssertEqual(model.pendingNudge, shown)
        }
    }
}

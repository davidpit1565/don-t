import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class StreakTrackerTests: XCTestCase {
    private func day(_ n: Int) -> DayStamp { DayStamp(index: 20_000 + n) }

    private func play(_ days: [Int], from state: StreakState = StreakState()) -> StreakState {
        days.reduce(state) { StreakTracker.recordPlay($0, on: day($1)) }
    }

    func testFirstPlayStartsAtOne() {
        let state = play([0])
        XCTAssertEqual(state.current, 1)
        XCTAssertEqual(state.best, 1)
        XCTAssertEqual(StreakTracker.displayedStreak(StreakState(), on: day(0)), 0)
    }

    func testSameDayIsIdempotent() {
        XCTAssertEqual(play([0, 0, 0]).current, 1)
    }

    func testConsecutiveDays() {
        let state = play([0, 1, 2, 3])
        XCTAssertEqual(state.current, 4)
        XCTAssertEqual(state.best, 4)
        XCTAssertEqual(StreakTracker.displayedStreak(state, on: day(3)), 4)
        XCTAssertEqual(StreakTracker.displayedStreak(state, on: day(4)), 4, "alive until the end of the next day")
    }

    func testOneMissedDayUsesAFreeze() {
        let state = play([0, 1, 3])
        XCTAssertEqual(state.current, 3)
        XCTAssertEqual(state.lastFreezeDay, day(2).index)
    }

    func testOnlyOneFreezePerSevenDays() {
        // Freeze used on day 2; missing day 5 cannot be covered (only 3 days later).
        let state = play([0, 1, 3, 4, 6])
        XCTAssertEqual(state.current, 1)
        XCTAssertEqual(state.best, 4)
        // After seven days a new freeze is available again.
        let later = play([0, 1, 3, 4, 5, 6, 7, 8, 10])
        XCTAssertEqual(later.lastFreezeDay, day(9).index)
        XCTAssertEqual(later.current, 9)
    }

    func testTwoMissedDaysResets() {
        let state = play([0, 1, 4])
        XCTAssertEqual(state.current, 1)
        XCTAssertEqual(state.best, 2)
    }

    func testDisplayedStreakExpires() {
        let state = play([0, 1])
        XCTAssertEqual(StreakTracker.displayedStreak(state, on: day(3)), 2, "freeze would cover day 2")
        XCTAssertTrue(StreakTracker.isRelyingOnFreeze(state, on: day(3)))
        XCTAssertEqual(StreakTracker.displayedStreak(state, on: day(4)), 0)
    }

    func testSmallBackwardMoveIsIgnored() {
        let state = play([0, 1, 2])
        let after = StreakTracker.recordPlay(state, on: day(1))  // time-zone hop west
        XCTAssertEqual(after, state)
        XCTAssertEqual(StreakTracker.displayedStreak(state, on: day(1)), 3)
    }

    func testLargeBackwardMoveRestartsWithoutTrapping() {
        // Clock was far in the future, then corrected.
        let state = play([500, 501, 502])
        let corrected = StreakTracker.recordPlay(state, on: day(0))
        XCTAssertEqual(corrected.current, 1)
        XCTAssertEqual(corrected.lastPlayedDay, day(0).index)
        XCTAssertEqual(corrected.best, 3, "best survives")
        XCTAssertEqual(StreakTracker.recordPlay(corrected, on: day(1)).current, 2, "and it can grow again")
    }

    func testCorruptStateIsSanitized() {
        let corrupt = StreakState(lastPlayedDay: day(0).index, current: -4, best: -9, lastFreezeDay: day(900).index)
        XCTAssertEqual(StreakTracker.displayedStreak(corrupt, on: day(0)), 0)
        let next = StreakTracker.recordPlay(corrupt, on: day(2))
        XCTAssertGreaterThanOrEqual(next.current, 1)
        XCTAssertGreaterThanOrEqual(next.best, next.current)
        // No last day but a positive count: treated as no streak.
        XCTAssertEqual(StreakTracker.displayedStreak(StreakState(lastPlayedDay: nil, current: 9, best: 9), on: day(0)), 0)
    }

    func testHugeStreakSaturates() {
        let state = StreakState(lastPlayedDay: day(0).index, current: Int.max, best: Int.max)
        XCTAssertEqual(StreakTracker.recordPlay(state, on: day(1)).current, Int.max)
    }
}

final class DailyTrackerTests: XCTestCase {
    private var clock = dailyTestDate(2026, 3, 10, hour: 9)
    private func tracker(_ store: StatsStoring) -> DailyTracker {
        DailyTracker(store: store, calendar: { dailyTestCalendar("UTC") }, now: { [unowned self] in self.clock })
    }

    func testPressesCountPerDayAndResetAtMidnight() {
        let store = InMemoryStatsStore()
        let daily = tracker(store)
        XCTAssertEqual(daily.snapshot.pressesToday, 0)
        XCTAssertEqual(daily.snapshot.streak, 0)
        daily.recordPress(); daily.recordPress()
        XCTAssertEqual(daily.snapshot.pressesToday, 2)
        XCTAssertEqual(daily.snapshot.streak, 1)

        clock = dailyTestDate(2026, 3, 11, hour: 0, minute: 1)
        XCTAssertEqual(daily.snapshot.pressesToday, 0, "a new day starts fresh")
        XCTAssertEqual(daily.snapshot.streak, 1, "still alive")
        daily.recordPress()
        XCTAssertEqual(daily.snapshot.pressesToday, 1)
        XCTAssertEqual(daily.snapshot.streak, 2)
    }

    func testPersistsAcrossRecreation() {
        let store = InMemoryStatsStore()
        tracker(store).recordPress()
        tracker(store).recordPress()
        let reloaded = tracker(store)
        XCTAssertEqual(reloaded.snapshot.pressesToday, 2)
        XCTAssertEqual(reloaded.snapshot.streak, 1)
    }

    func testRecordPressReportsTransition() {
        let store = InMemoryStatsStore()
        let daily = tracker(store)
        let challenge = daily.snapshot.challenge
        var results: [ChallengeResult] = []
        for _ in 0..<(challenge.target + 1) { results.append(daily.recordPress().after.result) }
        XCTAssertEqual(results.last, challenge.evaluate(presses: challenge.target + 1))
        XCTAssertEqual(results[challenge.target - 1], challenge.evaluate(presses: challenge.target))
    }

    func testSignatureReactionKeepsTheRarest() {
        let store = InMemoryStatsStore()
        let daily = tracker(store)
        daily.noteReaction(ReactionCatalog.mild[0])
        XCTAssertEqual(daily.signatureReaction, ReactionCatalog.mild[0])
        daily.noteReaction(ReactionCatalog.milestones[100]!)
        daily.noteReaction(ReactionCatalog.mild[1])
        XCTAssertEqual(daily.signatureReaction?.id, "milestone-100")
        daily.noteReaction(ReactionCatalog.fallback)
        XCTAssertEqual(tracker(store).signatureReaction?.id, "milestone-100", "persisted")
        XCTAssertEqual(SignatureReaction.reaction(withText: ReactionCatalog.mild[2].text), ReactionCatalog.mild[2])
        XCTAssertNil(SignatureReaction.reaction(withText: ReactionCatalog.idle))
    }

    func testUserDefaultsRoundTripAndCorruptValues() {
        let defaults = makeIsolatedDefaults(self)
        let store = UserDefaultsStatsStore(defaults: defaults)
        XCTAssertEqual(store.loadDailyProgress(), DailyProgress())
        XCTAssertEqual(store.loadStreakState(), StreakState())
        XCTAssertNil(store.loadSignatureReactionID())

        let streak = StreakState(lastPlayedDay: 20_500, current: 4, best: 9, lastFreezeDay: 20_490)
        store.saveStreakState(streak)
        store.saveDailyProgress(DailyProgress(day: 20_500, presses: 12))
        store.saveSignatureReactionID("mild-01")
        XCTAssertEqual(UserDefaultsStatsStore(defaults: defaults).loadStreakState(), streak)
        XCTAssertEqual(UserDefaultsStatsStore(defaults: defaults).loadDailyProgress(), DailyProgress(day: 20_500, presses: 12))
        XCTAssertEqual(UserDefaultsStatsStore(defaults: defaults).loadSignatureReactionID(), "mild-01")

        defaults.set("banana", forKey: UserDefaultsStatsStore.streakLastDayKey)
        defaults.set(-7, forKey: UserDefaultsStatsStore.streakCurrentKey)
        defaults.set("x", forKey: UserDefaultsStatsStore.streakBestKey)
        defaults.set([1, 2], forKey: UserDefaultsStatsStore.dailyDayKey)
        defaults.set(42, forKey: UserDefaultsStatsStore.signatureReactionKey)
        let corrupt = UserDefaultsStatsStore(defaults: defaults)
        XCTAssertNil(corrupt.loadStreakState().lastPlayedDay)
        XCTAssertEqual(corrupt.loadStreakState().current, 0)
        XCTAssertEqual(corrupt.loadDailyProgress(), DailyProgress())
        XCTAssertNil(corrupt.loadSignatureReactionID())
        // An unknown reaction id is simply ignored.
        defaults.set("no-such-line", forKey: UserDefaultsStatsStore.signatureReactionKey)
        XCTAssertNil(DailyTracker(store: UserDefaultsStatsStore(defaults: defaults)).signatureReaction)
    }
}

import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class ProNudgeSchedulerTests: XCTestCase {
    private let hour: TimeInterval = 3600
    private let day: TimeInterval = 86_400
    private var now = Date(timeIntervalSince1970: 1_800_000_000)
    private var store = InMemoryStatsStore()

    private func makeScheduler(launches: Int = 4, seed: UInt64 = 42) -> ProNudgeScheduler {
        let scheduler = ProNudgeScheduler(store: store, seed: seed, clock: { [unowned self] in self.now })
        for _ in 0..<launches { scheduler.registerLaunch() }
        return scheduler
    }

    private func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }

    /// Offers a moment, waits past the quiet period, and asks.
    @discardableResult
    private func showAutomatic(_ s: ProNudgeScheduler, _ moment: ProNudgeMoment = .dailyChallengeCompleted, isPro: Bool = false) -> ProNudge? {
        s.offer(moment)
        return s.nudgeIfIdle(isPro: isPro)
    }

    // MARK: Launch gate

    func testNeverDuringFirstThreeLaunches() {
        let s = makeScheduler(launches: 0)
        for launch in 1...3 {
            s.registerLaunch()
            XCTAssertNil(showAutomatic(s), "launch \(launch) must be quiet")
        }
        s.registerLaunch()
        XCTAssertNotNil(showAutomatic(s), "launch 4 may show")
    }

    func testLaunchCountPersistsAcrossRecreation() {
        _ = makeScheduler(launches: 2)
        let again = ProNudgeScheduler(store: store, clock: { [unowned self] in self.now })
        XCTAssertEqual(again.state.launchCount, 2)
        again.registerLaunch()
        XCTAssertNil(showAutomatic(again))
        again.registerLaunch()
        XCTAssertNotNil(showAutomatic(again))
    }

    func testFirstLaunchDateIsSetOnceOnly() {
        let s = makeScheduler(launches: 1)
        let first = s.state.firstLaunchAt
        advance(5 * day)
        s.registerLaunch()
        XCTAssertEqual(s.state.firstLaunchAt, first)
    }

    // MARK: Quiet after press (rapid taps)

    func testNeverWithinThreeSecondsOfLastPress() {
        let s = makeScheduler()
        s.offer(.dailyChallengeCompleted)
        s.notePress()
        XCTAssertNil(s.nudgeIfIdle(isPro: false))
        advance(2.999)
        XCTAssertNil(s.nudgeIfIdle(isPro: false))
        advance(0.001)
        XCTAssertNotNil(s.nudgeIfIdle(isPro: false), "exactly 3 s of quiet is enough")
    }

    func testRapidTappingKeepsDeferringThePendingMoment() {
        let s = makeScheduler()
        s.offer(.dailyChallengeCompleted)
        for _ in 0..<100 {
            s.notePress()
            XCTAssertNil(s.nudgeIfIdle(isPro: false))
            advance(0.1)
        }
        advance(3)
        XCTAssertNotNil(s.nudgeIfIdle(isPro: false), "shown once the tapping stops")
        XCTAssertNil(s.nudgeIfIdle(isPro: false), "and only once")
    }

    func testPendingMomentExpires() {
        let s = makeScheduler()
        s.offer(.dailyChallengeCompleted)
        advance(121)
        XCTAssertNil(s.nudgeIfIdle(isPro: false))
        XCTAssertNil(s.pending)
    }

    func testNothingPendingMeansNothingShown() {
        let s = makeScheduler()
        XCTAssertNil(s.nudgeIfIdle(isPro: false))
        XCTAssertTrue(s.canShowAutomatic(isPro: false))
    }

    // MARK: Rolling 24 h

    func testAtMostOnePerRolling24Hours() {
        let s = makeScheduler()
        XCTAssertNotNil(showAutomatic(s))
        advance(23 * hour + 59 * 60)
        XCTAssertNil(showAutomatic(s), "23h59 is too soon")
        advance(59)
        XCTAssertNil(showAutomatic(s), "23h59m59s is too soon")
        advance(1)
        XCTAssertNotNil(showAutomatic(s), "24h exactly is allowed")
    }

    func testClockMovedBackwardsStillRespectsCooldown() {
        let s = makeScheduler()
        XCTAssertNotNil(showAutomatic(s))
        advance(-2 * hour)
        XCTAssertNil(showAutomatic(s))
    }

    // MARK: First 14 days

    func testAtMostThreeInFirstFourteenDays() {
        let s = makeScheduler()
        var shown = 0
        for _ in 0..<13 {
            if showAutomatic(s) != nil { shown += 1 }
            advance(day)
        }
        XCTAssertEqual(shown, 3)
        XCTAssertEqual(s.state.automaticShownInIntroWindow, 3)
        // Day 14 and later: the intro cap no longer applies, only the 24 h cooldown.
        advance(day)
        XCTAssertNotNil(showAutomatic(s))
        advance(day)
        XCTAssertNotNil(showAutomatic(s))
    }

    func testFourteenDayBoundaryIsMeasuredFromFirstLaunch() {
        let s = makeScheduler()
        for _ in 0..<3 { XCTAssertNotNil(showAutomatic(s)); advance(day) }
        // now = first launch + 3 days. Move to just before day 14.
        advance(11 * day - 1)
        XCTAssertNil(showAutomatic(s))
        advance(1)
        XCTAssertNotNil(showAutomatic(s))
    }

    // MARK: Not now (doubling) and opt-out

    func testNotNowDoublesCooldownAndCaps() {
        let s = makeScheduler()
        XCTAssertEqual(s.snoozeDuration(afterNotNowCount: 0), 0)
        XCTAssertEqual(s.snoozeDuration(afterNotNowCount: 1), 2 * day)
        XCTAssertEqual(s.snoozeDuration(afterNotNowCount: 2), 4 * day)
        XCTAssertEqual(s.snoozeDuration(afterNotNowCount: 3), 8 * day)
        XCTAssertEqual(s.snoozeDuration(afterNotNowCount: 4), 16 * day)
        XCTAssertEqual(s.snoozeDuration(afterNotNowCount: 5), 30 * day)
        XCTAssertEqual(s.snoozeDuration(afterNotNowCount: 1_000), 30 * day)
        XCTAssertEqual(s.snoozeDuration(afterNotNowCount: Int.max), 30 * day)
    }

    func testNotNowSnoozesAutomaticPrompts() {
        let s = makeScheduler()
        advance(15 * day) // past the intro window so only cooldowns matter
        let first = showAutomatic(s)!
        s.recordNotNow(for: first)
        XCTAssertEqual(s.state.notNowCount, 1)
        advance(2 * day - 1)
        XCTAssertNil(showAutomatic(s))
        advance(1)
        let second = showAutomatic(s)!
        s.recordNotNow(for: second)
        advance(4 * day - 1)
        XCTAssertNil(showAutomatic(s))
        advance(1)
        XCTAssertNotNil(showAutomatic(s))
    }

    func testNotNowOnUserInitiatedCardChangesNothing() {
        let s = makeScheduler()
        let nudge = s.nudgeForLockedItem(.buttonStyle, isPro: false)!
        s.recordNotNow(for: nudge)
        XCTAssertEqual(s.state.notNowCount, 0)
        XCTAssertNil(s.state.snoozedUntil)
        XCTAssertNotNil(showAutomatic(s))
    }

    func testOptOutIsPermanentButLockedTapsStillWork() {
        let s = makeScheduler()
        s.offer(.dailyChallengeCompleted)
        s.recordOptOut()
        XCTAssertNil(s.pending)
        for _ in 0..<5 {
            advance(40 * day)
            XCTAssertNil(showAutomatic(s))
        }
        let again = ProNudgeScheduler(store: store, clock: { [unowned self] in self.now })
        XCTAssertTrue(again.state.optedOut)
        XCTAssertNil(showAutomatic(again))
        XCTAssertNotNil(again.nudgeForLockedItem(.toy(.egg), isPro: false))
    }

    // MARK: Pro and user-initiated

    func testNeverShownToProOwners() {
        let s = makeScheduler()
        XCTAssertNil(showAutomatic(s, isPro: true))
        XCTAssertNil(s.nudgeForLockedItem(.appIcon, isPro: true))
        XCTAssertFalse(s.canShowAutomatic(isPro: true))
    }

    func testLockedTapAlwaysAllowedAndNotCountedAsNag() {
        let s = makeScheduler(launches: 1) // even on launch 1
        s.notePress()                      // even right after a press
        for _ in 0..<10 { XCTAssertNotNil(s.nudgeForLockedItem(.toy(.balloon), isPro: false)) }
        XCTAssertNil(s.state.lastAutomaticShownAt)
        XCTAssertEqual(s.state.automaticShownInIntroWindow, 0)
    }

    func testLockedTapCannotBeOfferedAsAutomaticMoment() {
        let s = makeScheduler()
        s.offer(.lockedItemTapped(.appIcon))
        XCTAssertNil(s.pending)
    }

    func testLockedTapDoesNotConsumeAutomaticBudget() {
        let s = makeScheduler()
        _ = s.nudgeForLockedItem(.buttonStyle, isPro: false)
        XCTAssertNotNil(showAutomatic(s))
    }

    // MARK: Moments

    func testNearUnlockRequiresAtLeastEightyPercentAndNotDone() {
        XCTAssertFalse(ProNudgeMoment.nearUnlock(toy: .egg, progress: 0.79).isValid)
        XCTAssertTrue(ProNudgeMoment.nearUnlock(toy: .egg, progress: 0.8).isValid)
        XCTAssertTrue(ProNudgeMoment.nearUnlock(toy: .egg, progress: 0.99).isValid)
        XCTAssertFalse(ProNudgeMoment.nearUnlock(toy: .egg, progress: 1).isValid)
        XCTAssertFalse(ProNudgeMoment.nearUnlock(toy: .egg, progress: .nan).isValid)
        let s = makeScheduler()
        s.offer(.nearUnlock(toy: .egg, progress: 0.5))
        XCTAssertNil(s.pending)
        let nudge = showAutomatic(s, .nearUnlock(toy: .balloon, progress: 0.85))
        XCTAssertEqual(nudge?.moment, .nearUnlock(toy: .balloon, progress: 0.85))
    }

    func testNewerMomentReplacesPending() {
        let s = makeScheduler()
        s.offer(.dailyChallengeCompleted)
        s.offer(.toyUnlockedByPlay(.egg))
        XCTAssertEqual(s.nudgeIfIdle(isPro: false)?.moment, .toyUnlockedByPlay(.egg))
    }

    func testEveryNudgeListsWhatProIncludes() {
        let s = makeScheduler()
        let nudge = showAutomatic(s)!
        XCTAssertEqual(nudge.proIncludes, ProNudgeCopy.proIncludes)
        XCTAssertFalse(nudge.proIncludes.isEmpty)
    }

    // MARK: Corrupt state

    func testCorruptStoredValuesReadAsSafeDefaults() {
        let defaults = makeIsolatedDefaults(self)
        defaults.set("lots", forKey: UserDefaultsStatsStore.nudgeLaunchesKey)
        defaults.set("yesterday", forKey: UserDefaultsStatsStore.nudgeFirstLaunchKey)
        defaults.set(Double.nan, forKey: UserDefaultsStatsStore.nudgeLastShownKey)
        defaults.set(-5, forKey: UserDefaultsStatsStore.nudgeNotNowKey)
        defaults.set("true", forKey: UserDefaultsStatsStore.nudgeOptedOutKey)
        defaults.set(12, forKey: UserDefaultsStatsStore.nudgeLastCopyKey)
        let state = UserDefaultsStatsStore(defaults: defaults).loadProNudgeState()
        XCTAssertEqual(state, ProNudgeState())
    }

    func testUserDefaultsRoundTrip() {
        let store = UserDefaultsStatsStore(defaults: makeIsolatedDefaults(self))
        let state = ProNudgeState(
            launchCount: 7, firstLaunchAt: now, lastAutomaticShownAt: now.addingTimeInterval(10),
            automaticShownInIntroWindow: 2, presentedCount: 9, notNowCount: 3,
            snoozedUntil: now.addingTimeInterval(day), optedOut: true, lastCopyID: "daily.3"
        )
        store.saveProNudgeState(state)
        XCTAssertEqual(store.loadProNudgeState(), state)
        store.saveProNudgeState(ProNudgeState())
        XCTAssertEqual(store.loadProNudgeState(), ProNudgeState())
    }

    func testNegativeInMemoryValuesAreSanitized() {
        store.proNudgeState = ProNudgeState(launchCount: -3, automaticShownInIntroWindow: -1, presentedCount: -9, notNowCount: -2)
        let s = ProNudgeScheduler(store: store, clock: { [unowned self] in self.now })
        XCTAssertEqual(s.state, ProNudgeState())
    }

    func testFarFutureCorruptTimestampsDoNotSilenceForever() {
        store.proNudgeState = ProNudgeState(
            launchCount: 10, firstLaunchAt: now.addingTimeInterval(-100 * day),
            lastAutomaticShownAt: now.addingTimeInterval(1_000 * day),
            snoozedUntil: now.addingTimeInterval(1_000 * day)
        )
        let s = ProNudgeScheduler(store: store, clock: { [unowned self] in self.now })
        XCTAssertNotNil(showAutomatic(s))
    }

    func testHugeLaunchCountDoesNotOverflow() {
        store.proNudgeState = ProNudgeState(launchCount: Int.max)
        let s = ProNudgeScheduler(store: store, clock: { [unowned self] in self.now })
        s.registerLaunch()
        XCTAssertEqual(s.state.launchCount, Int.max)
    }

    // MARK: Copy

    func testCopySelectionIsDeterministicForASeed() {
        let a = makeScheduler(seed: 7)
        let idsA = (0..<6).map { _ in a.nudgeForLockedItem(.buttonStyle, isPro: false)!.copyID }
        store = InMemoryStatsStore()
        let b = makeScheduler(seed: 7)
        let idsB = (0..<6).map { _ in b.nudgeForLockedItem(.buttonStyle, isPro: false)!.copyID }
        XCTAssertEqual(idsA, idsB)
    }

    func testCopyNeverRepeatsBackToBack() {
        for seed in UInt64(0)..<20 {
            store = InMemoryStatsStore()
            let s = makeScheduler(seed: seed)
            var last: String?
            for _ in 0..<40 {
                let id = s.nudgeForLockedItem(.toy(.egg), isPro: false)!.copyID
                XCTAssertNotEqual(id, last)
                last = id
            }
        }
    }

    func testEachMomentHasAboutEightUniqueLines() {
        for kind in ProNudgeMoment.Kind.allCases {
            let lines = ProNudgeCopy.lines(for: kind)
            XCTAssertGreaterThanOrEqual(lines.count, 8, "\(kind)")
            XCTAssertEqual(Set(lines.map(\.id)).count, lines.count)
            XCTAssertEqual(Set(lines.map(\.message)).count, lines.count)
        }
    }

    func testCopyIsHonest() {
        let banned = ["limited", "hurry", "only today", "last chance", "% off", "discount", "sale", "expires",
                      "countdown", "everyone", "disappoint", "sad", "miss out", "don't you", "free trial", "seconds left"]
        let all = ProNudgeMoment.Kind.allCases.flatMap { ProNudgeCopy.lines(for: $0) }
        for line in all {
            let text = (line.title + " " + line.message).lowercased()
            for word in banned { XCTAssertFalse(text.contains(word), "\(line.id) contains '\(word)'") }
            XCTAssertLessThanOrEqual(line.message.count, 110, "\(line.id) is too long")
        }
    }

    func testPlaceholdersAreFilledAndCapitalised() {
        let moments: [ProNudgeMoment] = [
            .nearUnlock(toy: .egg, progress: 0.9), .toyUnlockedByPlay(.balloon), .dailyChallengeCompleted,
            .lockedItemTapped(.toy(.egg)), .lockedItemTapped(.buttonStyle), .lockedItemTapped(.appIcon),
        ]
        for moment in moments {
            for line in ProNudgeCopy.lines(for: moment.kind) {
                let text = ProNudgeCopy.fill(line.message, moment: moment)
                XCTAssertFalse(text.contains("{"), text)
                XCTAssertTrue(text.first?.isUppercase ?? false, text)
            }
        }
        XCTAssertEqual(ProNudgeCopy.fill("{toy} is close.", moment: .nearUnlock(toy: .egg, progress: 0.9)), "The Egg is close.")
        XCTAssertEqual(ProNudgeCopy.fill("Enjoy {toy}.", moment: .toyUnlockedByPlay(.balloon)), "Enjoy the Balloon.")
        XCTAssertEqual(ProNudgeCopy.fill("Hi. {item} is Pro.", moment: .lockedItemTapped(.appIcon)), "Hi. That app icon is Pro.")
    }

    func testProIncludesMatchesProViewClaims() {
        XCTAssertEqual(ProNudgeCopy.proIncludes.count, 5)
        XCTAssertTrue(ProNudgeCopy.proIncludes.contains("One-time purchase. No subscription"))
    }

    // MARK: Counting is untouched

    func testSchedulerNeverTouchesPressStats() {
        store = InMemoryStatsStore(PersistedStats(personalBest: 12, totalPresses: 99))
        let s = makeScheduler()
        s.offer(.dailyChallengeCompleted)
        for _ in 0..<50 { s.notePress() }
        advance(5)
        let nudge = s.nudgeIfIdle(isPro: false)!
        s.recordNotNow(for: nudge)
        s.recordOptOut()
        XCTAssertEqual(store.load(), PersistedStats(personalBest: 12, totalPresses: 99))
    }
}

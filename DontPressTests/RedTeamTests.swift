// Red-team robustness tests: hostile / corrupt stored values, extreme clocks, and a long
// hammering run. Everything here is Foundation-only so it runs with `swift test` on Linux.
import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

final class RedTeamTests: XCTestCase {
    /// XCTest runs on the main thread; this keeps the class free of `@MainActor` for Linux discovery.
    private func onMain(_ body: @MainActor () -> Void) { MainActor.assumeIsolated(body) }

    private func today(_ calendar: Calendar = .current) -> DayStamp { DayStamp(date: Date(), calendar: calendar) }

    // MARK: - UserDefaults store: wrong types, extremes, garbage

    func testCountersSurviveEveryHostileType() {
        let defaults = makeIsolatedDefaults(self)
        let store = UserDefaultsStatsStore(defaults: defaults)
        let hostile: [Any] = [
            "847", "", String(repeating: "x", count: 100_000), -1, Int.min, 3.7, Double.nan, Double.infinity,
            -Double.infinity, true, [1, 2, 3], ["a": 1], Data([0xFF, 0x00]), Date.distantPast,
            Array(repeating: "y", count: 50_000),
        ]
        for value in hostile {
            defaults.set(value, forKey: UserDefaultsStatsStore.bestKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.totalKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.themeKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.proKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.soundKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.discoveredReactionsKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.toyKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.creaturesKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.dailyDayKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.dailyPressesKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.streakLastDayKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.streakCurrentKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.streakBestKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.streakFreezeDayKey)
            defaults.set(value, forKey: UserDefaultsStatsStore.signatureReactionKey)

            let stats = store.load()
            XCTAssertGreaterThanOrEqual(stats.personalBest, 0, "\(value)")
            XCTAssertGreaterThanOrEqual(stats.totalPresses, 0, "\(value)")
            XCTAssertGreaterThanOrEqual(store.loadDailyProgress().presses, 0)
            let streak = store.loadStreakState()
            XCTAssertGreaterThanOrEqual(streak.current, 0)
            XCTAssertGreaterThanOrEqual(streak.best, streak.current)
            _ = store.loadIsPro(); _ = store.loadSoundEnabled(); _ = store.loadThemeID()
            _ = store.loadDiscoveredReactionIDs(); _ = store.loadDiscoveredCreatureIDs(); _ = store.loadSelectedToyID()
            _ = store.loadSignatureReactionID()

            // Every store-backed component must come up in a sane state.
            let service = PressService(store: store)
            XCTAssertEqual(service.stats.currentRun, 0)
            let result = service.registerPress()
            XCTAssertEqual(result.stats.currentRun, 1)
            XCTAssertGreaterThanOrEqual(result.stats.totalPresses, 1)
            XCTAssertGreaterThanOrEqual(result.stats.personalBest, 1)

            let tracker = DailyTracker(store: store)
            let (_, after) = tracker.recordPress()
            XCTAssertGreaterThanOrEqual(after.pressesToday, 1)
            XCTAssertGreaterThanOrEqual(after.streak, 1)
            XCTAssertGreaterThanOrEqual(after.bestStreak, after.streak)

            let theme = ButtonTheme.resolve(id: store.loadThemeID(), stats: service.stats, isPro: store.loadIsPro())
            XCTAssertTrue(ButtonTheme.all.contains(theme))
            let dex = Reactiondex(discoveredIDs: store.loadDiscoveredReactionIDs())
            XCTAssertLessThanOrEqual(dex.discoveredCount, dex.totalCount)
        }
    }

    func testProCacheOnlyReadsAsTrueForARealBool() {
        let defaults = makeIsolatedDefaults(self)
        let store = UserDefaultsStatsStore(defaults: defaults)
        for value in ["true", "YES", 1, 1.0, [true], "1"] as [Any] {
            defaults.set(value, forKey: UserDefaultsStatsStore.proKey)
            // Apple's NSNumber bridging may read 1 / 1.0 as a Bool; a string or array never is.
            if value is String || value is [Bool] { XCTAssertFalse(store.loadIsPro(), "\(value)") }
        }
        defaults.removeObject(forKey: UserDefaultsStatsStore.proKey)
        XCTAssertFalse(store.loadIsPro())
    }

    func testSaturationAtIntMaxNeverOverflows() {
        let store = InMemoryStatsStore(PersistedStats(personalBest: Int.max, totalPresses: Int.max))
        let service = PressService(store: store)
        for _ in 0..<3 { service.registerPress() }
        XCTAssertEqual(service.stats.totalPresses, Int.max)
        XCTAssertEqual(service.stats.personalBest, Int.max)
        XCTAssertEqual(service.stats.currentRun, 3)
        XCTAssertEqual(Int.max.saturatingIncremented(), Int.max)
        XCTAssertEqual(Int.min.saturatingIncremented(), 1)
        XCTAssertEqual((-5).saturatingIncremented(by: Int.max), Int.max)
        XCTAssertNil(Milestone.crossed(from: Int.max, to: Int.max))
        XCTAssertNotNil(ShareCardContent.make(personalBest: Int.max, totalPresses: Int.max, dayNumber: Int.max, streak: Int.max))
        XCTAssertEqual(RarityTitle.title(bestRun: Int.max, total: Int.min), "Mythical Menace")
        XCTAssertEqual(RarityTitle.title(bestRun: Int.min, total: Int.min), "Casual Offender")
        XCTAssertEqual(SoundEffect.pressStage(forRun: Int.max), SoundEffect.maxPressStage)
        XCTAssertEqual(SoundEffect.pressStage(forRun: Int.min), 0)
        XCTAssertEqual(SoundEffect.press(stage: Int.min).normalized, .press(stage: 0))
        XCTAssertEqual(SoundEffect.press(stage: Int.max).normalized, .press(stage: SoundEffect.maxPressStage))
        _ = AchievementStatus.statuses(for: PressStats(currentRun: Int.max, personalBest: Int.max, totalPresses: Int.max))
        for theme in ButtonTheme.all {
            XCTAssertNotNil(theme.rule.requirementText)
            XCTAssertTrue(theme.isUnlocked(for: PressStats(currentRun: 0, personalBest: Int.max, totalPresses: Int.max)))
        }
    }

    // MARK: - Streak / daily: extreme day values and clock jumps

    func testStreakStateWithIntMinAndIntMaxDaysDoesNotTrap() {
        let day = today()
        for last in [Int.min, Int.min + 1, -1_000_000_000, Int.max, Int.max - 1, 1_000_000_000] {
            for freeze in [nil, Int.min, Int.max, -5, 5] as [Int?] {
                var state = StreakState(lastPlayedDay: last, current: 3, best: 3, lastFreezeDay: freeze)
                XCTAssertGreaterThanOrEqual(StreakTracker.displayedStreak(state, on: day), 0, "last=\(last) freeze=\(String(describing: freeze))")
                _ = StreakTracker.isRelyingOnFreeze(state, on: day)
                _ = StreakTracker.hasFreeze(state, on: day)
                state = StreakTracker.recordPlay(state, on: day)
                XCTAssertGreaterThanOrEqual(state.current, 1)
                XCTAssertGreaterThanOrEqual(state.best, state.current)
                XCTAssertNotNil(state.lastPlayedDay)
                // After a play today the state is consistent for tomorrow.
                let tomorrow = StreakTracker.recordPlay(state, on: DayStamp(index: day.index + 1))
                XCTAssertGreaterThanOrEqual(tomorrow.current, 1)
            }
        }
        let extremes: [StreakState] = [
            StreakState(lastPlayedDay: Int.min, current: Int.max, best: Int.min, lastFreezeDay: Int.max),
            StreakState(lastPlayedDay: Int.max, current: Int.min, best: Int.max, lastFreezeDay: Int.min),
        ]
        for s in extremes {
            let clean = s.sanitized()
            XCTAssertGreaterThanOrEqual(clean.current, 0)
            XCTAssertGreaterThanOrEqual(clean.best, clean.current)
            XCTAssertEqual(StreakTracker.recordPlay(clean, on: DayStamp(index: Int.max)).current >= 1, true)
            XCTAssertGreaterThanOrEqual(StreakTracker.displayedStreak(clean, on: DayStamp(index: Int.min)), 0)
        }
    }

    func testDailyTrackerSurvivesCorruptDayValuesAndClockJumps() {
        let store = InMemoryStatsStore()
        store.dailyProgress = DailyProgress(day: Int.min, presses: Int.max)
        store.streakState = StreakState(lastPlayedDay: Int.min, current: -4, best: Int.min, lastFreezeDay: Int.max)
        store.signatureReactionID = String(repeating: "z", count: 10_000)
        var now = Date()
        let tracker = DailyTracker(store: store, now: { now })
        XCTAssertNil(tracker.signatureReaction)
        var snap = tracker.snapshot
        XCTAssertEqual(snap.pressesToday, 0)
        XCTAssertEqual(snap.streak, 0)
        XCTAssertEqual(tracker.recordPress().after.pressesToday, 1)
        XCTAssertEqual(tracker.snapshot.streak, 1)

        // Clock jumps: years forward, years backward, DST-sized hops, distant past/future.
        let jumps: [TimeInterval] = [
            86_400 * 366 * 5, -86_400 * 366 * 20, 3_600, -3_600, 86_400, -86_400 * 2, 86_400 * 1_000_000,
        ]
        for jump in jumps {
            now = now.addingTimeInterval(jump)
            snap = tracker.recordPress().after
            XCTAssertGreaterThanOrEqual(snap.pressesToday, 1)
            XCTAssertGreaterThanOrEqual(snap.streak, 0)
            XCTAssertGreaterThanOrEqual(snap.bestStreak, snap.streak)
            XCTAssertFalse(snap.progressText.isEmpty)
            XCTAssertFalse(snap.resultText.isEmpty)
        }
        for date in [Date.distantPast, Date.distantFuture, Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: -1)] {
            now = date
            snap = tracker.recordPress().after
            XCTAssertGreaterThanOrEqual(snap.pressesToday, 1)
            XCTAssertGreaterThanOrEqual(snap.streak, 0)
            _ = DailyShareContent.make(snapshot: snap)
        }
    }

    func testTimeZoneAndDSTChangesKeepStreakAlive() {
        let store = InMemoryStatsStore()
        var zone = TimeZone(identifier: "Pacific/Auckland")!
        // 23:30 local in Auckland.
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        var now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 23, minute: 30))!
        let tracker = DailyTracker(store: store, calendar: { var c = Calendar.current; c.timeZone = zone; return c }, now: { now })
        XCTAssertEqual(tracker.recordPress().after.streak, 1)
        // Fly to Honolulu: the local date goes back a day. Streak stays.
        zone = TimeZone(identifier: "Pacific/Honolulu")!
        XCTAssertEqual(tracker.recordPress().after.streak, 1)
        // Next local day in Honolulu.
        now = now.addingTimeInterval(86_400)
        XCTAssertEqual(tracker.recordPress().after.streak, 2)
        // Weird calendars give the same day index.
        let hebrew = Calendar(identifier: .hebrew)
        XCTAssertEqual(DayStamp(date: now, calendar: hebrew).index, DayStamp(date: now, calendar: Calendar(identifier: .gregorian)).index)
    }

    func testDailyChallengeIsSaneForAbsurdDays() {
        for index in [Int.min, Int.min / 2, -1, 0, 1, Int.max / 2, Int.max] {
            let challenge = DailyChallenge(day: DayStamp(index: index))
            XCTAssertGreaterThan(challenge.target, 0)
            XCTAssertFalse(challenge.title.isEmpty)
            for presses in [Int.min, -1, 0, 1, challenge.target, Int.max] {
                _ = challenge.evaluate(presses: presses)
            }
        }
        XCTAssertEqual(DayStamp.index(year: 1970, month: 1, day: 1), 0)
    }

    // MARK: - Reactiondex, toys, themes with hostile ids

    func testReactiondexIgnoresGarbageAndHugeInputs() {
        var ids = Array(repeating: "mild-01", count: 100_000)
        ids += ["", "💣", String(repeating: "a", count: 1_000_000), "../../etc/passwd", "mild-999999"]
        ids += Array(Reactiondex.collectibleIDs)
        let dex = Reactiondex(discoveredIDs: ids)
        XCTAssertEqual(dex.discoveredCount, dex.totalCount)
        XCTAssertEqual(dex.persistableIDs.count, dex.totalCount)
        var empty = Reactiondex()
        XCTAssertFalse(empty.record(String(repeating: "q", count: 100_000)))
        XCTAssertEqual(empty.discoveredCount, 0)
        for tier in ReactionTier.allCases { XCTAssertGreaterThan(empty.progress(for: tier).total, 0) }
    }

    func testToySessionAndThemesWithUnknownOrLockedIds() {
        onMain {
            let store = InMemoryStatsStore(themeID: String(repeating: "gold", count: 1000))
            store.saveSelectedToyID("dragon")
            store.saveDiscoveredCreatureIDs(["nope", "", "chairman", "chairman", String(repeating: "x", count: 50_000)])
            let session = ToySession(store: store)
            XCTAssertEqual(session.selectedKind, .button)
            XCTAssertEqual(session.discoveredCreatures.map(\.id), ["chairman"])
            XCTAssertEqual(ButtonTheme.resolve(id: store.loadThemeID(), stats: PressStats(), isPro: false), .classic)
            XCTAssertEqual(ButtonTheme.resolve(id: "radioactive", stats: PressStats(currentRun: 0, personalBest: 249, totalPresses: Int.max), isPro: false), .classic)
            XCTAssertEqual(ButtonTheme.resolve(id: "radioactive", stats: PressStats(), isPro: true), .radioactive)

            // A saved Pro toy without Pro must fall back to the free button.
            store.saveSelectedToyID(ToyKind.egg.rawValue)
            store.saveIsPro(false)
            let model = HomeViewModel(service: PressService(store: store))
            XCTAssertEqual(model.toys.selectedKind, .button)
            XCTAssertFalse(model.selectToy(.balloon))
            XCTAssertEqual(model.toys.selectedKind, .button)
            model.setPro(true)
            XCTAssertTrue(model.selectToy(.balloon))
            model.setPro(false)   // refund / revocation
            XCTAssertEqual(model.toys.selectedKind, .button)
            XCTAssertEqual(store.loadSelectedToyID(), ToyKind.button.rawValue)
            XCTAssertFalse(store.loadIsPro())
        }
    }

    func testHostileRandomSourcesNeverCrashToysOrReactions() {
        onMain {
            for value in [Int.min, -1, 0, Int.max] {
                let random: (Int) -> Int = { _ in value }
                var egg = EggToy(random: random)
                var balloon = BalloonToy(random: random)
                for _ in 0..<40 { _ = egg.tap(); _ = balloon.tap() }
                XCTAssertTrue((0...1).contains(egg.tension)); XCTAssertTrue((0...1).contains(balloon.tension))
                var engine = ReactionEngine(random: random)
                for run in [Int.min, -1, 0, 1, 10, 1000, Int.max] {
                    XCTAssertFalse(engine.storyAwareReaction(forRun: run, milestone: nil).text.isEmpty)
                }
                let session = ToySession(store: InMemoryStatsStore(), random: random)
                session.select(.egg)
                for _ in 0..<30 { _ = session.tapSelected() }
                session.select(.balloon)
                for _ in 0..<30 { _ = session.tapSelected() }
            }
        }
    }

    // MARK: - Hammering

    func testHammering200kPressesCountsExactlyAndStaysFast() {
        onMain {
            let store = InMemoryStatsStore()
            let haptics = SpyHaptics()
            let model = HomeViewModel(service: PressService(store: store), haptics: haptics, daily: DailyTracker(store: store))
            let presses = 200_000
            let start = Date()
            for _ in 0..<presses { model.press() }
            let elapsed = Date().timeIntervalSince(start)
            XCTAssertEqual(model.stats, PressStats(currentRun: presses, personalBest: presses, totalPresses: presses))
            XCTAssertEqual(model.pressCount, presses)
            XCTAssertEqual(haptics.pressCount + haptics.milestoneCount, presses)
            XCTAssertEqual(store.load(), PersistedStats(personalBest: presses, totalPresses: presses))
            XCTAssertEqual(model.daily?.pressesToday, presses)
            XCTAssertTrue(model.reactiondex.hasReachedEnding)
            XCTAssertLessThan(elapsed, 60, "200k presses took \(elapsed)s")
        }
    }

    func testHammering200kToyTapsCountsExactly() {
        onMain {
            let store = InMemoryStatsStore()
            store.saveIsPro(true)
            let model = HomeViewModel(service: PressService(store: store))
            XCTAssertTrue(model.selectToy(.egg))
            let presses = 200_000
            let start = Date()
            for i in 0..<presses {
                if i == presses / 2 { XCTAssertTrue(model.selectToy(.balloon)) }
                model.pressToy()
            }
            let elapsed = Date().timeIntervalSince(start)
            XCTAssertEqual(model.stats, PressStats(currentRun: presses, personalBest: presses, totalPresses: presses))
            XCTAssertGreaterThan(model.toys.payoffCount, presses / 20)
            XCTAssertEqual(model.toys.discoveredCreatures.count, CreatureCatalog.all.count)
            XCTAssertLessThan(elapsed, 60, "200k toy taps took \(elapsed)s")
        }
    }

    // MARK: - Share card can never leak or claim a ranking

    func testShareCardContainsOnlyKnownTextAndNoRankingClaims() {
        let hostile = String(repeating: "<script>", count: 10) + "\n\u{202E}" + String(repeating: "W", count: 5_000)
        let content = ShareCardContent.make(personalBest: 847, totalPresses: 1, dayNumber: Int.max, streak: -3, signatureLine: hostile)!
        XCTAssertEqual(content.totalText, "847 TOTAL PRESSES")   // total can never be below best
        XCTAssertNil(content.streakText)
        for text in content.allText {
            let lower = text.lowercased()
            for banned in ["world", "rank", "#1", "global", "leaderboard", "best in", "top "] {
                XCTAssertFalse(lower.contains(banned), "\(text)")
            }
        }
        XCTAssertNil(ShareCardContent.make(personalBest: 0))
        XCTAssertNil(ShareCardContent.make(personalBest: Int.min))
        XCTAssertNil(ShareCardContent.make(personalBest: 5, signatureLine: "")?.signatureLine)
    }
}

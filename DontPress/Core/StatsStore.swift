import Foundation

/// The two values that survive a cold launch.
struct PersistedStats: Equatable {
    var personalBest: Int = 0
    var totalPresses: Int = 0
}

protocol StatsStoring: AnyObject {
    func load() -> PersistedStats
    func save(_ stats: PersistedStats)
    /// The chosen button style id, if any.
    func loadThemeID() -> String?
    func saveThemeID(_ id: String)
    /// Last known Pro entitlement (StoreKit stays the source of truth; this avoids a flicker at launch).
    func loadIsPro() -> Bool
    func saveIsPro(_ value: Bool)
    /// Whether synthesized sound effects play. Defaults to on.
    func loadSoundEnabled() -> Bool
    func saveSoundEnabled(_ value: Bool)
    // Reactiondex: ids of reaction lines this device has seen.
    func loadDiscoveredReactionIDs() -> [String]
    func saveDiscoveredReactionIDs(_ ids: [String])

    // MARK: Daily challenge & streak (feat-daily)
    func loadDailyProgress() -> DailyProgress
    func saveDailyProgress(_ progress: DailyProgress)
    func loadStreakState() -> StreakState
    func saveStreakState(_ state: StreakState)
    func loadSignatureReactionID() -> String?
    func saveSignatureReactionID(_ id: String)
    // MARK: Toys (see Core/Toys)
    /// The chosen tap toy (`ToyKind` raw value), if any.
    func loadSelectedToyID() -> String?
    func saveSelectedToyID(_ id: String)
    /// Ids of creatures hatched from the egg so far.
    func loadDiscoveredCreatureIDs() -> [String]
    func saveDiscoveredCreatureIDs(_ ids: [String])
    // MARK: Pro nudges (feat-nudges). See ProNudgeScheduler.
    func loadProNudgeState() -> ProNudgeState
    func saveProNudgeState(_ state: ProNudgeState)
    /// Ids of prizes that have fallen out of the piñata so far (feat-pinata).
    func loadDiscoveredPinataPrizeIDs() -> [String]
    func saveDiscoveredPinataPrizeIDs(_ ids: [String])
}

/// Lightweight local store. Missing, negative, or wrongly typed values read as 0.
final class UserDefaultsStatsStore: StatsStoring {
    static let bestKey = "dontpress.personalBest"
    static let totalKey = "dontpress.totalPresses"
    static let themeKey = "dontpress.buttonTheme"
    static let proKey = "dontpress.isPro"
    static let soundKey = "dontpress.soundEnabled"
    static let discoveredReactionsKey = "dontpress.discoveredReactions"
    static let toyKey = "dontpress.selectedToy"
    static let creaturesKey = "dontpress.discoveredCreatures"
    static let pinataPrizesKey = "dontpress.discoveredPinataPrizes"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PersistedStats {
        PersistedStats(
            personalBest: readCounter(Self.bestKey),
            totalPresses: readCounter(Self.totalKey)
        )
    }

    func save(_ stats: PersistedStats) {
        defaults.set(Swift.max(stats.personalBest, 0), forKey: Self.bestKey)
        defaults.set(Swift.max(stats.totalPresses, 0), forKey: Self.totalKey)
    }

    func loadThemeID() -> String? { defaults.object(forKey: Self.themeKey) as? String }
    func saveThemeID(_ id: String) { defaults.set(id, forKey: Self.themeKey) }
    func loadIsPro() -> Bool { (defaults.object(forKey: Self.proKey) as? Bool) ?? false }
    func saveIsPro(_ value: Bool) { defaults.set(value, forKey: Self.proKey) }
    func loadSoundEnabled() -> Bool { (defaults.object(forKey: Self.soundKey) as? Bool) ?? true }
    func saveSoundEnabled(_ value: Bool) { defaults.set(value, forKey: Self.soundKey) }

    // Reactiondex. A wrongly typed value reads as empty.
    func loadDiscoveredReactionIDs() -> [String] {
        (defaults.object(forKey: Self.discoveredReactionsKey) as? [String]) ?? []
    }
    func saveDiscoveredReactionIDs(_ ids: [String]) {
        defaults.set(Array(Set(ids)).sorted(), forKey: Self.discoveredReactionsKey)
    }

    // MARK: Toys
    func loadSelectedToyID() -> String? { defaults.object(forKey: Self.toyKey) as? String }
    func saveSelectedToyID(_ id: String) { defaults.set(id, forKey: Self.toyKey) }
    /// Wrong type reads as nothing discovered.
    func loadDiscoveredCreatureIDs() -> [String] { (defaults.object(forKey: Self.creaturesKey) as? [String]) ?? [] }
    func saveDiscoveredCreatureIDs(_ ids: [String]) { defaults.set(ids, forKey: Self.creaturesKey) }
    func loadDiscoveredPinataPrizeIDs() -> [String] { (defaults.object(forKey: Self.pinataPrizesKey) as? [String]) ?? [] }
    func saveDiscoveredPinataPrizeIDs(_ ids: [String]) { defaults.set(ids, forKey: Self.pinataPrizesKey) }

    private func readCounter(_ key: String) -> Int {
        guard let raw = defaults.object(forKey: key) else { return 0 }
        if let value = raw as? Int { return Swift.max(value, 0) }
        return 0
    }

    // MARK: Daily challenge & streak (feat-daily). Wrong types read as defaults.
    static let dailyDayKey = "dontpress.daily.day"
    static let dailyPressesKey = "dontpress.daily.presses"
    static let streakLastDayKey = "dontpress.streak.lastDay"
    static let streakCurrentKey = "dontpress.streak.current"
    static let streakBestKey = "dontpress.streak.best"
    static let streakFreezeDayKey = "dontpress.streak.freezeDay"
    static let signatureReactionKey = "dontpress.signatureReaction"

    func loadDailyProgress() -> DailyProgress {
        let day = defaults.object(forKey: Self.dailyDayKey) as? Int
        return DailyProgress(day: day, presses: day == nil ? 0 : readCounter(Self.dailyPressesKey))
    }

    func saveDailyProgress(_ progress: DailyProgress) {
        if let day = progress.day { defaults.set(day, forKey: Self.dailyDayKey) } else { defaults.removeObject(forKey: Self.dailyDayKey) }
        defaults.set(Swift.max(progress.presses, 0), forKey: Self.dailyPressesKey)
    }

    func loadStreakState() -> StreakState {
        StreakState(
            lastPlayedDay: defaults.object(forKey: Self.streakLastDayKey) as? Int,
            current: readCounter(Self.streakCurrentKey),
            best: readCounter(Self.streakBestKey),
            lastFreezeDay: defaults.object(forKey: Self.streakFreezeDayKey) as? Int
        ).sanitized()
    }

    func saveStreakState(_ state: StreakState) {
        let state = state.sanitized()
        if let day = state.lastPlayedDay { defaults.set(day, forKey: Self.streakLastDayKey) } else { defaults.removeObject(forKey: Self.streakLastDayKey) }
        defaults.set(state.current, forKey: Self.streakCurrentKey)
        defaults.set(state.best, forKey: Self.streakBestKey)
        if let day = state.lastFreezeDay { defaults.set(day, forKey: Self.streakFreezeDayKey) } else { defaults.removeObject(forKey: Self.streakFreezeDayKey) }
    }

    func loadSignatureReactionID() -> String? { defaults.object(forKey: Self.signatureReactionKey) as? String }
    func saveSignatureReactionID(_ id: String) { defaults.set(id, forKey: Self.signatureReactionKey) }

    // MARK: Pro nudges (feat-nudges). Each field has its own key; a wrong type reads as its default.
    static let nudgeLaunchesKey = "dontpress.nudge.launches"
    static let nudgeFirstLaunchKey = "dontpress.nudge.firstLaunchAt"
    static let nudgeLastShownKey = "dontpress.nudge.lastAutomaticShownAt"
    static let nudgeIntroShownKey = "dontpress.nudge.introShown"
    static let nudgePresentedKey = "dontpress.nudge.presented"
    static let nudgeNotNowKey = "dontpress.nudge.notNow"
    static let nudgeSnoozedUntilKey = "dontpress.nudge.snoozedUntil"
    static let nudgeOptedOutKey = "dontpress.nudge.optedOut"
    static let nudgeLastCopyKey = "dontpress.nudge.lastCopy"

    func loadProNudgeState() -> ProNudgeState {
        ProNudgeState(
            launchCount: readCounter(Self.nudgeLaunchesKey),
            firstLaunchAt: readDate(Self.nudgeFirstLaunchKey),
            lastAutomaticShownAt: readDate(Self.nudgeLastShownKey),
            automaticShownInIntroWindow: readCounter(Self.nudgeIntroShownKey),
            presentedCount: readCounter(Self.nudgePresentedKey),
            notNowCount: readCounter(Self.nudgeNotNowKey),
            snoozedUntil: readDate(Self.nudgeSnoozedUntilKey),
            optedOut: (defaults.object(forKey: Self.nudgeOptedOutKey) as? Bool) ?? false,
            lastCopyID: defaults.object(forKey: Self.nudgeLastCopyKey) as? String
        ).sanitized()
    }

    func saveProNudgeState(_ state: ProNudgeState) {
        let state = state.sanitized()
        defaults.set(state.launchCount, forKey: Self.nudgeLaunchesKey)
        writeDate(state.firstLaunchAt, Self.nudgeFirstLaunchKey)
        writeDate(state.lastAutomaticShownAt, Self.nudgeLastShownKey)
        defaults.set(state.automaticShownInIntroWindow, forKey: Self.nudgeIntroShownKey)
        defaults.set(state.presentedCount, forKey: Self.nudgePresentedKey)
        defaults.set(state.notNowCount, forKey: Self.nudgeNotNowKey)
        writeDate(state.snoozedUntil, Self.nudgeSnoozedUntilKey)
        defaults.set(state.optedOut, forKey: Self.nudgeOptedOutKey)
        if let id = state.lastCopyID { defaults.set(id, forKey: Self.nudgeLastCopyKey) } else { defaults.removeObject(forKey: Self.nudgeLastCopyKey) }
    }

    /// Dates are stored as seconds since 1970; anything else (or a non-finite number) reads as nil.
    private func readDate(_ key: String) -> Date? {
        guard let seconds = defaults.object(forKey: key) as? Double, seconds.isFinite else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    private func writeDate(_ date: Date?, _ key: String) {
        if let date { defaults.set(date.timeIntervalSince1970, forKey: key) } else { defaults.removeObject(forKey: key) }
    }
}

/// Isolated store for tests and previews.
final class InMemoryStatsStore: StatsStoring {
    private var stats: PersistedStats
    private var themeID: String?
    private var isPro = false
    private var soundEnabled = true
    private var discoveredReactionIDs: [String] = []
    private var selectedToyID: String?
    private var discoveredCreatureIDs: [String] = []
    private var discoveredPinataPrizeIDs: [String] = []

    init(_ stats: PersistedStats = PersistedStats(), themeID: String? = nil) {
        self.stats = stats
        self.themeID = themeID
    }

    func loadThemeID() -> String? { themeID }
    func saveThemeID(_ id: String) { themeID = id }
    func loadIsPro() -> Bool { isPro }
    func saveIsPro(_ value: Bool) { isPro = value }
    func loadSoundEnabled() -> Bool { soundEnabled }
    func saveSoundEnabled(_ value: Bool) { soundEnabled = value }
    func loadDiscoveredReactionIDs() -> [String] { discoveredReactionIDs }
    func saveDiscoveredReactionIDs(_ ids: [String]) { discoveredReactionIDs = Array(Set(ids)).sorted() }

    // MARK: Toys
    func loadSelectedToyID() -> String? { selectedToyID }
    func saveSelectedToyID(_ id: String) { selectedToyID = id }
    func loadDiscoveredCreatureIDs() -> [String] { discoveredCreatureIDs }
    func saveDiscoveredCreatureIDs(_ ids: [String]) { discoveredCreatureIDs = ids }
    func loadDiscoveredPinataPrizeIDs() -> [String] { discoveredPinataPrizeIDs }
    func saveDiscoveredPinataPrizeIDs(_ ids: [String]) { discoveredPinataPrizeIDs = ids }

    func load() -> PersistedStats { stats }
    func save(_ stats: PersistedStats) { self.stats = stats }

    // MARK: Daily challenge & streak (feat-daily)
    var dailyProgress = DailyProgress()
    var streakState = StreakState()
    var signatureReactionID: String?
    func loadDailyProgress() -> DailyProgress { dailyProgress }
    func saveDailyProgress(_ progress: DailyProgress) { dailyProgress = progress }
    func loadStreakState() -> StreakState { streakState }
    func saveStreakState(_ state: StreakState) { streakState = state }
    func loadSignatureReactionID() -> String? { signatureReactionID }
    func saveSignatureReactionID(_ id: String) { signatureReactionID = id }

    // MARK: Pro nudges (feat-nudges)
    var proNudgeState = ProNudgeState()
    func loadProNudgeState() -> ProNudgeState { proNudgeState }
    func saveProNudgeState(_ state: ProNudgeState) { proNudgeState = state }
}

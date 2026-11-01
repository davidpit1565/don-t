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
    // MARK: Toys (see Core/Toys)
    /// The chosen tap toy (`ToyKind` raw value), if any.
    func loadSelectedToyID() -> String?
    func saveSelectedToyID(_ id: String)
    /// Ids of creatures hatched from the egg so far.
    func loadDiscoveredCreatureIDs() -> [String]
    func saveDiscoveredCreatureIDs(_ ids: [String])
}

/// Lightweight local store. Missing, negative, or wrongly typed values read as 0.
final class UserDefaultsStatsStore: StatsStoring {
    static let bestKey = "dontpress.personalBest"
    static let totalKey = "dontpress.totalPresses"
    static let themeKey = "dontpress.buttonTheme"
    static let proKey = "dontpress.isPro"
    static let toyKey = "dontpress.selectedToy"
    static let creaturesKey = "dontpress.discoveredCreatures"

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

    // MARK: Toys
    func loadSelectedToyID() -> String? { defaults.object(forKey: Self.toyKey) as? String }
    func saveSelectedToyID(_ id: String) { defaults.set(id, forKey: Self.toyKey) }
    /// Wrong type reads as nothing discovered.
    func loadDiscoveredCreatureIDs() -> [String] { (defaults.object(forKey: Self.creaturesKey) as? [String]) ?? [] }
    func saveDiscoveredCreatureIDs(_ ids: [String]) { defaults.set(ids, forKey: Self.creaturesKey) }

    private func readCounter(_ key: String) -> Int {
        guard let raw = defaults.object(forKey: key) else { return 0 }
        if let value = raw as? Int { return Swift.max(value, 0) }
        return 0
    }
}

/// Isolated store for tests and previews.
final class InMemoryStatsStore: StatsStoring {
    private var stats: PersistedStats
    private var themeID: String?
    private var isPro = false
    private var selectedToyID: String?
    private var discoveredCreatureIDs: [String] = []

    init(_ stats: PersistedStats = PersistedStats(), themeID: String? = nil) {
        self.stats = stats
        self.themeID = themeID
    }

    func loadThemeID() -> String? { themeID }
    func saveThemeID(_ id: String) { themeID = id }
    func loadIsPro() -> Bool { isPro }
    func saveIsPro(_ value: Bool) { isPro = value }

    // MARK: Toys
    func loadSelectedToyID() -> String? { selectedToyID }
    func saveSelectedToyID(_ id: String) { selectedToyID = id }
    func loadDiscoveredCreatureIDs() -> [String] { discoveredCreatureIDs }
    func saveDiscoveredCreatureIDs(_ ids: [String]) { discoveredCreatureIDs = ids }

    func load() -> PersistedStats { stats }
    func save(_ stats: PersistedStats) { self.stats = stats }
}

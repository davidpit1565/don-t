import Foundation

/// The two values that survive a cold launch.
struct PersistedStats: Equatable {
    var personalBest: Int = 0
    var totalPresses: Int = 0
}

protocol StatsStoring: AnyObject {
    func load() -> PersistedStats
    func save(_ stats: PersistedStats)
}

/// Lightweight local store. Missing, negative, or wrongly typed values read as 0.
final class UserDefaultsStatsStore: StatsStoring {
    static let bestKey = "dontpress.personalBest"
    static let totalKey = "dontpress.totalPresses"

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

    private func readCounter(_ key: String) -> Int {
        guard let raw = defaults.object(forKey: key) else { return 0 }
        if let value = raw as? Int { return Swift.max(value, 0) }
        return 0
    }
}

/// Isolated store for tests and previews.
final class InMemoryStatsStore: StatsStoring {
    private var stats: PersistedStats

    init(_ stats: PersistedStats = PersistedStats()) {
        self.stats = stats
    }

    func load() -> PersistedStats { stats }
    func save(_ stats: PersistedStats) { self.stats = stats }
}

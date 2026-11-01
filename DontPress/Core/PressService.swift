import Foundation

/// Owns counting. One call to `registerPress()` is exactly one accepted press.
final class PressService {
    private let store: StatsStoring
    private(set) var stats: PressStats

    /// A new `PressService` always starts a fresh current run at zero;
    /// only personal best and total are restored from the store.
    init(store: StatsStoring) {
        self.store = store
        let persisted = store.load()
        self.stats = PressStats(
            currentRun: 0,
            personalBest: persisted.personalBest,
            totalPresses: persisted.totalPresses
        )
    }

    var savedThemeID: String? { store.loadThemeID() }
    func saveThemeID(_ id: String) { store.saveThemeID(id) }
    var savedIsPro: Bool { store.loadIsPro() }
    func saveIsPro(_ value: Bool) { store.saveIsPro(value) }
    var savedSoundEnabled: Bool { store.loadSoundEnabled() }
    func saveSoundEnabled(_ value: Bool) { store.saveSoundEnabled(value) }
    // Reactiondex
    var savedDiscoveredReactionIDs: [String] { store.loadDiscoveredReactionIDs() }
    func saveDiscoveredReactionIDs(_ ids: [String]) { store.saveDiscoveredReactionIDs(ids) }

    @discardableResult
    func registerPress() -> PressResult {
        let previousRun = stats.currentRun
        stats.currentRun = previousRun.saturatingIncremented()
        stats.totalPresses = stats.totalPresses.saturatingIncremented()

        var isNewBest = false
        if stats.currentRun > stats.personalBest {
            stats.personalBest = stats.currentRun
            isNewBest = true
        }

        store.save(PersistedStats(personalBest: stats.personalBest, totalPresses: stats.totalPresses))

        return PressResult(
            stats: stats,
            isNewPersonalBest: isNewBest,
            milestone: Milestone.crossed(from: previousRun, to: stats.currentRun)
        )
    }
}

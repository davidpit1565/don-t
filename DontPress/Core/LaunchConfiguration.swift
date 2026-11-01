import Foundation

/// Decides which store the app uses. Normal launches use standard UserDefaults.
/// UI tests pass `-UITestMode` to get an isolated suite, plus optional seeding,
/// so they never touch real data.
struct LaunchConfiguration: Equatable {
    var isUITestMode = false
    var resetStore = false
    var seedBest: Int?
    var seedTotal: Int?
    /// UI tests only: start with Pro owned and skip the StoreKit refresh.
    var forcePro = false

    static let uiTestSuiteName = "app.dontpress.uitests"

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        // Test hooks exist only in debug builds; a release app always uses the real store.
        #if DEBUG
        isUITestMode = arguments.contains("-UITestMode")
        resetStore = arguments.contains("-UITestReset")
        seedBest = value(after: "-UITestSeedBest").flatMap { Int($0) }
        seedTotal = value(after: "-UITestSeedTotal").flatMap { Int($0) }
        forcePro = isUITestMode && arguments.contains("-UITestPro")
        #endif
    }

    func makeStore() -> StatsStoring {
        guard isUITestMode, let defaults = UserDefaults(suiteName: Self.uiTestSuiteName) else {
            return UserDefaultsStatsStore()
        }
        if resetStore {
            defaults.removePersistentDomain(forName: Self.uiTestSuiteName)
        }
        let store = UserDefaultsStatsStore(defaults: defaults)
        if seedBest != nil || seedTotal != nil {
            var stats = store.load()
            if let seedBest { stats.personalBest = seedBest }
            if let seedTotal { stats.totalPresses = seedTotal }
            store.save(stats)
        }
        if forcePro { store.saveIsPro(true) }
        return store
    }
}

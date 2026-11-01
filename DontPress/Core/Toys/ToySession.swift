import Foundation
import Observation

/// Owns the selected toy, both toy state machines and the discovered-creature set.
/// It never counts presses: `HomeViewModel.pressToy()` calls `press()` first, then `tapSelected()`.
@MainActor
@Observable
final class ToySession {
    private(set) var selectedKind: ToyKind
    private(set) var egg: EggToy
    private(set) var balloon: BalloonToy
    private(set) var pinata: PinataToy
    private(set) var discoveredCreatureIDs: Set<String>
    /// feat-pinata: prizes that have spilled out so far.
    private(set) var discoveredPrizeIDs: Set<String>
    /// Increments on every payoff (hatch or pop); views may key one-shot animations on it.
    private(set) var payoffCount = 0

    @ObservationIgnored private let store: StatsStoring

    init(store: StatsStoring, random: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }) {
        self.store = store
        self.selectedKind = ToyKind.resolve(id: store.loadSelectedToyID())
        self.egg = EggToy(random: random)
        self.balloon = BalloonToy(random: random)
        self.pinata = PinataToy(random: random)
        self.discoveredCreatureIDs = Set(store.loadDiscoveredCreatureIDs().filter { CreatureCatalog.creature(id: $0) != nil })
        self.discoveredPrizeIDs = Set(store.loadDiscoveredPinataPrizeIDs().filter { PinataPrizeCatalog.prize(id: $0) != nil })
    }

    func select(_ kind: ToyKind) {
        guard kind != selectedKind else { return }
        selectedKind = kind
        store.saveSelectedToyID(kind.rawValue)
    }

    /// Advances the selected toy by one already-counted tap. Returns the payoff line when it resolves.
    @discardableResult
    func tapSelected() -> String? {
        switch selectedKind {
        case .button:
            return nil
        case .egg:
            guard let creature = egg.tap() else { return nil }
            discover(creature)
            payoffCount &+= 1
            return creature.hatchLine
        case .balloon:
            guard let line = balloon.tap() else { return nil }
            payoffCount &+= 1
            return line
        case .pinata:
            guard let prize = pinata.tap() else { return nil }
            discover(prize)
            payoffCount &+= 1
            return prize.burstLine
        }
    }

    /// Returns any resolved toy to idle (called by the view once the payoff has been seen).
    func clearPayoff() {
        if egg.isResolved { egg.reset() }
        if balloon.isResolved { balloon.reset() }
        if pinata.isResolved { pinata.reset() }
    }

    var discoveredCreatures: [Creature] { CreatureCatalog.all.filter { discoveredCreatureIDs.contains($0.id) } }

    func isDiscovered(_ creature: Creature) -> Bool { discoveredCreatureIDs.contains(creature.id) }

    // MARK: feat-pinata
    var discoveredPrizes: [PinataPrize] { PinataPrizeCatalog.all.filter { discoveredPrizeIDs.contains($0.id) } }

    func isDiscovered(_ prize: PinataPrize) -> Bool { discoveredPrizeIDs.contains(prize.id) }

    private func discover(_ prize: PinataPrize) {
        guard !discoveredPrizeIDs.contains(prize.id) else { return }
        discoveredPrizeIDs.insert(prize.id)
        store.saveDiscoveredPinataPrizeIDs(discoveredPrizeIDs.sorted())
    }

    private func discover(_ creature: Creature) {
        guard !discoveredCreatureIDs.contains(creature.id) else { return }
        discoveredCreatureIDs.insert(creature.id)
        store.saveDiscoveredCreatureIDs(discoveredCreatureIDs.sorted())
    }
}

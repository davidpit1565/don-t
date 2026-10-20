import Foundation

enum ReactionTier: CaseIterable {
    case mild, sarcasm, concern, absurd, dramatic, legendary

    /// Tier for the Nth press of the current run (1-based).
    static func tier(forPress count: Int) -> ReactionTier {
        switch count {
        case ..<4: return .mild          // 1–3 (and anything below 1)
        case 4...10: return .sarcasm
        case 11...25: return .concern
        case 26...50: return .absurd
        case 51...100: return .dramatic
        default: return .legendary       // 101+
        }
    }
}

struct Reaction: Equatable, Identifiable {
    let id: String
    let text: String
    let tier: ReactionTier
    /// Rare lines are drawn only occasionally within their tier.
    let isRare: Bool
}

/// Picks curated reactions. Randomness is injected so tests are deterministic.
/// Selection never touches counters.
struct ReactionEngine {
    /// Percent chance (0–100) of drawing from the rare pool when one exists.
    static let rareChancePercent = 12

    private let catalog: [Reaction]
    /// Returns a value in `0..<upperBound`.
    private let random: (Int) -> Int
    private(set) var lastReactionID: String?

    init(
        catalog: [Reaction] = ReactionCatalog.all,
        random: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }
    ) {
        self.catalog = catalog
        self.random = random
    }

    mutating func reaction(forPress count: Int) -> Reaction {
        let tier = ReactionTier.tier(forPress: count)
        let inTier = catalog.filter { $0.tier == tier }
        let rare = inTier.filter { $0.isRare }
        let common = inTier.filter { !$0.isRare }

        var pool = common
        if !rare.isEmpty, random(100) < Self.rareChancePercent {
            pool = rare
        } else if common.isEmpty {
            pool = rare
        }
        if pool.isEmpty { return remember(ReactionCatalog.fallback) }

        // Avoid repeating the previous line where there is any alternative.
        let candidates = pool.count > 1 ? pool.filter { $0.id != lastReactionID } : pool
        let index = min(max(random(candidates.count), 0), candidates.count - 1)
        return remember(candidates[index])
    }

    /// Curated line for a milestone press, replacing the normal reaction.
    mutating func reaction(forMilestone milestone: Int) -> Reaction {
        let line = ReactionCatalog.milestones[milestone] ?? ReactionCatalog.fallback
        return remember(line)
    }

    private mutating func remember(_ reaction: Reaction) -> Reaction {
        lastReactionID = reaction.id
        return reaction
    }
}

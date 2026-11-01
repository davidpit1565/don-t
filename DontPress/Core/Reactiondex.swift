// The Reactiondex: which curated lines this device has seen. Only ids are stored.
import Foundation

struct ReactiondexEntry: Identifiable, Equatable {
    let reaction: Reaction
    let kind: ReactionKind
    let isDiscovered: Bool
    var id: String { reaction.id }
}

struct ReactiondexProgress: Equatable {
    let discovered: Int
    let total: Int
}

struct Reactiondex: Equatable {
    /// Every line that can actually be shown, in display order:
    /// tier lines, milestones (minus superseded ones), story beats, secrets, ending.
    static let collectibles: [(reaction: Reaction, kind: ReactionKind)] = {
        let superseded = StoryCatalog.supersededMilestones
        var list: [(reaction: Reaction, kind: ReactionKind)] = []
        for tier in ReactionTier.allCases {
            list += ReactionCatalog.all.filter { $0.tier == tier }.map { ($0, .regular) }
        }
        list += ReactionCatalog.milestones
            .filter { !superseded.contains($0.key) }
            .sorted { $0.key < $1.key }
            .map { ($0.value, .milestone) }
        list += StoryCatalog.orderedBeats.map { ($0, .story) }
        list += StoryCatalog.secrets.sorted { $0.key < $1.key }.map { ($0.value, .secret) }
        list.append((StoryCatalog.ending, .ending))
        return list
    }()

    static let collectibleIDs: Set<String> = Set(collectibles.map(\.reaction.id))

    private(set) var discoveredIDs: Set<String>

    /// Unknown ids (e.g. lines removed in a later version) and duplicates are ignored.
    init(discoveredIDs: [String] = []) {
        self.discoveredIDs = Set(discoveredIDs.filter { Self.collectibleIDs.contains($0) })
    }

    /// Records a shown line. Returns true only the first time a collectible id is seen.
    @discardableResult
    mutating func record(_ id: String) -> Bool {
        guard Self.collectibleIDs.contains(id) else { return false }
        return discoveredIDs.insert(id).inserted
    }

    func isDiscovered(_ id: String) -> Bool { discoveredIDs.contains(id) }

    var discoveredCount: Int { discoveredIDs.count }
    var totalCount: Int { Self.collectibles.count }

    var progress: ReactiondexProgress { ReactiondexProgress(discovered: discoveredCount, total: totalCount) }

    /// Discovered/total for every line of a tier (all kinds).
    func progress(for tier: ReactionTier) -> ReactiondexProgress {
        let inTier = Self.collectibles.filter { $0.reaction.tier == tier }
        return ReactiondexProgress(discovered: inTier.filter { isDiscovered($0.reaction.id) }.count, total: inTier.count)
    }

    /// Discovered/total for one kind (story, secret, ...).
    func progress(for kind: ReactionKind) -> ReactiondexProgress {
        let ofKind = Self.collectibles.filter { $0.kind == kind }
        return ReactiondexProgress(discovered: ofKind.filter { isDiscovered($0.reaction.id) }.count, total: ofKind.count)
    }

    /// Rare lines found (rare tier lines, milestones, secrets, the ending).
    var rareFoundCount: Int {
        Self.collectibles.filter { $0.reaction.isRare && isDiscovered($0.reaction.id) }.count
    }

    var rareTotalCount: Int { Self.collectibles.filter { $0.reaction.isRare }.count }

    var hasReachedEnding: Bool { isDiscovered(StoryCatalog.ending.id) }

    var entries: [ReactiondexEntry] {
        Self.collectibles.map { ReactiondexEntry(reaction: $0.reaction, kind: $0.kind, isDiscovered: isDiscovered($0.reaction.id)) }
    }

    /// Stable, sorted list for the store.
    var persistableIDs: [String] { discoveredIDs.sorted() }

    static func == (lhs: Reactiondex, rhs: Reactiondex) -> Bool { lhs.discoveredIDs == rhs.discoveredIDs }
}

extension ReactionTier {
    var displayName: String {
        switch self {
        case .mild: return "Mild"
        case .sarcasm: return "Sarcasm"
        case .concern: return "Concern"
        case .absurd: return "Absurd"
        case .dramatic: return "Dramatic"
        case .legendary: return "Legendary"
        }
    }

    /// Run range in which this tier's regular lines appear.
    var rangeText: String {
        switch self {
        case .mild: return "Presses 1–3"
        case .sarcasm: return "Presses 4–10"
        case .concern: return "Presses 11–25"
        case .absurd: return "Presses 26–50"
        case .dramatic: return "Presses 51–100"
        case .legendary: return "Presses 101+"
        }
    }
}

extension ReactionKind {
    var displayName: String {
        switch self {
        case .regular: return "Reaction"
        case .milestone: return "Milestone"
        case .story: return "Story"
        case .secret: return "Secret"
        case .ending: return "Ending"
        }
    }
}

import Foundation

enum CreatureRarity: String, CaseIterable, Equatable {
    case common, rare, legendary

    var title: String { rawValue.capitalized }

    /// Percent chance of each tier on a hatch. Drawn with one `random(100)` roll.
    static let legendaryPercent = 5
    static let rarePercent = 25

    static func forRoll(_ roll: Int) -> CreatureRarity {
        if roll < legendaryPercent { return .legendary }
        if roll < legendaryPercent + rarePercent { return .rare }
        return .common
    }
}

/// Data only. Colours are hex so Core stays UI-free; the view draws the creature from shapes.
struct Creature: Equatable, Identifiable {
    let id: String
    let name: String
    let rarity: CreatureRarity
    /// One short funny line shown when it hatches.
    let line: String
    let bodyHex: UInt32
    let accentHex: UInt32

    /// The reaction line after a hatch.
    var hatchLine: String { "\(name) hatched. \(line)" }
}

/// Curated, original creatures. Nothing here resembles an existing character.
enum CreatureCatalog {
    static let all: [Creature] = [
        // Common
        Creature(id: "blorp", name: "Blorp", rarity: .common, line: "A round, damp optimist.", bodyHex: 0x3FC1A8, accentHex: 0x1E7A68),
        Creature(id: "wobbleton", name: "Wobbleton", rarity: .common, line: "Mostly knees. Entirely confused.", bodyHex: 0xF2A64B, accentHex: 0xA8641A),
        Creature(id: "pip", name: "Pip Nobody", rarity: .common, line: "Hatched, looked around, regretted it.", bodyHex: 0xB9B5E6, accentHex: 0x6B64B3),
        Creature(id: "sircrumb", name: "Sir Crumb", rarity: .common, line: "A knight. Of toast.", bodyHex: 0xD9A066, accentHex: 0x8C5A2B),
        Creature(id: "doodlefish", name: "Doodlefish", rarity: .common, line: "Can't swim. Can't fly. Can vibe.", bodyHex: 0x5FA8FF, accentHex: 0x2461B5),
        Creature(id: "grumbo", name: "Grumbo", rarity: .common, line: "Already filing a complaint.", bodyHex: 0x8FA36A, accentHex: 0x56643A),
        Creature(id: "nib", name: "Nib", rarity: .common, line: "Smaller than expected. Louder than expected.", bodyHex: 0xFF8FA3, accentHex: 0xB7445C),
        // Rare
        Creature(id: "velvetine", name: "Velvetine", rarity: .rare, line: "Softer than it has any right to be.", bodyHex: 0xC98BFF, accentHex: 0x7A3FB5),
        Creature(id: "dennis", name: "The Quiet Dennis", rarity: .rare, line: "Says nothing. Knows everything.", bodyHex: 0x9AA4B2, accentHex: 0x4E5866),
        Creature(id: "marmalade", name: "Marmalade Ox", rarity: .rare, line: "Sticky, sturdy, and spreading.", bodyHex: 0xFF7A2F, accentHex: 0xB04A0E),
        Creature(id: "ulp", name: "Ulp", rarity: .rare, line: "Hatched mid-gulp. Still gulping.", bodyHex: 0x6FE3D2, accentHex: 0x2E8C80),
        // Legendary
        Creature(id: "chairman", name: "Chairman Egg", rarity: .legendary, line: "Hatched from an egg. Is also an egg. Don't ask.", bodyHex: 0xF5E9C8, accentHex: 0xC9A84A),
        Creature(id: "tuesday", name: "The Long Tuesday", rarity: .legendary, line: "A creature made entirely of afternoons.", bodyHex: 0xFFD166, accentHex: 0x8A5CFF),
    ]

    static func creature(id: String) -> Creature? { all.first { $0.id == id } }

    static func creatures(of rarity: CreatureRarity) -> [Creature] { all.filter { $0.rarity == rarity } }

    /// One rarity roll, then one pick inside that tier, avoiding an immediate repeat where possible.
    static func draw(random: (Int) -> Int, avoiding lastID: String? = nil) -> Creature {
        let rarity = CreatureRarity.forRoll(random(100))
        var pool = creatures(of: rarity)
        if pool.isEmpty { pool = all }
        let candidates = pool.count > 1 ? pool.filter { $0.id != lastID } : pool
        return candidates[ToyRandom.index(count: candidates.count, random: random)]
    }
}

enum EggStage: Equatable {
    case intact
    case hairline
    case cracked
    case shaking
    case hatched(Creature)

    var accessibilityDescription: String {
        switch self {
        case .intact: return "Intact"
        case .hairline: return "Hairline crack"
        case .cracked: return "Cracked"
        case .shaking: return "Shaking, about to hatch"
        case .hatched(let creature): return "Hatched \(creature.name), \(creature.rarity.title)"
        }
    }
}

/// Egg that cracks over a few taps and hatches a creature. Pure state; no counting.
struct EggToy: TapToy {
    static let kind = ToyKind.egg
    /// Taps needed to hatch, drawn at each reset.
    static let hatchTapRange = 5...9

    private let random: (Int) -> Int
    private(set) var tapsThisCycle = 0
    private(set) var tapsToHatch = EggToy.hatchTapRange.lowerBound
    private(set) var hatched: Creature?
    private(set) var lastCreatureID: String?

    init(random: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }) {
        self.random = random
        reset()
    }

    var isResolved: Bool { hatched != nil }

    var tension: Double {
        if hatched != nil { return 1 }
        return min(1, Double(tapsThisCycle) / Double(tapsToHatch))
    }

    var stage: EggStage {
        if let hatched { return .hatched(hatched) }
        if tapsThisCycle == 0 { return .intact }
        if tension < 0.4 { return .hairline }
        if tension < 0.75 { return .cracked }
        return .shaking
    }

    mutating func tap() -> Creature? {
        if hatched != nil { reset() }
        tapsThisCycle = tapsThisCycle.saturatingIncremented()
        guard tapsThisCycle >= tapsToHatch else { return nil }
        let creature = CreatureCatalog.draw(random: random, avoiding: lastCreatureID)
        hatched = creature
        lastCreatureID = creature.id
        return creature
    }

    mutating func reset() {
        tapsThisCycle = 0
        hatched = nil
        tapsToHatch = ToyRandom.draw(in: Self.hatchTapRange, random: random)
    }
}

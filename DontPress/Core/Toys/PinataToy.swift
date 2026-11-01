import Foundation

enum PinataPrizeRarity: String, CaseIterable, Equatable {
    case common, rare, legendary

    var title: String { rawValue.capitalized }

    /// Percent chance of each tier on a burst. Drawn with one `random(100)` roll.
    static let legendaryPercent = 6
    static let rarePercent = 24

    static func forRoll(_ roll: Int) -> PinataPrizeRarity {
        if roll < legendaryPercent { return .legendary }
        if roll < legendaryPercent + rarePercent { return .rare }
        return .common
    }
}

/// Something that falls out of the piñata. Data only; the view draws the confetti.
struct PinataPrize: Equatable, Identifiable {
    let id: String
    let name: String
    let rarity: PinataPrizeRarity
    /// One short funny line shown when it spills out.
    let line: String
    /// Confetti colour for this prize (hex so Core stays UI-free).
    let colorHex: UInt32

    /// The reaction line after a burst.
    var burstLine: String { "The piñata gave up: \(name). \(line)" }
}

/// Curated, original prizes. Deliberately useless.
enum PinataPrizeCatalog {
    static let all: [PinataPrize] = [
        // Common
        PinataPrize(id: "sock", name: "A Single Sock", rarity: .common, line: "Left. Always left.", colorHex: 0x9FD1FF),
        PinataPrize(id: "coupon", name: "An Expired Coupon", rarity: .common, line: "Ten percent off something that no longer exists.", colorHex: 0xF2A64B),
        PinataPrize(id: "pebble", name: "A Decorative Pebble", rarity: .common, line: "It's decorative. It decorates.", colorHex: 0xB9B5E6),
        PinataPrize(id: "lint", name: "Lint of Distinction", rarity: .common, line: "Pocket-aged. Full-bodied.", colorHex: 0xC9BFA8),
        PinataPrize(id: "confetto", name: "One (1) Confetto", rarity: .common, line: "The singular of confetti. You earned it.", colorHex: 0xFF8FA3),
        PinataPrize(id: "handshake", name: "A Firm Handshake", rarity: .common, line: "From nobody in particular.", colorHex: 0x8FA36A),
        PinataPrize(id: "receipt", name: "A Receipt for the Piñata", rarity: .common, line: "No refunds. It was clearly used.", colorHex: 0xF3ECDC),
        // Rare
        PinataPrize(id: "spork", name: "The Golden Spork", rarity: .rare, line: "Neither here nor there. Beautifully.", colorHex: 0xFFD166),
        PinataPrize(id: "trophy", name: "A Tiny Trophy for Persistence", rarity: .rare, line: "Engraved with one word: STOP.", colorHex: 0xC98BFF),
        PinataPrize(id: "candy", name: "A Self-Aware Candy", rarity: .rare, line: "It knows what it is. Do you?", colorHex: 0x6FE3D2),
        // Legendary
        PinataPrize(id: "deed", name: "The Deed to the Button", rarity: .legendary, line: "Non-binding. Deeply flattering.", colorHex: 0xFF3347),
        PinataPrize(id: "pinata", name: "A Second, Smaller Piñata", rarity: .legendary, line: "It's piñatas all the way down.", colorHex: 0xFF7A2F),
    ]

    static func prize(id: String) -> PinataPrize? { all.first { $0.id == id } }

    static func prizes(of rarity: PinataPrizeRarity) -> [PinataPrize] { all.filter { $0.rarity == rarity } }

    /// One rarity roll, then one pick inside that tier, avoiding an immediate repeat where possible.
    static func draw(random: (Int) -> Int, avoiding lastID: String? = nil) -> PinataPrize {
        let rarity = PinataPrizeRarity.forRoll(random(100))
        var pool = prizes(of: rarity)
        if pool.isEmpty { pool = all }
        let candidates = pool.count > 1 ? pool.filter { $0.id != lastID } : pool
        return candidates[ToyRandom.index(count: candidates.count, random: random)]
    }
}

enum PinataStage: Equatable {
    /// Hanging, untouched (or just nudged).
    case swinging
    case dented
    case cracked
    case burst(PinataPrize)

    var accessibilityDescription: String {
        switch self {
        case .swinging: return "Hanging, swinging"
        case .dented: return "Dented"
        case .cracked: return "Cracked, about to burst"
        case .burst(let prize): return "Burst. It dropped \(prize.name), \(prize.rarity.title)"
        }
    }
}

/// Piñata that takes a hidden number of hits, dents, cracks, then bursts and spills a prize.
/// Pure state; no counting. The mythic toy: see `PinataGate` for who may select it.
struct PinataToy: TapToy {
    static let kind = ToyKind.pinata
    /// Hits needed to burst, drawn at each reset. Never shown to the player.
    static let hitRange = 12...25

    private let random: (Int) -> Int
    private(set) var tapsThisCycle = 0
    private(set) var hitsToBurst = PinataToy.hitRange.lowerBound
    private(set) var prize: PinataPrize?
    private(set) var lastPrizeID: String?

    init(random: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }) {
        self.random = random
        reset()
    }

    var isResolved: Bool { prize != nil }
    var isBurst: Bool { isResolved }

    var tension: Double {
        if prize != nil { return 1 }
        return min(1, Double(tapsThisCycle) / Double(hitsToBurst))
    }

    var stage: PinataStage {
        if let prize { return .burst(prize) }
        if tension < 0.35 { return .swinging }
        if tension < 0.7 { return .dented }
        return .cracked
    }

    /// +1 or -1: the side the piñata swings towards after the latest hit. Purely visual.
    var swingDirection: Int { tapsThisCycle.isMultiple(of: 2) ? 1 : -1 }

    mutating func tap() -> PinataPrize? {
        if prize != nil { reset() }
        tapsThisCycle = tapsThisCycle.saturatingIncremented()
        guard tapsThisCycle >= hitsToBurst else { return nil }
        let drawn = PinataPrizeCatalog.draw(random: random, avoiding: lastPrizeID)
        prize = drawn
        lastPrizeID = drawn.id
        return drawn
    }

    mutating func reset() {
        tapsThisCycle = 0
        prize = nil
        hitsToBurst = ToyRandom.draw(in: Self.hitRange, random: random)
    }
}

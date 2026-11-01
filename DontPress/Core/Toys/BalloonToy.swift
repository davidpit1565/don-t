import Foundation

/// Curated pop punchlines. Short, original, never unkind.
enum BalloonPunchlines {
    static let all: [String] = [
        "It had a good run. Briefly.",
        "That was the balloon's whole life.",
        "Pop. Reflect.",
        "You heard it. The neighbours heard it.",
        "Pressure: released. Dignity: not.",
        "Balloon status: former.",
        "That one's on you.",
        "Loud. Pointless. Perfect.",
        "It trusted you.",
        "Textbook overinflation.",
        "Somewhere, a party is one balloon short.",
        "A brief, rubbery tragedy.",
    ]
}

/// Balloon that grows with each tap and pops at a hidden random threshold.
/// `tension` approaches 1 without ever revealing the threshold, then snaps to 1 on the pop.
struct BalloonToy: TapToy {
    static let kind = ToyKind.balloon
    static let popTapRange = 6...14
    /// Each tap closes this fraction of the remaining distance to "full".
    static let tensionDecay = 0.8

    private let random: (Int) -> Int
    private(set) var tapsThisCycle = 0
    private(set) var popThreshold = BalloonToy.popTapRange.lowerBound
    private(set) var punchline: String?
    private(set) var lastPunchlineIndex: Int?

    init(random: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }) {
        self.random = random
        reset()
    }

    var isResolved: Bool { punchline != nil }
    var isPopped: Bool { isResolved }

    var tension: Double {
        if isPopped { return 1 }
        return 1 - pow(Self.tensionDecay, Double(tapsThisCycle))
    }

    var accessibilityDescription: String {
        if isPopped { return "Popped" }
        if tapsThisCycle == 0 { return "Deflated" }
        return "Inflated \(Int((tension * 100).rounded())) percent"
    }

    mutating func tap() -> String? {
        if isPopped { reset() }
        tapsThisCycle = tapsThisCycle.saturatingIncremented()
        guard tapsThisCycle >= popThreshold else { return nil }
        let lines = BalloonPunchlines.all
        var indices = Array(lines.indices)
        if indices.count > 1, let last = lastPunchlineIndex { indices.removeAll { $0 == last } }
        let chosen = indices[ToyRandom.index(count: indices.count, random: random)]
        lastPunchlineIndex = chosen
        punchline = lines[chosen]
        return punchline
    }

    mutating func reset() {
        tapsThisCycle = 0
        punchline = nil
        popThreshold = ToyRandom.draw(in: Self.popTapRange, random: random)
    }
}

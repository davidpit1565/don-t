import Foundation

/// What sits in the middle of the home screen and receives taps.
/// Every accepted tap on any kind goes through the one counting path (`PressService.registerPress()`);
/// toys only decorate those taps with a small state machine and a payoff.
enum ToyKind: String, CaseIterable, Identifiable {
    case button, egg, balloon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .button: return "Button"
        case .egg: return "Egg"
        case .balloon: return "Balloon"
        }
    }

    /// Stored id if it is a known kind, otherwise the big button.
    static func resolve(id: String?) -> ToyKind {
        guard let id, let kind = ToyKind(rawValue: id) else { return .button }
        return kind
    }
}

/// A pure, Foundation-only tap toy. Randomness is injected (`(upperBound) -> value in 0..<upperBound`,
/// the same closure style as `ReactionEngine`) so every toy is deterministic under test.
protocol TapToy {
    associatedtype Payoff: Equatable

    static var kind: ToyKind { get }

    /// Taps since the toy was last reset. Never counts presses; that is the press service's job.
    var tapsThisCycle: Int { get }
    /// True while the payoff (hatched creature, popped balloon) is showing.
    var isResolved: Bool { get }
    /// 0...1, how close the payoff feels. Exactly 1 while resolved.
    var tension: Double { get }

    /// One accepted tap. Returns the payoff on the tap that resolves the toy, nil otherwise.
    /// A tap on a resolved toy starts a fresh cycle and is applied to that new cycle, so no tap is wasted.
    mutating func tap() -> Payoff?
    /// Back to the idle state with a freshly drawn hidden threshold.
    mutating func reset()
}

/// Shared helper: draws a value inside a closed range from the injected random closure.
enum ToyRandom {
    static func draw(in range: ClosedRange<Int>, random: (Int) -> Int) -> Int {
        let span = range.upperBound - range.lowerBound + 1
        let offset = random(span)
        return range.lowerBound + min(max(offset, 0), span - 1)
    }

    /// Clamped index into a non-empty collection.
    static func index(count: Int, random: (Int) -> Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(random(count), 0), count - 1)
    }
}

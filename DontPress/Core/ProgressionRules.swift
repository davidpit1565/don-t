import Foundation

/// How a toy came to be playable.
enum ToyUnlockSource: Equatable {
    /// Earned by pressing (total presses reached the toy's play threshold), or free from the start.
    case play
    /// Unlocked by owning Pro before the play threshold was reached.
    case pro
}

/// Whether a toy can be selected, and how far the player is from earning it.
enum ToyUnlockState: Equatable {
    case unlocked(by: ToyUnlockSource)
    /// `progress` is total presses clamped to `0...target`. A `target` of 0 means the toy has no
    /// play threshold at all: Pro is the only way in.
    case locked(progress: Int, target: Int)

    var isUnlocked: Bool {
        if case .unlocked = self { return true }
        return false
    }
}

/// Every progression gate for the toys, in one place. Pure functions of `PressStats` (whose
/// `totalPresses` already persists), so no extra storage is needed and counting is never touched.
///
/// Thresholds are reachable on purpose: at roughly 150 presses a day the egg arrives in a couple
/// of days and the balloon in about ten. (15,000 / 100,000 were considered and rejected: 100+ and
/// 600+ days for the toys that are meant to be the hook.)
enum ProgressionRules {
    /// Total presses that unlock the Egg without Pro.
    static let eggTotalPresses = 300
    /// Total presses that unlock the Balloon without Pro.
    static let balloonTotalPresses = 1_500

    /// Play thresholds by toy. The big button is free (0). A kind that is not listed here
    /// (e.g. a newly added toy) has no play threshold and is unlocked by Pro only.
    static let toyThresholds: [ToyKind: Int] = [
        .button: 0,
        .egg: eggTotalPresses,
        .balloon: balloonTotalPresses,
    ]

    /// Total presses needed to unlock `kind` by play, or nil when only Pro unlocks it.
    static func playThreshold(for kind: ToyKind) -> Int? {
        toyThresholds[kind].map { max($0, 0) }
    }

    static func unlockState(for kind: ToyKind, stats: PressStats, isPro: Bool) -> ToyUnlockState {
        let total = max(stats.totalPresses, 0)
        // The piñata is Pro AND play: Pro alone is not enough, play alone is not enough.
        if kind == .pinata {
            if PinataGate.isUnlocked(totalPresses: total, isPro: isPro) { return .unlocked(by: .pro) }
            return .locked(progress: min(total, PinataGate.minTotalPresses), target: PinataGate.minTotalPresses)
        }
        if let target = playThreshold(for: kind), total >= target { return .unlocked(by: .play) }
        if isPro { return .unlocked(by: .pro) }
        guard let target = playThreshold(for: kind) else { return .locked(progress: 0, target: 0) }
        return .locked(progress: min(total, target), target: target)
    }

    /// 0...1 progress towards the play threshold (1 once reached; 0 for a Pro-only toy). Ignores Pro.
    static func fractionToUnlock(for kind: ToyKind, stats: PressStats) -> Double {
        guard let target = playThreshold(for: kind) else { return 0 }
        guard target > 0 else { return 1 }
        let total = max(stats.totalPresses, 0)
        if total >= target { return 1 }
        return Double(total) / Double(target)
    }

    /// Toys whose play threshold was crossed going from `before` to `after` (exactly once per
    /// crossing; free toys never appear). Order follows `ToyKind.allCases`.
    static func newlyUnlockedByPlay(before: PressStats, after: PressStats) -> [ToyKind] {
        ToyKind.allCases.filter { kind in
            guard let target = playThreshold(for: kind), target > 0 else { return false }
            return max(before.totalPresses, 0) < target && max(after.totalPresses, 0) >= target
        }
    }

    /// Banner text for toys just earned by play, or nil when there are none.
    static func unlockMessage(for kinds: [ToyKind]) -> String? {
        guard !kinds.isEmpty else { return nil }
        let names = kinds.map(\.title).joined(separator: ", ")
        return "New toy, earned by pressing: \(names)"
    }

    /// Compact chip label for a locked toy, e.g. "123/300". Nil when there is no play threshold.
    static func progressLabel(for state: ToyUnlockState) -> String? {
        guard case let .locked(progress, target) = state, target > 0 else { return nil }
        return "\(progress)/\(target)"
    }

    /// VoiceOver value for a toy chip.
    static func accessibilityValue(for state: ToyUnlockState) -> String {
        switch state {
        case .unlocked: return ""
        case let .locked(progress, target):
            if target > 0 { return "Locked. \(progress) of \(target) presses, or unlock with Pro" }
            return "Locked. Included with Pro"
        }
    }
}

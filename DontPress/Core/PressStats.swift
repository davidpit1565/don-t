import Foundation

/// The three numbers shown on the home screen.
struct PressStats: Equatable {
    /// Accepted presses in the active app session. Never persisted.
    var currentRun: Int = 0
    /// Highest `currentRun` ever reached on this device. Persisted.
    var personalBest: Int = 0
    /// Cumulative accepted presses across sessions. Persisted.
    var totalPresses: Int = 0
}

/// What a single accepted press produced.
struct PressResult: Equatable {
    let stats: PressStats
    /// True when this press raised the personal best.
    let isNewPersonalBest: Bool
    /// Non-nil only on the press that crosses a milestone.
    let milestone: Int?
}

enum Milestone {
    static let thresholds: [Int] = [10, 25, 50, 100, 250, 500, 1000]

    /// The highest milestone crossed when the run goes from `previous` to `current`.
    static func crossed(from previous: Int, to current: Int) -> Int? {
        thresholds.last { $0 > previous && $0 <= current }
    }
}

extension Int {
    /// Saturating add for non-negative counters. Never traps, never goes negative.
    func saturatingIncremented(by amount: Int = 1) -> Int {
        let base = Swift.max(self, 0)
        let (sum, overflow) = base.addingReportingOverflow(Swift.max(amount, 0))
        return overflow ? Int.max : sum
    }
}

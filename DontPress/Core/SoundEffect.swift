import Foundation

/// Every sound the app can make. All of them are synthesized at runtime by `SoundSynth`;
/// the app ships no audio files.
enum SoundEffect: Hashable, Sendable {
    /// The normal press tick. `stage` escalates the pitch as the run grows (0...maxPressStage).
    case press(stage: Int)
    case milestone
    case achievement
    case unlock
    case balloonSqueak
    case balloonPop
    case eggCrack
    case eggHatch
    case boom
    case error

    /// Highest press stage; higher values are clamped.
    static let maxPressStage = 8
    /// Presses per escalation step.
    static let pressesPerStage = 10

    /// Stage for a given current-run value: `min(currentRun / 10, maxPressStage)`, never negative.
    static func pressStage(forRun run: Int) -> Int {
        Swift.min(Swift.max(run, 0) / pressesPerStage, maxPressStage)
    }

    /// Convenience: the press tick for a given current-run value.
    static func press(forRun run: Int) -> SoundEffect {
        .press(stage: pressStage(forRun: run))
    }

    /// The same effect with an out-of-range press stage clamped, so it maps onto a
    /// preallocated buffer.
    var normalized: SoundEffect {
        if case .press(let stage) = self {
            return .press(stage: Swift.min(Swift.max(stage, 0), Self.maxPressStage))
        }
        return self
    }

    /// Every distinct (normalized) effect, including each press stage.
    static var allCases: [SoundEffect] {
        (0...maxPressStage).map { SoundEffect.press(stage: $0) }
            + [.milestone, .achievement, .unlock, .balloonSqueak, .balloonPop, .eggCrack, .eggHatch, .boom, .error]
    }
}

/// Sounds are optional polish; nothing depends on them for correctness. Implementations
/// must never throw, crash, or block, and must tolerate being called rapidly.
@MainActor
protocol SoundEffects: AnyObject {
    /// Warm up (render/allocate) ahead of the first press. Safe to call more than once.
    func prepare()
    func play(_ effect: SoundEffect)
}

final class NoSounds: SoundEffects {
    func prepare() {}
    func play(_ effect: SoundEffect) {}
}

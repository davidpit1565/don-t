import Foundation

/// "The button fights back": a short, scripted set-piece that plays over the button area
/// when a milestone is crossed. Everything here is pure data; the SwiftUI layer interprets it.
/// Counting never depends on any of this.
struct SetPiece: Equatable, Identifiable {
    let id: String
    /// Human-readable name (also used for accessibility announcements).
    let name: String
    /// The run milestone that triggers it (see `Milestone.thresholds`).
    let milestone: Int
    /// Total length in seconds; the final step always restores the button by this time.
    let duration: TimeInterval
    /// Timed visual steps, sorted by `at` ascending.
    let steps: [SetPieceStep]
    /// The closing line the overlay shows as the set-piece resolves.
    let reactionLine: String
    /// Timed haptic cues, sorted by `at` ascending. Pure data; no UIKit here.
    let haptics: [HapticCue]

    /// Steps to play under Reduce Motion: no scaling, movement, rotation, shaking or glitching.
    /// Captions, the lock card, dimming and flashes stay, so the joke is still readable.
    var reducedMotionSteps: [SetPieceStep] {
        var result: [SetPieceStep] = []
        var hadFlash = false
        for step in steps {
            switch step.action {
            case .scale, .offset, .rotation, .shake, .glitch:
                continue
            case .flash:
                hadFlash = true
                result.append(step)
            case .caption, .lock, .opacity, .restore:
                result.append(step)
            }
        }
        if !hadFlash {
            result.insert(SetPieceStep(at: 0, action: .flash(0.35)), at: 0)
        }
        return result
    }

    /// The steps to play for the given motion preference.
    func steps(reduceMotion: Bool) -> [SetPieceStep] {
        reduceMotion ? reducedMotionSteps : steps
    }
}

/// One timed visual instruction. Geometry values are fractions of the button diameter so the
/// same script works on every screen size.
struct SetPieceStep: Equatable {
    /// Seconds after the set-piece starts.
    let at: TimeInterval
    let action: SetPieceAction
}

enum SetPieceAction: Equatable {
    /// Scale the button (1 = normal).
    case scale(Double)
    /// Move the button by (x, y) in units of its diameter.
    case offset(x: Double, y: Double)
    /// Rotate the button, in degrees.
    case rotation(Double)
    /// Button opacity (1 = normal).
    case opacity(Double)
    /// Shake horizontally with the given amplitude (fraction of diameter) for `cycles` cycles.
    /// A `shake(amplitude: 0, cycles: 0)` stops shaking.
    case shake(amplitude: Double, cycles: Int)
    /// Toggle the "glitch" look (jitter plus colour-split bands).
    case glitch(Bool)
    /// Show (non-nil) or hide (nil) the in-app "button locked" card with a progress value 0...1.
    case lock(progress: Double?)
    /// Show (non-nil) or hide (nil) a short caption over the button area.
    case caption(String?)
    /// Brief full-area flash at the given peak opacity; fades out on its own.
    case flash(Double)
    /// Return every property to normal and hide every overlay.
    case restore
}

/// Haptic plan entry. Interpreted by the UIKit layer; never required for correctness.
struct HapticCue: Equatable {
    enum Kind: Equatable, CaseIterable {
        case light, medium, heavy, success, warning
    }
    let at: TimeInterval
    let kind: Kind
}

/// The scripted set-pieces, one per milestone. Deterministic: a milestone always maps to the
/// same set-piece.
enum SetPieceCatalog {
    static func setPiece(forMilestone milestone: Int) -> SetPiece? {
        all.first { $0.milestone == milestone }
    }

    static let all: [SetPiece] = [flinch, getaway, lockdown, glitch, tremor, gameOver, ending]

    // 10: the button shrinks away, then sheepishly returns.
    static let flinch = SetPiece(
        id: "flinch", name: "The Flinch", milestone: 10, duration: 1.8,
        steps: [
            SetPieceStep(at: 0.00, action: .caption("Nope.")),
            SetPieceStep(at: 0.00, action: .scale(0.55)),
            SetPieceStep(at: 0.70, action: .caption("Fine. Fine.")),
            SetPieceStep(at: 0.90, action: .scale(1.06)),
            SetPieceStep(at: 1.15, action: .scale(1.0)),
            SetPieceStep(at: 1.80, action: .restore),
        ],
        reactionLine: "It flinched. You didn't.",
        haptics: [HapticCue(at: 0, kind: .medium), HapticCue(at: 0.9, kind: .light)]
    )

    // 25: the button leaves the screen, thinks about it, and comes back from the other side.
    static let getaway = SetPiece(
        id: "getaway", name: "The Getaway", milestone: 25, duration: 2.6,
        steps: [
            SetPieceStep(at: 0.00, action: .caption("I'm leaving.")),
            SetPieceStep(at: 0.05, action: .offset(x: 1.6, y: 0)),
            SetPieceStep(at: 0.80, action: .caption("...")),
            SetPieceStep(at: 1.10, action: .offset(x: -1.6, y: 0)),
            SetPieceStep(at: 1.15, action: .caption("I have nowhere else to go.")),
            SetPieceStep(at: 1.30, action: .offset(x: 0, y: 0)),
            SetPieceStep(at: 2.60, action: .restore),
        ],
        reactionLine: "It tried to leave. It came back. Same as you.",
        haptics: [HapticCue(at: 0.05, kind: .light), HapticCue(at: 1.3, kind: .medium)]
    )

    // 50: the button "locks itself" behind an in-app progress bar. The unlock fails. Obviously.
    static let lockdown = SetPiece(
        id: "lockdown", name: "Lockdown", milestone: 50, duration: 3.4,
        steps: [
            SetPieceStep(at: 0.00, action: .lock(progress: 0)),
            SetPieceStep(at: 0.00, action: .opacity(0.55)),
            SetPieceStep(at: 0.10, action: .lock(progress: 0.35)),
            SetPieceStep(at: 0.90, action: .lock(progress: 0.62)),
            SetPieceStep(at: 1.60, action: .lock(progress: 0.97)),
            SetPieceStep(at: 2.30, action: .lock(progress: 1.0)),
            SetPieceStep(at: 2.45, action: .lock(progress: nil)),
            SetPieceStep(at: 2.45, action: .opacity(1.0)),
            SetPieceStep(at: 2.45, action: .caption("Lock failed. It never had a lock.")),
            SetPieceStep(at: 3.40, action: .restore),
        ],
        reactionLine: "Security has been notified. Security is also a button.",
        haptics: [
            HapticCue(at: 0, kind: .medium), HapticCue(at: 0.9, kind: .light),
            HapticCue(at: 1.6, kind: .light), HapticCue(at: 2.3, kind: .warning),
        ]
    )

    // 100: the interface "breaks", then quietly repairs itself.
    static let glitch = SetPiece(
        id: "glitch", name: "The Glitch", milestone: 100, duration: 2.4,
        steps: [
            SetPieceStep(at: 0.00, action: .glitch(true)),
            SetPieceStep(at: 0.00, action: .flash(0.5)),
            SetPieceStep(at: 0.00, action: .rotation(-4)),
            SetPieceStep(at: 0.35, action: .rotation(3)),
            SetPieceStep(at: 0.40, action: .caption("sys: button.integrity = low")),
            SetPieceStep(at: 0.70, action: .rotation(-2)),
            SetPieceStep(at: 1.20, action: .glitch(false)),
            SetPieceStep(at: 1.20, action: .rotation(0)),
            SetPieceStep(at: 1.25, action: .caption("Repaired. Unfortunately.")),
            SetPieceStep(at: 2.40, action: .restore),
        ],
        reactionLine: "Something broke. It wasn't the button.",
        haptics: [
            HapticCue(at: 0, kind: .heavy), HapticCue(at: 0.35, kind: .light),
            HapticCue(at: 0.7, kind: .light), HapticCue(at: 1.2, kind: .success),
        ]
    )

    // 250: a tremor with a haptic crescendo.
    static let tremor = SetPiece(
        id: "tremor", name: "The Tremor", milestone: 250, duration: 2.8,
        steps: [
            SetPieceStep(at: 0.00, action: .caption("Do you feel that?")),
            SetPieceStep(at: 0.00, action: .shake(amplitude: 0.01, cycles: 8)),
            SetPieceStep(at: 0.60, action: .shake(amplitude: 0.03, cycles: 10)),
            SetPieceStep(at: 1.20, action: .shake(amplitude: 0.06, cycles: 12)),
            SetPieceStep(at: 1.90, action: .flash(0.6)),
            SetPieceStep(at: 1.90, action: .shake(amplitude: 0, cycles: 0)),
            SetPieceStep(at: 1.95, action: .caption("That was the button clearing its throat.")),
            SetPieceStep(at: 2.80, action: .restore),
        ],
        reactionLine: "The ground moved. Your finger did not.",
        haptics: [
            HapticCue(at: 0.0, kind: .light), HapticCue(at: 0.3, kind: .light),
            HapticCue(at: 0.6, kind: .medium), HapticCue(at: 0.9, kind: .medium),
            HapticCue(at: 1.2, kind: .heavy), HapticCue(at: 1.45, kind: .heavy),
            HapticCue(at: 1.7, kind: .heavy), HapticCue(at: 1.9, kind: .success),
        ]
    )

    // 500: "GAME OVER". It is not game over. It is never game over.
    static let gameOver = SetPiece(
        id: "game-over", name: "Game Over", milestone: 500, duration: 3.6,
        steps: [
            SetPieceStep(at: 0.00, action: .opacity(0.25)),
            SetPieceStep(at: 0.00, action: .scale(0.92)),
            SetPieceStep(at: 0.10, action: .caption("GAME OVER")),
            SetPieceStep(at: 1.60, action: .caption("GAME OVER (not really)")),
            SetPieceStep(at: 2.20, action: .opacity(1.0)),
            SetPieceStep(at: 2.20, action: .scale(1.0)),
            SetPieceStep(at: 2.25, action: .caption("There is no game. Continue.")),
            SetPieceStep(at: 3.60, action: .restore),
        ],
        reactionLine: "Game over. Press to disagree.",
        haptics: [HapticCue(at: 0, kind: .heavy), HapticCue(at: 2.2, kind: .success)]
    )

    // 1000: the named ending. The button takes a bow, then stays, because it has to.
    static let ending = SetPiece(
        id: "ending", name: "The End of the Button", milestone: 1000, duration: 4.8,
        steps: [
            SetPieceStep(at: 0.00, action: .flash(0.8)),
            SetPieceStep(at: 0.00, action: .caption("THE END OF THE BUTTON")),
            SetPieceStep(at: 0.05, action: .rotation(360)),
            SetPieceStep(at: 0.05, action: .scale(1.12)),
            SetPieceStep(at: 1.40, action: .scale(0.0)),
            SetPieceStep(at: 1.40, action: .opacity(0.0)),
            SetPieceStep(at: 1.60, action: .caption("Starring: you. Also starring: your thumb.")),
            SetPieceStep(at: 3.00, action: .caption("Directed by nobody. Nobody wanted this.")),
            SetPieceStep(at: 3.90, action: .rotation(0)),
            SetPieceStep(at: 3.90, action: .scale(1.0)),
            SetPieceStep(at: 3.90, action: .opacity(1.0)),
            SetPieceStep(at: 3.95, action: .caption("It's still here. So are you.")),
            SetPieceStep(at: 4.80, action: .restore),
        ],
        reactionLine: "One thousand. The button has run out of endings. You haven't.",
        haptics: [
            HapticCue(at: 0.0, kind: .heavy), HapticCue(at: 0.5, kind: .medium),
            HapticCue(at: 1.0, kind: .light), HapticCue(at: 1.4, kind: .warning),
            HapticCue(at: 3.9, kind: .success),
        ]
    )
}

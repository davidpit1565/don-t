import Foundation

/// Pure state machine deciding when a set-piece starts. It never blocks or delays a press:
/// the caller counts every press exactly once before consulting the director, and a press that
/// lands during a set-piece is an ordinary press.
struct SetPieceDirector: Equatable {
    /// What a press did, from the director's point of view.
    enum Outcome: Equatable {
        /// Nothing to show; the press was counted by the caller as usual.
        case none
        /// Start this set-piece now (replacing any set-piece still playing).
        case start(SetPiece)
    }

    /// The set-piece currently playing, if any.
    private(set) var active: SetPiece?
    /// Milestones whose set-piece already played in this run.
    private(set) var playedMilestones: Set<Int> = []
    /// Presses accepted while a set-piece was playing. Exists to make the "never blocked"
    /// guarantee observable in tests.
    private(set) var pressesDuringSetPiece = 0

    /// Presses are always accepted; a set-piece is purely visual.
    var acceptsPresses: Bool { true }

    var isPlaying: Bool { active != nil }

    init() {}

    /// Call once per accepted press, *after* the caller has counted it. `milestone` is the
    /// milestone this press crossed, if any (see `PressResult.milestone`).
    mutating func registerPress(milestone: Int?) -> Outcome {
        if active != nil { pressesDuringSetPiece &+= 1 }
        guard let milestone,
              !playedMilestones.contains(milestone),
              let piece = SetPieceCatalog.setPiece(forMilestone: milestone)
        else { return .none }
        playedMilestones.insert(milestone)
        active = piece
        return .start(piece)
    }

    /// The presenting layer reports that the set-piece with this id has finished (or was
    /// interrupted). A stale id (a set-piece that was already replaced) is ignored.
    mutating func finish(id: String) {
        guard active?.id == id else { return }
        active = nil
    }

    /// A new run (a cold launch creates a new director anyway); every milestone may play again.
    mutating func startNewRun() {
        active = nil
        playedMilestones = []
        pressesDuringSetPiece = 0
    }
}

import Foundation

/// Presses made on one calendar day (across all runs that day). Persisted.
struct DailyProgress: Equatable {
    var day: Int?
    var presses: Int = 0

    func presses(on day: DayStamp) -> Int {
        self.day == day.index ? max(presses, 0) : 0
    }
}

/// Snapshot for the daily-challenge UI and share card.
struct DailySnapshot: Equatable {
    let challenge: DailyChallenge
    let pressesToday: Int
    let result: ChallengeResult
    let streak: Int
    let bestStreak: Int
    let hasFreeze: Bool
    let isRelyingOnFreeze: Bool

    var progressText: String {
        "\(pressesToday.formatted()) of \(challenge.target.formatted())"
    }

    var resultText: String {
        switch result {
        case .pending: return pressesToday == 0 ? "Not started. Ideal, honestly." : "In progress."
        case .success: return "Complete. Stop now. Please."
        case .fail: return "Failed. Spectacularly. Try again tomorrow."
        }
    }
}

/// Owns the daily challenge counter, the day streak and the "signature" (rarest) reaction.
/// Counting stays in `PressService`; this only observes accepted presses.
final class DailyTracker {
    private let store: StatsStoring
    private let calendar: () -> Calendar
    private let now: () -> Date

    private(set) var progress: DailyProgress
    private(set) var streakState: StreakState
    private(set) var signatureReactionID: String?

    init(store: StatsStoring, calendar: @escaping () -> Calendar = { .current }, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.calendar = calendar
        self.now = now
        self.progress = store.loadDailyProgress()
        self.streakState = store.loadStreakState().sanitized()
        self.signatureReactionID = store.loadSignatureReactionID()
    }

    var today: DayStamp { DayStamp(date: now(), calendar: calendar()) }

    var snapshot: DailySnapshot {
        let day = today
        let challenge = DailyChallenge(day: day)
        let presses = progress.presses(on: day)
        return DailySnapshot(
            challenge: challenge,
            pressesToday: presses,
            result: challenge.evaluate(presses: presses),
            streak: StreakTracker.displayedStreak(streakState, on: day),
            bestStreak: streakState.best,
            hasFreeze: StreakTracker.hasFreeze(streakState, on: day),
            isRelyingOnFreeze: StreakTracker.isRelyingOnFreeze(streakState, on: day)
        )
    }

    /// Call once per accepted press. Returns the snapshot and the result before the press,
    /// so callers can react to a change (e.g. challenge just completed).
    @discardableResult
    func recordPress() -> (before: ChallengeResult, after: DailySnapshot) {
        let day = today
        let before = DailyChallenge(day: day).evaluate(presses: progress.presses(on: day))
        if progress.day == day.index {
            progress.presses = max(progress.presses, 0).saturatingIncremented()
        } else {
            progress = DailyProgress(day: day.index, presses: 1)
        }
        streakState = StreakTracker.recordPlay(streakState, on: day)
        store.saveDailyProgress(progress)
        store.saveStreakState(streakState)
        return (before, snapshot)
    }

    /// Remembers the rarest reaction the user has seen. Never affects counting.
    func noteReaction(_ reaction: Reaction) {
        let current = signatureReactionID.flatMap(SignatureReaction.reaction(withID:))
        guard SignatureReaction.isBetter(reaction, than: current) else { return }
        signatureReactionID = reaction.id
        store.saveSignatureReactionID(reaction.id)
    }

    var signatureReaction: Reaction? { signatureReactionID.flatMap(SignatureReaction.reaction(withID:)) }
}

enum SignatureReaction {
    static func reaction(withID id: String) -> Reaction? {
        ReactionCatalog.all.first { $0.id == id } ?? ReactionCatalog.milestones.values.first { $0.id == id }
    }

    /// Maps a displayed line back to its catalog entry (texts are unique in the catalog).
    static func reaction(withText text: String) -> Reaction? {
        ReactionCatalog.all.first { $0.text == text } ?? ReactionCatalog.milestones.values.first { $0.text == text }
    }

    static func score(_ reaction: Reaction) -> Int {
        let tierRank = ReactionTier.allCases.firstIndex(of: reaction.tier) ?? 0
        return tierRank * 2 + (reaction.isRare ? 1 : 0)
    }

    static func isBetter(_ candidate: Reaction, than current: Reaction?) -> Bool {
        guard candidate.id != ReactionCatalog.fallback.id else { return false }
        guard let current else { return true }
        return score(candidate) > score(current)
    }
}

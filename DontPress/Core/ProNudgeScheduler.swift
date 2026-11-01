import Foundation

// MARK: - Pro nudges: soft, honest, rare upgrade prompts
//
// The scheduler decides whether ONE small, dismissible card may appear at a natural moment.
// It never touches counting: the view model calls it only AFTER a press has been counted,
// and it only ever returns an optional value to display.
//
// Hard rules (all unit-tested in ProNudgeSchedulerTests):
// - Never shown to Pro owners (not even user-initiated).
// - User-initiated (tapping a locked toy/style/icon) is always allowed and never counted as a nag.
// - Automatic prompts:
//   - never during the first `minimumLaunches` launches (launches 1...3 show nothing);
//   - never within `quietAfterPress` (3 s) of the last press, so rapid tapping is never interrupted;
//   - at most one per rolling 24 h;
//   - at most 3 within the first 14 days after first launch;
//   - "Not now" snoozes for 24 h × 2^n (n = times "Not now" was chosen), capped at 30 days;
//   - "Don't ask again" is permanent.
// - No countdowns, no scarcity, no discounts, no guilt: see `ProNudgeCopy`.

/// A natural moment at which a soft Pro prompt may be considered.
enum ProNudgeMoment: Equatable {
    /// The user has played a locked toy's progression to >= 80 % of its threshold (fraction 0...1).
    case nearUnlock(toy: ToyKind, progress: Double)
    /// A toy was just unlocked by play.
    case toyUnlockedByPlay(ToyKind)
    /// Today's daily challenge was just completed.
    case dailyChallengeCompleted
    /// The user tapped something locked. User-initiated: always allowed, never counted as a nag.
    case lockedItemTapped(LockedProItem)

    enum Kind: String, CaseIterable {
        case nearUnlock, toyUnlockedByPlay, dailyChallengeCompleted, lockedItemTapped
    }

    var kind: Kind {
        switch self {
        case .nearUnlock: return .nearUnlock
        case .toyUnlockedByPlay: return .toyUnlockedByPlay
        case .dailyChallengeCompleted: return .dailyChallengeCompleted
        case .lockedItemTapped: return .lockedItemTapped
        }
    }

    var isUserInitiated: Bool { kind == .lockedItemTapped }

    /// The progress fraction at which "nearly unlocked" becomes a valid moment.
    static let nearUnlockThreshold = 0.8

    /// Whether the moment is meaningful at all (e.g. 79 % or an already-finished bar is not "near").
    var isValid: Bool {
        switch self {
        case .nearUnlock(_, let progress):
            return progress.isFinite && progress >= Self.nearUnlockThreshold && progress < 1
        default:
            return true
        }
    }
}

/// What the user tapped when a Pro item was locked.
enum LockedProItem: Equatable {
    case toy(ToyKind)
    case buttonStyle
    case appIcon
}

/// One prompt, ready to display.
struct ProNudge: Equatable, Identifiable {
    /// Unique per presentation, so a view can key a transition on it.
    let id: Int
    let moment: ProNudgeMoment
    let copyID: String
    let title: String
    let message: String
    /// Always shown: exactly what Pro includes.
    let proIncludes: [String]
    var isUserInitiated: Bool { moment.isUserInitiated }
}

/// Persisted scheduler state. Every field has a safe default; see the store for decoding.
struct ProNudgeState: Equatable {
    var launchCount: Int = 0
    var firstLaunchAt: Date?
    var lastAutomaticShownAt: Date?
    /// Automatic prompts shown within the first 14 days after `firstLaunchAt`.
    var automaticShownInIntroWindow: Int = 0
    /// Total prompts presented (seeds copy selection).
    var presentedCount: Int = 0
    var notNowCount: Int = 0
    var snoozedUntil: Date?
    var optedOut: Bool = false
    var lastCopyID: String?

    /// Clamps negative counters (corrupt or hand-edited values) to zero.
    func sanitized() -> ProNudgeState {
        var copy = self
        copy.launchCount = max(launchCount, 0)
        copy.automaticShownInIntroWindow = max(automaticShownInIntroWindow, 0)
        copy.presentedCount = max(presentedCount, 0)
        copy.notNowCount = max(notNowCount, 0)
        return copy
    }
}

/// Decides when a soft Pro prompt may appear. Pure logic + an injected clock and store.
final class ProNudgeScheduler {
    struct Rules: Equatable {
        var minimumLaunches = 3
        var quietAfterPress: TimeInterval = 3
        var automaticCooldown: TimeInterval = 24 * 60 * 60
        var introWindow: TimeInterval = 14 * 24 * 60 * 60
        var maxAutomaticInIntroWindow = 3
        var maxSnooze: TimeInterval = 30 * 24 * 60 * 60
        /// A pending moment that was never shown (e.g. the user kept tapping) expires after this.
        var pendingLifetime: TimeInterval = 120
    }

    let rules: Rules
    private let store: StatsStoring
    private let clock: () -> Date
    private let seed: UInt64
    private(set) var state: ProNudgeState
    /// Not persisted: a new process always starts with no recent press and no pending moment.
    private(set) var lastPressAt: Date?
    private(set) var pending: (moment: ProNudgeMoment, at: Date)?

    init(store: StatsStoring, rules: Rules = Rules(), seed: UInt64 = 0x0D07_9E55, clock: @escaping () -> Date = Date.init) {
        self.store = store
        self.rules = rules
        self.clock = clock
        self.seed = seed
        self.state = store.loadProNudgeState().sanitized()
    }

    // MARK: Inputs

    /// Call once per cold process launch.
    func registerLaunch() {
        state.launchCount = state.launchCount >= Int.max - 1 ? Int.max : state.launchCount + 1
        if state.firstLaunchAt == nil { state.firstLaunchAt = clock() }
        persist()
    }

    /// Call after every accepted press. Cheap; never fails; never affects counting.
    func notePress() {
        lastPressAt = clock()
    }

    /// Records an automatic moment as a candidate. It is shown later by `nudgeIfIdle`, once the
    /// user has stopped tapping. A newer moment replaces an older pending one.
    func offer(_ moment: ProNudgeMoment) {
        guard moment.isValid, !moment.isUserInitiated else { return }
        pending = (moment, clock())
    }

    // MARK: Decisions

    /// Returns a prompt for the pending automatic moment if every rule allows it right now,
    /// and records it as shown. Otherwise nil (the pending moment stays until it expires).
    func nudgeIfIdle(isPro: Bool) -> ProNudge? {
        guard let candidate = pending else { return nil }
        let now = clock()
        if now.timeIntervalSince(candidate.at) > rules.pendingLifetime || now < candidate.at {
            pending = nil
            return nil
        }
        guard canShowAutomatic(isPro: isPro) else { return nil }
        pending = nil
        state.lastAutomaticShownAt = now
        if isInIntroWindow(now) { state.automaticShownInIntroWindow += 1 }
        return present(candidate.moment)
    }

    /// The user tapped a locked item. Allowed even after "Don't ask again"; never counted as a nag.
    func nudgeForLockedItem(_ item: LockedProItem, isPro: Bool) -> ProNudge? {
        guard !isPro else { return nil }
        return present(.lockedItemTapped(item))
    }

    /// Whether an automatic prompt would be allowed right now (ignores whether a moment is pending).
    func canShowAutomatic(isPro: Bool) -> Bool {
        let now = clock()
        if isPro || state.optedOut { return false }
        if state.launchCount <= rules.minimumLaunches { return false }
        if let lastPressAt, now.timeIntervalSince(lastPressAt) < rules.quietAfterPress { return false }
        // A clock moved backwards still respects the cooldown; a timestamp absurdly far in the
        // future (corrupt) is ignored rather than silencing the scheduler forever.
        if let last = state.lastAutomaticShownAt, abs(now.timeIntervalSince(last)) < rules.automaticCooldown {
            return false
        }
        if let until = state.snoozedUntil, now < until, until.timeIntervalSince(now) <= rules.maxSnooze { return false }
        if isInIntroWindow(now), state.automaticShownInIntroWindow >= rules.maxAutomaticInIntroWindow { return false }
        return true
    }

    // MARK: Responses

    /// "Not now": snoozes automatic prompts for 24 h × 2^n (n counts every "Not now"), capped at 30 days.
    /// A "Not now" on a user-initiated card changes nothing: the user asked for it.
    func recordNotNow(for nudge: ProNudge) {
        guard !nudge.isUserInitiated else { return }
        state.notNowCount = min(state.notNowCount + 1, 64)
        state.snoozedUntil = clock().addingTimeInterval(snoozeDuration(afterNotNowCount: state.notNowCount))
        persist()
    }

    /// "Don't ask again": automatic prompts never return. Tapping locked items still explains Pro.
    func recordOptOut() {
        state.optedOut = true
        pending = nil
        persist()
    }

    /// Snooze length after the n-th "Not now" (n >= 1): 48 h, 96 h, 8 d, 16 d, then 30 d.
    func snoozeDuration(afterNotNowCount n: Int) -> TimeInterval {
        guard n > 0 else { return 0 }
        let doublings = min(n, 20) // 2^20 days is far beyond the cap; avoids overflow
        return min(rules.automaticCooldown * pow(2, Double(doublings)), rules.maxSnooze)
    }

    // MARK: Private

    private func isInIntroWindow(_ now: Date) -> Bool {
        guard let first = state.firstLaunchAt else { return true }
        return now.timeIntervalSince(first) < rules.introWindow
    }

    private func present(_ moment: ProNudgeMoment) -> ProNudge {
        let line = ProNudgeCopy.pick(for: moment, seed: seed, counter: state.presentedCount, avoiding: state.lastCopyID)
        state.presentedCount = state.presentedCount == Int.max ? 0 : state.presentedCount + 1
        state.lastCopyID = line.id
        persist()
        return ProNudge(
            id: state.presentedCount,
            moment: moment,
            copyID: line.id,
            title: line.title,
            message: ProNudgeCopy.fill(line.message, moment: moment),
            proIncludes: ProNudgeCopy.proIncludes
        )
    }

    private func persist() { store.saveProNudgeState(state) }
}

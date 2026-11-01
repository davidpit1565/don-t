import Foundation

// MARK: - Pro nudges (feat-nudges)
//
// The view model only relays: the scheduler decides, the view displays. None of these methods
// touches the counters, and none is called from inside `press()` except `offer`/`notePress`.
extension HomeViewModel {
    /// Offers an automatic moment (e.g. a toy at >= 80 % of its play threshold, or just unlocked
    /// by play). It is shown later by `checkForNudge()` only if every rule allows it.
    func offerProMoment(_ moment: ProNudgeMoment) {
        guard !isPro else { return }
        nudges?.offer(moment)
    }

    /// Called by the view once the user has stopped tapping (about 3 s after the last press).
    /// Shows at most one card; an existing card is never replaced.
    func checkForNudge() {
        guard pendingNudge == nil, let nudges else { return }
        if isPro { return }
        pendingNudge = nudges.nudgeIfIdle(isPro: isPro)
    }

    /// The user tapped a locked toy, style or icon: always allowed (even after "Don't ask again").
    func showProNudge(for item: LockedProItem) {
        guard !isPro, let nudges else { return }
        pendingNudge = nudges.nudgeForLockedItem(item, isPro: isPro)
    }

    /// "See Pro": the card closes; the view opens ProView. No snooze penalty, no reward.
    func nudgeSeePro() {
        pendingNudge = nil
    }

    /// "Not now": the card closes and automatic prompts back off (doubling, capped at 30 days).
    func nudgeNotNow() {
        guard let nudge = pendingNudge else { return }
        nudges?.recordNotNow(for: nudge)
        pendingNudge = nil
    }

    /// "Don't ask again": automatic prompts stop for good. Tapping locked items still explains Pro.
    func nudgeOptOut() {
        nudges?.recordOptOut()
        pendingNudge = nil
    }
}

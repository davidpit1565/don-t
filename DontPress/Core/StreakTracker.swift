import Foundation

/// Persisted streak data. Day values are `DayStamp.index`.
struct StreakState: Equatable {
    /// Last day the user pressed at least once.
    var lastPlayedDay: Int?
    /// Consecutive played days ending at `lastPlayedDay` (frozen days bridge but do not add).
    var current: Int = 0
    var best: Int = 0
    /// Day that a freeze last covered. One freeze per 7 days.
    var lastFreezeDay: Int?

    /// Day indices a real clock can produce (roughly years 1 to 30000). Anything outside
    /// comes from a corrupt store and is dropped, so day arithmetic can never overflow.
    static let plausibleDayRange = -1_000_000...10_000_000

    /// Clamps anything a corrupt store could produce into a valid state.
    func sanitized() -> StreakState {
        var copy = self
        copy.current = max(current, 0)
        copy.best = max(best, copy.current)
        if let day = copy.lastPlayedDay, !Self.plausibleDayRange.contains(day) { copy.lastPlayedDay = nil }
        if let day = copy.lastFreezeDay, !Self.plausibleDayRange.contains(day) { copy.lastFreezeDay = nil }
        if copy.lastPlayedDay == nil { copy.current = 0 }
        return copy
    }
}

extension Int {
    /// `self - other`, clamped instead of trapping on overflow (for day-index gaps).
    func saturatingDistance(to other: Int) -> Int {
        let (diff, overflow) = self.subtractingReportingOverflow(other)
        if !overflow { return diff }
        return self > other ? Int.max : Int.min
    }
}

/// Consecutive-day streak of days with at least one press. Pure logic over `StreakState`.
enum StreakTracker {
    static let freezeInterval = 7
    /// Moving back by at most this many days is treated as a time-zone hop and ignored.
    static let toleratedBackwardDays = 1

    /// Whether a freeze can cover a missed day `missedDay`.
    static func isFreezeAvailable(_ state: StreakState, forMissedDay missedDay: Int) -> Bool {
        guard let used = state.lastFreezeDay else { return true }
        // A freeze recorded "in the future" (clock moved) never blocks: treat as available.
        if used > missedDay { return true }
        return missedDay.saturatingDistance(to: used) >= freezeInterval
    }

    /// Records that the user played on `day`. Idempotent for the same day.
    static func recordPlay(_ input: StreakState, on day: DayStamp) -> StreakState {
        var state = input.sanitized()
        let today = day.index

        guard let last = state.lastPlayedDay else {
            state.lastPlayedDay = today
            state.current = 1
            state.best = max(state.best, 1)
            return state
        }

        if today == last { return state }

        if today < last {
            // Small backward move (time-zone change): keep everything as it is.
            if last.saturatingDistance(to: today) <= toleratedBackwardDays { return state }
            // Large backward move: the clock was wrong before (or now). Restart safely.
            state.lastPlayedDay = today
            state.current = 1
            if let freeze = state.lastFreezeDay, freeze > today { state.lastFreezeDay = nil }
            return state
        }

        let gap = today.saturatingDistance(to: last)
        if gap == 1 {
            state.current = state.current.saturatingIncremented()
        } else if gap == 2, isFreezeAvailable(state, forMissedDay: today - 1) {
            state.current = state.current.saturatingIncremented()
            state.lastFreezeDay = today - 1
        } else {
            state.current = 1
        }
        state.lastPlayedDay = today
        state.best = max(state.best, state.current)
        return state
    }

    /// The streak to display on `day` (it is still alive if the user played yesterday,
    /// or the day before with a freeze available). Never negative.
    static func displayedStreak(_ input: StreakState, on day: DayStamp) -> Int {
        let state = input.sanitized()
        guard let last = state.lastPlayedDay else { return 0 }
        let gap = day.index.saturatingDistance(to: last)
        if gap <= 1 { return state.current }   // today, yesterday, or a small backward hop
        if gap == 2, isFreezeAvailable(state, forMissedDay: day.index - 1) { return state.current }
        return 0
    }

    /// True when today's play is still needed to keep the streak and a freeze would be consumed.
    static func isRelyingOnFreeze(_ input: StreakState, on day: DayStamp) -> Bool {
        let state = input.sanitized()
        guard let last = state.lastPlayedDay, state.current > 0 else { return false }
        return day.index.saturatingDistance(to: last) == 2 && isFreezeAvailable(state, forMissedDay: day.index - 1)
    }

    /// Whether a freeze is currently banked (not used in the last 7 days).
    static func hasFreeze(_ input: StreakState, on day: DayStamp) -> Bool {
        isFreezeAvailable(input.sanitized(), forMissedDay: day.index)
    }
}

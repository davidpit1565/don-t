import Foundation

/// A calendar day as a plain integer (days since 1970-01-01), derived from the
/// user's local date. Independent of DST and of the user's calendar system.
struct DayStamp: Equatable, Comparable, Hashable {
    let index: Int

    init(index: Int) { self.index = index }

    /// The local day (in `calendar.timeZone`) that contains `date`.
    /// Gregorian components are used regardless of the calendar's identifier, so a
    /// Buddhist or Hebrew calendar gives the same day as everyone else in that time zone.
    init(date: Date, calendar: Calendar = .current) {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = calendar.timeZone
        let parts = local.dateComponents([.year, .month, .day], from: date)
        self.index = DayStamp.index(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// Days since 1970-01-01 for a proleptic Gregorian date (pure arithmetic, no time zones).
    static func index(year: Int, month: Int, day: Int) -> Int {
        // Howard Hinnant's days_from_civil.
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let m = month
        let doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    static func < (lhs: DayStamp, rhs: DayStamp) -> Bool { lhs.index < rhs.index }
}

/// Outcome of today's challenge so far.
enum ChallengeResult: Equatable {
    case pending
    case success
    case fail
}

/// One deterministic challenge per calendar day, the same for everyone, derived only from the date.
struct DailyChallenge: Equatable {
    enum Kind: Equatable {
        /// Press exactly `n` times today. One more and it is over.
        case exactly(Int)
        /// End the day somewhere in `low...high`. Above `high` fails.
        case between(Int, Int)
        /// Press at least `n` times today.
        case atLeast(Int)
        /// Stop on a multiple of `k` that is at least `minimum`. Can be lost and regained.
        case stopOnMultiple(of: Int, minimum: Int)
    }

    /// 2026-01-01 is Day 1.
    static let epoch = DayStamp(index: DayStamp.index(year: 2026, month: 1, day: 1))

    let day: DayStamp
    let kind: Kind

    /// Days since the epoch, starting at 1. Can be zero or negative if the clock is before 2026.
    var dayNumber: Int { day.index - Self.epoch.index + 1 }

    init(day: DayStamp) {
        self.day = day
        self.kind = Self.kind(for: day)
    }

    /// Explicit kind, for tests and previews.
    init(day: DayStamp, kind: Kind) {
        self.day = day
        self.kind = kind
    }

    init(date: Date, calendar: Calendar = .current) {
        self.init(day: DayStamp(date: date, calendar: calendar))
    }

    /// Pure: today's press count in, verdict out.
    func evaluate(presses rawPresses: Int) -> ChallengeResult {
        let presses = max(rawPresses, 0)
        switch kind {
        case .exactly(let n):
            if presses < n { return .pending }
            return presses == n ? .success : .fail
        case .between(let low, let high):
            if presses < low { return .pending }
            return presses <= high ? .success : .fail
        case .atLeast(let n):
            return presses >= n ? .success : .pending
        case .stopOnMultiple(let k, let minimum):
            return presses >= minimum && presses % k == 0 ? .success : .pending
        }
    }

    /// The target number used for progress display.
    var target: Int {
        switch kind {
        case .exactly(let n), .atLeast(let n): return n
        case .between(_, let high): return high
        case .stopOnMultiple(_, let minimum): return minimum
        }
    }

    var title: String {
        switch kind {
        case .exactly(let n): return "Press it exactly \(n) times."
        case .between(let low, let high): return "Press it between \(low) and \(high) times."
        case .atLeast(let n): return "Press it at least \(n) times."
        case .stopOnMultiple(let k, let minimum): return "Stop on a multiple of \(k). At least \(minimum)."
        }
    }

    var detail: String {
        switch kind {
        case .exactly: return "Not one more. Every press today counts, across every run."
        case .between: return "Overshoot and it is over. Every press today counts."
        case .atLeast: return "Today the button is, reluctantly, asking for it."
        case .stopOnMultiple: return "Land on it and stop. Overshoot and you can try for the next one."
        }
    }

    // MARK: Deterministic generation

    private static func kind(for day: DayStamp) -> Kind {
        var rng = SplitMix64(seed: UInt64(bitPattern: Int64(day.index)) ^ 0xD0_17_B7_E5_5A_11_7E_D5)
        switch rng.next(100) {
        case 0..<40:
            return .exactly(7 + rng.next(36))                 // 7...42
        case 40..<65:
            let low = 15 + rng.next(46)                       // 15...60
            return .between(low, low + 2 + rng.next(4))       // window of 3...6
        case 65..<85:
            return .atLeast(50 + rng.next(101))               // 50...150
        default:
            let k = 6 + rng.next(4)                           // 6...9
            return .stopOnMultiple(of: k, minimum: k * (3 + rng.next(3)))
        }
    }
}

/// Tiny, stable PRNG. Must never change, or every past day would get a new challenge.
struct SplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func nextUInt64() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform-enough value in 0..<upperBound.
    mutating func next(_ upperBound: Int) -> Int {
        guard upperBound > 1 else { return 0 }
        return Int(nextUInt64() % UInt64(upperBound))
    }
}

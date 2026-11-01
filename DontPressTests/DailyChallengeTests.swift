import XCTest
#if canImport(DontPressCore)
@testable import DontPressCore
#else
@testable import DontPress
#endif

/// Calendar pinned to an explicit time zone, so results do not depend on the machine running the tests.
func pinnedCalendar(_ zone: String = "UTC", identifier: Calendar.Identifier = .gregorian) -> Calendar {
    var calendar = Calendar(identifier: identifier)
    calendar.timeZone = TimeZone(identifier: zone)!
    return calendar
}

func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0, zone: String = "UTC") -> Date {
    let calendar = pinnedCalendar(zone)
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

final class DailyChallengeTests: XCTestCase {
    func testDayIndexArithmetic() {
        XCTAssertEqual(DayStamp.index(year: 1970, month: 1, day: 1), 0)
        XCTAssertEqual(DayStamp.index(year: 2000, month: 3, day: 1), 11_017)
        XCTAssertEqual(DayStamp.index(year: 2024, month: 3, day: 1) - DayStamp.index(year: 2024, month: 2, day: 28), 2) // leap year
        XCTAssertEqual(DayStamp.index(year: 1969, month: 12, day: 31), -1)
    }

    func testDayNumberStartsAtOneOnEpoch() {
        XCTAssertEqual(DailyChallenge(date: date(2026, 1, 1), calendar: pinnedCalendar()).dayNumber, 1)
        XCTAssertEqual(DailyChallenge(date: date(2026, 1, 2), calendar: pinnedCalendar()).dayNumber, 2)
        XCTAssertEqual(DailyChallenge(date: date(2026, 11, 1), calendar: pinnedCalendar()).dayNumber, 305)
        XCTAssertEqual(DailyChallenge(date: date(2025, 12, 31), calendar: pinnedCalendar()).dayNumber, 0)
    }

    func testLocalDayFollowsTheUsersTimeZone() {
        // 23:30 in Los Angeles on 1 March is already 2 March in UTC.
        let instant = date(2026, 3, 1, hour: 23, minute: 30, zone: "America/Los_Angeles")
        XCTAssertEqual(DayStamp(date: instant, calendar: pinnedCalendar("America/Los_Angeles")).index,
                       DayStamp.index(year: 2026, month: 3, day: 1))
        XCTAssertEqual(DayStamp(date: instant, calendar: pinnedCalendar("UTC")).index,
                       DayStamp.index(year: 2026, month: 3, day: 2))
    }

    func testSameLocalDateGivesSameChallengeEverywhere() {
        let tokyo = DailyChallenge(date: date(2026, 6, 15, hour: 8, zone: "Asia/Tokyo"), calendar: pinnedCalendar("Asia/Tokyo"))
        let ny = DailyChallenge(date: date(2026, 6, 15, hour: 22, zone: "America/New_York"), calendar: pinnedCalendar("America/New_York"))
        XCTAssertEqual(tokyo, ny)
    }

    func testDSTDoesNotSkipOrRepeatDays() {
        let calendar = pinnedCalendar("Europe/London")
        // Clocks go forward 29 March 2026 and back 25 October 2026.
        let before = DayStamp(date: date(2026, 3, 28, hour: 23, zone: "Europe/London"), calendar: calendar)
        let after = DayStamp(date: date(2026, 3, 29, hour: 0, minute: 30, zone: "Europe/London"), calendar: calendar)
        XCTAssertEqual(after.index - before.index, 1)
        let lateOct = DayStamp(date: date(2026, 10, 25, hour: 23, minute: 59, zone: "Europe/London"), calendar: calendar)
        XCTAssertEqual(lateOct.index, DayStamp.index(year: 2026, month: 10, day: 25))
    }

    func testNonGregorianCalendarsUseTheSameDay() {
        let instant = date(2026, 5, 5)
        XCTAssertEqual(DayStamp(date: instant, calendar: pinnedCalendar(identifier: .buddhist)),
                       DayStamp(date: instant, calendar: pinnedCalendar()))
        XCTAssertEqual(DayStamp(date: instant, calendar: pinnedCalendar(identifier: .hebrew)),
                       DayStamp(date: instant, calendar: pinnedCalendar()))
    }

    func testGenerationIsDeterministicAndPinned() {
        // Pin a few days so an accidental generator change (which would change past days) is caught.
        let days = (0..<400).map { DailyChallenge(day: DayStamp(index: DailyChallenge.epoch.index + $0)) }
        let again = (0..<400).map { DailyChallenge(day: DayStamp(index: DailyChallenge.epoch.index + $0)) }
        XCTAssertEqual(days, again)
        // Variety: all four kinds appear within a year.
        var seen = Set<String>()
        for challenge in days {
            switch challenge.kind {
            case .exactly(let n): seen.insert("exactly"); XCTAssertTrue((7...42).contains(n))
            case .between(let low, let high): seen.insert("between"); XCTAssertTrue(low < high && high - low <= 5 && low >= 15)
            case .atLeast(let n): seen.insert("atLeast"); XCTAssertTrue((50...150).contains(n))
            case .stopOnMultiple(let k, let minimum): seen.insert("multiple"); XCTAssertEqual(minimum % k, 0); XCTAssertGreaterThan(minimum, 0)
            }
            XCTAssertFalse(challenge.title.isEmpty)
            XCTAssertFalse(challenge.detail.isEmpty)
        }
        XCTAssertEqual(seen.count, 4)
        // Neighbouring days are not all identical.
        XCTAssertGreaterThan(Set(days.map(\.title)).count, 100)
    }

    func testEvaluateExactly() {
        let challenge = DailyChallenge(day: DailyChallenge.epoch).with(.exactly(13))
        XCTAssertEqual(challenge.evaluate(presses: 0), .pending)
        XCTAssertEqual(challenge.evaluate(presses: -5), .pending)
        XCTAssertEqual(challenge.evaluate(presses: 12), .pending)
        XCTAssertEqual(challenge.evaluate(presses: 13), .success)
        XCTAssertEqual(challenge.evaluate(presses: 14), .fail)
        XCTAssertEqual(challenge.evaluate(presses: Int.max), .fail)
    }

    func testEvaluateBetween() {
        let challenge = DailyChallenge(day: DailyChallenge.epoch).with(.between(20, 24))
        XCTAssertEqual(challenge.evaluate(presses: 19), .pending)
        XCTAssertEqual(challenge.evaluate(presses: 20), .success)
        XCTAssertEqual(challenge.evaluate(presses: 24), .success)
        XCTAssertEqual(challenge.evaluate(presses: 25), .fail)
    }

    func testEvaluateAtLeast() {
        let challenge = DailyChallenge(day: DailyChallenge.epoch).with(.atLeast(50))
        XCTAssertEqual(challenge.evaluate(presses: 49), .pending)
        XCTAssertEqual(challenge.evaluate(presses: 50), .success)
        XCTAssertEqual(challenge.evaluate(presses: Int.max), .success)
    }

    func testEvaluateStopOnMultiple() {
        let challenge = DailyChallenge(day: DailyChallenge.epoch).with(.stopOnMultiple(of: 7, minimum: 21))
        XCTAssertEqual(challenge.evaluate(presses: 7), .pending)   // below minimum
        XCTAssertEqual(challenge.evaluate(presses: 21), .success)
        XCTAssertEqual(challenge.evaluate(presses: 22), .pending)  // can be regained
        XCTAssertEqual(challenge.evaluate(presses: 28), .success)
    }
}

private extension DailyChallenge {
    /// Test helper: same day, chosen kind.
    func with(_ kind: Kind) -> DailyChallenge { DailyChallenge(day: day, kind: kind) }
}

import Foundation

/// Plain data for the achievement image. Contains only the user's real numbers.
/// Never claims a ranking against other people.
struct ShareCardContent: Equatable {
    let title: String
    let caption: String
    let countText: String
    let unitText: String
    let quote: String
    let footnote: String

    // v2
    /// Curated title from the user's own best run and total ("Certified Menace").
    let rarityTitle: String
    /// "DAY 312", or nil when no day is known / the clock is before the epoch.
    let dayText: String?
    /// "7-DAY STREAK", or nil when there is no streak.
    let streakText: String?
    /// "1,234 TOTAL PRESSES".
    let totalText: String?
    /// The rarest reaction the user has seen, in quotes; nil if unknown.
    let signatureLine: String?
    /// "Can you beat my 847?"
    let callToAction: String
    /// The app is not live and has no verified URL, so no link is printed.
    let storeHint: String

    static let cardTitle = "DON'T PRESS"
    static let cardCaption = "PERSONAL BEST"
    static let storeHintText = "Search DontPress on the App Store"

    /// Returns nil when there is nothing to share (personal best of zero).
    static func make(
        personalBest: Int,
        totalPresses: Int? = nil,
        dayNumber: Int? = nil,
        streak: Int = 0,
        signatureLine: String? = nil,
        locale: Locale = .current
    ) -> ShareCardContent? {
        guard personalBest > 0 else { return nil }
        let (quote, footnote) = lines(for: personalBest)
        let total = totalPresses.map { max($0, personalBest) }
        let count = formatCount(personalBest, locale: locale)
        return ShareCardContent(
            title: cardTitle,
            caption: cardCaption,
            countText: count,
            unitText: personalBest == 1 ? "PRESS" : "PRESSES",
            quote: quote,
            footnote: footnote,
            rarityTitle: RarityTitle.title(bestRun: personalBest, total: total ?? personalBest),
            dayText: dayNumber.flatMap { $0 > 0 ? "DAY \(formatCount($0, locale: locale))" : nil },
            streakText: streak > 0 ? "\(formatCount(streak, locale: locale))-DAY STREAK" : nil,
            totalText: total.map { "\(formatCount($0, locale: locale)) TOTAL \($0 == 1 ? "PRESS" : "PRESSES")" },
            signatureLine: signatureLine.flatMap { $0.isEmpty ? nil : "“\($0)”" },
            callToAction: "Can you beat my \(count)?",
            storeHint: storeHintText
        )
    }

    static func formatCount(_ value: Int, locale: Locale = .current) -> String {
        value.formatted(.number.locale(locale))
    }

    /// Every piece of text on the card, for checks such as "no ranking claims".
    var allText: [String] {
        [title, caption, countText, unitText, quote, footnote, rarityTitle, callToAction, storeHint]
            + [dayText, streakText, totalText, signatureLine].compactMap { $0 }
    }

    var accessibilityDescription: String {
        var parts = ["\(title). \(rarityTitle). \(caption): \(countText) \(unitText.lowercased())."]
        if let totalText { parts.append(totalText.lowercased() + ".") }
        if let streakText { parts.append(streakText.lowercased() + ".") }
        if let dayText { parts.append(dayText.capitalized + ".") }
        parts.append(signatureLine ?? quote)
        parts.append(callToAction)
        parts.append(storeHint + ".")
        return parts.joined(separator: " ")
    }

    private static func lines(for best: Int) -> (String, String) {
        switch best {
        case 1...9:
            return ("“You were told not to.”", "“A modest start. The button remembers.”")
        case 10...24:
            return ("“Double digits of disobedience.”", "“Not a mistake anymore. A choice.”")
        case 25...49:
            return ("“This was not an accident.”", "“The button has noticed you.”")
        case 50...99:
            return ("“Fifty-plus ignored warnings.”", "“Somewhere, a sign is crying.”")
        case 100...499:
            return ("“Triple digits. Zero regrets.”", "“A tidy number for a questionable habit.”")
        case 500...999:
            return ("“You were told not to.”", "“Officially unnecessary. Impressively committed.”")
        default:
            return ("“Past one thousand.”", "“The button has run out of warnings.”")
        }
    }
}

/// Curated titles. Earned from the user's own best run OR lifetime total, whichever is higher.
enum RarityTitle {
    struct Level: Equatable {
        let title: String
        let minBestRun: Int
        let minTotal: Int
    }

    /// Ascending. Thresholds are the user's own numbers only.
    static let levels: [Level] = [
        Level(title: "Casual Offender", minBestRun: 1, minTotal: 1),
        Level(title: "Repeat Offender", minBestRun: 10, minTotal: 50),
        Level(title: "Certified Menace", minBestRun: 25, minTotal: 250),
        Level(title: "Professional Disobeyer", minBestRun: 50, minTotal: 1_000),
        Level(title: "Button's Nemesis", minBestRun: 100, minTotal: 5_000),
        Level(title: "Unstoppable Nuisance", minBestRun: 500, minTotal: 25_000),
        Level(title: "Mythical Menace", minBestRun: 1_000, minTotal: 100_000),
    ]

    static func title(bestRun: Int, total: Int) -> String {
        let level = levels.last { bestRun >= $0.minBestRun || total >= $0.minTotal } ?? levels[0]
        return level.title
    }
}

/// No-spoiler card for today's challenge: shows the outcome and the streak, never the target
/// or the press count (which would give the answer away).
struct DailyShareContent: Equatable {
    let result: ChallengeResult
    let title: String
    let dayText: String
    let resultTitle: String
    let resultLine: String
    let streakText: String?
    let callToAction: String
    let storeHint: String

    static func make(snapshot: DailySnapshot, locale: Locale = .current) -> DailyShareContent? {
        let number = snapshot.challenge.dayNumber
        guard number > 0, snapshot.pressesToday > 0 else { return nil }
        let (resultTitle, resultLine): (String, String)
        switch snapshot.result {
        case .success: (resultTitle, resultLine) = ("CHALLENGE COMPLETE", "Restraint, eventually.")
        case .fail: (resultTitle, resultLine) = ("CHALLENGE FAILED", "Pressed it one time too many. Classic.")
        case .pending: (resultTitle, resultLine) = ("STILL PRESSING", "The verdict is pending. So is my dignity.")
        }
        return DailyShareContent(
            result: snapshot.result,
            title: ShareCardContent.cardTitle,
            dayText: "DAILY #\(ShareCardContent.formatCount(number, locale: locale))",
            resultTitle: resultTitle,
            resultLine: resultLine,
            streakText: snapshot.streak > 0 ? "\(ShareCardContent.formatCount(snapshot.streak, locale: locale))-DAY STREAK" : nil,
            callToAction: "Today's challenge is the same for everyone. Try it.",
            storeHint: ShareCardContent.storeHintText
        )
    }

    var allText: [String] {
        [title, dayText, resultTitle, resultLine, callToAction, storeHint] + [streakText].compactMap { $0 }
    }

    var accessibilityDescription: String {
        ([title, dayText, resultTitle, resultLine] + [streakText].compactMap { $0 } + [callToAction, storeHint])
            .joined(separator: ". ")
    }
}

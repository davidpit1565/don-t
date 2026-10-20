import Foundation

/// Plain data for the achievement image. Contains only the user's real personal best.
struct ShareCardContent: Equatable {
    let title: String
    let caption: String
    let countText: String
    let unitText: String
    let quote: String
    let footnote: String

    static let cardTitle = "DON'T PRESS"
    static let cardCaption = "PERSONAL BEST"

    /// Returns nil when there is nothing to share (personal best of zero).
    static func make(personalBest: Int, locale: Locale = .current) -> ShareCardContent? {
        guard personalBest > 0 else { return nil }
        let (quote, footnote) = lines(for: personalBest)
        return ShareCardContent(
            title: cardTitle,
            caption: cardCaption,
            countText: formatCount(personalBest, locale: locale),
            unitText: personalBest == 1 ? "PRESS" : "PRESSES",
            quote: quote,
            footnote: footnote
        )
    }

    static func formatCount(_ value: Int, locale: Locale = .current) -> String {
        value.formatted(.number.locale(locale))
    }

    var accessibilityDescription: String {
        "\(title). \(caption): \(countText) \(unitText.lowercased()). \(quote) \(footnote)"
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

import Foundation

/// A home-screen icon that matches one button style. Classic Red is the primary icon
/// (`iconName == nil`); the others are alternate icon sets in the asset catalog, listed in the
/// app target's ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES build setting.
/// Unlocking follows the matching style exactly: its normal rule, or Pro.
struct AppIconChoice: Equatable, Identifiable {
    let theme: ButtonTheme
    /// Name passed to `UIApplication.setAlternateIconName(_:)`; nil means the primary icon.
    let iconName: String?

    var id: String { theme.id }
    var name: String { theme.name }

    static let iconNames: [String: String] = [
        ButtonTheme.cobalt.id: "AppIcon-Cobalt",
        ButtonTheme.stealth.id: "AppIcon-Stealth",
        ButtonTheme.radioactive.id: "AppIcon-Radioactive",
        ButtonTheme.gold.id: "AppIcon-Gold",
    ]

    /// One choice per button style, in the same order as `ButtonTheme.all`.
    static let all: [AppIconChoice] = ButtonTheme.all.map { AppIconChoice(theme: $0, iconName: iconNames[$0.id]) }

    static let primary = AppIconChoice(theme: .classic, iconName: nil)

    /// The choice for the icon name the system reports; unknown names fall back to the primary icon.
    static func choice(forIconName name: String?) -> AppIconChoice {
        guard let name else { return primary }
        return all.first { $0.iconName == name } ?? primary
    }

    /// Alternate icons are a Pro perk; the classic (primary) icon is always available.
    func isUnlocked(for stats: PressStats, isPro: Bool = false) -> Bool {
        iconName == nil || isPro
    }

    static func statuses(stats: PressStats, isPro: Bool, currentIconName: String?) -> [AppIconStatus] {
        let current = choice(forIconName: currentIconName)
        return all.map {
            AppIconStatus(choice: $0, isUnlocked: $0.isUnlocked(for: stats, isPro: isPro), isSelected: $0 == current)
        }
    }
}

struct AppIconStatus: Identifiable, Equatable {
    let choice: AppIconChoice
    let isUnlocked: Bool
    let isSelected: Bool
    var id: String { choice.id }

    /// Shown under a locked row; mirrors the button-style wording.
    var requirementText: String? {
        isUnlocked ? nil : "Included with Pro"
    }
}

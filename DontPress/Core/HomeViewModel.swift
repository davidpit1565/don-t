import Foundation
import Observation

/// Glue between the press service, reactions, and haptics. Holds no counting logic.
@MainActor
@Observable
final class HomeViewModel {
    private(set) var stats: PressStats
    private(set) var reactionText: String
    /// True once this run has set a new personal best (a tie with an older best does not count).
    private(set) var isAtPersonalBest = false
    private(set) var selectedTheme: ButtonTheme
    /// Whether the Pro purchase is owned (all button styles unlocked). Set by the store layer.
    private(set) var isPro: Bool
    /// One-line banner for newly unlocked achievements / button styles; cleared by the view.
    private(set) var unlockMessage: String?

    /// Increments once per accepted press; views may key light animation on it.
    private(set) var pressCount = 0

    // MARK: Toys (egg / balloon) — see Core/Toys. Observable object; its own properties drive the views.
    let toys: ToySession

    @ObservationIgnored private let service: PressService
    @ObservationIgnored private var reactions: ReactionEngine
    @ObservationIgnored private let haptics: HapticFeedback

    init(service: PressService, reactions: ReactionEngine = ReactionEngine(), haptics: HapticFeedback? = nil,
         toys: ToySession? = nil) {
        self.service = service
        self.reactions = reactions
        let haptics = haptics ?? NoHaptics()
        self.haptics = haptics
        self.toys = toys ?? ToySession(store: service.store)
        self.stats = service.stats
        self.isPro = service.savedIsPro
        self.selectedTheme = ButtonTheme.resolve(id: service.savedThemeID, stats: service.stats, isPro: service.savedIsPro)
        self.reactionText = ReactionCatalog.idle
        haptics.prepare()
    }

    /// One accepted press. Counting happens first; reaction and haptics cannot affect it.
    func press() {
        let before = stats
        let result = service.registerPress()
        stats = result.stats
        // Only a press that actually raised the best counts; merely tying an older best does not.
        if result.isNewPersonalBest { isAtPersonalBest = true }
        pressCount &+= 1

        let newAchievements = Achievement.newlyUnlocked(before: before, after: result.stats)
        // With Pro everything is already unlocked, so earning a style is not news.
        let newThemes = isPro ? [] : ButtonTheme.newlyUnlocked(before: before, after: result.stats)
        if !newAchievements.isEmpty || !newThemes.isEmpty {
            var parts: [String] = []
            if !newAchievements.isEmpty { parts.append("Achievement: " + newAchievements.map(\.title).joined(separator: ", ")) }
            if !newThemes.isEmpty { parts.append("New button style: " + newThemes.map(\.name).joined(separator: ", ")) }
            unlockMessage = parts.joined(separator: " · ")
        }

        if let milestone = result.milestone {
            reactionText = reactions.reaction(forMilestone: milestone).text
            haptics.milestone()
        } else if !newAchievements.isEmpty {
            reactionText = reactions.reaction(forPress: result.stats.currentRun).text
            haptics.milestone()
        } else {
            reactionText = reactions.reaction(forPress: result.stats.currentRun).text
            haptics.press()
        }
    }

    func dismissUnlockMessage() { unlockMessage = nil }

    // MARK: Toys
    /// One accepted tap on the egg or balloon. Counted exactly once through `press()` (counters,
    /// achievements, reaction, haptic), then the toy advances; a hatch or pop replaces the reaction
    /// line and adds the stronger haptic.
    func pressToy() {
        press()
        if let payoffLine = toys.tapSelected() {
            reactionText = payoffLine
            haptics.milestone()
        }
    }

    /// Called when the purchase state changes (purchase, restore, refund). Falls back to
    /// Classic if the selected style is no longer unlocked.
    func setPro(_ value: Bool) {
        guard value != isPro else { return }
        isPro = value
        service.saveIsPro(value)
        selectedTheme = ButtonTheme.resolve(id: selectedTheme.id, stats: stats, isPro: value)
        if selectedTheme.id != service.savedThemeID { service.saveThemeID(selectedTheme.id) }
    }

    /// Choosing a locked style is ignored.
    func selectTheme(_ theme: ButtonTheme) {
        guard theme.isUnlocked(for: stats, isPro: isPro) else { return }
        selectedTheme = theme
        service.saveThemeID(theme.id)
    }

    var themeStatuses: [ThemeStatus] {
        ButtonTheme.all.map {
            ThemeStatus(theme: $0, isUnlocked: $0.isUnlocked(for: stats, isPro: isPro), isSelected: $0 == selectedTheme)
        }
    }

    var achievementStatuses: [AchievementStatus] { AchievementStatus.statuses(for: stats) }

    var unlockedAchievementCount: Int { achievementStatuses.filter(\.isUnlocked).count }

    var shareContent: ShareCardContent? {
        ShareCardContent.make(personalBest: stats.personalBest)
    }
}

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
    /// One-line banner for newly unlocked achievements / button styles; cleared by the view.
    private(set) var unlockMessage: String?

    /// Increments once per accepted press; views may key light animation on it.
    private(set) var pressCount = 0

    @ObservationIgnored private let service: PressService
    @ObservationIgnored private var reactions: ReactionEngine
    @ObservationIgnored private let haptics: HapticFeedback

    init(service: PressService, reactions: ReactionEngine = ReactionEngine(), haptics: HapticFeedback? = nil) {
        self.service = service
        self.reactions = reactions
        let haptics = haptics ?? NoHaptics()
        self.haptics = haptics
        self.stats = service.stats
        self.selectedTheme = ButtonTheme.resolve(id: service.savedThemeID, stats: service.stats)
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
        let newThemes = ButtonTheme.newlyUnlocked(before: before, after: result.stats)
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

    /// Choosing a locked style is ignored.
    func selectTheme(_ theme: ButtonTheme) {
        guard theme.isUnlocked(for: stats) else { return }
        selectedTheme = theme
        service.saveThemeID(theme.id)
    }

    var themeStatuses: [ThemeStatus] {
        ButtonTheme.all.map {
            ThemeStatus(theme: $0, isUnlocked: $0.isUnlocked(for: stats), isSelected: $0 == selectedTheme)
        }
    }

    var achievementStatuses: [AchievementStatus] { AchievementStatus.statuses(for: stats) }

    var unlockedAchievementCount: Int { achievementStatuses.filter(\.isUnlocked).count }

    var shareContent: ShareCardContent? {
        ShareCardContent.make(personalBest: stats.personalBest)
    }
}

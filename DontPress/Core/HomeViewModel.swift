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

    // [audio] Persisted mute setting; on by default.
    private(set) var isSoundEnabled: Bool
    // Reactiondex: lines seen on this device, and whether the latest press revealed a new one.
    private(set) var reactiondex: Reactiondex
    private(set) var isNewDiscovery = false

    @ObservationIgnored private let service: PressService
    @ObservationIgnored private var reactions: ReactionEngine
    @ObservationIgnored private let haptics: HapticFeedback
    @ObservationIgnored private let sounds: SoundEffects // [audio]

    init(service: PressService, reactions: ReactionEngine = ReactionEngine(), haptics: HapticFeedback? = nil,
         sounds: SoundEffects? = nil) {
        self.service = service
        self.reactions = reactions
        let haptics = haptics ?? NoHaptics()
        self.haptics = haptics
        self.stats = service.stats
        self.isPro = service.savedIsPro
        self.selectedTheme = ButtonTheme.resolve(id: service.savedThemeID, stats: service.stats, isPro: service.savedIsPro)
        self.reactionText = ReactionCatalog.idle
        self.reactiondex = Reactiondex(discoveredIDs: service.savedDiscoveredReactionIDs)
        haptics.prepare()
        // [audio]
        let sounds = sounds ?? NoSounds()
        self.sounds = sounds
        self.isSoundEnabled = service.savedSoundEnabled
        if isSoundEnabled { sounds.prepare() }
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

        // Special story/secret/ending line for this exact run count, else milestone, else tier line.
        let line = reactions.storyAwareReaction(forRun: result.stats.currentRun, milestone: result.milestone)
        reactionText = line.text
        if result.milestone != nil || !newAchievements.isEmpty {
            haptics.milestone()
        } else {
            haptics.press()
        }
        recordDiscovery(line)

        // [audio] After counting; sound can never affect the stats.
        if result.milestone != nil { playSound(.milestone) }
        else if !newAchievements.isEmpty { playSound(.achievement) }
        else if !newThemes.isEmpty { playSound(.unlock) }
        else { playSound(.press(forRun: result.stats.currentRun)) }
    }

    // MARK: [audio]

    /// Plays a synthesized effect unless the user muted sounds. Other features (balloon, egg,
    /// boom, errors) can call this too.
    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        sounds.play(effect)
    }

    func setSoundEnabled(_ value: Bool) {
        guard value != isSoundEnabled else { return }
        isSoundEnabled = value
        service.saveSoundEnabled(value)
        if value { sounds.prepare() }
    }

    func dismissUnlockMessage() { unlockMessage = nil }

    // MARK: Reactiondex

    private func recordDiscovery(_ line: Reaction) {
        isNewDiscovery = reactiondex.record(line.id)
        if isNewDiscovery { service.saveDiscoveredReactionIDs(reactiondex.persistableIDs) }
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

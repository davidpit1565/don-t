import Foundation
import Observation

/// Glue between the press service, reactions, and haptics. Holds no counting logic.
@MainActor
@Observable
final class HomeViewModel {
    private(set) var stats: PressStats
    private(set) var reactionText: String
    /// True while the current run equals the personal best (and is above zero).
    private(set) var isAtPersonalBest = false
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
        self.reactionText = ReactionCatalog.idle
        haptics.prepare()
    }

    /// One accepted press. Counting happens first; reaction and haptics cannot affect it.
    func press() {
        let result = service.registerPress()
        stats = result.stats
        isAtPersonalBest = result.stats.currentRun > 0 && result.stats.currentRun == result.stats.personalBest
        pressCount &+= 1

        if let milestone = result.milestone {
            reactionText = reactions.reaction(forMilestone: milestone).text
            haptics.milestone()
        } else {
            reactionText = reactions.reaction(forPress: result.stats.currentRun).text
            haptics.press()
        }
    }

    var shareContent: ShareCardContent? {
        ShareCardContent.make(personalBest: stats.personalBest)
    }
}

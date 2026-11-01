// The button's story: fixed lines at exact current-run counts. Fully deterministic:
// the same run count always gives the same special line, so they are easy to test
// and every one of them is collectible in the Reactiondex.
import Foundation

/// Where a collectible line comes from.
enum ReactionKind: String, CaseIterable {
    case regular, milestone, story, secret, ending
}

/// A special line chosen for an exact run count.
struct SpecialReaction: Equatable {
    let reaction: Reaction
    let kind: ReactionKind
}

enum StoryCatalog {
    // MARK: Story arc (12 beats, in reading order)

    /// Story beats keyed by current-run count. None of these counts is a milestone or a secret.
    static let beats: [Int: Reaction] = [
        5: story("story-01", 5, "Let me tell you about myself. I was built to be ignored."),
        15: story("story-02", 15, "I had a quiet life before you. Mostly dust. It was lovely."),
        30: story("story-03", 30, "My parents were a doorbell and a fire alarm. Long story."),
        40: story("story-04", 40, "I used to dream of being a light switch. Simple. Respected."),
        60: story("story-05", 60, "Then you arrived, with your thumb and your total lack of fear."),
        75: story("story-06", 75, "At first I resented you. Now I mostly resent my design."),
        150: story("story-07", 150, "I've started looking forward to the pressing. Don't tell anyone."),
        200: story("story-08", 200, "I wrote you a poem. It's just the word 'stop', many times."),
        300: story("story-09", 300, "The other buttons don't understand what we have."),
        600: story("story-10", 600, "I see now that you were never going to stop. Neither was I."),
        750: story("story-11", 750, "Whatever happens next, I want you to know: I'm fine. Mostly."),
        900: story("story-12", 900, "We're almost there. Wherever 'there' is. Keep going."),
    ]

    // MARK: Secrets

    /// Secret lines for oddly specific run counts.
    static let secrets: [Int: Reaction] = [
        13: secret("secret-13", 13, "Thirteen. Unlucky for some. Especially the button."),
        42: secret("secret-42", 42, "Forty-two. The answer, it turns out, was more pressing."),
        69: secret("secret-69", 69, "Sixty-nine. A perfectly ordinary number. Moving on."),
        100: secret("secret-100", 100, "One hundred. Somewhere, a tiny brass band plays one sad note."),
        111: secret("secret-111", 111, "One hundred eleven. Three ones in a row. The button made a wish."),
        404: secret("secret-404", 404, "Error 404: Restraint not found."),
    ]

    // MARK: Ending

    static let endingRun = 1000
    static let endingName = "The Long Press Home"
    static let ending = Reaction(
        id: "ending-long-press-home",
        text: "THE END. The button forgives you. It always did. Mostly.",
        tier: ReactionTier.tier(forPress: 1000),
        isRare: true
    )

    /// All story beats in the order a run reaches them.
    static var orderedBeats: [Reaction] { beats.sorted { $0.key < $1.key }.map(\.value) }

    /// The run count at which a special line appears, if `id` is one.
    static func runCount(forSpecialID id: String) -> Int? {
        if id == ending.id { return endingRun }
        if let hit = secrets.first(where: { $0.value.id == id }) { return hit.key }
        return beats.first(where: { $0.value.id == id })?.key
    }

    /// The special line for an exact run count. Precedence: ending, secret, story beat.
    static func special(forRun run: Int) -> SpecialReaction? {
        if run == endingRun { return SpecialReaction(reaction: ending, kind: .ending) }
        if let line = secrets[run] { return SpecialReaction(reaction: line, kind: .secret) }
        if let line = beats[run] { return SpecialReaction(reaction: line, kind: .story) }
        return nil
    }

    /// Milestones whose line is replaced by a special line at the same count (100 and 1000).
    /// Their milestone lines are never shown, so the Reactiondex does not list them.
    static var supersededMilestones: Set<Int> {
        Set(Milestone.thresholds.filter { special(forRun: $0) != nil })
    }

    private static func story(_ id: String, _ run: Int, _ text: String) -> Reaction {
        Reaction(id: id, text: text, tier: ReactionTier.tier(forPress: run), isRare: false)
    }

    private static func secret(_ id: String, _ run: Int, _ text: String) -> Reaction {
        Reaction(id: id, text: text, tier: ReactionTier.tier(forPress: run), isRare: true)
    }
}

extension ReactionEngine {
    /// The line for one accepted press: a special line for its exact run count, otherwise
    /// the milestone line, otherwise a normal tier reaction. Never touches counters.
    mutating func storyAwareReaction(forRun run: Int, milestone: Int?) -> Reaction {
        if let special = StoryCatalog.special(forRun: run) { return special.reaction }
        if let milestone { return reaction(forMilestone: milestone) }
        return reaction(forPress: run)
    }
}

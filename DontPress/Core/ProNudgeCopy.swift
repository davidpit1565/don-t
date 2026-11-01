import Foundation

/// Curated, original, honest prompt copy. Rules for every line:
/// no countdowns, no "limited time", no fake discounts, no scarcity, no guilt, no claims about
/// other users. Short, dry, in the app's voice. The card always lists `proIncludes` separately.
/// Placeholders: `{toy}` (e.g. "the Egg") and `{item}` (e.g. "that button style").
enum ProNudgeCopy {
    struct Line: Equatable {
        let id: String
        let title: String
        let message: String
    }

    /// Mirrors ProView's feature list. Keep the two in sync.
    static let proIncludes = [
        "The Egg and the Balloon toys",
        "All 5 button styles right away",
        "4 alternate app icons",
        "One-time purchase. No subscription",
    ]

    static let nearUnlock: [Line] = [
        Line(id: "near.1", title: "Almost there.", message: "{toy} is nearly yours. Keep pressing, or let Pro skip the queue."),
        Line(id: "near.2", title: "So close.", message: "A few more presses unlock {toy}. Pro unlocks it now. Both are fine."),
        Line(id: "near.3", title: "Nearly earned.", message: "You've done most of the work for {toy}. Pro is the shortcut, not the requirement."),
        Line(id: "near.4", title: "The finish line is visible.", message: "{toy} is within reach. Carry on, or take the Pro elevator."),
        Line(id: "near.5", title: "Progress report.", message: "{toy}: mostly unlocked. Pro: completely unlocked. Your call."),
        Line(id: "near.6", title: "A small heads-up.", message: "{toy} is close. If you'd rather not wait, Pro has it ready."),
        Line(id: "near.7", title: "Look at you go.", message: "Persistence is about to pay off with {toy}. Pro also exists, quietly."),
        Line(id: "near.8", title: "Nearly.", message: "Keep going for {toy}, or open Pro and skip ahead. No pressure. Well, some pressing."),
    ]

    static let toyUnlockedByPlay: [Line] = [
        Line(id: "unlocked.1", title: "Earned it.", message: "{toy} is unlocked. Pro skips the wait next time."),
        Line(id: "unlocked.2", title: "Unlocked the hard way.", message: "Respect. If you'd like everything at once, that's what Pro is."),
        Line(id: "unlocked.3", title: "You did that.", message: "{toy} is yours. Pro unlocks the rest without the grind."),
        Line(id: "unlocked.4", title: "New toy.", message: "Enjoy {toy}. The rest of the collection is in Pro, if you're curious."),
        Line(id: "unlocked.5", title: "Officially unnecessary.", message: "And officially unlocked. Pro opens everything else in one go."),
        Line(id: "unlocked.6", title: "Achievement: patience.", message: "{toy} unlocked by sheer pressing. Pro is the impatient option."),
        Line(id: "unlocked.7", title: "That worked.", message: "{toy} is ready. Next time, Pro can skip straight to this part."),
        Line(id: "unlocked.8", title: "Well pressed.", message: "You earned {toy}. Pro is there if you want the rest today."),
    ]

    static let dailyChallengeCompleted: [Line] = [
        Line(id: "daily.1", title: "Challenge done.", message: "You were told not to. You did it anyway. Pro adds more ways to ignore us."),
        Line(id: "daily.2", title: "Daily complete.", message: "Nice work. If you want more to press, Pro adds two extra toys."),
        Line(id: "daily.3", title: "Today: handled.", message: "The button is mildly impressed. Pro adds toys, styles and icons."),
        Line(id: "daily.4", title: "Mission accomplished.", message: "Pointless, but accomplished. Pro makes the pointlessness prettier."),
        Line(id: "daily.5", title: "Done for today.", message: "Come back tomorrow. Or browse Pro now. Or neither. All valid."),
        Line(id: "daily.6", title: "Challenge cleared.", message: "Good pressing. Pro is a one-time unlock for the extras, if you fancy them."),
        Line(id: "daily.7", title: "That's the daily.", message: "Completed with style. Pro has more styles, literally."),
        Line(id: "daily.8", title: "Another day, another press.", message: "Well done. Pro adds the Egg, the Balloon and a wardrobe for the button."),
    ]

    static let lockedItemTapped: [Line] = [
        Line(id: "locked.1", title: "That one's Pro.", message: "{item} comes with Pro, along with the rest below."),
        Line(id: "locked.2", title: "Locked, politely.", message: "{item} is part of Pro. Here's exactly what that includes."),
        Line(id: "locked.3", title: "Good taste.", message: "{item} is in Pro. One purchase, everything below, no subscription."),
        Line(id: "locked.4", title: "Pro territory.", message: "{item} unlocks with Pro. No tricks, just the list below."),
        Line(id: "locked.5", title: "Not yet.", message: "{item} is a Pro extra. Have a look, or carry on pressing."),
        Line(id: "locked.6", title: "Behind the velvet rope.", message: "{item} is part of Pro. The rope is very small and entirely optional."),
        Line(id: "locked.7", title: "Ah, that one.", message: "{item} is included in Pro. Here's what else comes with it."),
        Line(id: "locked.8", title: "Pro, briefly.", message: "{item} is one of the Pro extras. Look around, no obligation."),
    ]

    static func lines(for kind: ProNudgeMoment.Kind) -> [Line] {
        switch kind {
        case .nearUnlock: return nearUnlock
        case .toyUnlockedByPlay: return toyUnlockedByPlay
        case .dailyChallengeCompleted: return dailyChallengeCompleted
        case .lockedItemTapped: return lockedItemTapped
        }
    }

    /// Deterministic for a given (seed, counter); never returns `avoiding` when an alternative exists.
    static func pick(for moment: ProNudgeMoment, seed: UInt64, counter: Int, avoiding lastID: String?) -> Line {
        let pool = lines(for: moment.kind)
        var index = Int(splitMix(seed &+ UInt64(truncatingIfNeeded: counter)) % UInt64(pool.count))
        if pool.count > 1, pool[index].id == lastID { index = (index + 1) % pool.count }
        return pool[index]
    }

    /// Fills placeholders; a sentence that starts with a placeholder is capitalised.
    static func fill(_ template: String, moment: ProNudgeMoment) -> String {
        var text = template
        let toy = toyPhrase(moment)
        let item = itemPhrase(moment)
        text = replaceCapitalisingAtSentenceStart(text, placeholder: "{toy}", with: toy)
        text = replaceCapitalisingAtSentenceStart(text, placeholder: "{item}", with: item)
        return text
    }

    static func toyPhrase(_ moment: ProNudgeMoment) -> String {
        switch moment {
        case .nearUnlock(let toy, _), .toyUnlockedByPlay(let toy), .lockedItemTapped(.toy(let toy)):
            return "the \(toy.title)"
        default:
            return "the next toy"
        }
    }

    static func itemPhrase(_ moment: ProNudgeMoment) -> String {
        switch moment {
        case .lockedItemTapped(.toy(let toy)): return "the \(toy.title)"
        case .lockedItemTapped(.buttonStyle): return "that button style"
        case .lockedItemTapped(.appIcon): return "that app icon"
        default: return "that"
        }
    }

    private static func replaceCapitalisingAtSentenceStart(_ text: String, placeholder: String, with value: String) -> String {
        guard !value.isEmpty else { return text.replacingOccurrences(of: placeholder, with: value) }
        let capitalised = value.prefix(1).uppercased() + value.dropFirst()
        var result = text
        if result.hasPrefix(placeholder) {
            result = capitalised + result.dropFirst(placeholder.count)
        }
        for end in [". ", "! ", "? "] {
            result = result.replacingOccurrences(of: end + placeholder, with: end + capitalised)
        }
        return result.replacingOccurrences(of: placeholder, with: value)
    }

    private static func splitMix(_ input: UInt64) -> UInt64 {
        var z = input &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

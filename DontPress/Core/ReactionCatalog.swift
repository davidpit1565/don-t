// Curated, locally stored reactions. No generated fragments: every line is complete.
import Foundation

enum ReactionCatalog {
    static let fallback = Reaction(id: "fallback", text: "The button has no comment.", tier: .mild, isRare: false)

    static let idle = "Nothing has happened. Keep it that way."

    static let milestones: [Int: Reaction] = [
        10: Reaction(id: "milestone-10", text: "Ten. Double digits. Bold.", tier: .legendary, isRare: true),
        25: Reaction(id: "milestone-25", text: "Twenty-five. A quarter of nothing in particular.", tier: .legendary, isRare: true),
        50: Reaction(id: "milestone-50", text: "Fifty presses. The button has stopped being surprised.", tier: .legendary, isRare: true),
        100: Reaction(id: "milestone-100", text: "One hundred. A tidy number for a questionable decision.", tier: .legendary, isRare: true),
        250: Reaction(id: "milestone-250", text: "Two hundred fifty. This is no longer a phase.", tier: .legendary, isRare: true),
        500: Reaction(id: "milestone-500", text: "Five hundred. The button is writing you a letter.", tier: .legendary, isRare: true),
        1000: Reaction(id: "milestone-1000", text: "One thousand. Officially unnecessary. Impressively committed.", tier: .legendary, isRare: true),
    ]

    static let all: [Reaction] = mild + sarcasm + concern + absurd + dramatic + legendary
        + extended // Reactiondex expansion: ReactionCatalog+Extended.swift

    // 1–3: mild disapproval
    static let mild: [Reaction] = [
        Reaction(id: "mild-01", text: "I TOLD YOU NOT TO.", tier: .mild, isRare: false),
        Reaction(id: "mild-02", text: "That was unnecessary.", tier: .mild, isRare: false),
        Reaction(id: "mild-03", text: "You had ONE job.", tier: .mild, isRare: false),
        Reaction(id: "mild-04", text: "Interesting decision.", tier: .mild, isRare: false),
        Reaction(id: "mild-05", text: "Bold of you.", tier: .mild, isRare: false),
        Reaction(id: "mild-06", text: "We talked about this.", tier: .mild, isRare: false),
        Reaction(id: "mild-07", text: "Noted. And judged.", tier: .mild, isRare: false),
        Reaction(id: "mild-08", text: "Really? Right away?", tier: .mild, isRare: false),
        Reaction(id: "mild-09", text: "That was not a suggestion.", tier: .mild, isRare: false),
        Reaction(id: "mild-10", text: "The instructions were very clear.", tier: .mild, isRare: false),
        Reaction(id: "mild-11", text: "Hm. Okay.", tier: .mild, isRare: false),
        Reaction(id: "mild-12", text: "A small mistake. Nobody saw. I saw.", tier: .mild, isRare: false),
        Reaction(id: "mild-13", text: "Why would you do that?", tier: .mild, isRare: false),
        Reaction(id: "mild-14", text: "The button felt that.", tier: .mild, isRare: false),
        Reaction(id: "mild-15", text: "That went about as expected.", tier: .mild, isRare: false),
        Reaction(id: "mild-16", text: "You pressed it. Of course you did.", tier: .mild, isRare: false),
        Reaction(id: "mild-rare-01", text: "The button is only a little disappointed.", tier: .mild, isRare: true),
        Reaction(id: "mild-rare-02", text: "A first-time offender. Adorable.", tier: .mild, isRare: true),
    ]

    // 4–10: sarcasm
    static let sarcasm: [Reaction] = [
        Reaction(id: "sarcasm-01", text: "And yet, you pressed it.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-02", text: "Oh, great. More of this.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-03", text: "Sure, why stop now?", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-04", text: "Wow. Very restrained.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-05", text: "Is this a hobby?", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-06", text: "Stunning self-control.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-07", text: "Another one. Fantastic.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-08", text: "Don't mind me. Carry on.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-09", text: "Have you tried not doing that?", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-10", text: "Please, continue ignoring me.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-11", text: "This is going great, apparently.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-12", text: "I'm sure it's fine.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-13", text: "A masterclass in ignoring instructions.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-14", text: "Do you read signs, ever?", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-15", text: "Truly, a person of conviction.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-16", text: "Yes, yes. Another press. Thrilling.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-rare-01", text: "Whatever you're doing, you're doing it on purpose.", tier: .sarcasm, isRare: true),
        Reaction(id: "sarcasm-rare-02", text: "The button has started keeping notes.", tier: .sarcasm, isRare: true),
    ]

    // 11–25: exaggerated concern
    static let concern: [Reaction] = [
        Reaction(id: "concern-01", text: "This is getting embarrassing.", tier: .concern, isRare: false),
        Reaction(id: "concern-02", text: "You could have stopped at any time.", tier: .concern, isRare: false),
        Reaction(id: "concern-03", text: "Are you okay? Blink twice.", tier: .concern, isRare: false),
        Reaction(id: "concern-04", text: "Perhaps a glass of water?", tier: .concern, isRare: false),
        Reaction(id: "concern-05", text: "Let's take a breath. Then, not press again.", tier: .concern, isRare: false),
        Reaction(id: "concern-06", text: "I'm starting to worry about us.", tier: .concern, isRare: false),
        Reaction(id: "concern-07", text: "The button would like a word.", tier: .concern, isRare: false),
        Reaction(id: "concern-08", text: "This is no longer an accident.", tier: .concern, isRare: false),
        Reaction(id: "concern-09", text: "Your thumb needs a vacation.", tier: .concern, isRare: false),
        Reaction(id: "concern-10", text: "Somebody should check on you.", tier: .concern, isRare: false),
        Reaction(id: "concern-11", text: "We have entered a pattern.", tier: .concern, isRare: false),
        Reaction(id: "concern-12", text: "I'm calling it: a lifestyle.", tier: .concern, isRare: false),
        Reaction(id: "concern-13", text: "Was it something I said?", tier: .concern, isRare: false),
        Reaction(id: "concern-14", text: "Stop. Or don't. I can't tell anymore.", tier: .concern, isRare: false),
        Reaction(id: "concern-15", text: "The situation has not improved.", tier: .concern, isRare: false),
        Reaction(id: "concern-16", text: "Mild panic is now appropriate.", tier: .concern, isRare: false),
        Reaction(id: "concern-rare-01", text: "The button has called a meeting about you.", tier: .concern, isRare: true),
        Reaction(id: "concern-rare-02", text: "Legally, this is now a commitment.", tier: .concern, isRare: true),
    ]

    // 26–50: absurd commentary
    static let absurd: [Reaction] = [
        Reaction(id: "absurd-01", text: "Somewhere, a pigeon is proud of you.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-02", text: "The button has filed a formal complaint.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-03", text: "This is now on your permanent record. The cosmic one.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-04", text: "A small cloud has noticed you.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-05", text: "You are in a committed relationship with a rectangle. Well, a circle.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-06", text: "Scientists have been informed. They shrugged.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-07", text: "The furniture is starting to talk about you.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-08", text: "Your thumb has its own fan club now. It's three moths.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-09", text: "The universe is on hold. Please remain pressing.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-10", text: "Some mysteries should remain unsolved.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-11", text: "Archaeologists will study this moment. Briefly.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-12", text: "The moon would like this to stop. The moon is fine, actually.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-13", text: "Fun fact: this is not a fun fact.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-14", text: "A distant lighthouse blinked in disapproval.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-15", text: "The button has begun to dream of silence.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-16", text: "You and the button are, regrettably, a team.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-rare-01", text: "Breaking: local thumb refuses to rest.", tier: .absurd, isRare: true),
        Reaction(id: "absurd-rare-02", text: "A committee of teaspoons has been formed in your honor.", tier: .absurd, isRare: true),
    ]

    // 51–100: increasingly dramatic
    static let dramatic: [Reaction] = [
        Reaction(id: "dramatic-01", text: "THE PROPHECY WAS RIGHT.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-02", text: "This is how legends begin. Bad legends.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-03", text: "Historians will not know what to write.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-04", text: "The button has seen things.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-05", text: "Even the silence is shocked.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-06", text: "We are past the point of no return policy.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-07", text: "Gravity itself has questions.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-08", text: "Mountains are quietly taking notes.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-09", text: "This has become a saga.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-10", text: "Absolutely historic. Completely pointless.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-11", text: "The button is writing its memoirs.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-12", text: "Nobody asked for this. Yet here we are.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-13", text: "A choir somewhere just gave up.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-14", text: "The sun is rethinking its schedule.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-15", text: "Entire empires have fallen over less.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-16", text: "You are the weather now.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-rare-01", text: "Chapter 51: The Thumb Rises.", tier: .dramatic, isRare: true),
        Reaction(id: "dramatic-rare-02", text: "The button would like to speak to your manager.", tier: .dramatic, isRare: true),
    ]

    // 101+: rare escalating absurdity
    static let legendary: [Reaction] = [
        Reaction(id: "legendary-01", text: "I respect your lack of restraint.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-02", text: "You have transcended pressing.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-03", text: "The button is now a philosophy.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-04", text: "At this point, it's simply who you are.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-05", text: "Time has stopped being a useful concept.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-06", text: "Even the void has applauded. Quietly.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-07", text: "You've outlasted three imaginary eras.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-08", text: "The button has retired and un-retired twice.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-09", text: "This is performance art now.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-10", text: "Reality has requested a transfer.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-11", text: "You are legally a landmark.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-12", text: "The concept of 'don't' has left the chat.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-13", text: "Statues of you are being considered. By mice.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-14", text: "The numbers are no longer impressed. They are scared.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-15", text: "A new constellation looks suspiciously like a thumb.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-16", text: "The button has no more warnings. Only admiration.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-rare-01", text: "Level: unreasonable. Status: magnificent.", tier: .legendary, isRare: true),
        Reaction(id: "legendary-rare-02", text: "Please stop. Or don't. History has already decided.", tier: .legendary, isRare: true),
    ]

}

// Second batch of curated reactions (Reactiondex expansion). Same rules as the
// original catalog: complete sentences, original, nothing crude or humiliating.
import Foundation

extension ReactionCatalog {
    /// Every tier's extra lines, in tier order. Merged into `ReactionCatalog.all`.
    static let extended: [Reaction] = mildExtra + sarcasmExtra + concernExtra + absurdExtra + dramaticExtra + legendaryExtra

    static let mildExtra: [Reaction] = [
        Reaction(id: "mild-17", text: "That was the one thing we asked.", tier: .mild, isRare: false),
        Reaction(id: "mild-18", text: "Ah. So that's the kind of day it is.", tier: .mild, isRare: false),
        Reaction(id: "mild-19", text: "Please don't make this a habit.", tier: .mild, isRare: false),
        Reaction(id: "mild-20", text: "Gently, firmly: no.", tier: .mild, isRare: false),
        Reaction(id: "mild-21", text: "The sign said don't. The sign is very upset.", tier: .mild, isRare: false),
        Reaction(id: "mild-22", text: "I'll pretend I didn't see that.", tier: .mild, isRare: false),
        Reaction(id: "mild-23", text: "Okay. Let's never speak of this.", tier: .mild, isRare: false),
        Reaction(id: "mild-24", text: "Well. That happened.", tier: .mild, isRare: false),
        Reaction(id: "mild-rare-03", text: "The button blinked first. Buttons can't blink. Yet here we are.", tier: .mild, isRare: true),
        Reaction(id: "mild-rare-04", text: "Beginner's luck. Except it isn't luck, and it isn't good.", tier: .mild, isRare: true),
    ]

    static let sarcasmExtra: [Reaction] = [
        Reaction(id: "sarcasm-17", text: "Oh good, you're still here.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-18", text: "What a surprise. Truly, nobody saw that coming.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-19", text: "Your restraint is legendary. As in, it's a myth.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-20", text: "Love the commitment to the bit.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-21", text: "Yes, keep pressing. That will definitely fix things.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-22", text: "Someone's been practicing.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-23", text: "Very original. Nobody has ever pressed a button before.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-24", text: "I'm writing this down. In pencil. For now.", tier: .sarcasm, isRare: false),
        Reaction(id: "sarcasm-rare-03", text: "Plot twist: you pressed it again.", tier: .sarcasm, isRare: true),
        Reaction(id: "sarcasm-rare-04", text: "If ignoring advice were a sport, you'd have sponsors.", tier: .sarcasm, isRare: true),
    ]

    static let concernExtra: [Reaction] = [
        Reaction(id: "concern-17", text: "Should I call someone? I don't have hands. Or a phone.", tier: .concern, isRare: false),
        Reaction(id: "concern-18", text: "Your thumb and I need to have a serious talk.", tier: .concern, isRare: false),
        Reaction(id: "concern-19", text: "Have you eaten today? Something other than buttons?", tier: .concern, isRare: false),
        Reaction(id: "concern-20", text: "This is a safe space. Except for the button.", tier: .concern, isRare: false),
        Reaction(id: "concern-21", text: "I'm not mad. I'm just extremely concerned.", tier: .concern, isRare: false),
        Reaction(id: "concern-22", text: "Maybe go look at a tree for a while.", tier: .concern, isRare: false),
        Reaction(id: "concern-23", text: "Let's set some boundaries. You go first.", tier: .concern, isRare: false),
        Reaction(id: "concern-24", text: "A gentle reminder that other apps exist.", tier: .concern, isRare: false),
        Reaction(id: "concern-rare-03", text: "The button has started a support group. You're the only topic.", tier: .concern, isRare: true),
        Reaction(id: "concern-rare-04", text: "An intervention has been scheduled. The button is bringing snacks.", tier: .concern, isRare: true),
    ]

    static let absurdExtra: [Reaction] = [
        Reaction(id: "absurd-17", text: "A goose in Belgium just felt a disturbance.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-18", text: "The button's horoscope warned it about you.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-19", text: "Your thumb has been nominated for a small regional award.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-20", text: "Three clouds have formed a disapproving face.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-21", text: "The button now owns a tiny hat. For formal disappointment.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-22", text: "Somewhere, a sock has gone missing in protest.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-23", text: "A snail has overtaken your sense of restraint.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-24", text: "Local weather: cloudy with a chance of pressing.", tier: .absurd, isRare: false),
        Reaction(id: "absurd-rare-03", text: "A wizard appeared, saw what you were doing, and left.", tier: .absurd, isRare: true),
        Reaction(id: "absurd-rare-04", text: "Your fridge hummed a sad little tune just now.", tier: .absurd, isRare: true),
    ]

    static let dramaticExtra: [Reaction] = [
        Reaction(id: "dramatic-17", text: "And so the thumb descended, again, as foretold.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-18", text: "Thunder rolls. The button braces itself.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-19", text: "Bards will sing of this. Off-key, and only once.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-20", text: "The stars align. They're mostly just watching.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-21", text: "Somewhere, an orchestra hits one very loud note.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-22", text: "This press will echo through the ages. Well, the afternoon.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-23", text: "A dramatic pause. Then, inevitably, more pressing.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-24", text: "The curtains part. It's just you, pressing a button.", tier: .dramatic, isRare: false),
        Reaction(id: "dramatic-rare-03", text: "Narrator: they did not, in fact, stop.", tier: .dramatic, isRare: true),
        Reaction(id: "dramatic-rare-04", text: "Cue the slow-motion replay. Cue the sad violins.", tier: .dramatic, isRare: true),
    ]

    static let legendaryExtra: [Reaction] = [
        Reaction(id: "legendary-17", text: "Ancient texts mention you. In the footnotes.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-18", text: "The button has accepted you as its equal.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-19", text: "Your thumb is a renewable energy source now.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-20", text: "Mathematicians are inventing a new number just for you.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-21", text: "This is no longer pressing. This is a calling.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-22", text: "Galaxies are naming their spiral arms after your thumb.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-23", text: "The button has written you into its will.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-24", text: "You are the reason buttons have warning labels.", tier: .legendary, isRare: false),
        Reaction(id: "legendary-rare-03", text: "A monk on a distant mountain felt this press and nodded.", tier: .legendary, isRare: true),
        Reaction(id: "legendary-rare-04", text: "The button and you are now a single, stubborn idea.", tier: .legendary, isRare: true),
    ]
}

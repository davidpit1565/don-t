import SwiftUI

/// Touch-down feedback for the egg and balloon: a subtle squash, quick spring back.
/// The action itself still runs exactly once per tap.
struct ToyPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(reduceMotion ? DS.Motion.reduced : DS.Motion.pressSpring, value: configuration.isPressed)
    }
}

extension Creature {
    var fillColor: Color { Color(hex: bodyHex) }
    var accentColor: Color { Color(hex: accentHex) }
}

extension CreatureRarity {
    /// Shown next to the word, never instead of it.
    var tint: Color {
        switch self {
        case .common: return DS.Palette.textSecondary
        case .rare: return Color(hex: 0x9FD1FF)
        case .legendary: return Color(hex: 0xFFD166)
        }
    }
}

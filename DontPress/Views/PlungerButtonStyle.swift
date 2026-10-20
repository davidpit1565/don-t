import SwiftUI

/// The big red button. All press feedback comes from `configuration.isPressed`,
/// so it responds on touch-down; the action itself runs once per tap.
struct PlungerButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var diameter: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let depth = diameter * 0.045

        return ZStack {
            // Housing
            Circle()
                .fill(LinearGradient(colors: [DS.Palette.surface, DS.Palette.background], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().strokeBorder(DS.Palette.border, lineWidth: 1.5))
                .shadow(color: .black.opacity(0.6), radius: diameter * 0.04, y: diameter * 0.02)

            // Cap
            ZStack {
                Circle()
                    .fill(DS.Palette.darkRed)
                    .offset(y: pressed ? depth * 0.2 : depth)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [pressed ? DS.Palette.buttonRed : DS.Palette.highlight, DS.Palette.buttonRed, DS.Palette.darkRed],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(pressed ? 0.10 : 0.22), lineWidth: 1.5)
                    )
                    .offset(y: pressed ? depth * 0.2 : 0)
                configuration.label
                    .offset(y: pressed ? depth * 0.2 : 0)
            }
            .padding(diameter * 0.075)
            .scaleEffect(pressed ? 0.965 : 1)
            .shadow(color: DS.Palette.darkRed.opacity(pressed ? 0.25 : 0.45), radius: pressed ? 6 : 14, y: pressed ? 2 : 8)
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .animation(reduceMotion ? DS.Motion.reduced : DS.Motion.pressSpring, value: pressed)
    }
}

struct BigRedButtonLabel: View {
    var diameter: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Text("DON'T")
            Text("PRESS")
        }
        .font(.system(size: diameter * 0.15, weight: .heavy, design: .default))
        .tracking(diameter * 0.006)
        .foregroundStyle(.white)
        .shadow(color: DS.Palette.darkRed.opacity(0.7), radius: 0, y: 1.5)
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .accessibilityHidden(true)
    }
}

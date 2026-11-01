import SwiftUI

/// The balloon toy: each tap inflates it a little more (the pop threshold stays hidden),
/// then it bursts into shards with the punchline on the reaction line. Takes its colours
/// from the selected button style so it always matches the rest of the screen.
struct BalloonToyView: View {
    var model: HomeViewModel
    /// Side of the square the toy may use.
    var size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let balloon = model.toys.balloon
        let theme = model.selectedTheme
        let tension = balloon.tension
        let popped = balloon.isPopped
        let fullWidth = size * 0.62
        let fullHeight = size * 0.74
        // Grows from a limp 55% to full size; a little extra sideways stretch as it tightens.
        let scale = 0.55 + 0.45 * tension
        let stretch = 1 + 0.08 * tension

        Button {
            model.pressToy()
        } label: {
            ZStack {
                if popped {
                    PopShards(theme: theme, size: size)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.3).combined(with: .opacity))
                    Text("POP")
                        .font(.system(size: size * 0.2, weight: .black, design: .rounded))
                        .foregroundStyle(DS.Palette.textPrimary)
                        .offset(y: -size * 0.06)
                        .transition(reduceMotion ? .opacity : .scale(scale: 1.6).combined(with: .opacity))
                } else {
                    VStack(spacing: 0) {
                        balloonBody(theme: theme, tension: tension)
                            .frame(width: fullWidth, height: fullHeight)
                            .scaleEffect(x: scale * stretch, y: scale, anchor: .bottom)
                        BalloonString()
                            .stroke(DS.Palette.textSecondary.opacity(0.7), style: StrokeStyle(lineWidth: max(1, size * 0.006), lineCap: .round))
                            .frame(width: size * 0.12, height: size * 0.16)
                    }
                    .offset(y: size * 0.02)
                    .transition(.opacity)
                }
            }
            .frame(width: size, height: size)
            .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.58), value: tension)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: popped)
        }
        .buttonStyle(ToyPressStyle())
        .accessibilityLabel("Balloon")
        .accessibilityHint("Double tap to inflate it. Each tap counts as a press. It pops when it has had enough.")
        .accessibilityValue(balloon.accessibilityDescription)
        .accessibilityIdentifier("balloonToy")
        .task(id: model.toys.payoffCount) {
            guard model.toys.balloon.isPopped else { return }
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .snappy) { model.toys.clearPayoff() }
        }
    }

    private func balloonBody(theme: ButtonTheme, tension: Double) -> some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [theme.highlight, theme.base, theme.dark],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 0, endRadius: size * 0.42
                    )
                )
                .overlay(
                    // Rubber thins as it stretches: the sheen gets stronger.
                    Ellipse()
                        .fill(.white.opacity(0.12 + 0.3 * tension))
                        .frame(width: size * 0.12, height: size * 0.22)
                        .rotationEffect(.degrees(-25))
                        .offset(x: -size * 0.14, y: -size * 0.2)
                )
                .overlay(Ellipse().strokeBorder(.white.opacity(0.15), lineWidth: 1))
                .padding(.bottom, size * 0.03)
            // Knot
            Knot()
                .fill(theme.dark)
                .frame(width: size * 0.07, height: size * 0.05)
        }
    }
}

/// Little triangle under the balloon.
struct Knot: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A gentle S-curve of string.
struct BalloonString: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX + rect.width * 0.2, y: rect.maxY),
            control1: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.4),
            control2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.7)
        )
        return path
    }
}

/// Shards of rubber flung outwards. Fixed angles, so the burst always looks the same.
struct PopShards: View {
    var theme: ButtonTheme
    var size: CGFloat

    private static let angles: [Double] = [10, 65, 120, 170, 225, 280, 330]

    var body: some View {
        ZStack {
            ForEach(Array(Self.angles.enumerated()), id: \.offset) { index, angle in
                let radians = angle * .pi / 180
                let distance = size * (index.isMultiple(of: 2) ? 0.34 : 0.26)
                Capsule()
                    .fill(index.isMultiple(of: 3) ? theme.highlight : theme.base)
                    .frame(width: size * 0.11, height: size * 0.045)
                    .rotationEffect(.degrees(angle + 90))
                    .offset(x: CGFloat(cos(radians)) * distance, y: CGFloat(sin(radians)) * distance)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

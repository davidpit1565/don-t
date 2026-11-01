import SwiftUI

/// The egg toy: cracks a little more on each tap, shakes near the end, then the top of the
/// shell lifts away and a creature is sitting in the bottom half. All vector, no assets.
struct EggToyView: View {
    var model: HomeViewModel
    /// Side of the square the toy may use.
    var size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let shellTop = Color(hex: 0xF3ECDC)
    private static let shellBottom = Color(hex: 0xD9CFB8)
    private static let shellShadow = Color(hex: 0x9C9079)
    private static let crackColor = Color(hex: 0x4A4234)

    var body: some View {
        let egg = model.toys.egg
        let stage = egg.stage
        let hatchedCreature = Self.creature(in: stage)
        let eggHeight = size * 0.72
        let eggWidth = eggHeight * 0.78

        Button {
            model.pressToy()
        } label: {
            ZStack {
                if let creature = hatchedCreature {
                    CreatureFigure(creature: creature, size: eggWidth * 0.95)
                        .offset(y: -eggHeight * 0.06)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
                }

                // Bottom half of the shell: always present, sits in front of the creature.
                shellGradient
                    .clipShape(EggShape())
                    .mask { ShellSplit(part: .bottom) }
                    .frame(width: eggWidth, height: eggHeight)
                    .shadow(color: .black.opacity(0.45), radius: size * 0.04, y: size * 0.02)

                // Top half: joins the bottom seamlessly until it hatches, then lifts away.
                shellGradient
                    .clipShape(EggShape())
                    .mask { ShellSplit(part: .top) }
                    .frame(width: eggWidth, height: eggHeight)
                    .rotationEffect(.degrees(hatchedCreature == nil ? 0 : -24), anchor: .bottomLeading)
                    .offset(
                        x: hatchedCreature == nil ? 0 : -eggWidth * 0.22,
                        y: hatchedCreature == nil ? 0 : -eggHeight * 0.30
                    )
                    .opacity(hatchedCreature == nil ? 1 : 0.9)

                if hatchedCreature == nil {
                    CrackLines(stage: stage, color: Self.crackColor)
                        .frame(width: eggWidth, height: eggHeight)
                        .clipShape(EggShape())
                }
            }
            .rotationEffect(.degrees(shakeDegrees(for: stage)))
            .frame(width: size, height: size)
            .overlay(alignment: .bottom) {
                if let creature = hatchedCreature {
                    creatureCaption(creature)
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.68), value: stage)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.5), value: egg.tapsThisCycle)
        }
        .buttonStyle(ToyPressStyle())
        .accessibilityLabel("Egg")
        .accessibilityHint("Double tap to tap the egg. Each tap counts as a press.")
        .accessibilityValue(stage.accessibilityDescription)
        .accessibilityIdentifier("eggToy")
        .task(id: model.toys.payoffCount) {
            // Let the creature be admired, then quietly bring a new egg. A tap in the meantime
            // starts the next egg on its own, so this only ever resets a still-resolved toy.
            guard model.toys.egg.isResolved else { return }
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .snappy) { model.toys.clearPayoff() }
        }
    }

    private var shellGradient: some View {
        LinearGradient(
            colors: [Self.shellTop, Self.shellBottom, Self.shellShadow],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay {
            // Soft highlight so the shell reads as a curved object.
            Ellipse()
                .fill(.white.opacity(0.35))
                .blur(radius: size * 0.03)
                .frame(width: size * 0.16, height: size * 0.26)
                .offset(x: -size * 0.12, y: -size * 0.18)
        }
    }

    private static func creature(in stage: EggStage) -> Creature? {
        if case .hatched(let creature) = stage { return creature }
        return nil
    }

    /// A small lean that grows with the crack. Each tap re-triggers the view's spring via `stage`,
    /// and `tapsThisCycle` flips the direction so consecutive taps rock the egg side to side.
    private func shakeDegrees(for stage: EggStage) -> Double {
        guard !reduceMotion else { return 0 }
        let amplitude: Double
        switch stage {
        case .intact, .hatched: return 0
        case .hairline: amplitude = 2
        case .cracked: amplitude = 4
        case .shaking: amplitude = 7
        }
        return model.toys.egg.tapsThisCycle.isMultiple(of: 2) ? amplitude : -amplitude
    }

    private func creatureCaption(_ creature: Creature) -> some View {
        VStack(spacing: 2) {
            Text(creature.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DS.Palette.textPrimary)
            Text(creature.rarity.title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(creature.rarity.tint)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.bottom, size * 0.02)
        .accessibilityHidden(true)   // already in the button's value
    }
}

// MARK: - Shapes

/// A slightly top-heavy oval: narrower at the top than an ellipse.
struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let midX = rect.midX
        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.62),
            control1: CGPoint(x: midX + w * 0.36, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.30)
        )
        path.addCurve(
            to: CGPoint(x: midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.92),
            control2: CGPoint(x: midX + w * 0.30, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + h * 0.62),
            control1: CGPoint(x: midX - w * 0.30, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.92)
        )
        path.addCurve(
            to: CGPoint(x: midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.30),
            control2: CGPoint(x: midX - w * 0.36, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

/// Mask for one half of the shell, split along a jagged seam.
struct ShellSplit: Shape {
    enum Part { case top, bottom }
    var part: Part

    /// The seam, as fractions of the shape's bounds.
    static let seam: [CGPoint] = [
        CGPoint(x: 0.00, y: 0.56), CGPoint(x: 0.14, y: 0.50), CGPoint(x: 0.26, y: 0.60),
        CGPoint(x: 0.40, y: 0.51), CGPoint(x: 0.52, y: 0.61), CGPoint(x: 0.66, y: 0.52),
        CGPoint(x: 0.80, y: 0.60), CGPoint(x: 0.92, y: 0.53), CGPoint(x: 1.00, y: 0.58),
    ]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points = Self.seam.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }
        path.move(to: points[0])
        for point in points.dropFirst() { path.addLine(to: point) }
        switch part {
        case .top:
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY - 1))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY - 1))
        case .bottom:
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY + 1))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY + 1))
        }
        path.closeSubpath()
        return path
    }
}

/// Cracks drawn with Canvas; more of the polyline appears at each stage. Fixed points, so the
/// drawing is deterministic and never affects anything but pixels.
struct CrackLines: View {
    var stage: EggStage
    var color: Color

    private static let main: [CGPoint] = [
        CGPoint(x: 0.95, y: 0.55), CGPoint(x: 0.80, y: 0.50), CGPoint(x: 0.71, y: 0.58),
        CGPoint(x: 0.59, y: 0.52), CGPoint(x: 0.50, y: 0.61), CGPoint(x: 0.38, y: 0.55),
        CGPoint(x: 0.29, y: 0.63), CGPoint(x: 0.17, y: 0.57), CGPoint(x: 0.05, y: 0.62),
    ]
    private static let upperBranch: [CGPoint] = [
        CGPoint(x: 0.59, y: 0.52), CGPoint(x: 0.56, y: 0.41), CGPoint(x: 0.61, y: 0.31), CGPoint(x: 0.57, y: 0.22),
    ]
    private static let lowerBranch: [CGPoint] = [
        CGPoint(x: 0.38, y: 0.55), CGPoint(x: 0.43, y: 0.68), CGPoint(x: 0.37, y: 0.79),
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let polylines: [[CGPoint]]
            let lineWidth: CGFloat
            switch stage {
            case .intact, .hatched:
                return
            case .hairline:
                polylines = [Array(Self.main.prefix(4))]
                lineWidth = max(1, canvasSize.width * 0.008)
            case .cracked:
                polylines = [Array(Self.main.prefix(7)), Array(Self.upperBranch.prefix(3))]
                lineWidth = max(1.2, canvasSize.width * 0.012)
            case .shaking:
                polylines = [Self.main, Self.upperBranch, Self.lowerBranch]
                lineWidth = max(1.5, canvasSize.width * 0.016)
            }
            for line in polylines {
                var path = Path()
                let scaled = line.map { CGPoint(x: $0.x * canvasSize.width, y: $0.y * canvasSize.height) }
                path.addLines(scaled)
                context.stroke(
                    path, with: .color(color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Creature

/// A friendly blob built from shapes and tinted with the creature's colours.
/// Rarity changes the silhouette: common is plain, rare has ear tufts, legendary wears a crown.
struct CreatureFigure: View {
    var creature: Creature
    var size: CGFloat

    var body: some View {
        let bodyWidth = size * 0.78
        let bodyHeight = size * 0.66
        let eye = size * 0.13

        ZStack {
            // Headgear sits behind the body.
            switch creature.rarity {
            case .common:
                EmptyView()
            case .rare:
                HStack(spacing: bodyWidth * 0.42) {
                    Tuft().fill(creature.accentColor).frame(width: size * 0.16, height: size * 0.22)
                    Tuft().fill(creature.accentColor).frame(width: size * 0.16, height: size * 0.22)
                }
                .offset(y: -bodyHeight * 0.42)
            case .legendary:
                Crown().fill(creature.accentColor)
                    .frame(width: bodyWidth * 0.5, height: size * 0.2)
                    .offset(y: -bodyHeight * 0.48)
            }

            Ellipse()
                .fill(
                    LinearGradient(colors: [creature.fillColor.opacity(0.95), creature.fillColor, creature.accentColor],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(Ellipse().strokeBorder(creature.accentColor.opacity(0.6), lineWidth: max(1, size * 0.012)))
                .frame(width: bodyWidth, height: bodyHeight)

            // Spots
            Circle().fill(creature.accentColor.opacity(0.35)).frame(width: size * 0.1)
                .offset(x: bodyWidth * 0.26, y: bodyHeight * 0.18)
            Circle().fill(creature.accentColor.opacity(0.35)).frame(width: size * 0.06)
                .offset(x: -bodyWidth * 0.3, y: bodyHeight * 0.22)

            // Eyes
            HStack(spacing: eye * 0.9) {
                eyeView(diameter: eye)
                eyeView(diameter: eye)
            }
            .offset(y: -bodyHeight * 0.12)

            // A small, uncertain mouth.
            Capsule()
                .fill(creature.accentColor)
                .frame(width: eye * 0.9, height: max(2, size * 0.025))
                .offset(y: bodyHeight * 0.12)

            // Feet
            HStack(spacing: bodyWidth * 0.3) {
                Capsule().fill(creature.accentColor).frame(width: size * 0.16, height: size * 0.07)
                Capsule().fill(creature.accentColor).frame(width: size * 0.16, height: size * 0.07)
            }
            .offset(y: bodyHeight * 0.48)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func eyeView(diameter: CGFloat) -> some View {
        ZStack {
            Circle().fill(.white)
            Circle().fill(Color(hex: 0x1B1B1F)).frame(width: diameter * 0.5)
                .offset(x: diameter * 0.08, y: diameter * 0.1)
            Circle().fill(.white).frame(width: diameter * 0.16)
                .offset(x: diameter * -0.05, y: diameter * -0.08)
        }
        .frame(width: diameter, height: diameter)
    }
}

struct Tuft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct Crown: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

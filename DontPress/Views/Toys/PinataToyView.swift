import SwiftUI

/// The piñata toy (mythic, see `PinataGate`): hangs from a string and swings on every hit,
/// dents, cracks, then bursts into confetti with a prize on the reaction line. Original
/// vector art: a rounded, banded gem body with tissue-paper fringe, no assets.
struct PinataToyView: View {
    var model: HomeViewModel
    /// Side of the square the toy may use.
    var size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Fringe bands, top to bottom (repeats).
    static let bandColors: [Color] = [
        Color(hex: 0xFF3347), Color(hex: 0xF3ECDC), Color(hex: 0x3FC1A8), Color(hex: 0xFFD166), Color(hex: 0xC98BFF),
    ]
    private static let dentColor = Color(hex: 0x1A1216)

    var body: some View {
        let pinata = model.toys.pinata
        let stage = pinata.stage
        let prize = Self.prize(in: stage)
        let bodyWidth = size * 0.64
        let bodyHeight = size * 0.5
        let stringHeight = size * 0.17

        Button {
            model.pressToy()
        } label: {
            ZStack {
                if let prize {
                    PrizeConfetti(colors: Self.bandColors + [Color(hex: prize.colorHex)], size: size)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.2).combined(with: .opacity))
                }

                VStack(spacing: 0) {
                    PinataString()
                        .stroke(DS.Palette.textSecondary.opacity(0.75), style: StrokeStyle(lineWidth: max(1, size * 0.007), lineCap: .round))
                        .frame(width: size * 0.06, height: stringHeight)
                        .opacity(prize == nil ? 1 : 0.35)

                    ZStack {
                        if prize == nil {
                            pinataBody(stage: stage, tension: pinata.tension)
                                .transition(.opacity)
                        } else {
                            // The two halves fall apart.
                            pinataBody(stage: stage, tension: 1)
                                .mask(alignment: .leading) { Rectangle().frame(width: bodyWidth * 0.5) }
                                .rotationEffect(.degrees(reduceMotion ? 0 : -28), anchor: .bottomLeading)
                                .offset(x: reduceMotion ? 0 : -bodyWidth * 0.18, y: reduceMotion ? 0 : bodyHeight * 0.35)
                                .opacity(0.55)
                            pinataBody(stage: stage, tension: 1)
                                .mask(alignment: .trailing) { Rectangle().frame(width: bodyWidth * 0.5) }
                                .rotationEffect(.degrees(reduceMotion ? 0 : 24), anchor: .bottomTrailing)
                                .offset(x: reduceMotion ? 0 : bodyWidth * 0.2, y: reduceMotion ? 0 : bodyHeight * 0.3)
                                .opacity(0.55)
                        }
                    }
                    .frame(width: bodyWidth, height: bodyHeight)
                    .shadow(color: .black.opacity(0.45), radius: size * 0.04, y: size * 0.02)
                }
                .rotationEffect(.degrees(swingDegrees(for: pinata)), anchor: .top)
                .offset(y: -size * 0.06)
            }
            .frame(width: size, height: size)
            .overlay(alignment: .bottom) {
                if let prize {
                    prizeCaption(prize)
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.45), value: pinata.tapsThisCycle)
            .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.7), value: stage)
        }
        .buttonStyle(ToyPressStyle())
        .accessibilityLabel("Piñata")
        .accessibilityHint("Double tap to hit it. Each hit counts as a press. It bursts when it has had enough.")
        .accessibilityValue(stage.accessibilityDescription)
        .accessibilityIdentifier("pinataToy")
        .task(id: model.toys.payoffCount) {
            // Let the prize be admired, then hang a fresh piñata. A hit in the meantime starts the
            // next one on its own, so this only ever resets a still-resolved toy.
            guard model.toys.pinata.isResolved else { return }
            try? await Task.sleep(for: .seconds(3.5))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .snappy) { model.toys.clearPayoff() }
        }
    }

    // MARK: Body

    private func pinataBody(stage: PinataStage, tension: Double) -> some View {
        PinataBands(colors: Self.bandColors, fringe: true)
            .clipShape(PinataBodyShape())
            .overlay {
                // Curved-object sheen.
                Ellipse()
                    .fill(.white.opacity(0.22))
                    .blur(radius: size * 0.025)
                    .frame(width: size * 0.16, height: size * 0.1)
                    .offset(x: -size * 0.14, y: -size * 0.14)
            }
            .overlay {
                PinataDamage(stage: stage, tension: tension, color: Self.dentColor)
                    .clipShape(PinataBodyShape())
            }
            .overlay(PinataBodyShape().strokeBorder(.black.opacity(0.35), lineWidth: max(1, size * 0.006)))
    }

    private static func prize(in stage: PinataStage) -> PinataPrize? {
        if case .burst(let prize) = stage { return prize }
        return nil
    }

    /// Each hit knocks it to the other side; harder as it gets closer to bursting.
    private func swingDegrees(for pinata: PinataToy) -> Double {
        guard !reduceMotion else { return 0 }
        let amplitude: Double
        switch pinata.stage {
        case .burst: return 0
        case .swinging: amplitude = pinata.tapsThisCycle == 0 ? 0 : 7
        case .dented: amplitude = 10
        case .cracked: amplitude = 14
        }
        return Double(pinata.swingDirection) * amplitude
    }

    private func prizeCaption(_ prize: PinataPrize) -> some View {
        VStack(spacing: 2) {
            Text(prize.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DS.Palette.textPrimary)
            Text(prize.rarity.title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(prize.rarity.tint)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.bottom, size * 0.02)
        .accessibilityHidden(true)   // already in the button's value
    }
}

extension PinataPrizeRarity {
    /// Shown next to the word, never instead of it.
    var tint: Color {
        switch self {
        case .common: return DS.Palette.textSecondary
        case .rare: return Color(hex: 0x9FD1FF)
        case .legendary: return Color(hex: 0xFFD166)
        }
    }
}

// MARK: - Shapes

/// A chunky, rounded eight-sided gem: wider than tall, flat top and bottom, pointed sides.
struct PinataBodyShape: InsettableShape {
    var inset: CGFloat = 0

    func inset(by amount: CGFloat) -> PinataBodyShape {
        var copy = self
        copy.inset += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        let w = r.width, h = r.height
        let points = [
            CGPoint(x: r.minX + w * 0.22, y: r.minY),
            CGPoint(x: r.maxX - w * 0.22, y: r.minY),
            CGPoint(x: r.maxX - w * 0.04, y: r.minY + h * 0.3),
            CGPoint(x: r.maxX, y: r.midY),
            CGPoint(x: r.maxX - w * 0.06, y: r.maxY - h * 0.22),
            CGPoint(x: r.maxX - w * 0.3, y: r.maxY),
            CGPoint(x: r.minX + w * 0.3, y: r.maxY),
            CGPoint(x: r.minX + w * 0.06, y: r.maxY - h * 0.22),
            CGPoint(x: r.minX, y: r.midY),
            CGPoint(x: r.minX + w * 0.04, y: r.minY + h * 0.3),
        ]
        // Rounded polygon: run through edge midpoints, bending around each corner.
        var path = Path()
        let count = points.count
        func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }
        path.move(to: mid(points[count - 1], points[0]))
        for i in 0..<count {
            let corner = points[i]
            let next = points[(i + 1) % count]
            path.addQuadCurve(to: mid(corner, next), control: corner)
        }
        path.closeSubpath()
        return path
    }
}

/// A short string with a tiny loop at the top.
struct PinataString: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let loop = min(rect.width, rect.height * 0.3)
        path.addEllipse(in: CGRect(x: rect.midX - loop / 2, y: rect.minY, width: loop, height: loop * 0.7))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + loop * 0.7))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

/// Horizontal tissue-paper bands with a zigzag fringe hanging off each one.
struct PinataBands: View {
    var colors: [Color]
    var fringe: Bool

    var body: some View {
        Canvas { context, canvasSize in
            let bands = 6
            let bandHeight = canvasSize.height / CGFloat(bands)
            let tooth = max(3, canvasSize.width * 0.045)
            for band in 0..<bands {
                let color = colors[band % max(colors.count, 1)]
                let y = CGFloat(band) * bandHeight
                context.fill(Path(CGRect(x: 0, y: y, width: canvasSize.width, height: bandHeight + 1)), with: .color(color))
                guard fringe else { continue }
                // Fringe: a row of little triangles hanging below the band, a shade darker.
                var zigzag = Path()
                var x: CGFloat = -tooth
                let top = y + bandHeight - tooth * 0.9
                let bottom = y + bandHeight + tooth * 0.5
                zigzag.move(to: CGPoint(x: x, y: top))
                while x < canvasSize.width + tooth {
                    zigzag.addLine(to: CGPoint(x: x + tooth / 2, y: bottom))
                    zigzag.addLine(to: CGPoint(x: x + tooth, y: top))
                    x += tooth
                }
                zigzag.closeSubpath()
                context.fill(zigzag, with: .color(.black.opacity(0.22)))
            }
        }
    }
}

/// Dents, then cracks, at fixed places so the damage always looks the same.
struct PinataDamage: View {
    var stage: PinataStage
    var tension: Double
    var color: Color

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width, h = canvasSize.height
            let dents: [(CGFloat, CGFloat, CGFloat)] = [(0.3, 0.42, 0.11), (0.68, 0.3, 0.09), (0.56, 0.7, 0.1), (0.22, 0.72, 0.07)]
            let visibleDents: Int
            switch stage {
            case .swinging, .burst: visibleDents = 0
            case .dented: visibleDents = tension < 0.55 ? 2 : 3
            case .cracked: visibleDents = 4
            }
            for (index, dent) in dents.prefix(visibleDents).enumerated() {
                let radius = w * dent.2
                let rect = CGRect(x: w * dent.0 - radius, y: h * dent.1 - radius * 0.7, width: radius * 2, height: radius * 1.4)
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(index == 0 ? 0.5 : 0.4)))
            }
            if case .cracked = stage {
                var crack = Path()
                crack.move(to: CGPoint(x: w * 0.36, y: h * 0.1))
                crack.addLine(to: CGPoint(x: w * 0.44, y: h * 0.38))
                crack.addLine(to: CGPoint(x: w * 0.4, y: h * 0.52))
                crack.addLine(to: CGPoint(x: w * 0.5, y: h * 0.78))
                crack.move(to: CGPoint(x: w * 0.44, y: h * 0.38))
                crack.addLine(to: CGPoint(x: w * 0.62, y: h * 0.46))
                crack.addLine(to: CGPoint(x: w * 0.7, y: h * 0.64))
                let width = max(1.2, w * 0.012)
                context.stroke(crack, with: .color(color.opacity(0.85)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

/// Confetti flung outwards from the burst. Fixed angles, so it always looks the same.
struct PrizeConfetti: View {
    var colors: [Color]
    var size: CGFloat

    private static let angles: [Double] = [255, 285, 240, 300, 220, 320, 200, 340, 270, 180, 0, 160, 20, 90]

    var body: some View {
        ZStack {
            ForEach(Array(Self.angles.enumerated()), id: \.offset) { index, angle in
                let radians = angle * .pi / 180
                let distance = size * (index.isMultiple(of: 2) ? 0.36 : 0.26) * (index < 10 ? 1 : 0.8)
                RoundedRectangle(cornerRadius: size * 0.006)
                    .fill(colors[index % max(colors.count, 1)])
                    .frame(width: size * (index.isMultiple(of: 3) ? 0.05 : 0.035), height: size * 0.075)
                    .rotationEffect(.degrees(angle * 1.7))
                    .offset(x: CGFloat(cos(radians)) * distance, y: CGFloat(sin(radians)) * distance)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

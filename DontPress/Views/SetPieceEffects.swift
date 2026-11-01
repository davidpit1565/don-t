import SwiftUI

/// Plays the active `SetPiece` over the button it modifies.
///
/// Rendering uses transforms and opacity only (scale, rotation, offset, opacity, plus
/// non-interactive overlays), so it stays on the compositor. Every overlay is hit-test
/// transparent: taps keep reaching the button and counting is entirely independent of
/// whatever this modifier is doing. The timeline is a single `.task(id:)` driven by a
/// clock, never by animation completion callbacks; haptics are fired from that task.
struct SetPieceEffectModifier: ViewModifier {
    var setPiece: SetPiece?
    /// The button's diameter in points; script geometry is expressed in diameters.
    var diameter: CGFloat
    /// Interprets the haptic plan (UIKit lives behind this closure). May do nothing.
    var onHaptic: (HapticCue.Kind) -> Void
    /// Called once with the set-piece id when its timeline ends; never called for an
    /// interrupted set-piece (the replacement's task takes over).
    var onFinished: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visual = SetPieceVisualState()

    func body(content: Content) -> some View {
        content
            .scaleEffect(visual.scale)
            .rotationEffect(.degrees(visual.rotation))
            .offset(
                x: (visual.offsetX + visual.shakeX + visual.glitchJitter) * diameter,
                y: visual.offsetY * diameter
            )
            .opacity(visual.opacity)
            // Overlays come after the transforms, so they stay in place while the button moves.
            .overlay { glitchBands }
            .overlay { flash }
            .overlay { lockCard }
            .overlay(alignment: .top) { caption }
            .task(id: setPiece?.id) { await play() }
    }

    // MARK: Overlays (all non-interactive)

    @ViewBuilder
    private var caption: some View {
        if let text = visual.caption {
            let shouting = text == text.uppercased() && text.count <= 24
            Text(text)
                .font(shouting ? .title3.weight(.heavy) : .subheadline.weight(.semibold))
                .tracking(shouting ? 1.5 : 0)
                .foregroundStyle(DS.Palette.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, DS.Spacing.m)
                .padding(.vertical, DS.Spacing.s)
                .background(DS.Palette.surface.opacity(0.96), in: Capsule())
                .overlay(Capsule().strokeBorder(DS.Palette.border, lineWidth: 1))
                .frame(maxWidth: max(diameter, 220))
                .offset(y: -DS.Spacing.s)
                .transition(.opacity)
                .allowsHitTesting(false)
                .accessibilityIdentifier("setPieceCaption")
        }
    }

    @ViewBuilder
    private var lockCard: some View {
        if let progress = visual.lockProgress {
            VStack(spacing: DS.Spacing.s) {
                Text("BUTTON LOCKED")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                    .foregroundStyle(DS.Palette.textPrimary)
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(DS.Palette.border)
                        Capsule()
                            .fill(DS.Palette.buttonRed)
                            .frame(width: proxy.size.width * CGFloat(min(max(progress, 0), 1)))
                    }
                }
                .frame(height: 6)
                Text(progress >= 1 ? "Lock failed" : "Securing the button…")
                    .font(.caption2)
                    .foregroundStyle(DS.Palette.textSecondary)
                    .contentTransition(.opacity)
            }
            .padding(DS.Spacing.m)
            .frame(width: max(min(diameter * 0.8, 260), 180))
            .background(DS.Palette.surface.opacity(0.97), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(DS.Palette.border, lineWidth: 1))
            .transition(.opacity)
            .allowsHitTesting(false)
            .accessibilityIdentifier("setPieceLockCard")
        }
    }

    @ViewBuilder
    private var flash: some View {
        if visual.flash > 0 {
            Circle()
                .fill(DS.Palette.textPrimary)
                .opacity(visual.flash)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var glitchBands: some View {
        if visual.isGlitching {
            VStack(spacing: diameter * 0.12) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index.isMultiple(of: 2) ? DS.Palette.highlight : DS.Palette.textSecondary)
                        .frame(height: max(diameter * 0.02, 3))
                        .opacity(0.55)
                        .offset(x: (index.isMultiple(of: 2) ? 1 : -1) * visual.glitchJitter * diameter * 3)
                }
            }
            .frame(width: diameter * 1.1)
            .clipShape(Circle())
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    // MARK: Timeline

    @MainActor
    private func play() async {
        // A new (or no) set-piece: start from a clean slate without animating the reset.
        var transaction = SwiftUI.Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { visual = SetPieceVisualState() }

        guard let piece = setPiece else { return }
        AccessibilityNotification.Announcement("\(piece.name). \(piece.reactionLine)").post()

        let steps = piece.steps(reduceMotion: reduceMotion)
        var events: [TimelineEvent] = []
        for (index, step) in steps.enumerated() {
            events.append(TimelineEvent(at: step.at, order: index, kind: .step(step)))
        }
        for (index, cue) in piece.haptics.enumerated() {
            events.append(TimelineEvent(at: cue.at, order: steps.count + index, kind: .haptic(cue)))
        }
        events.sort { ($0.at, $0.order) < ($1.at, $1.order) }

        let clock = ContinuousClock()
        let start = clock.now
        for event in events {
            let target = start.advanced(by: .seconds(event.at))
            if clock.now < target {
                do { try await clock.sleep(until: target, tolerance: .milliseconds(8)) } catch { return }
            }
            if Task.isCancelled { return }
            switch event.kind {
            case .step(let step): apply(step)
            case .haptic(let cue): onHaptic(cue.kind)
            }
        }

        // Closing line, then hand control back. Taps keep counting throughout.
        withAnimation(.easeOut(duration: 0.15)) { visual.caption = piece.reactionLine }
        do { try await clock.sleep(for: .seconds(1.4)) } catch { return }
        if Task.isCancelled { return }
        withAnimation(.easeOut(duration: 0.2)) { visual.caption = nil }
        do { try await clock.sleep(for: .seconds(0.2)) } catch { return }
        if Task.isCancelled { return }
        onFinished(piece.id)
    }

    @MainActor
    private func apply(_ step: SetPieceStep) {
        let fade = Animation.easeOut(duration: 0.15)
        let hidden = visual.opacity <= 0 || visual.scale <= 0
        switch step.action {
        case .scale(let value):
            withAnimation(reduceMotion ? fade : .spring(response: 0.38, dampingFraction: 0.72)) {
                visual.scale = CGFloat(value)
            }
        case .offset(let x, let y):
            withAnimation(reduceMotion ? fade : .spring(response: 0.45, dampingFraction: 0.8)) {
                visual.offsetX = CGFloat(x)
                visual.offsetY = CGFloat(y)
            }
        case .rotation(let degrees):
            if hidden {
                // Nobody can see it: snap, so the reappearance is not a reverse spin.
                var transaction = SwiftUI.Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { visual.rotation = degrees }
            } else {
                let big = abs(degrees - visual.rotation) >= 180
                withAnimation(reduceMotion ? fade : (big ? .easeInOut(duration: 1.2) : .spring(response: 0.3, dampingFraction: 0.65))) {
                    visual.rotation = degrees
                }
            }
        case .opacity(let value):
            withAnimation(.easeOut(duration: 0.25)) { visual.opacity = value }
        case .shake(let amplitude, let cycles):
            if amplitude <= 0 || cycles <= 0 {
                withAnimation(.linear(duration: 0.05)) { visual.shakeX = 0 }
            } else {
                withAnimation(.linear(duration: 0.05).repeatCount(cycles, autoreverses: true)) {
                    visual.shakeX = CGFloat(amplitude)
                }
            }
        case .glitch(let on):
            withAnimation(fade) { visual.isGlitching = on }
            if on {
                withAnimation(.linear(duration: 0.07).repeatForever(autoreverses: true)) { visual.glitchJitter = 0.02 }
            } else {
                withAnimation(.linear(duration: 0.05)) { visual.glitchJitter = 0 }
            }
        case .lock(let progress):
            if let progress {
                let animation: Animation = visual.lockProgress == nil ? fade : .easeInOut(duration: 0.6)
                withAnimation(animation) { visual.lockProgress = progress }
            } else {
                withAnimation(fade) { visual.lockProgress = nil }
            }
        case .caption(let text):
            withAnimation(fade) { visual.caption = text }
        case .flash(let peak):
            withAnimation(.easeOut(duration: 0.05)) { visual.flash = peak }
            withAnimation(.easeOut(duration: 0.45).delay(0.08)) { visual.flash = 0 }
        case .restore:
            withAnimation(reduceMotion ? fade : .spring(response: 0.35, dampingFraction: 0.75)) {
                visual = SetPieceVisualState()
            }
        }
    }

    private struct TimelineEvent {
        enum Kind {
            case step(SetPieceStep)
            case haptic(HapticCue)
        }
        let at: TimeInterval
        let order: Int
        let kind: Kind
    }
}

/// Everything the modifier animates. Geometry is in button diameters (converted at render time).
struct SetPieceVisualState: Equatable {
    var scale: CGFloat = 1
    var rotation: Double = 0
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var opacity: Double = 1
    var shakeX: CGFloat = 0
    var glitchJitter: CGFloat = 0
    var isGlitching = false
    var lockProgress: Double?
    var caption: String?
    var flash: Double = 0
}

extension View {
    /// Renders `setPiece` over this (button) view. See `SetPieceEffectModifier`.
    func setPieceEffects(
        _ setPiece: SetPiece?,
        diameter: CGFloat,
        onHaptic: @escaping (HapticCue.Kind) -> Void = { _ in },
        onFinished: @escaping (String) -> Void
    ) -> some View {
        modifier(SetPieceEffectModifier(setPiece: setPiece, diameter: diameter, onHaptic: onHaptic, onFinished: onFinished))
    }
}

import SwiftUI

/// Compact row of three 44pt targets that swaps what sits in the middle of the screen.
/// Taps on any toy still go through the one counting path.
struct ToyPicker: View {
    var model: HomeViewModel
    /// Called when a locked toy is tapped (not yet earned by play, no Pro): show the Pro offer.
    var onLockedTap: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            ForEach(ToyKind.allCases) { kind in
                let selected = model.toys.selectedKind == kind
                let unlockState = model.toyUnlockState(kind)
                let locked = !unlockState.isUnlocked
                let progressLabel = ProgressionRules.progressLabel(for: unlockState)
                Button {
                    if locked {
                        onLockedTap()
                    } else {
                        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) { _ = model.selectToy(kind) }
                    }
                } label: {
                    HStack(spacing: DS.Spacing.xs + 2) {
                        ToyGlyph(kind: kind, theme: model.selectedTheme)
                            .frame(width: 20, height: 20)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(kind.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            // Progression: how far this toy is from being earned by play.
                            if let progressLabel {
                                Text(progressLabel)
                                    .font(.caption2.weight(.medium).monospacedDigit())
                                    .foregroundStyle(DS.Palette.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9, weight: .bold))
                                .accessibilityHidden(true)
                        }
                    }
                    .foregroundStyle(selected ? DS.Palette.textPrimary : DS.Palette.textSecondary)
                    .padding(.horizontal, DS.Spacing.m)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(selected ? DS.Palette.surface : .clear, in: Capsule())
                    .overlay(Capsule().strokeBorder(selected ? DS.Palette.textSecondary.opacity(0.6) : DS.Palette.border, lineWidth: 1))
                    .overlay(alignment: .bottom) {
                        if progressLabel != nil {
                            ToyUnlockProgressBar(fraction: ProgressionRules.fractionToUnlock(for: kind, stats: model.stats))
                                .padding(.horizontal, DS.Spacing.m)
                                .padding(.bottom, 5)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(kind.title) toy")
                .accessibilityHint("Puts the \(kind.title.lowercased()) in the middle of the screen. Taps on it still count.")
                .accessibilityValue(ProgressionRules.accessibilityValue(for: unlockState))
                .accessibilityAddTraits(selected ? [.isSelected] : [])
                .accessibilityIdentifier("toyPicker.\(kind.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tap toy")
        .accessibilityIdentifier("toyPicker")
    }
}

/// Hairline progress towards earning a locked toy by play. Not colour-only: the chip also shows "123/300".
private struct ToyUnlockProgressBar: View {
    var fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.Palette.border)
                Capsule()
                    .fill(DS.Palette.textSecondary)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 2)
    }
}

/// Tiny vector icon for each toy; the button one follows the selected style's colours.
struct ToyGlyph: View {
    var kind: ToyKind
    var theme: ButtonTheme

    var body: some View {
        switch kind {
        case .button:
            Circle()
                .fill(LinearGradient(colors: [theme.highlight, theme.base, theme.dark], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                .padding(2)
        case .egg:
            EggShape()
                .fill(LinearGradient(colors: [Color(hex: 0xF3ECDC), Color(hex: 0xBFB49A)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
        case .balloon:
            VStack(spacing: 0) {
                Ellipse()
                    .fill(LinearGradient(colors: [theme.highlight, theme.base], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 13, height: 15)
                Knot().fill(theme.dark).frame(width: 4, height: 3)
            }
        }
    }
}

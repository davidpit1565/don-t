import SwiftUI

/// Compact row of four 44pt targets that swaps what sits in the middle of the screen.
/// Taps on any toy still go through the one counting path. Chips are glyph-over-label and
/// share the width equally so all four fit an iPhone SE (272pt usable: ~62pt each).
struct ToyPicker: View {
    var model: HomeViewModel
    /// Called when a Pro toy is tapped without Pro.
    var onLockedTap: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            ForEach(ToyKind.allCases) { kind in
                let selected = model.toys.selectedKind == kind
                let locked = !model.isToyUnlocked(kind)
                // feat-pinata: with Pro but not enough play, the chip itself shows the progress; no offer to show.
                let needsProOffer = locked && !(kind == .pinata && model.isPro)
                Button {
                    if needsProOffer {
                        onLockedTap()
                    } else if !locked {
                        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) { _ = model.selectToy(kind) }
                    }
                } label: {
                    VStack(spacing: 3) {
                        ToyGlyph(kind: kind, theme: model.selectedTheme)
                            .frame(width: 18, height: 18)
                            .overlay(alignment: .topTrailing) {
                                if locked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(DS.Palette.textPrimary)
                                        .padding(1.5)
                                        .background(DS.Palette.background, in: Circle())
                                        .offset(x: 5, y: -4)
                                        .accessibilityHidden(true)
                                }
                            }
                        Text(chipLabel(for: kind, locked: locked))
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    .foregroundStyle(selected ? DS.Palette.textPrimary : DS.Palette.textSecondary)
                    .padding(.horizontal, DS.Spacing.xs)
                    .padding(.vertical, DS.Spacing.xs)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(selected ? DS.Palette.surface : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(selected ? DS.Palette.textSecondary.opacity(0.6) : DS.Palette.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(kind.title) toy")
                .accessibilityHint("Puts the \(kind.title.lowercased()) in the middle of the screen. Taps on it still count.")
                .accessibilityValue(accessibilityValue(for: kind, locked: locked))
                .accessibilityAddTraits(selected ? [.isSelected] : [])
                .accessibilityIdentifier("toyPicker.\(kind.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tap toy")
        .accessibilityIdentifier("toyPicker")
    }

    /// The locked piñata shows how far away it is, e.g. "1,200/5,000 · Pro".
    private func chipLabel(for kind: ToyKind, locked: Bool) -> String {
        if kind == .pinata && locked { return model.pinataProgressText }
        return kind.title
    }

    private func accessibilityValue(for kind: ToyKind, locked: Bool) -> String {
        guard locked else { return "" }
        if kind == .pinata {
            let presses = model.stats.totalPresses.formatted()
            let needed = PinataGate.minTotalPresses.formatted()
            return model.isPro
                ? "Locked. Needs \(needed) total presses. \(presses) so far"
                : "Locked. Needs Pro and \(needed) total presses. \(presses) so far"
        }
        return "Locked. Included with Pro"
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
        case .pinata:
            // feat-pinata: the banded gem body, no fringe at this size.
            PinataBands(colors: PinataToyView.bandColors, fringe: false)
                .clipShape(PinataBodyShape())
                .overlay(PinataBodyShape().strokeBorder(.black.opacity(0.4), lineWidth: 0.8))
                .frame(width: 18, height: 13)
        }
    }
}

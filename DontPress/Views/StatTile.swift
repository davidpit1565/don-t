import SwiftUI

struct StatTile: View {
    let title: String
    let value: Int
    var emphasized = false
    var identifier: String
    var accessibilitySuffix: String = ""

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Full grouping up to 999,999,999; compact beyond that so it never truncates on narrow tiles.
    private var displayText: String {
        value >= 1_000_000_000 ? value.formatted(.number.notation(.compactName)) : value.formatted()
    }

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(DS.Palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(displayText)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(emphasized ? DS.Palette.highlight : DS.Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: value)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.m)
        .padding(.horizontal, DS.Spacing.s)
        .background(DS.Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(DS.Palette.border, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title.capitalized)
        .accessibilityValue("\(value.formatted())\(accessibilitySuffix)")
        .accessibilityIdentifier(identifier)
    }
}

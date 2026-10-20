import SwiftUI

/// Dedicated 4:5 portrait card (1080×1350 pt at render scale 1). Not a screenshot.
struct ShareCardView: View {
    static let size = CGSize(width: 1080, height: 1350)
    let content: ShareCardContent

    var body: some View {
        ZStack {
            DS.Palette.background
            RadialGradient(
                colors: [DS.Palette.darkRed.opacity(0.28), .clear],
                center: .init(x: 0.5, y: 0.42), startRadius: 0, endRadius: 620
            )

            VStack(spacing: 0) {
                Text(content.title)
                    .font(.system(size: 44, weight: .heavy))
                    .tracking(10)
                    .foregroundStyle(DS.Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer(minLength: 40)

                miniButton

                Spacer(minLength: 40)

                Text(content.caption)
                    .font(.system(size: 34, weight: .semibold))
                    .tracking(8)
                    .foregroundStyle(DS.Palette.textSecondary)
                    .padding(.bottom, 8)

                Text(content.countText)
                    .font(.system(size: 220, weight: .heavy).monospacedDigit())
                    .foregroundStyle(DS.Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.2)

                Text(content.unitText)
                    .font(.system(size: 52, weight: .heavy))
                    .tracking(12)
                    .foregroundStyle(DS.Palette.buttonRed)
                    .padding(.bottom, 56)

                Text(content.quote)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(DS.Palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .padding(.bottom, 14)

                Text(content.footnote)
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(DS.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 96)
            .padding(.vertical, 96)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .environment(\.colorScheme, .dark)
    }

    private var miniButton: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [DS.Palette.surface, DS.Palette.background], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().strokeBorder(DS.Palette.border, lineWidth: 3))
            Circle()
                .fill(LinearGradient(colors: [DS.Palette.highlight, DS.Palette.buttonRed, DS.Palette.darkRed], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().strokeBorder(.white.opacity(0.22), lineWidth: 3))
                .padding(16)
        }
        .frame(width: 200, height: 200)
        .shadow(color: DS.Palette.darkRed.opacity(0.5), radius: 30, y: 12)
        .accessibilityHidden(true)
    }
}

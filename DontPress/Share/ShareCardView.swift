import SwiftUI

/// Dedicated 4:5 portrait card (1080×1350 pt at render scale 1). Not a screenshot.
/// Every number is the user's own; there is no ranking against anyone else.
struct ShareCardView: View {
    static let size = CGSize(width: 1080, height: 1350)
    let content: ShareCardContent

    var body: some View {
        ZStack {
            ShareCardBackground()

            VStack(spacing: 0) {
                ShareCardHeader(left: content.title, right: content.dayText)

                Spacer(minLength: 24)

                HStack(alignment: .center, spacing: 44) {
                    ShareCardMiniButton(diameter: 230)
                    VStack(alignment: .leading, spacing: 14) {
                        Text(content.caption)
                            .font(.system(size: 30, weight: .semibold))
                            .tracking(8)
                            .foregroundStyle(DS.Palette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        RarityBadge(text: content.rarityTitle)
                    }
                    Spacer(minLength: 0)
                }

                Spacer(minLength: 24)

                Text(content.countText)
                    .font(.system(size: 300, weight: .black).monospacedDigit())
                    .foregroundStyle(DS.Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.12)          // Int.max still fits on one line
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 300)

                Text(content.unitText)
                    .font(.system(size: 56, weight: .heavy))
                    .tracking(16)
                    .foregroundStyle(DS.Palette.buttonRed)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 24)

                Text(content.signatureLine ?? content.quote)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(DS.Palette.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 26)

                if content.streakText != nil || content.totalText != nil {
                    HStack(spacing: 16) {
                        if let streak = content.streakText { ShareCardChip(text: streak, systemImage: "flame.fill") }
                        if let total = content.totalText { ShareCardChip(text: total, systemImage: "sum") }
                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, 34)
                }

                Rectangle()
                    .fill(DS.Palette.border)
                    .frame(height: 2)
                    .padding(.bottom, 32)

                ShareCardFooter(callToAction: content.callToAction, storeHint: content.storeHint)
            }
            .padding(.horizontal, 88)
            .padding(.top, 84)
            .padding(.bottom, 92)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityDescription)
    }
}

/// No-spoiler card for today's challenge: outcome and streak only, never the target.
struct DailyShareCardView: View {
    static let size = ShareCardView.size
    let content: DailyShareContent

    private var symbol: String {
        switch content.result {
        case .success: return "checkmark"
        case .fail: return "xmark"
        case .pending: return "ellipsis"
        }
    }

    var body: some View {
        ZStack {
            ShareCardBackground()

            VStack(spacing: 0) {
                ShareCardHeader(left: content.title, right: content.dayText)

                Spacer(minLength: 24)

                ZStack {
                    ShareCardMiniButton(diameter: 360)
                    Image(systemName: symbol)
                        .font(.system(size: 130, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                }

                Spacer(minLength: 24)

                Text(content.resultTitle)
                    .font(.system(size: 92, weight: .black))
                    .foregroundStyle(DS.Palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .padding(.bottom, 18)

                Text(content.resultLine)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(DS.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .padding(.bottom, 30)

                if let streak = content.streakText {
                    ShareCardChip(text: streak, systemImage: "flame.fill")
                }

                Spacer(minLength: 24)

                Rectangle()
                    .fill(DS.Palette.border)
                    .frame(height: 2)
                    .padding(.bottom, 32)

                ShareCardFooter(callToAction: content.callToAction, storeHint: content.storeHint)
            }
            .padding(.horizontal, 88)
            .padding(.top, 84)
            .padding(.bottom, 92)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityDescription)
    }
}

// MARK: Shared card parts

private struct ShareCardBackground: View {
    var body: some View {
        ZStack {
            DS.Palette.background
            RadialGradient(
                colors: [DS.Palette.darkRed.opacity(0.30), .clear],
                center: .init(x: 0.22, y: 0.30), startRadius: 0, endRadius: 760
            )
            VStack {
                Spacer()
                HazardStripe()
                    .frame(height: 22)
            }
        }
    }
}

/// Thin red/black diagonal warning band along the bottom edge: the card's signature detail.
private struct HazardStripe: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(DS.Palette.background))
            let stripe: CGFloat = 34
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                path.addLine(to: CGPoint(x: x + size.height + stripe, y: 0))
                path.addLine(to: CGPoint(x: x + stripe, y: size.height))
                path.closeSubpath()
                context.fill(path, with: .color(DS.Palette.buttonRed))
                x += stripe * 2
            }
        }
    }
}

private struct ShareCardHeader: View {
    let left: String
    let right: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(left)
                .font(.system(size: 40, weight: .heavy))
                .tracking(9)
                .foregroundStyle(DS.Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer(minLength: 24)
            if let right {
                Text(right)
                    .font(.system(size: 30, weight: .bold).monospacedDigit())
                    .tracking(5)
                    .foregroundStyle(DS.Palette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

private struct RarityBadge: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 34, weight: .heavy))
            .tracking(4)
            .foregroundStyle(DS.Palette.highlight)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 26)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(DS.Palette.buttonRed, lineWidth: 3)
            )
    }
}

private struct ShareCardChip: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(DS.Palette.buttonRed)
            Text(text)
                .foregroundStyle(DS.Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
        .font(.system(size: 30, weight: .bold).monospacedDigit())
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(DS.Palette.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(DS.Palette.border, lineWidth: 2))
    }
}

private struct ShareCardFooter: View {
    let callToAction: String
    let storeHint: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(callToAction)
                .font(.system(size: 50, weight: .heavy))
                .foregroundStyle(DS.Palette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.4)
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                Text(storeHint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(DS.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The big red button, small: concentric housing + glossy cap.
struct ShareCardMiniButton: View {
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [DS.Palette.surface, DS.Palette.background], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().strokeBorder(DS.Palette.border, lineWidth: 3))
            Circle()
                .fill(LinearGradient(colors: [DS.Palette.highlight, DS.Palette.buttonRed, DS.Palette.darkRed], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().strokeBorder(.white.opacity(0.22), lineWidth: 3))
                .padding(diameter * 0.08)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: DS.Palette.darkRed.opacity(0.5), radius: 30, y: 12)
        .accessibilityHidden(true)
    }
}

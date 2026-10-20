import SwiftUI

struct HomeView: View {
    @Bindable var model: HomeViewModel
    @State private var isSharing = false
    @State private var shareError = false

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: DS.Spacing.l) {
                    header
                    Spacer(minLength: 0)
                    pressButton(available: proxy.size)
                    reactionLine
                    Spacer(minLength: 0)
                    stats
                    shareButton
                    legalLinks
                }
                .padding(.horizontal, DS.Spacing.l)
                .padding(.vertical, DS.Spacing.m)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(DS.Palette.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .alert("Couldn't make the image", isPresented: $shareError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your stats are unchanged. Try again in a moment.")
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: DS.Spacing.s) {
            Text("DON'T PRESS")
                .font(.footnote.weight(.heavy))
                .tracking(3)
                .foregroundStyle(DS.Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("wordmark")
            Text("Whatever you do, don't press it.")
                .font(.headline.weight(.regular))
                .foregroundStyle(DS.Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func pressButton(available: CGSize) -> some View {
        let base = min(available.width - DS.Spacing.l * 2, available.height * 0.38, 340)
        let diameter = max(base, 180)
        return Button {
            model.press()
        } label: {
            BigRedButtonLabel(diameter: diameter)
        }
        .buttonStyle(PlungerButtonStyle(diameter: diameter))
        .accessibilityLabel("Don't press")
        .accessibilityHint("Double tap to press it anyway. Adds one to your run.")
        .accessibilityValue(buttonAccessibilityValue)
        .accessibilityIdentifier("pressButton")
    }

    /// VoiceOver reads this after activation, so the reaction is heard without extra announcements.
    private var buttonAccessibilityValue: String {
        let run = "Current run \(model.stats.currentRun.formatted())"
        return model.stats.currentRun == 0 ? run : "\(run). \(model.reactionText)"
    }

    private var reactionLine: some View {
        Text(model.reactionText)
            .font(.title3.weight(.semibold))
            .foregroundStyle(DS.Palette.textPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.opacity)
            .animation(.easeOut(duration: 0.12), value: model.reactionText)
            .accessibilityIdentifier("reactionLabel")
    }

    @ViewBuilder
    private var stats: some View {
        let tiles = Group {
            StatTile(title: "CURRENT RUN", value: model.stats.currentRun, identifier: "currentRun")
            StatTile(
                title: "PERSONAL BEST", value: model.stats.personalBest,
                emphasized: model.isAtPersonalBest, identifier: "personalBest",
                accessibilitySuffix: model.isAtPersonalBest ? ", new personal best" : ""
            )
            StatTile(title: "TOTAL PRESSES", value: model.stats.totalPresses, identifier: "totalPresses")
        }
        if typeSize.isAccessibilitySize {
            VStack(spacing: DS.Spacing.s) { tiles }
        } else {
            HStack(spacing: DS.Spacing.s) { tiles }
        }
    }

    private var shareButton: some View {
        Button {
            share()
        } label: {
            Label("Share personal best", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
                .padding(.horizontal, DS.Spacing.m)
        }
        .buttonStyle(.bordered)
        .tint(DS.Palette.textSecondary)
        .foregroundStyle(DS.Palette.textPrimary)
        .disabled(model.shareContent == nil)
        .accessibilityHint(model.shareContent == nil ? "Press the button at least once to unlock sharing." : "Opens the share sheet with an image of your personal best.")
        .accessibilityIdentifier("shareButton")
    }

    private var legalLinks: some View {
        HStack(spacing: DS.Spacing.l) {
            Link("Privacy", destination: AppLinks.privacyPolicy)
                .frame(minWidth: 64, minHeight: 44)
                .accessibilityIdentifier("privacyLink")
            Link("Support", destination: AppLinks.support)
                .frame(minWidth: 64, minHeight: 44)
                .accessibilityIdentifier("supportLink")
        }
        .font(.footnote)
        .foregroundStyle(DS.Palette.textSecondary)
    }

    // MARK: Sharing

    private func share() {
        guard !isSharing, let content = model.shareContent else { return }
        isSharing = true
        guard let image = ShareImageRenderer.render(content) else {
            isSharing = false
            shareError = true
            return
        }
        let presented = SharePresenter.present(image: image) {
            isSharing = false   // completed or cancelled: statistics are never touched
        }
        if !presented {
            isSharing = false
            shareError = true
        }
    }
}

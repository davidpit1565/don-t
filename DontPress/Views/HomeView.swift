import SwiftUI

struct HomeView: View {
    @Bindable var model: HomeViewModel
    var proStore: ProStore
    @State private var isSharing = false
    @State private var shareError = false
    @State private var showCollection = false
    /// Set-pieces: plays the haptic plan of the active set-piece (see SetPieceEffects.swift).
    @State private var setPieceHaptics = SetPieceHaptics()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { proxy in
            if typeSize.isAccessibilitySize {
                // Huge accessibility text cannot fit one screen: allow scrolling only here.
                ScrollView {
                    content(fixedDiameter: min(proxy.size.width - DS.Spacing.l * 2, 240))
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                // Everything on ONE screen, no scrolling: the button takes the space that is left.
                content(fixedDiameter: nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .top) { unlockBanner }
        .sheet(isPresented: $showCollection) { CollectionView(model: model, proStore: proStore) }
        .background(DS.Palette.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .alert("Couldn't make the image", isPresented: $shareError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your stats are unchanged. Try again in a moment.")
        }
    }

    // MARK: Layout

    private func content(fixedDiameter: CGFloat?) -> some View {
        VStack(spacing: DS.Spacing.m) {
            header
            buttonArea(fixedDiameter: fixedDiameter)
            reactionLine
            stats
            shareButton
            legalLinks
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.vertical, DS.Spacing.s)
        .frame(maxWidth: 520)
    }

    @ViewBuilder
    private func buttonArea(fixedDiameter: CGFloat?) -> some View {
        if let fixedDiameter {
            pressButton(diameter: fixedDiameter)
        } else {
            GeometryReader { geo in
                let diameter = max(min(geo.size.width, geo.size.height, 340), 120)
                pressButton(diameter: diameter)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(minHeight: 140)
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: DS.Spacing.s) {
            HStack {
                SoundToggleButton(model: model) // [audio] replaces the 44pt spacer
                Spacer()
                Text("DON'T PRESS")
                    .font(.footnote.weight(.heavy))
                    .tracking(3)
                    .foregroundStyle(DS.Palette.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("wordmark")
                Spacer()
                Button { showCollection = true } label: {
                    Image(systemName: "trophy")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(DS.Palette.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Achievements and button styles")
                .accessibilityValue("\(model.unlockedAchievementCount) of \(Achievement.all.count) unlocked")
                .accessibilityIdentifier("collectionButton")
            }
            Text("Whatever you do, don't press it.")
                .font(.headline.weight(.regular))
                .foregroundStyle(DS.Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func pressButton(diameter: CGFloat) -> some View {
        Button {
            model.press()
        } label: {
            BigRedButtonLabel(diameter: diameter, theme: model.selectedTheme)
        }
        .buttonStyle(PlungerButtonStyle(diameter: diameter, theme: model.selectedTheme))
        // Set-pieces ("the button fights back"): visual only; taps keep counting underneath.
        .setPieceEffects(
            model.activeSetPiece, diameter: diameter,
            onHaptic: { setPieceHaptics.play($0) },
            onFinished: { model.finishSetPiece(id: $0) }
        )
        .accessibilityLabel("Don't press")
        .accessibilityHint("Double tap to press it anyway. Adds one to your run.")
        .accessibilityValue(buttonAccessibilityValue)
        .accessibilityIdentifier("pressButton")
    }

    /// VoiceOver reads this after activation, so the reaction is heard without extra announcements.
    private var buttonAccessibilityValue: String {
        let run = "Current run \(model.stats.currentRun.formatted())"
        let fresh = model.isNewDiscovery ? " New line discovered." : "" // Reactiondex
        return model.stats.currentRun == 0 ? run : "\(run). \(model.reactionText)\(fresh)"
    }

    private var reactionLine: some View {
        Text(model.reactionText)
            .font(.title3.weight(.semibold))
            .foregroundStyle(DS.Palette.textPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.opacity)
            .animation(.easeOut(duration: 0.12), value: model.reactionText)
            .accessibilityIdentifier("reactionLabel")
            .overlay(alignment: .bottom) { newDiscoveryMarker }
    }

    /// Reactiondex: small "NEW" tag under the reaction when this press revealed an unseen line.
    /// Hangs below the line (into the stack spacing) so it never changes the layout.
    @ViewBuilder
    private var newDiscoveryMarker: some View {
        if model.isNewDiscovery && model.stats.currentRun > 0 {
            Text("NEW")
                .font(.caption2.weight(.heavy))
                .tracking(1.5)
                .foregroundStyle(DS.Palette.textPrimary)
                .padding(.horizontal, DS.Spacing.s)
                .padding(.vertical, 2)
                .background(DS.Palette.darkRed, in: Capsule())
                .alignmentGuide(.bottom) { $0[.top] }
                .transition(.opacity)
                .accessibilityLabel("New line discovered")
                .accessibilityIdentifier("newDiscoveryMarker")
        }
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

    @ViewBuilder
    private var unlockBanner: some View {
        if let message = model.unlockMessage {
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DS.Palette.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.m)
                .padding(.vertical, DS.Spacing.s)
                .background(DS.Palette.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(DS.Palette.border, lineWidth: 1))
                .padding(.top, DS.Spacing.s)
                .padding(.horizontal, DS.Spacing.l)
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                .accessibilityIdentifier("unlockBanner")
                .task(id: message) {
                    AccessibilityNotification.Announcement(message).post()
                    try? await Task.sleep(for: .seconds(3.5))
                    withAnimation(reduceMotion ? nil : .snappy) { model.dismissUnlockMessage() }
                }
        }
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

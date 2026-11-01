import SwiftUI

/// A small, dismissible bottom card that mentions Pro. Overlays the home screen without moving
/// anything underneath; never blocks the button (taps outside the card keep counting).
/// "See Pro" and "Not now" have identical size and style; "Don't ask again" is a quiet link.
/// No timers, no countdowns, no auto-dismiss pressure.
struct ProNudgeView: View {
    let nudge: ProNudge
    var onSeePro: () -> Void
    var onNotNow: () -> Void
    var onDontAskAgain: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text(nudge.title)
                .font(.headline)
                .foregroundStyle(DS.Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(nudge.message)
                .font(.subheadline)
                .foregroundStyle(DS.Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Pro: " + nudge.proIncludes.joined(separator: " · "))
                .font(.footnote)
                .foregroundStyle(DS.Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Pro includes: " + nudge.proIncludes.joined(separator: ", "))

            HStack(spacing: DS.Spacing.s) {
                actionButton("Not now", identifier: "nudgeNotNow", hint: "Closes this card.", action: onNotNow)
                actionButton("See Pro", identifier: "nudgeSeePro", hint: "Opens the Pro details.", action: onSeePro)
            }
            .padding(.top, DS.Spacing.xs)

            Button("Don't ask again", action: onDontAskAgain)
                .font(.footnote)
                .foregroundStyle(DS.Palette.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityHint("Stops these suggestions. Locked items still show what Pro includes.")
                .accessibilityIdentifier("nudgeOptOut")
        }
        .padding(DS.Spacing.m)
        .background(DS.Palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DS.Palette.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
        .frame(maxWidth: 480)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("About Pro")
        .accessibilityIdentifier("proNudge")
    }

    private func actionButton(_ title: String, identifier: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(DS.Palette.textSecondary)
        .foregroundStyle(DS.Palette.textPrimary)
        .accessibilityHint(hint)
        .accessibilityIdentifier(identifier)
    }
}

/// Places the nudge card at the bottom of the screen and announces it to VoiceOver.
/// Usage in HomeView: `.overlay(alignment: .bottom) { ProNudgeOverlay(model: model) { showToyPro = true } }`
struct ProNudgeOverlay: View {
    @Bindable var model: HomeViewModel
    /// Opens ProView (HomeView already owns that sheet).
    var openPro: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            if let nudge = model.pendingNudge {
                ProNudgeView(
                    nudge: nudge,
                    onSeePro: { close { model.nudgeSeePro() }; openPro() },
                    onNotNow: { close { model.nudgeNotNow() } },
                    onDontAskAgain: { close { model.nudgeOptOut() } }
                )
                .padding(.horizontal, DS.Spacing.m)
                .padding(.bottom, DS.Spacing.s)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .id(nudge.id)
                .onAppear {
                    AccessibilityNotification.Announcement("\(nudge.title) \(nudge.message)").post()
                }
            }
        }
        .animation(reduceMotion ? Animation.easeOut(duration: 0.15) : Animation.snappy, value: model.pendingNudge?.id)
    }

    private func close(_ change: () -> Void) {
        withAnimation(reduceMotion ? Animation.easeOut(duration: 0.15) : Animation.snappy) { change() }
    }
}

/// Asks the scheduler once the user has stopped tapping. The task restarts on every press, so it
/// only completes after ~3 s of quiet (the scheduler enforces the exact rule with its own clock).
/// Usage in HomeView: `.proNudgeIdleCheck(model)` on the root view.
struct ProNudgeIdleCheck: ViewModifier {
    let model: HomeViewModel

    func body(content: Content) -> some View {
        content.task(id: model.pressCount) {
            try? await Task.sleep(for: .seconds(3.2))
            guard !Task.isCancelled else { return }
            model.checkForNudge()
        }
    }
}

extension View {
    func proNudgeIdleCheck(_ model: HomeViewModel) -> some View {
        modifier(ProNudgeIdleCheck(model: model))
    }
}

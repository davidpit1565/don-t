import SwiftUI
import UIKit

/// "App icon" section for CollectionView: one home-screen icon per button style.
/// Each icon unlocks with its style's normal rule, or with Pro. Locked rows call `onLockedTap`
/// (CollectionView passes `{ showPro = true }`, the same as locked style rows).
@MainActor
struct AppIconPickerSection: View {
    let stats: PressStats
    let isPro: Bool
    let onLockedTap: () -> Void

    /// Read from UIApplication on appear; nil is the primary (Classic Red) icon.
    @State private var currentIconName: String?
    @State private var supportsAlternateIcons = true
    @State private var isChanging = false
    @State private var message: String?

    var body: some View {
        Section {
            ForEach(AppIconChoice.statuses(stats: stats, isPro: isPro, currentIconName: currentIconName)) { status in
                row(status)
            }
        } header: {
            Text("App icon")
        } footer: {
            Text(footerText)
                .font(.footnote)
                .foregroundStyle(DS.Palette.textSecondary)
                .accessibilityIdentifier("appIconFooter")
        }
        .onAppear(perform: refresh)
    }

    private var footerText: String {
        if let message { return message }
        if !supportsAlternateIcons { return "This device can't change the app icon." }
        return "Matches the button styles. iOS confirms the change with a short alert."
    }

    private func row(_ status: AppIconStatus) -> some View {
        let unavailable = status.isUnlocked && (!supportsAlternateIcons || isChanging)
        return Button {
            select(status)
        } label: {
            HStack(spacing: DS.Spacing.m) {
                AppIconPreview(theme: status.choice.theme)
                    .opacity(status.isUnlocked ? 1 : 0.35)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.choice.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(status.isUnlocked ? DS.Palette.textPrimary : DS.Palette.textSecondary)
                    if let requirement = status.requirementText {
                        Text(requirement)
                            .font(.footnote)
                            .foregroundStyle(DS.Palette.textSecondary)
                    }
                }
                Spacer()
                if status.isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(DS.Palette.textPrimary)
                } else if !status.isUnlocked {
                    Image(systemName: "lock.fill").foregroundStyle(DS.Palette.textSecondary)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .disabled(unavailable)
        .listRowBackground(DS.Palette.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(status.choice.name) app icon")
        .accessibilityValue(accessibilityValue(status))
        .accessibilityHint(status.isUnlocked ? (status.isSelected ? "" : "Sets the home screen icon") : "Opens the Pro offer")
        .accessibilityAddTraits(status.isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("appIcon-\(status.choice.id)")
    }

    private func accessibilityValue(_ status: AppIconStatus) -> String {
        if status.isSelected { return "Selected" }
        if let requirement = status.requirementText { return "Locked. \(requirement)" }
        return "Unlocked"
    }

    private func refresh() {
        supportsAlternateIcons = UIApplication.shared.supportsAlternateIcons
        currentIconName = UIApplication.shared.alternateIconName
    }

    private func select(_ status: AppIconStatus) {
        guard status.isUnlocked else {
            onLockedTap()
            return
        }
        guard supportsAlternateIcons, !isChanging, !status.isSelected else { return }
        let name = status.choice.iconName
        isChanging = true
        message = nil
        Task { @MainActor in
            do {
                try await UIApplication.shared.setAlternateIconName(name)
            } catch {
                show("Couldn't change the icon right now. Try again later.")
            }
            currentIconName = UIApplication.shared.alternateIconName
            isChanging = false
        }
    }

    private func show(_ text: String) {
        message = text
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}

/// Small home-screen-icon-shaped swatch drawn in SwiftUI (no extra preview assets).
struct AppIconPreview: View {
    let theme: ButtonTheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
        shape
            .fill(DS.Palette.background)
            .overlay(theme.swatch.padding(7))
            .overlay(shape.strokeBorder(DS.Palette.border, lineWidth: 1))
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)
    }
}

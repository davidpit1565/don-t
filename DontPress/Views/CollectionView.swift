import SwiftUI

/// Button styles and achievements. Everything is local and derived from the saved stats.
struct CollectionView: View {
    @Bindable var model: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(model.themeStatuses) { status in
                        themeRow(status)
                    }
                } header: {
                    Text("Button style")
                }

                Section {
                    ForEach(model.achievementStatuses) { status in
                        achievementRow(status)
                    }
                } header: {
                    Text("Achievements · \(model.unlockedAchievementCount) of \(Achievement.all.count)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.Palette.background.ignoresSafeArea())
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("collectionDone")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func themeRow(_ status: ThemeStatus) -> some View {
        Button {
            model.selectTheme(status.theme)
        } label: {
            HStack(spacing: DS.Spacing.m) {
                status.theme.swatch
                    .frame(width: 40, height: 40)
                    .opacity(status.isUnlocked ? 1 : 0.35)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.theme.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(status.isUnlocked ? DS.Palette.textPrimary : DS.Palette.textSecondary)
                    if !status.isUnlocked {
                        Text(status.theme.rule.requirementText)
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
        }
        .disabled(!status.isUnlocked)
        .listRowBackground(DS.Palette.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.theme.name)
        .accessibilityValue(status.isSelected ? "Selected" : status.isUnlocked ? "Unlocked" : "Locked. \(status.theme.rule.requirementText)")
        .accessibilityAddTraits(status.isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("theme-\(status.theme.id)")
    }

    private func achievementRow(_ status: AchievementStatus) -> some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: status.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                .font(.title3)
                .foregroundStyle(status.isUnlocked ? DS.Palette.highlight : DS.Palette.textSecondary)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(status.achievement.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(status.isUnlocked ? DS.Palette.textPrimary : DS.Palette.textSecondary)
                Text(status.achievement.detail)
                    .font(.footnote)
                    .foregroundStyle(DS.Palette.textSecondary)
            }
            Spacer()
            if let progress = status.progress {
                Text("\(progress.current.formatted())/\(progress.target.formatted())")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(DS.Palette.textSecondary)
            }
        }
        .frame(minHeight: 44)
        .listRowBackground(DS.Palette.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.achievement.title)
        .accessibilityValue(status.isUnlocked ? "Unlocked. \(status.achievement.detail)" : "Locked. \(status.achievement.detail)")
        .accessibilityIdentifier("achievement-\(status.achievement.id)")
    }
}

import SwiftUI

/// Button styles and achievements. Everything is local and derived from the saved stats.
struct CollectionView: View {
    @Bindable var model: HomeViewModel
    @Bindable var proStore: ProStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPro = false
    @State private var showReactiondex = false
    @State private var showDaily = false   // feat-daily

    var body: some View {
        NavigationStack {
            List {
                // feat-daily: entry point to the daily challenge sheet.
                if model.daily != nil {
                    Section { dailyRow }
                }

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

                Section {
                    reactiondexRow
                } header: {
                    Text("Reactions")
                }

                Section {
                    proRow
                } header: {
                    Text("Pro")
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
        .sheet(isPresented: $showPro) { ProView(proStore: proStore) }
        .sheet(isPresented: $showReactiondex) { ReactiondexView(dex: model.reactiondex) }
        .sheet(isPresented: $showDaily) { DailyChallengeView(model: model) }   // feat-daily
    }

    // feat-daily
    private var dailyRow: some View {
        Button { showDaily = true } label: {
            HStack(spacing: DS.Spacing.m) {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(DS.Palette.highlight)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily challenge").font(.body.weight(.semibold)).foregroundStyle(DS.Palette.textPrimary)
                    Text(dailySubtitle).font(.footnote).foregroundStyle(DS.Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(DS.Palette.textSecondary)
            }
            .frame(minHeight: 44)
        }
        .listRowBackground(DS.Palette.surface)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dailyRow")
    }

    private var dailySubtitle: String {
        guard let daily = model.daily else { return "" }
        let streak = daily.streak == 1 ? "1-day streak" : "\(daily.streak.formatted())-day streak"
        switch daily.result {
        case .success: return "Done for today · \(streak)"
        case .fail: return "Failed today · \(streak)"
        case .pending: return "In progress · \(streak)"
        }
    }

    // MARK: Reactiondex

    private var reactiondexRow: some View {
        let dex = model.reactiondex
        return Button { showReactiondex = true } label: {
            HStack(spacing: DS.Spacing.m) {
                Image(systemName: "text.book.closed")
                    .font(.title3)
                    .foregroundStyle(DS.Palette.highlight)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reactiondex").font(.body.weight(.semibold)).foregroundStyle(DS.Palette.textPrimary)
                    Text(verbatim: "Discovered \(dex.discoveredCount)/\(dex.totalCount) · \(dex.rareFoundCount) rare")
                        .font(.footnote).foregroundStyle(DS.Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(DS.Palette.textSecondary)
            }
            .frame(minHeight: 44)
        }
        .listRowBackground(DS.Palette.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reactiondex")
        .accessibilityValue("\(dex.discoveredCount) of \(dex.totalCount) lines discovered, \(dex.rareFoundCount) rare")
        .accessibilityHint("Opens every reaction line you have found")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("reactiondexRow")
    }

    private var proRow: some View {
        Button { showPro = true } label: {
            HStack(spacing: DS.Spacing.m) {
                Image(systemName: model.isPro ? "checkmark.seal.fill" : "sparkles")
                    .font(.title3)
                    .foregroundStyle(DS.Palette.highlight)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("DON'T PRESS Pro").font(.body.weight(.semibold)).foregroundStyle(DS.Palette.textPrimary)
                    Text(model.isPro ? "Unlocked. Thank you!" : "Unlock all button styles right away")
                        .font(.footnote).foregroundStyle(DS.Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(DS.Palette.textSecondary)
            }
            .frame(minHeight: 44)
        }
        .listRowBackground(DS.Palette.surface)
        .accessibilityIdentifier("proRow")
    }

    private func themeRow(_ status: ThemeStatus) -> some View {
        Button {
            if status.isUnlocked { model.selectTheme(status.theme) } else { showPro = true }
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
                        Text("\(status.theme.rule.requirementText), or unlock with Pro")
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
        .listRowBackground(DS.Palette.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.theme.name)
        .accessibilityValue(status.isSelected ? "Selected" : status.isUnlocked ? "Unlocked" : "Locked. \(status.theme.rule.requirementText), or unlock with Pro")
        .accessibilityHint(status.isUnlocked ? "" : "Opens the Pro offer")
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

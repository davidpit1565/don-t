import SwiftUI

/// Compact sheet: today's challenge (same for everyone, derived from the date), progress and streak.
struct DailyChallengeView: View {
    @Bindable var model: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSharing = false
    @State private var shareError = false

    var body: some View {
        NavigationStack {
            List {
                if let daily = model.daily {
                    challengeSection(daily)
                    streakSection(daily)
                    shareSection
                } else {
                    Section {
                        Text("The daily challenge is not available right now.")
                            .foregroundStyle(DS.Palette.textSecondary)
                            .listRowBackground(DS.Palette.surface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.Palette.background.ignoresSafeArea())
            .navigationTitle("Daily")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("dailyDone")
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { model.refreshDaily() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refreshDaily() }   // picks up a new day after midnight
        }
        .alert("Couldn't make the image", isPresented: $shareError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your progress is unchanged. Try again in a moment.")
        }
    }

    // MARK: Sections

    private func challengeSection(_ daily: DailySnapshot) -> some View {
        Section {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text(daily.challenge.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DS.Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("dailyTitle")
                Text(daily.challenge.detail)
                    .font(.footnote)
                    .foregroundStyle(DS.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressView(
                    value: Double(min(max(daily.pressesToday, 0), daily.challenge.target)),
                    total: Double(max(daily.challenge.target, 1))
                )
                .tint(progressTint(daily.result))
                .padding(.top, DS.Spacing.xs)
                .accessibilityHidden(true)

                HStack {
                    Text(daily.progressText)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(DS.Palette.textPrimary)
                    Spacer()
                    Label(daily.resultText, systemImage: resultSymbol(daily.result))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(daily.result == .pending ? DS.Palette.textSecondary : DS.Palette.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.vertical, DS.Spacing.xs)
            .listRowBackground(DS.Palette.surface)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("dailyChallenge")
        } header: {
            Text(daily.challenge.dayNumber > 0 ? "Today · Daily #\(daily.challenge.dayNumber.formatted())" : "Today")
        } footer: {
            Text("Same challenge for everyone today. Every press today counts, across every run. A new one starts at midnight.")
        }
    }

    private func streakSection(_ daily: DailySnapshot) -> some View {
        Section {
            row(symbol: "flame.fill", title: "Day streak", value: dayCount(daily.streak), identifier: "dailyStreak")
            row(symbol: "crown", title: "Longest streak", value: dayCount(daily.bestStreak), identifier: "dailyBestStreak")
            row(
                symbol: daily.hasFreeze ? "snowflake" : "hourglass",
                title: "Streak freeze",
                value: daily.isRelyingOnFreeze ? "Covering yesterday" : (daily.hasFreeze ? "Ready" : "Recharging"),
                identifier: "dailyFreeze"
            )
        } header: {
            Text("Streak")
        } footer: {
            Text("Press at least once a day to keep it going. One missed day per week is forgiven automatically.")
        }
    }

    private var shareSection: some View {
        Section {
            Button {
                share()
            } label: {
                Label("Share today's result", systemImage: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .frame(minHeight: 44)
            }
            .disabled(model.dailyShareContent == nil || isSharing)
            .listRowBackground(DS.Palette.surface)
            .accessibilityHint(model.dailyShareContent == nil
                ? "Press the button at least once today to unlock sharing."
                : "Shares an image of today's outcome and streak, without the answer.")
            .accessibilityIdentifier("dailyShareButton")
        } footer: {
            Text("No spoilers: the card shows whether you made it and your streak, never the number.")
        }
    }

    private func row(symbol: String, title: String, value: String, identifier: String) -> some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(DS.Palette.highlight)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(title)
                .foregroundStyle(DS.Palette.textPrimary)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundStyle(DS.Palette.textSecondary)
        }
        .frame(minHeight: 44)
        .listRowBackground(DS.Palette.surface)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    // MARK: Helpers

    private func dayCount(_ value: Int) -> String {
        value == 1 ? "1 day" : "\(value.formatted()) days"
    }

    private func resultSymbol(_ result: ChallengeResult) -> String {
        switch result {
        case .pending: return "circle.dotted"
        case .success: return "checkmark.circle.fill"
        case .fail: return "xmark.circle.fill"
        }
    }

    private func progressTint(_ result: ChallengeResult) -> Color {
        switch result {
        case .pending: return DS.Palette.textSecondary
        case .success: return DS.Palette.highlight
        case .fail: return DS.Palette.darkRed
        }
    }

    private func share() {
        guard !isSharing, let content = model.dailyShareContent else { return }
        isSharing = true
        guard let image = ShareImageRenderer.render(content) else {
            isSharing = false
            shareError = true
            return
        }
        let presented = SharePresenter.present(image: image, title: "DON'T PRESS: today's challenge") {
            isSharing = false   // completed or cancelled: nothing is counted
        }
        if !presented {
            isSharing = false
            shareError = true
        }
    }
}

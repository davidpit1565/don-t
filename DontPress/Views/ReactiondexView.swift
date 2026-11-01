import SwiftUI

/// Every curated line, discovered or not. Undiscovered lines show as "???" with their badge.
struct ReactiondexView: View {
    let dex: Reactiondex
    @Environment(\.dismiss) private var dismiss

    private static let specialKinds: [ReactionKind] = [.milestone, .story, .secret, .ending]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    meter
                }

                ForEach(ReactionTier.allCases, id: \.self) { tier in
                    section(
                        title: tier.displayName,
                        subtitle: tier.rangeText,
                        entries: dex.entries.filter { $0.kind == .regular && $0.reaction.tier == tier }
                    )
                }

                ForEach(Self.specialKinds, id: \.self) { kind in
                    section(
                        title: sectionTitle(for: kind),
                        subtitle: nil,
                        entries: dex.entries.filter { $0.kind == kind }
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.Palette.background.ignoresSafeArea())
            .navigationTitle("Reactiondex")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("reactiondexDone")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Meter

    private var meter: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("Discovered")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Palette.textSecondary)
                Spacer()
                Text(verbatim: "\(dex.discoveredCount)/\(dex.totalCount)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(DS.Palette.textPrimary)
            }
            ProgressView(value: Double(dex.discoveredCount), total: Double(max(dex.totalCount, 1)))
                .tint(DS.Palette.buttonRed)
            Text(verbatim: "Rare lines found: \(dex.rareFoundCount) of \(dex.rareTotalCount)")
                .font(.footnote)
                .foregroundStyle(DS.Palette.textSecondary)
            Text(verbatim: dex.hasReachedEnding
                 ? "Ending reached: \(StoryCatalog.endingName)"
                 : "Some lines only appear at very specific moments.")
                .font(.footnote)
                .foregroundStyle(dex.hasReachedEnding ? DS.Palette.highlight : DS.Palette.textSecondary)
        }
        .padding(.vertical, DS.Spacing.s)
        .listRowBackground(DS.Palette.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reactiondex progress")
        .accessibilityValue(meterAccessibilityValue)
        .accessibilityIdentifier("reactiondexMeter")
    }

    private var meterAccessibilityValue: String {
        var parts = [
            "\(dex.discoveredCount) of \(dex.totalCount) lines discovered",
            "\(dex.rareFoundCount) of \(dex.rareTotalCount) rare lines found",
        ]
        if dex.hasReachedEnding { parts.append("Ending reached: \(StoryCatalog.endingName)") }
        return parts.joined(separator: ". ")
    }

    // MARK: Sections

    @ViewBuilder
    private func section(title: String, subtitle: String?, entries: [ReactiondexEntry]) -> some View {
        if !entries.isEmpty {
            let found = entries.filter(\.isDiscovered).count
            Section {
                ForEach(entries) { entry in
                    row(entry)
                }
            } header: {
                Text(verbatim: headerText(title: title, subtitle: subtitle, found: found, total: entries.count))
                    .accessibilityLabel(Text(verbatim: "\(title). \(found) of \(entries.count) discovered"))
            }
        }
    }

    private func headerText(title: String, subtitle: String?, found: Int, total: Int) -> String {
        if let subtitle { return "\(title) · \(subtitle) · \(found)/\(total)" }
        return "\(title) · \(found)/\(total)"
    }

    private func sectionTitle(for kind: ReactionKind) -> String {
        switch kind {
        case .regular: return "Reactions"
        case .milestone: return "Milestones"
        case .story: return "The Button's Story"
        case .secret: return "Secrets"
        case .ending: return "Ending"
        }
    }

    // MARK: Rows

    private func row(_ entry: ReactiondexEntry) -> some View {
        HStack(alignment: .center, spacing: DS.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: entry.isDiscovered ? entry.reaction.text : "???")
                    .font(entry.isDiscovered ? Font.body : Font.body.weight(.semibold))
                    .foregroundStyle(entry.isDiscovered ? DS.Palette.textPrimary : DS.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = detailText(for: entry) {
                    Text(verbatim: detail)
                        .font(.footnote)
                        .foregroundStyle(DS.Palette.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            badge(for: entry)
        }
        .frame(minHeight: 44)
        .listRowBackground(DS.Palette.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: entry.isDiscovered ? entry.reaction.text : "Undiscovered line"))
        .accessibilityValue(Text(verbatim: accessibilityValue(for: entry)))
        .accessibilityIdentifier("dex-\(entry.id)")
    }

    private func detailText(for entry: ReactiondexEntry) -> String? {
        switch entry.kind {
        case .ending:
            return entry.isDiscovered ? "Ending: \(StoryCatalog.endingName)" : "Somewhere at the end of a very long run."
        case .story:
            guard let run = StoryCatalog.runCount(forSpecialID: entry.id) else { return nil }
            let part = (StoryCatalog.orderedBeats.firstIndex { $0.id == entry.id } ?? 0) + 1
            return entry.isDiscovered ? "Part \(part) · press \(run.formatted())" : "Part \(part)"
        case .secret:
            guard entry.isDiscovered, let run = StoryCatalog.runCount(forSpecialID: entry.id) else { return nil }
            return "Press \(run.formatted())"
        case .regular, .milestone:
            return nil
        }
    }

    private func badgeText(for entry: ReactiondexEntry) -> String {
        entry.kind == .regular ? entry.reaction.tier.displayName : entry.kind.displayName
    }

    private func badge(for entry: ReactiondexEntry) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(verbatim: badgeText(for: entry).uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(entry.isDiscovered ? DS.Palette.textPrimary : DS.Palette.textSecondary)
                .padding(.horizontal, DS.Spacing.s)
                .padding(.vertical, 3)
                .background(DS.Palette.background, in: Capsule())
                .overlay(Capsule().strokeBorder(DS.Palette.border, lineWidth: 1))
            if entry.reaction.isRare {
                Label("Rare", systemImage: "sparkle")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DS.Palette.highlight)
            }
        }
        .fixedSize()
    }

    private func accessibilityValue(for entry: ReactiondexEntry) -> String {
        var parts = [badgeText(for: entry)]
        if entry.reaction.isRare { parts.append("rare") }
        if let detail = detailText(for: entry) { parts.append(detail) }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    ReactiondexView(dex: Reactiondex(discoveredIDs: ["mild-01", "secret-13", "story-01"]))
}

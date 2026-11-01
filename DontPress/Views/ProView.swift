import SwiftUI

/// Optional one-time purchase that unlocks every button style immediately.
/// Shown only when the user taps a locked style or the Pro row; never automatically.
struct ProView: View {
    @Bindable var proStore: ProStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.l) {
                    HStack(spacing: DS.Spacing.m) {
                        ForEach(ButtonTheme.all) { theme in
                            theme.swatch.frame(width: 48, height: 48)
                        }
                    }
                    .accessibilityHidden(true)
                    .padding(.top, DS.Spacing.m)

                    Text("DON'T PRESS Pro")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(DS.Palette.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        point("The Egg and the Balloon toys")
                        point("All 5 button styles right away")
                        point("4 alternate app icons")
                        point("One-time purchase. No subscription")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if proStore.isPro {
                        Label("Pro is unlocked. Thank you!", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(DS.Palette.textPrimary)
                            .accessibilityIdentifier("proUnlocked")
                    } else {
                        buyButton
                    }

                    Button("Restore Purchases") { Task { await proStore.restore() } }
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                        .disabled(proStore.isBusy)
                        .accessibilityIdentifier("proRestore")

                    if let message = proStore.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(DS.Palette.textSecondary)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("proMessage")
                    }

                    HStack(spacing: DS.Spacing.l) {
                        Link("Privacy", destination: AppLinks.privacyPolicy).frame(minHeight: 44)
                        Link("Support", destination: AppLinks.support).frame(minHeight: 44)
                    }
                    .font(.footnote)
                    .foregroundStyle(DS.Palette.textSecondary)
                }
                .padding(.horizontal, DS.Spacing.l)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .background(DS.Palette.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("proClose")
                }
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("proSheet")
    }

    private var buyButton: some View {
        Button {
            Task { await proStore.purchase() }
        } label: {
            Group {
                if proStore.isBusy {
                    ProgressView().tint(.white)
                } else if let product = proStore.product {
                    Text("Unlock Pro · \(product.displayPrice)")
                } else {
                    Text("Pro isn't available right now")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(DS.Palette.buttonRed)
        .disabled(proStore.product == nil || proStore.isBusy)
        .accessibilityIdentifier("proBuy")
    }

    private func point(_ text: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.s) {
            Image(systemName: "checkmark")
                .font(.footnote.weight(.bold))
                .foregroundStyle(DS.Palette.highlight)
                .padding(.top, 3)
                .accessibilityHidden(true)
            Text(text)
                .font(.body)
                .foregroundStyle(DS.Palette.textPrimary)
        }
    }
}

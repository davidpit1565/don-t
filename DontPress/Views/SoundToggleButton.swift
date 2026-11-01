import SwiftUI

/// Compact mute/unmute control for the header. 44pt touch target, icon plus a spoken
/// state, so it never relies on the icon alone.
struct SoundToggleButton: View {
    let model: HomeViewModel

    var body: some View {
        Button {
            model.setSoundEnabled(!model.isSoundEnabled)
        } label: {
            Image(systemName: model.isSoundEnabled ? "speaker.wave.2" : "speaker.slash")
                .font(.body.weight(.semibold))
                .foregroundStyle(DS.Palette.textSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Sound effects")
        .accessibilityValue(model.isSoundEnabled ? "On" : "Off")
        .accessibilityHint("Double-tap to turn sound effects \(model.isSoundEnabled ? "off" : "on").")
        .accessibilityIdentifier("soundToggle")
    }
}

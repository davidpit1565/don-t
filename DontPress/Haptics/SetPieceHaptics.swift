import UIKit

/// Plays a set-piece's haptic plan (`HapticCue.Kind`) with native generators.
/// Driven only from the set-piece timeline task, never from view redraws or animation callbacks.
/// Optional polish: if a generator cannot play, nothing else is affected.
@MainActor
final class SetPieceHaptics {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    init() { prepare() }

    func prepare() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notification.prepare()
    }

    func play(_ kind: HapticCue.Kind) {
        switch kind {
        case .light:
            light.impactOccurred()
            light.prepare()
        case .medium:
            medium.impactOccurred()
            medium.prepare()
        case .heavy:
            heavy.impactOccurred(intensity: 1.0)
            heavy.prepare()
        case .success:
            notification.notificationOccurred(.success)
            notification.prepare()
        case .warning:
            notification.notificationOccurred(.warning)
            notification.prepare()
        }
    }
}

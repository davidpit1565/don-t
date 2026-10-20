import UIKit

/// Native haptics. Generators are prepared ahead of time and re-prepared after use.
/// Called only from the press action, never from view redraws or animation callbacks.
@MainActor
final class UIKitHaptics: HapticFeedback {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let strong = UIImpactFeedbackGenerator(style: .rigid)

    func prepare() {
        light.prepare()
        strong.prepare()
    }

    func press() {
        light.impactOccurred()
        light.prepare()
    }

    func milestone() {
        strong.impactOccurred(intensity: 0.9)
        strong.prepare()
    }
}

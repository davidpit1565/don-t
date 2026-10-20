import Foundation

/// Haptics are optional polish; nothing depends on them for correctness.
@MainActor
protocol HapticFeedback: AnyObject {
    func prepare()
    func press()
    func milestone()
}

final class NoHaptics: HapticFeedback {
    func prepare() {}
    func press() {}
    func milestone() {}
}

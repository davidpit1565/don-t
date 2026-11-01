import Foundation

/// Who may hang the piñata. Self-contained on purpose: the piñata is the "mythic" toy and
/// needs BOTH Pro and a lot of play. A Pro owner still has to earn it; a free player never gets it.
enum PinataGate {
    /// Total presses (across all runs, on this device) needed on top of Pro.
    static let minTotalPresses = 5_000

    static func isUnlocked(totalPresses: Int, isPro: Bool) -> Bool {
        isPro && totalPresses >= minTotalPresses
    }

    /// 0...1 progress of the play half of the gate (Pro is separate: see `isUnlocked`).
    static func progress(totalPresses: Int) -> Double {
        guard totalPresses > 0 else { return 0 }
        return min(1, Double(totalPresses) / Double(minTotalPresses))
    }

    /// True on the press that crossed the threshold while Pro is owned (shows an unlock banner once).
    static func newlyUnlocked(before: Int, after: Int, isPro: Bool) -> Bool {
        isPro && before < minTotalPresses && after >= minTotalPresses
    }

    /// Picker caption while locked, e.g. "1,200/5,000 · Pro". Presses are clamped to the threshold
    /// so a Pro-less player with 9,000 presses reads "5,000/5,000 · Pro".
    static func progressText(totalPresses: Int, isPro: Bool, locale: Locale = .current) -> String {
        let shown = min(max(totalPresses, 0), minTotalPresses)
        let count = "\(format(shown, locale: locale))/\(format(minTotalPresses, locale: locale))"
        return isPro ? count : "\(count) · Pro"
    }

    private static func format(_ value: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

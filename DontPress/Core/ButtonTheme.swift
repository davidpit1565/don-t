import Foundation

/// Colour set for the big button. Colours are plain hex so Core stays UI-free.
struct ButtonTheme: Equatable, Identifiable {
    let id: String
    let name: String
    let rule: UnlockRule
    let highlightHex: UInt32
    let baseHex: UInt32
    let darkHex: UInt32
    let labelHex: UInt32

    static let classic = ButtonTheme(id: "classic", name: "Classic Red", rule: .always,
                                     highlightHex: 0xFF6877, baseHex: 0xFF3347, darkHex: 0xC71930, labelHex: 0xFFFFFF)
    static let cobalt = ButtonTheme(id: "cobalt", name: "Blue Mistake", rule: .bestRun(10),
                                    highlightHex: 0x7DB1FF, baseHex: 0x2F6BFF, darkHex: 0x1B3FB0, labelHex: 0xFFFFFF)
    static let stealth = ButtonTheme(id: "stealth", name: "Stealth", rule: .bestRun(50),
                                     highlightHex: 0x9A9AA6, baseHex: 0x55555F, darkHex: 0x2C2C33, labelHex: 0xFFFFFF)
    static let gold = ButtonTheme(id: "gold", name: "Gold Standard", rule: .totalPresses(500),
                                  highlightHex: 0xFFDB78, baseHex: 0xF2A900, darkHex: 0xB07400, labelHex: 0x2A1D00)
    static let radioactive = ButtonTheme(id: "radioactive", name: "Radioactive", rule: .bestRun(250),
                                         highlightHex: 0xA6FF94, baseHex: 0x2ED65A, darkHex: 0x138A33, labelHex: 0x04210C)

    static let all: [ButtonTheme] = [.classic, .cobalt, .stealth, .radioactive, .gold]

    static func theme(id: String) -> ButtonTheme? { all.first { $0.id == id } }

    func isUnlocked(for stats: PressStats) -> Bool { rule.isMet(by: stats) }

    /// Stored choice if it still exists and is unlocked, otherwise Classic.
    static func resolve(id: String?, stats: PressStats) -> ButtonTheme {
        guard let id, let theme = theme(id: id), theme.isUnlocked(for: stats) else { return .classic }
        return theme
    }

    static func newlyUnlocked(before: PressStats, after: PressStats) -> [ButtonTheme] {
        all.filter { $0.rule.isMet(by: after) && !$0.rule.isMet(by: before) }
    }
}

struct ThemeStatus: Identifiable, Equatable {
    let theme: ButtonTheme
    let isUnlocked: Bool
    let isSelected: Bool
    var id: String { theme.id }
}

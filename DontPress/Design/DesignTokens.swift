import SwiftUI

enum DS {
    enum Palette {
        static let background = Color(hex: 0x0B0B0D)
        static let surface = Color(hex: 0x17171B)
        static let textPrimary = Color(hex: 0xF7F7F8)
        static let textSecondary = Color(hex: 0x96969F)
        static let buttonRed = Color(hex: 0xFF3347)
        static let darkRed = Color(hex: 0xC71930)
        static let highlight = Color(hex: 0xFF6877)
        static let border = Color(hex: 0x29292F)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Motion {
        /// Quick, natural spring for the button; no exaggerated bounce.
        static let pressSpring = Animation.spring(response: 0.22, dampingFraction: 0.78)
        /// Reduce Motion replacement: short fade-like change, no spring.
        static let reduced = Animation.easeOut(duration: 0.08)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

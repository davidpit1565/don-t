import SwiftUI

extension ButtonTheme {
    var highlight: Color { Color(hex: highlightHex) }
    var base: Color { Color(hex: baseHex) }
    var dark: Color { Color(hex: darkHex) }
    var label: Color { Color(hex: labelHex) }

    /// Flat circle used as a swatch in the collection list.
    var swatch: some View {
        Circle()
            .fill(LinearGradient(colors: [highlight, base, dark], startPoint: .top, endPoint: .bottom))
            .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1))
    }
}

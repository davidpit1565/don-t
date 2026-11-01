import SwiftUI
import UIKit

enum ShareImageRenderer {
    /// Renders the personal-best card to an opaque UIImage. Returns nil on failure.
    @MainActor
    static func render(_ content: ShareCardContent) -> UIImage? {
        renderCard(ShareCardView(content: content))
    }

    /// Renders the no-spoiler daily challenge card. Returns nil on failure.
    @MainActor
    static func render(_ content: DailyShareContent) -> UIImage? {
        renderCard(DailyShareCardView(content: content))
    }

    @MainActor
    private static func renderCard<Card: View>(_ card: Card) -> UIImage? {
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1                          // cards are already 1080×1350
        renderer.isOpaque = true
        guard let image = renderer.uiImage, image.size.width > 0, image.size.height > 0 else { return nil }
        return image
    }
}

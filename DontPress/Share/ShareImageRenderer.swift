import SwiftUI
import UIKit

enum ShareImageRenderer {
    /// Renders the share card to an opaque UIImage. Returns nil on failure.
    @MainActor
    static func render(_ content: ShareCardContent) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(content: content))
        renderer.scale = 1                          // card is already 1080×1350
        renderer.isOpaque = true
        guard let image = renderer.uiImage, image.size.width > 0, image.size.height > 0 else { return nil }
        return image
    }
}

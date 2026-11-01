import SwiftUI
import UIKit
import LinkPresentation

/// Presents the native share sheet with an actual image.
enum SharePresenter {
    @MainActor
    @discardableResult
    static func present(image: UIImage, title: String = "DON'T PRESS: my personal best", onFinish: @escaping () -> Void) -> Bool {
        guard let presenter = topViewController() else { return false }
        let controller = UIActivityViewController(activityItems: [ShareItem(image: image, title: title)], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onFinish()   // fires for both completion and cancellation
        }
        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.maxY - 60, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        presenter.present(controller, animated: true)
        return true
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

/// Supplies the image itself (not text) to the share sheet.
private final class ShareItem: NSObject, UIActivityItemSource {
    let image: UIImage
    let title: String

    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any { image }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? { image }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String { "DON'T PRESS" }
}

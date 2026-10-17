#if os(iOS)
import StoreKit
import SwiftUI

/// Presents the App Store page of an app inside the host app while `appID` is not `nil`.
struct StoreProductPresenter: UIViewControllerRepresentable {
    @Binding var appID: Int?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        context.coordinator.onFinish = { appID = nil }

        guard let appID, viewController.presentedViewController == nil else { return }

        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = context.coordinator
        storeViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: appID])
        viewController.present(storeViewController, animated: true)
        storeViewController.presentationController?.delegate = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator: NSObject, @MainActor SKStoreProductViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
        var onFinish: () -> Void = {}

        /// Called when the user taps the close button of the App Store page.
        func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true)
            onFinish()
        }

        /// Called when the user swipes down the App Store page, which doesn't call `productViewControllerDidFinish`.
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            onFinish()
        }
    }
}
#endif

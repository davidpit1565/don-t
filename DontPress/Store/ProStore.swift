import StoreKit
import SwiftUI

/// StoreKit 2 wrapper for the single non-consumable "Pro" purchase.
/// Entitlements always come from StoreKit; the app only caches the last known value.
@MainActor
@Observable
final class ProStore {
    static let productID = "com.davidpitchkhadze.dontpress.pro"

    private(set) var product: Product?
    private(set) var isPro: Bool
    private(set) var isBusy = false
    /// Short, user-facing outcome of the last purchase/restore attempt.
    private(set) var message: String?

    /// Called whenever the entitlement changes (including at launch).
    @ObservationIgnored var onChange: ((Bool) -> Void)?
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init(cachedIsPro: Bool) {
        self.isPro = cachedIsPro
    }

    /// Starts listening for transaction updates and loads the product + current entitlement.
    func start() async {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await update in Transaction.updates {
                    await self?.handle(update)
                }
            }
        }
        await refreshEntitlement()
        await loadProduct()
    }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            product = nil
        }
    }

    func purchase() async {
        guard let product, !isBusy else { return }
        isBusy = true
        message = nil
        defer { isBusy = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                await handle(verification)
                if !isPro { message = "The purchase couldn't be verified." }
            case .userCancelled:
                break
            case .pending:
                message = "Your purchase is waiting for approval."
            @unknown default:
                break
            }
        } catch {
            message = "The purchase couldn't be completed. You were not charged."
        }
    }

    func restore() async {
        guard !isBusy else { return }
        isBusy = true
        message = nil
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            message = isPro ? nil : "No previous Pro purchase was found for this Apple ID."
        } catch {
            message = "Restore didn't work. Check your connection and try again."
        }
    }

    // MARK: Private

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result, transaction.productID == Self.productID else { return }
        await transaction.finish()
        await refreshEntitlement()
    }

    private func refreshEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        setPro(owned)
    }

    private func setPro(_ value: Bool) {
        isPro = value
        onChange?(value)
    }
}

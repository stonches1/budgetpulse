//
//  SubscriptionManager.swift
//  BudgetPulse
//

import Foundation
import StoreKit

@MainActor
@Observable
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    // Product IDs - these must match App Store Connect
    static let monthlyProductID = "com.budgetpulse.premium.monthly"
    static let yearlyProductID = "com.budgetpulse.premium.yearly"

    private let premiumKey = "isPremiumUser"
    private let subscriptionExpiryKey = "subscriptionExpiry"

    var isPremium: Bool {
        didSet {
            UserDefaults.standard.set(isPremium, forKey: premiumKey)
        }
    }

    var products: [Product] = []
    var purchaseInProgress = false
    var showingPaywall = false

    // Feature limits for free users
    let maxFreeSavingsGoals = 2

    private init() {
        self.isPremium = UserDefaults.standard.bool(forKey: premiumKey)

        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }

    // MARK: - Product Loading

    func loadProducts() async {
        do {
            let productIDs = [Self.monthlyProductID, Self.yearlyProductID]
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    isPremium = true
                    return true
                case .unverified:
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            return isPremium
        } catch {
            print("Restore failed: \(error)")
            return false
        }
    }

    // MARK: - Subscription Status

    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == Self.monthlyProductID ||
                   transaction.productID == Self.yearlyProductID {
                    isPremium = true
                    return
                }
            case .unverified:
                continue
            }
        }

        // No valid subscription found
        isPremium = false
    }

    // MARK: - Feature Access

    var canAccessReports: Bool {
        isPremium
    }

    var canAccessReceipts: Bool {
        isPremium
    }

    var canAccessCategoryBudgets: Bool {
        isPremium
    }

    var canExportData: Bool {
        isPremium
    }

    var canAccessSubscriptionTracker: Bool {
        isPremium
    }

    var canAccessBudgetRollover: Bool {
        isPremium
    }

    func canAddMoreSavingsGoals(currentCount: Int) -> Bool {
        isPremium || currentCount < maxFreeSavingsGoals
    }

    // MARK: - Helpers

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductID }
    }

    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }
}

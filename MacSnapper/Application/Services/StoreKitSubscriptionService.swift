import Foundation
import StoreKit
import Combine

/// Real StoreKit 2 implementation for App Store subscriptions
/// This replaces the simulated subscription service with actual payment processing
@available(macOS 12.0, *)
public final class StoreKitSubscriptionService: ObservableObject {

    // MARK: - Product IDs (configure these in App Store Connect)

    public enum ProductID: String, CaseIterable {
        case monthlyPremium = "com.nicksoftware.macsnapper.premium.monthly"
        case annualPremium = "com.nicksoftware.macsnapper.premium.annual"

        var displayName: String {
            switch self {
            case .monthlyPremium: return "Monthly Premium"
            case .annualPremium: return "Annual Premium"
            }
        }
    }

    // MARK: - Published Properties

    @Published public private(set) var availableProducts: [Product] = []
    @Published public private(set) var purchasedProducts: [Product] = []
    @Published public private(set) var subscriptionStatus: SubscriptionStatus = .free
    @Published public private(set) var isLoading = false
    @Published public private(set) var lastError: SubscriptionError?

    // MARK: - Properties

    private let logger = Logger(category: "StoreKitSubscriptionService")
    private var updateListenerTask: Task<Void, Error>? = nil
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init() {
        startTransactionListener()
        loadProducts()
        checkSubscriptionStatus()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Interface

    /// Loads available products from App Store
    public func loadProducts() {
        Task {
            do {
                let products = try await Product.products(for: ProductID.allCases.map(\.rawValue))

                await MainActor.run {
                    self.availableProducts = products.sorted { $0.price < $1.price }
                    self.logger.info("Loaded \(products.count) products")
                }
            } catch {
                await MainActor.run {
                    self.lastError = .networkError
                    self.logger.error("Failed to load products: \(error)")
                }
            }
        }
    }

    /// Purchases a subscription product
    public func purchase(_ product: Product) async -> Bool {
        await MainActor.run {
            isLoading = true
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Deliver content and finish transaction
                await transaction.finish()
                await updateSubscriptionStatus()

                await MainActor.run {
                    self.isLoading = false
                }

                logger.info("Purchase successful: \(product.id)")
                return true

            case .userCancelled:
                await MainActor.run {
                    self.isLoading = false
                }
                logger.info("Purchase cancelled by user")
                return false

            case .pending:
                await MainActor.run {
                    self.isLoading = false
                }
                logger.info("Purchase pending approval")
                return false

            @unknown default:
                await MainActor.run {
                    self.lastError = .purchaseFailed("Unknown error")
                    self.isLoading = false
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.lastError = .purchaseFailed(error.localizedDescription)
                self.isLoading = false
            }
            logger.error("Purchase failed: \(error)")
            return false
        }
    }

    /// Restores previous purchases
    public func restorePurchases() async {
        await MainActor.run {
            isLoading = true
        }

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()

            await MainActor.run {
                self.isLoading = false
            }

            logger.info("Purchases restored successfully")
        } catch {
            await MainActor.run {
                self.lastError = .networkError
                self.isLoading = false
            }
            logger.error("Failed to restore purchases: \(error)")
        }
    }

    /// Checks if a specific feature is available
    public func isFeatureAvailable(_ feature: PremiumFeature) -> Bool {
        switch subscriptionStatus {
        case .free:
            return feature.isAvailableInFree
        case .trial, .premium:
            return true
        case .expired:
            return feature.isAvailableInFree
        }
    }

    /// Gets premium features list
    public func getPremiumFeatures() -> [PremiumFeature] {
        return PremiumFeature.allCases.filter { !$0.isAvailableInFree }
    }

    /// Clears any error state
    public func clearError() {
        lastError = nil
    }

    // MARK: - Private Methods

    private func startTransactionListener() {
        updateListenerTask = Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                } catch {
                    self.logger.error("Transaction update failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError(.failedVerification)
        case .verified(let transaction):
            return transaction
        }
    }

    private func updateSubscriptionStatus() async {
        var currentSubscriptions: [Product] = []

        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if let product = availableProducts.first(where: { $0.id == transaction.productID }) {
                    currentSubscriptions.append(product)
                }
            } catch {
                logger.error("Failed to verify transaction: \(error)")
            }
        }

        await MainActor.run {
            self.purchasedProducts = currentSubscriptions

            if !currentSubscriptions.isEmpty {
                // Has active subscription
                let expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
                self.subscriptionStatus = .premium(expiryDate: expiryDate)
            } else {
                // Check if trial is available (implement your trial logic here)
                if shouldShowTrial() {
                    self.subscriptionStatus = .free
                } else {
                    self.subscriptionStatus = .free
                }
            }
        }
    }

    private func checkSubscriptionStatus() {
        Task {
            await updateSubscriptionStatus()
        }
    }

    private func shouldShowTrial() -> Bool {
        // Implement trial logic based on your needs
        // For now, allowing trial for all free users
        return !UserDefaults.standard.bool(forKey: "MacSnapper.TrialUsed")
    }

    /// Starts a trial subscription (free trial implementation)
    public func startTrial() async {
        guard shouldShowTrial() else {
            await MainActor.run {
                self.lastError = .trialAlreadyUsed
            }
            return
        }

        await MainActor.run {
            isLoading = true
        }

        // Mark trial as used and activate for 7 days
        let expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        await MainActor.run {
            UserDefaults.standard.set(true, forKey: "MacSnapper.TrialUsed")
            UserDefaults.standard.set(expiryDate, forKey: "MacSnapper.TrialExpiry")
            self.subscriptionStatus = .trial(expiryDate: expiryDate)
            self.isLoading = false
        }

        logger.info("Trial subscription activated until \(expiryDate)")

        // Set up trial expiry monitoring
        setupTrialMonitoring(expiryDate: expiryDate)
    }

    private func setupTrialMonitoring(expiryDate: Date) {
        Timer.publish(every: 3600, on: .main, in: .common) // Check every hour
            .autoconnect()
            .sink { [weak self] _ in
                if Date() > expiryDate {
                    Task {
                        await MainActor.run {
                            self?.subscriptionStatus = .expired(previousExpiry: expiryDate)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types (reuse existing ones)

// The SubscriptionStatus, PremiumFeature, and SubscriptionError enums
// remain the same as they are in the original SubscriptionService.swift

// MARK: - Logger

private struct Logger {
    let category: String

    func debug(_ message: String) {
        print("🔍 [\(category)] \(message)")
    }

    func info(_ message: String) {
        print("ℹ️ [\(category)] \(message)")
    }

    func warning(_ message: String) {
        print("⚠️ [\(category)] \(message)")
    }

    func error(_ message: String) {
        print("❌ [\(category)] \(message)")
    }
}
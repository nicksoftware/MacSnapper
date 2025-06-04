import Foundation
import Combine

/// Subscription service adapter that can switch between simulated and real implementations
/// This allows for easy testing and development with the simulated service,
/// while using the real StoreKit service for production builds
public final class SubscriptionServiceAdapter: ObservableObject {

    // MARK: - Configuration

    /// Set this to true to use real StoreKit, false for simulated service
    /// In production, this should always be true
    public static let useRealStoreKit: Bool = {
        #if DEBUG
        // Use simulated service in debug builds for easier testing
        return UserDefaults.standard.bool(forKey: "MacSnapper.UseRealStoreKit")
        #else
        // Always use real StoreKit in release builds
        return true
        #endif
    }()

    // MARK: - Published Properties

    @Published public private(set) var subscriptionStatus: SubscriptionStatus = .free
    @Published public private(set) var isLoading = false
    @Published public private(set) var lastError: SubscriptionError?

    // MARK: - Properties

    private let simulatedService: SubscriptionService
    private var storeKitService: AnyObject?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(category: "SubscriptionServiceAdapter")

    // MARK: - Initialization

    public init() {
        // Always create the simulated service for fallback
        self.simulatedService = SubscriptionService()

        // Create StoreKit service only if available and configured
        if Self.useRealStoreKit {
            if #available(macOS 12.0, *) {
                self.storeKitService = StoreKitSubscriptionService()
                setupStoreKitBindings()
                logger.info("Using real StoreKit subscription service")
            } else {
                logger.warning("StoreKit 2 not available, falling back to simulated service")
                setupSimulatedBindings()
            }
        } else {
            setupSimulatedBindings()
            logger.info("Using simulated subscription service")
        }
    }

    // MARK: - Public Interface

    /// Checks if a specific feature is available
    public func isFeatureAvailable(_ feature: PremiumFeature) -> Bool {
        if Self.useRealStoreKit, #available(macOS 12.0, *),
           let storeKit = storeKitService as? StoreKitSubscriptionService {
            return storeKit.isFeatureAvailable(feature)
        } else {
            return simulatedService.isFeatureAvailable(feature)
        }
    }

    /// Starts a trial subscription
    public func startTrial() async {
        if Self.useRealStoreKit, #available(macOS 12.0, *),
           let storeKit = storeKitService as? StoreKitSubscriptionService {
            await storeKit.startTrial()
        } else {
            await simulatedService.startTrial()
        }
    }

    /// Activates premium subscription (simulated service only)
    public func activatePremium() async {
        // This method is only for the simulated service
        // Real purchases go through the StoreKit purchase flow
        if !Self.useRealStoreKit {
            await simulatedService.activatePremium()
        }
    }

    /// Restores previous purchases
    public func restorePurchase() async {
        if Self.useRealStoreKit, #available(macOS 12.0, *),
           let storeKit = storeKitService as? StoreKitSubscriptionService {
            await storeKit.restorePurchases()
        } else {
            await simulatedService.restorePurchase()
        }
    }

    /// Gets premium features list
    public func getPremiumFeatures() -> [PremiumFeature] {
        if Self.useRealStoreKit, #available(macOS 12.0, *),
           let storeKit = storeKitService as? StoreKitSubscriptionService {
            return storeKit.getPremiumFeatures()
        } else {
            return simulatedService.getPremiumFeatures()
        }
    }

    /// Clears any error state
    public func clearError() {
        if Self.useRealStoreKit, #available(macOS 12.0, *),
           let storeKit = storeKitService as? StoreKitSubscriptionService {
            storeKit.clearError()
        } else {
            simulatedService.clearError()
        }
    }

    /// Gets the underlying StoreKit service for direct access (when needed)
    @available(macOS 12.0, *)
    public var storeKitSubscriptionService: StoreKitSubscriptionService? {
        return storeKitService as? StoreKitSubscriptionService
    }

    // MARK: - Private Methods

    private func setupSimulatedBindings() {
        simulatedService.$subscriptionStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$subscriptionStatus)

        simulatedService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        simulatedService.$lastError
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastError)
    }

    @available(macOS 12.0, *)
    private func setupStoreKitBindings() {
        guard let storeKit = storeKitService as? StoreKitSubscriptionService else { return }

        storeKit.$subscriptionStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$subscriptionStatus)

        storeKit.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        storeKit.$lastError
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastError)
    }
}

// MARK: - Debug Configuration

#if DEBUG
extension SubscriptionServiceAdapter {

    /// Switches to real StoreKit for testing (debug builds only)
    public static func enableRealStoreKit() {
        UserDefaults.standard.set(true, forKey: "MacSnapper.UseRealStoreKit")
    }

    /// Switches to simulated service for testing (debug builds only)
    public static func enableSimulatedService() {
        UserDefaults.standard.set(false, forKey: "MacSnapper.UseRealStoreKit")
    }
}
#endif

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
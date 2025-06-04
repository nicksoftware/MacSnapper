import Foundation
import Combine

/// Subscription service for managing premium features and licensing
/// Implements freemium model with subscription-based premium features
public final class SubscriptionService: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var subscriptionStatus: SubscriptionStatus = .free
    @Published public private(set) var isLoading = false
    @Published public private(set) var lastError: SubscriptionError?

    // MARK: - Properties

    private let logger = Logger(category: "SubscriptionService")
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    // Keys for UserDefaults
    private let subscriptionStatusKey = "MacSnapper.SubscriptionStatus"
    private let subscriptionExpiryKey = "MacSnapper.SubscriptionExpiry"
    private let trialUsedKey = "MacSnapper.TrialUsed"

    // MARK: - Initialization

    public init() {
        loadSubscriptionStatus()
        setupAutoValidation()
    }

    // MARK: - Public Interface

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

    /// Starts a trial subscription (7 days)
    public func startTrial() async {
        logger.info("Starting trial subscription")

        guard !hasUsedTrial else {
            await MainActor.run {
                self.lastError = .trialAlreadyUsed
            }
            return
        }

        await MainActor.run {
            isLoading = true
        }

        // Simulate trial activation
        await Task.sleep(1_000_000_000) // 1 second delay

        let expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        await MainActor.run {
            self.subscriptionStatus = .trial(expiryDate: expiryDate)
            self.userDefaults.set(true, forKey: self.trialUsedKey)
            self.userDefaults.set(expiryDate, forKey: self.subscriptionExpiryKey)
            self.saveSubscriptionStatus()
            self.isLoading = false
        }

        logger.info("Trial subscription activated until \(expiryDate)")
    }

    /// Activates premium subscription
    public func activatePremium() async {
        logger.info("Activating premium subscription")

        await MainActor.run {
            isLoading = true
        }

        // In a real app, this would integrate with App Store Connect or other payment provider
        await Task.sleep(1_000_000_000) // 1 second delay

        let expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()

        await MainActor.run {
            self.subscriptionStatus = .premium(expiryDate: expiryDate)
            self.userDefaults.set(expiryDate, forKey: self.subscriptionExpiryKey)
            self.saveSubscriptionStatus()
            self.isLoading = false
        }

        logger.info("Premium subscription activated until \(expiryDate)")
    }

    /// Restores previous purchase
    public func restorePurchase() async {
        logger.info("Restoring purchase")

        await MainActor.run {
            isLoading = true
        }

        // Simulate restore process
        await Task.sleep(1_000_000_000)

        // In a real app, verify with payment provider
        if let expiryDate = userDefaults.object(forKey: subscriptionExpiryKey) as? Date,
           expiryDate > Date() {
            await MainActor.run {
                self.subscriptionStatus = .premium(expiryDate: expiryDate)
                self.saveSubscriptionStatus()
                self.isLoading = false
            }
            logger.info("Purchase restored successfully")
        } else {
            await MainActor.run {
                self.lastError = .noPurchaseToRestore
                self.isLoading = false
            }
            logger.warning("No valid purchase found to restore")
        }
    }

    /// Gets premium features list
    public func getPremiumFeatures() -> [PremiumFeature] {
        return PremiumFeature.allCases.filter { !$0.isAvailableInFree }
    }

    /// Validates current subscription status
    public func validateSubscription() async {
        logger.debug("Validating subscription status")

        switch subscriptionStatus {
        case .trial(let expiryDate), .premium(let expiryDate):
            if expiryDate <= Date() {
                await MainActor.run {
                    self.subscriptionStatus = .expired(previousExpiry: expiryDate)
                    self.saveSubscriptionStatus()
                }
                logger.info("Subscription expired on \(expiryDate)")
            }
        default:
            break
        }
    }

    /// Clears any error state
    public func clearError() {
        lastError = nil
    }
}

// MARK: - Private Methods

private extension SubscriptionService {

    func loadSubscriptionStatus() {
        guard let statusData = userDefaults.data(forKey: subscriptionStatusKey),
              let status = try? JSONDecoder().decode(SubscriptionStatus.self, from: statusData) else {
            subscriptionStatus = .free
            return
        }

        subscriptionStatus = status
        logger.debug("Loaded subscription status: \(status)")
    }

    func saveSubscriptionStatus() {
        guard let statusData = try? JSONEncoder().encode(subscriptionStatus) else {
            logger.error("Failed to encode subscription status")
            return
        }

        userDefaults.set(statusData, forKey: subscriptionStatusKey)
        logger.debug("Saved subscription status: \(subscriptionStatus)")
    }

    var hasUsedTrial: Bool {
        return userDefaults.bool(forKey: trialUsedKey)
    }

    func setupAutoValidation() {
        // Validate subscription every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.validateSubscription()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types

public enum SubscriptionStatus: Codable, Equatable {
    case free
    case trial(expiryDate: Date)
    case premium(expiryDate: Date)
    case expired(previousExpiry: Date)

    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .trial: return "Trial"
        case .premium: return "Premium"
        case .expired: return "Expired"
        }
    }

    public var isPremium: Bool {
        switch self {
        case .trial, .premium: return true
        case .free, .expired: return false
        }
    }
}

public enum PremiumFeature: String, CaseIterable, Codable {
    case customKeyboardShortcuts = "custom_keyboard_shortcuts"
    case advancedSnapping = "advanced_snapping"
    case multiMonitorSupport = "multi_monitor_support"
    case windowPresets = "window_presets"
    case excludedApplications = "excluded_applications"
    case advancedPositioning = "advanced_positioning"

    public var displayName: String {
        switch self {
        case .customKeyboardShortcuts: return "Custom Keyboard Shortcuts"
        case .advancedSnapping: return "Advanced Snapping (Thirds, Custom)"
        case .multiMonitorSupport: return "Multi-Monitor Support"
        case .windowPresets: return "Window Presets & Layouts"
        case .excludedApplications: return "Excluded Applications"
        case .advancedPositioning: return "Advanced Positioning"
        }
    }

    public var description: String {
        switch self {
        case .customKeyboardShortcuts:
            return "Customize all keyboard shortcuts to your preference"
        case .advancedSnapping:
            return "Access thirds, sixths, and custom snap positions"
        case .multiMonitorSupport:
            return "Intelligent window management across multiple displays"
        case .windowPresets:
            return "Save and restore custom window layouts"
        case .excludedApplications:
            return "Exclude specific apps from window management"
        case .advancedPositioning:
            return "Precise pixel-perfect window positioning"
        }
    }

    public var isAvailableInFree: Bool {
        switch self {
        case .customKeyboardShortcuts, .advancedSnapping, .multiMonitorSupport,
             .windowPresets, .excludedApplications, .advancedPositioning:
            return false
        }
    }
}

public enum SubscriptionError: LocalizedError, Equatable {
    case trialAlreadyUsed
    case purchaseFailed(String)
    case noPurchaseToRestore
    case networkError
    case invalidReceipt

    public var errorDescription: String? {
        switch self {
        case .trialAlreadyUsed:
            return "Trial already used. Please upgrade to Premium to continue."
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        case .noPurchaseToRestore:
            return "No previous purchase found to restore."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .invalidReceipt:
            return "Invalid receipt. Please contact support."
        }
    }
}

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
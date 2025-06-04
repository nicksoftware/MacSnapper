import Foundation

/// Dependency Injection Container that manages all application dependencies
/// This follows the Dependency Inversion Principle and makes the app testable
/// Uses the Service Locator pattern for dependency resolution
public final class DIContainer {

    // MARK: - Singleton

    public static let shared = DIContainer()

    // MARK: - Private Properties

    private var services: [String: Any] = [:]
    private let logger = Logger(category: "DIContainer")

    // MARK: - Initialization

    private init() {
        registerDefaultServices()
    }

    // MARK: - Registration

    /// Registers a service with the container
    /// - Parameters:
    ///   - type: The protocol or type to register
    ///   - service: The concrete implementation
    public func register<T>(_ type: T.Type, service: T) {
        let key = String(describing: type)
        services[key] = service
        logger.debug("Registered service: \(key)")
    }

    /// Registers a service with lazy initialization
    /// - Parameters:
    ///   - type: The protocol or type to register
    ///   - factory: Factory closure that creates the service
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        services[key] = factory
        logger.debug("Registered factory for service: \(key)")
    }

    // MARK: - Resolution

    /// Resolves a service from the container
    /// - Parameter type: The type to resolve
    /// - Returns: The resolved service instance
    /// - Throws: DIError if the service is not registered
    public func resolve<T>(_ type: T.Type) throws -> T {
        let key = String(describing: type)

        guard let service = services[key] else {
            logger.error("Service not registered: \(key)")
            throw DIError.serviceNotRegistered(key)
        }

        // If it's a factory closure, call it
        if let factory = service as? () -> T {
            let instance = factory()
            logger.debug("Created instance from factory: \(key)")
            return instance
        }

        // If it's already an instance, return it
        guard let instance = service as? T else {
            logger.error("Service type mismatch: \(key)")
            throw DIError.typeMismatch(key, String(describing: T.self))
        }

        logger.debug("Resolved service: \(key)")
        return instance
    }

    /// Resolves a service safely, returning nil if not found
    /// - Parameter type: The type to resolve
    /// - Returns: The resolved service instance or nil
    public func resolveSafely<T>(_ type: T.Type) -> T? {
        do {
            return try resolve(type)
        } catch {
            logger.warning("Failed to resolve service safely: \(String(describing: type))")
            return nil
        }
    }

    // MARK: - Lifecycle

    /// Clears all registered services (useful for testing)
    public func reset() {
        services.removeAll()
        logger.info("Container reset - all services cleared")
    }

    /// Re-registers default services after reset
    public func resetToDefaults() {
        reset()
        registerDefaultServices()
        logger.info("Container reset to defaults")
    }
}

// MARK: - Default Service Registration

private extension DIContainer {

    func registerDefaultServices() {
        logger.info("Registering default services")

        // Register concrete implementations
        let windowRepository = AccessibilityWindowRepository()
        register(WindowRepositoryProtocol.self, service: windowRepository)

        // Register subscription service
        let subscriptionService = SubscriptionService()
        register(SubscriptionService.self, service: subscriptionService)

        // Register global hotkey service
        let globalHotkeyService = GlobalHotkeyService()
        register(GlobalHotkeyService.self, service: globalHotkeyService)

        // Register screen service with dependency
        register(ScreenServiceProtocol.self) { [weak self] in
            guard let windowRepo = self?.resolveSafely(WindowRepositoryProtocol.self) else {
                fatalError("WindowRepositoryProtocol must be registered before ScreenServiceProtocol")
            }
            return ScreenService(windowRepository: windowRepo)
        }

        // Register use case with dependencies
        register(WindowManagementUseCase.self) { [weak self] in
            guard let windowRepo = self?.resolveSafely(WindowRepositoryProtocol.self),
                  let screenService = self?.resolveSafely(ScreenServiceProtocol.self) else {
                fatalError("Dependencies must be registered before WindowManagementUseCase")
            }
            return WindowManagementUseCase(
                windowRepository: windowRepo,
                screenService: screenService
            )
        }

        logger.info("Default services registered successfully")
    }
}

// MARK: - Errors

public enum DIError: LocalizedError, Equatable {
    case serviceNotRegistered(String)
    case typeMismatch(String, String)
    case circularDependency(String)

    public var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let serviceName):
            return "Service '\(serviceName)' is not registered in the DI container"
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: expected '\(expected)', got '\(actual)'"
        case .circularDependency(let serviceName):
            return "Circular dependency detected for service '\(serviceName)'"
        }
    }
}

// MARK: - Convenience Extensions

extension DIContainer {

    /// Convenience method to get the window management use case
    public var windowManagementUseCase: WindowManagementUseCase {
        do {
            return try resolve(WindowManagementUseCase.self)
        } catch {
            fatalError("WindowManagementUseCase not registered: \(error)")
        }
    }

    /// Convenience method to get the window repository
    public var windowRepository: WindowRepositoryProtocol {
        do {
            return try resolve(WindowRepositoryProtocol.self)
        } catch {
            fatalError("WindowRepositoryProtocol not registered: \(error)")
        }
    }

    /// Convenience method to get the screen service
    public var screenService: ScreenServiceProtocol {
        do {
            return try resolve(ScreenServiceProtocol.self)
        } catch {
            fatalError("ScreenServiceProtocol not registered: \(error)")
        }
    }

    /// Convenience method to get the subscription service
    public var subscriptionService: SubscriptionService {
        do {
            return try resolve(SubscriptionService.self)
        } catch {
            fatalError("SubscriptionService not registered: \(error)")
        }
    }

    /// Convenience method to get the global hotkey service
    public var globalHotkeyService: GlobalHotkeyService {
        do {
            return try resolve(GlobalHotkeyService.self)
        } catch {
            fatalError("GlobalHotkeyService not registered: \(error)")
        }
    }
}

// MARK: - Testing Support

#if DEBUG
extension DIContainer {

    /// Registers mock services for testing
    /// This allows us to inject test doubles during unit testing
    public func registerMockServices() {
        logger.info("Registering mock services for testing")

        // In a real implementation, you would register mock implementations here
        // Example:
        // register(WindowRepositoryProtocol.self, service: MockWindowRepository())

        logger.info("Mock services registered")
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
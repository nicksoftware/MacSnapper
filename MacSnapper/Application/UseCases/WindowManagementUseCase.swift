import Foundation
import Combine
import AppKit

/// Primary use case for window management operations
/// This orchestrates all window-related business logic and coordinates between different services
/// Follows the Single Responsibility Principle by focusing solely on window management orchestration
public final class WindowManagementUseCase: ObservableObject {

    // MARK: - Dependencies

    private let windowRepository: WindowRepositoryProtocol
    private let screenService: ScreenServiceProtocol
    private let logger = Logger(category: "WindowManagementUseCase")

    // MARK: - Published Properties

    @Published public private(set) var availableWindows: [WindowInfo] = []
    @Published public private(set) var focusedWindow: WindowInfo?
    @Published public private(set) var isLoading = false
    @Published public private(set) var hasAccessibilityPermissions = false
    @Published public private(set) var lastError: WindowRepositoryError?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        windowRepository: WindowRepositoryProtocol,
        screenService: ScreenServiceProtocol
    ) {
        self.windowRepository = windowRepository
        self.screenService = screenService

        setupBindings()
        checkPermissions()
    }

    // MARK: - Public Interface

    /// Refreshes the list of available windows
    public func refreshWindows() async {
        logger.info("Refreshing windows list")

        await MainActor.run {
            isLoading = true
            lastError = nil
        }

        do {
            let windows = try await windowRepository.getAllWindows()
            await MainActor.run {
                self.availableWindows = windows
                self.isLoading = false
            }
            logger.info("Successfully refreshed \(windows.count) windows")
        } catch let error as WindowRepositoryError {
            await MainActor.run {
                self.lastError = error
                self.isLoading = false
            }
            logger.error("Failed to refresh windows: \(error.localizedDescription)")
        } catch {
            await MainActor.run {
                self.lastError = .systemError(error.localizedDescription)
                self.isLoading = false
            }
            logger.error("Unexpected error refreshing windows: \(error)")
        }
    }

    /// Performs a snap action on the specified window
    /// - Parameters:
    ///   - window: The window to snap
    ///   - snapType: The type of snap operation to perform
    public func snapWindow(_ window: WindowInfo, to snapType: SnapType) async {
        logger.info("Snapping window '\(window.applicationName)' to \(snapType.displayName)")

        guard hasAccessibilityPermissions else {
            await MainActor.run {
                self.lastError = .accessibilityPermissionsDenied
            }
            logger.error("Cannot snap window - accessibility permissions required")
            return
        }

        do {
            // Get the screen info for the window
            let screenInfo = try await screenService.getScreenContaining(point: window.center)

            // Create the snap action
            let snapAction = SnapAction.create(
                type: snapType,
                screenBounds: screenInfo.visibleFrame
            )

            // Perform the snap
            try await windowRepository.setWindowFrame(window, frame: snapAction.targetFrame)

            logger.info("Successfully snapped window to \(snapType.displayName)")

            // Note: Removed expensive refreshWindows() call for better performance
            // Window updates will be detected by the background monitoring

        } catch let error as WindowRepositoryError {
            await MainActor.run {
                self.lastError = error
            }
            logger.error("Failed to snap window: \(error.localizedDescription)")
        } catch {
            await MainActor.run {
                self.lastError = .systemError(error.localizedDescription)
            }
            logger.error("Unexpected error snapping window: \(error)")
        }
    }

    /// Snaps the currently focused window to the specified position
    /// This is called by global hotkeys to snap the active window
    public func snapFocusedWindow(to snapType: SnapType) async {
        logger.info("Snapping focused window to \(snapType.displayName)")

        guard hasAccessibilityPermissions else {
            logger.warning("Cannot snap focused window: missing accessibility permissions")
            return
        }

        do {
            // Get the focused window directly (fast path - no scanning all windows)
            guard let focusedWindow = try await windowRepository.getFocusedWindow() else {
                logger.warning("No focused window found")
                return
            }

            logger.info("Found focused window: \(focusedWindow.windowTitle) in \(focusedWindow.applicationName)")

            // Get the screen info for the window (fast operation)
            let screenInfo = try await screenService.getScreenContaining(point: focusedWindow.center)

            // Create the snap action
            let snapAction = SnapAction.create(
                type: snapType,
                screenBounds: screenInfo.visibleFrame
            )

            // Perform the snap directly (no refresh after)
            try await windowRepository.setWindowFrame(focusedWindow, frame: snapAction.targetFrame)

            logger.info("Successfully snapped focused window to \(snapType.displayName)")

        } catch {
            logger.error("Failed to snap focused window: \(error)")
            await MainActor.run {
                self.lastError = .systemError("Failed to snap focused window: \(error.localizedDescription)")
            }
        }
    }

    /// Requests accessibility permissions from the system
    public func requestAccessibilityPermissions() async {
        logger.info("Requesting accessibility permissions")

        do {
            try await windowRepository.requestAccessibilityPermissions()
            await MainActor.run {
                self.hasAccessibilityPermissions = true
                self.lastError = nil
            }
            logger.info("Accessibility permissions granted")

            // Start monitoring after permissions are granted
            await refreshWindows()
        } catch let error as WindowRepositoryError {
            await MainActor.run {
                self.lastError = error
            }
            logger.error("Failed to get accessibility permissions: \(error.localizedDescription)")
        } catch {
            await MainActor.run {
                self.lastError = .systemError(error.localizedDescription)
            }
            logger.error("Unexpected error requesting permissions: \(error)")
        }
    }

    /// Gets all available snap actions for the current screen configuration
    /// - Returns: Array of available snap actions
    public func getAvailableSnapActions() async -> [SnapAction] {
        do {
            let screens = try await screenService.getAllScreens()
            guard let primaryScreen = screens.first(where: { $0.isPrimary }) else {
                logger.warning("No primary screen found")
                return []
            }

            return SnapType.allCases.map { snapType in
                SnapAction.create(
                    type: snapType,
                    screenBounds: primaryScreen.visibleFrame,
                    keyboardShortcut: getDefaultKeyboardShortcut(for: snapType)
                )
            }
        } catch {
            logger.error("Failed to get available snap actions: \(error)")
            return []
        }
    }

    /// Clears the last error
    public func clearError() {
        lastError = nil
    }
}

// MARK: - Private Methods

private extension WindowManagementUseCase {

    func setupBindings() {
        // Subscribe to window updates
        windowRepository.windowUpdates
            .receive(on: DispatchQueue.main)
            .assign(to: \.availableWindows, on: self)
            .store(in: &cancellables)

        // Subscribe to focused window updates
        windowRepository.focusedWindowUpdates
            .receive(on: DispatchQueue.main)
            .assign(to: \.focusedWindow, on: self)
            .store(in: &cancellables)
    }

    func checkPermissions() {
        Task { @MainActor in
            hasAccessibilityPermissions = windowRepository.hasAccessibilityPermissions()
            logger.info("Accessibility permissions status: \(hasAccessibilityPermissions)")
        }
    }

    func getDefaultKeyboardShortcut(for snapType: SnapType) -> KeyboardShortcut? {
        // Define default keyboard shortcuts similar to Rectangle
        switch snapType {
        case .leftHalf:
            return KeyboardShortcut(modifiers: [.command, .option], key: KeyEquivalent("←"))
        case .rightHalf:
            return KeyboardShortcut(modifiers: [.command, .option], key: KeyEquivalent("→"))
        case .topHalf:
            return KeyboardShortcut(modifiers: [.command, .option], key: KeyEquivalent("↑"))
        case .bottomHalf:
            return KeyboardShortcut(modifiers: [.command, .option], key: KeyEquivalent("↓"))
        case .maximize:
            return KeyboardShortcut(modifiers: [.command, .option], key: KeyEquivalent("f"))
        case .center:
            return KeyboardShortcut(modifiers: [.command, .option], key: KeyEquivalent("c"))
        default:
            return nil
        }
    }
}

// MARK: - Supporting Protocol

/// Protocol for screen-related operations
/// This allows us to mock screen operations for testing
public protocol ScreenServiceProtocol {
    func getAllScreens() async throws -> [ScreenInfo]
    func getScreenContaining(point: CGPoint) async throws -> ScreenInfo
    func getPrimaryScreen() async throws -> ScreenInfo
}

// MARK: - Screen Service Implementation

public final class ScreenService: ScreenServiceProtocol {

    private let windowRepository: WindowRepositoryProtocol
    private let logger = Logger(category: "ScreenService")

    public init(windowRepository: WindowRepositoryProtocol) {
        self.windowRepository = windowRepository
    }

    public func getAllScreens() async throws -> [ScreenInfo] {
        return try await windowRepository.getScreenInfo()
    }

    public func getScreenContaining(point: CGPoint) async throws -> ScreenInfo {
        let screens = try await getAllScreens()

        // Find screen that contains the point
        for screen in screens {
            if screen.frame.contains(point) {
                return screen
            }
        }

        // Fallback to primary screen
        return try await getPrimaryScreen()
    }

    public func getPrimaryScreen() async throws -> ScreenInfo {
        let screens = try await getAllScreens()

        guard let primaryScreen = screens.first(where: { $0.isPrimary }) else {
            throw WindowRepositoryError.systemError("No primary screen found")
        }

        return primaryScreen
    }
}

// MARK: - Logger (if not already defined elsewhere)

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
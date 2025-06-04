import Foundation
import Combine

/// Protocol defining the contract for window data access
/// This abstraction allows us to swap implementations and makes the code testable
/// Follows the Repository Pattern from DDD
public protocol WindowRepositoryProtocol {

    // MARK: - Window Discovery

    /// Retrieves all visible windows from the system
    /// - Returns: Array of WindowInfo objects representing current windows
    /// - Throws: WindowRepositoryError if accessibility permissions are not granted or other system errors occur
    func getAllWindows() async throws -> [WindowInfo]

    /// Retrieves windows for a specific application
    /// - Parameter applicationName: Name of the application to filter by
    /// - Returns: Array of WindowInfo objects for the specified application
    /// - Throws: WindowRepositoryError if operation fails
    func getWindows(for applicationName: String) async throws -> [WindowInfo]

    /// Gets the currently focused/active window
    /// - Returns: WindowInfo of the focused window, nil if no window is focused
    /// - Throws: WindowRepositoryError if operation fails
    func getFocusedWindow() async throws -> WindowInfo?

    /// Gets a specific window by its ID
    /// - Parameter windowId: Unique identifier for the window
    /// - Returns: WindowInfo if found, nil otherwise
    /// - Throws: WindowRepositoryError if operation fails
    func getWindow(by windowId: String) async throws -> WindowInfo?

    // MARK: - Window Manipulation

    /// Moves and resizes a window to the specified frame
    /// - Parameters:
    ///   - windowInfo: The window to manipulate
    ///   - frame: Target frame (position and size)
    /// - Throws: WindowRepositoryError if operation fails
    func setWindowFrame(_ windowInfo: WindowInfo, frame: CGRect) async throws

    /// Minimizes the specified window
    /// - Parameter windowInfo: The window to minimize
    /// - Throws: WindowRepositoryError if operation fails
    func minimizeWindow(_ windowInfo: WindowInfo) async throws

    /// Restores a minimized window
    /// - Parameter windowInfo: The window to restore
    /// - Throws: WindowRepositoryError if operation fails
    func restoreWindow(_ windowInfo: WindowInfo) async throws

    /// Brings a window to the front (focus)
    /// - Parameter windowInfo: The window to focus
    /// - Throws: WindowRepositoryError if operation fails
    func focusWindow(_ windowInfo: WindowInfo) async throws

    // MARK: - Real-time Updates

    /// Publisher that emits window state changes
    /// This allows the UI to react to external window changes
    var windowUpdates: AnyPublisher<[WindowInfo], Never> { get }

    /// Publisher that emits when the focused window changes
    var focusedWindowUpdates: AnyPublisher<WindowInfo?, Never> { get }

    // MARK: - System State

    /// Checks if the app has necessary accessibility permissions
    /// - Returns: True if permissions are granted
    func hasAccessibilityPermissions() -> Bool

    /// Requests accessibility permissions from the system
    /// This will prompt the user to grant permissions if not already granted
    func requestAccessibilityPermissions() async throws

    /// Gets information about all available screens/displays
    /// - Returns: Array of screen information including bounds and scaling
    func getScreenInfo() async throws -> [ScreenInfo]
}

// MARK: - Supporting Types

/// Represents display/screen information
public struct ScreenInfo: Identifiable, Equatable {
    public let id: String
    public let frame: CGRect
    public let visibleFrame: CGRect // Frame minus menu bar, dock, etc.
    public let scaleFactor: CGFloat
    public let isPrimary: Bool

    public init(
        id: String,
        frame: CGRect,
        visibleFrame: CGRect,
        scaleFactor: CGFloat = 1.0,
        isPrimary: Bool = false
    ) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.scaleFactor = scaleFactor
        self.isPrimary = isPrimary
    }
}

/// Errors that can occur in window repository operations
public enum WindowRepositoryError: LocalizedError, Equatable {
    case accessibilityPermissionsDenied
    case windowNotFound(String)
    case applicationNotFound(String)
    case systemError(String)
    case operationNotSupported(String)
    case invalidWindowState(String)

    public var errorDescription: String? {
        switch self {
        case .accessibilityPermissionsDenied:
            return "Accessibility permissions are required to manage windows. Please grant permissions in System Settings."
        case .windowNotFound(let windowId):
            return "Window with ID '\(windowId)' was not found."
        case .applicationNotFound(let appName):
            return "Application '\(appName)' was not found or is not running."
        case .systemError(let message):
            return "System error occurred: \(message)"
        case .operationNotSupported(let operation):
            return "Operation '\(operation)' is not supported on this window."
        case .invalidWindowState(let message):
            return "Invalid window state: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .accessibilityPermissionsDenied:
            return "Go to System Settings > Privacy & Security > Accessibility and enable MacSnapper."
        case .windowNotFound, .applicationNotFound:
            return "Try refreshing the window list or check if the application is still running."
        case .systemError:
            return "Try restarting the application or checking system logs for more details."
        case .operationNotSupported:
            return "This window may not support the requested operation."
        case .invalidWindowState:
            return "The window may have been closed or moved to another space."
        }
    }
}
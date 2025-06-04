import Foundation
import CoreGraphics

/// Core domain entity representing a window in the system
/// This is the central model that all other layers depend on
public struct WindowInfo: Identifiable, Equatable, Hashable {

    // MARK: - Properties

    public let id: String
    public let processID: pid_t
    public let applicationName: String
    public let windowTitle: String
    public let frame: CGRect
    public let isMinimized: Bool
    public let isVisible: Bool
    public let isOnScreen: Bool
    public let level: Int
    public let role: WindowRole
    public let subrole: WindowSubrole?

    // MARK: - Initialization

    public init(
        id: String,
        processID: pid_t,
        applicationName: String,
        windowTitle: String,
        frame: CGRect,
        isMinimized: Bool = false,
        isVisible: Bool = true,
        isOnScreen: Bool = true,
        level: Int = 0,
        role: WindowRole = .window,
        subrole: WindowSubrole? = nil
    ) {
        self.id = id
        self.processID = processID
        self.applicationName = applicationName
        self.windowTitle = windowTitle
        self.frame = frame
        self.isMinimized = isMinimized
        self.isVisible = isVisible
        self.isOnScreen = isOnScreen
        self.level = level
        self.role = role
        self.subrole = subrole
    }
}

// MARK: - Supporting Types

public enum WindowRole: String, CaseIterable {
    case window = "AXWindow"
    case dialog = "AXDialog"
    case sheet = "AXSheet"
    case drawer = "AXDrawer"
    case application = "AXApplication"
    case systemDialog = "AXSystemDialog"
    case unknown = "AXUnknown"
}

public enum WindowSubrole: String, CaseIterable {
    case standardWindow = "AXStandardWindow"
    case dialog = "AXDialog"
    case systemDialog = "AXSystemDialog"
    case floatingWindow = "AXFloatingWindow"
    case documentWindow = "AXDocumentWindow"
    case toolbar = "AXToolbar"
    case unknown = "AXUnknown"
}

// MARK: - Extensions

extension WindowInfo {

    /// Returns true if this window can be managed (resized, moved, etc.)
    public var isManageable: Bool {
        // Be more inclusive - allow any window that's visible and has reasonable size
        // This ensures MacSnapper's own windows are manageable too
        return isVisible &&
               !isMinimized &&
               isOnScreen &&
               (role == .window || role == .dialog) && // Include dialogs which some SwiftUI windows use
               frame.width > 50 &&
               frame.height > 50
    }

    /// Returns the center point of the window
    public var center: CGPoint {
        return CGPoint(
            x: frame.midX,
            y: frame.midY
        )
    }

    /// Returns a description suitable for debugging
    public var debugDescription: String {
        return """
        WindowInfo(
            id: \(id),
            app: \(applicationName),
            title: \(windowTitle),
            frame: \(frame),
            manageable: \(isManageable)
        )
        """
    }
}
import Foundation
import ApplicationServices
import Combine
import CoreGraphics
import AppKit

/// Concrete implementation of WindowRepositoryProtocol using macOS Accessibility APIs
/// This is the infrastructure layer that handles the actual system integration
public final class AccessibilityWindowRepository: WindowRepositoryProtocol {

    // MARK: - Properties

    private let logger = Logger(category: "AccessibilityWindowRepository")
    private let windowUpdateSubject = PassthroughSubject<[WindowInfo], Never>()
    private let focusedWindowSubject = PassthroughSubject<WindowInfo?, Never>()

    // Timer for periodic window updates
    private var updateTimer: Timer?
    private var lastKnownWindows: [WindowInfo] = []
    private var lastKnownFocusedWindow: WindowInfo?

    // MARK: - Initialization

    public init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - WindowRepositoryProtocol Implementation

    public func getAllWindows() async throws -> [WindowInfo] {
        logger.debug("Fetching all windows")

        guard hasAccessibilityPermissions() else {
            logger.error("Accessibility permissions not granted")
            throw WindowRepositoryError.accessibilityPermissionsDenied
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    let windows = try self?.fetchAllWindows() ?? []
                    self?.logger.info("Retrieved \(windows.count) windows")
                    continuation.resume(returning: windows)
                } catch {
                    self?.logger.error("Failed to fetch windows: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    public func getWindows(for applicationName: String) async throws -> [WindowInfo] {
        logger.debug("Fetching windows for application: \(applicationName)")

        let allWindows = try await getAllWindows()
        let filteredWindows = allWindows.filter { $0.applicationName == applicationName }

        logger.info("Found \(filteredWindows.count) windows for \(applicationName)")
        return filteredWindows
    }

    public func getFocusedWindow() async throws -> WindowInfo? {
        logger.debug("Getting focused window")

        guard hasAccessibilityPermissions() else {
            throw WindowRepositoryError.accessibilityPermissionsDenied
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let focusedWindow = self?.fetchFocusedWindow()
                self?.logger.debug("Focused window: \(focusedWindow?.debugDescription ?? "none")")
                continuation.resume(returning: focusedWindow)
            }
        }
    }

    public func getWindow(by windowId: String) async throws -> WindowInfo? {
        logger.debug("Getting window by ID: \(windowId)")

        let allWindows = try await getAllWindows()
        let window = allWindows.first { $0.id == windowId }

        if window == nil {
            logger.warning("Window not found: \(windowId)")
        }

        return window
    }

    public func setWindowFrame(_ windowInfo: WindowInfo, frame: CGRect) async throws {
        logger.info("Setting window frame for '\(windowInfo.applicationName)' to \(frame)")

        guard hasAccessibilityPermissions() else {
            throw WindowRepositoryError.accessibilityPermissionsDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    try self?.performSetWindowFrame(windowInfo, frame: frame)
                    self?.logger.info("Successfully set window frame")
                    continuation.resume()
                } catch {
                    self?.logger.error("Failed to set window frame: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func minimizeWindow(_ windowInfo: WindowInfo) async throws {
        logger.info("Minimizing window: \(windowInfo.applicationName)")
        // Implementation would go here
        throw WindowRepositoryError.operationNotSupported("minimize")
    }

    public func restoreWindow(_ windowInfo: WindowInfo) async throws {
        logger.info("Restoring window: \(windowInfo.applicationName)")
        // Implementation would go here
        throw WindowRepositoryError.operationNotSupported("restore")
    }

    public func focusWindow(_ windowInfo: WindowInfo) async throws {
        logger.info("Focusing window: \(windowInfo.applicationName)")
        // Implementation would go here
        throw WindowRepositoryError.operationNotSupported("focus")
    }

    public var windowUpdates: AnyPublisher<[WindowInfo], Never> {
        windowUpdateSubject.eraseToAnyPublisher()
    }

    public var focusedWindowUpdates: AnyPublisher<WindowInfo?, Never> {
        focusedWindowSubject.eraseToAnyPublisher()
    }

    public func hasAccessibilityPermissions() -> Bool {
        let options: [String: Bool] = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    public func requestAccessibilityPermissions() async throws {
        logger.info("Requesting accessibility permissions")

        let options: [String: Bool] = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let isGranted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !isGranted {
            logger.warning("Accessibility permissions not granted after request")
            throw WindowRepositoryError.accessibilityPermissionsDenied
        }

        logger.info("Accessibility permissions granted")
    }

    public func getScreenInfo() async throws -> [ScreenInfo] {
        logger.debug("Getting screen information")

        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let screens = NSScreen.screens.enumerated().map { index, screen in
                    ScreenInfo(
                        id: "screen_\(index)",
                        frame: screen.frame,
                        visibleFrame: screen.visibleFrame,
                        scaleFactor: screen.backingScaleFactor,
                        isPrimary: screen == NSScreen.main
                    )
                }
                continuation.resume(returning: screens)
            }
        }
    }
}

// MARK: - Private Implementation

private extension AccessibilityWindowRepository {

    func startMonitoring() {
        logger.info("Starting window monitoring")

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForUpdates()
        }
    }

    func stopMonitoring() {
        logger.info("Stopping window monitoring")
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func checkForUpdates() {
        guard hasAccessibilityPermissions() else { return }

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            do {
                let currentWindows = try self.fetchAllWindows()
                let currentFocusedWindow = self.fetchFocusedWindow()

                // Check if windows changed
                if currentWindows != self.lastKnownWindows {
                    self.lastKnownWindows = currentWindows
                    self.windowUpdateSubject.send(currentWindows)
                }

                // Check if focused window changed
                if currentFocusedWindow?.id != self.lastKnownFocusedWindow?.id {
                    self.lastKnownFocusedWindow = currentFocusedWindow
                    self.focusedWindowSubject.send(currentFocusedWindow)
                }

            } catch {
                self.logger.error("Error during monitoring update: \(error)")
            }
        }
    }

    func fetchAllWindows() throws -> [WindowInfo] {
        var windows: [WindowInfo] = []

        // Get all running applications
        let runningApps = NSWorkspace.shared.runningApplications

        for app in runningApps {
            guard let bundleId = app.bundleIdentifier,
                  let appName = app.localizedName,
                  !app.isTerminated else { continue }

            let appElement = AXUIElementCreateApplication(app.processIdentifier)

            var windowsRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

            guard result == AXError.success,
                  let windowsArray = windowsRef as? [AXUIElement] else { continue }

            for (index, windowElement) in windowsArray.enumerated() {
                if let windowInfo = createWindowInfo(
                    from: windowElement,
                    processID: app.processIdentifier,
                    applicationName: appName,
                    windowIndex: index
                ) {
                    windows.append(windowInfo)
                }
            }
        }

        return windows.filter { $0.isManageable }
    }

    func fetchFocusedWindow() -> WindowInfo? {
        let systemElement = AXUIElementCreateSystemWide()

        var focusedAppRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemElement, kAXFocusedApplicationAttribute as CFString, &focusedAppRef) == AXError.success,
              let focusedAppRef = focusedAppRef,
              CFGetTypeID(focusedAppRef) == AXUIElementGetTypeID() else {
            return nil
        }
        let focusedApp = focusedAppRef as! AXUIElement

        var focusedWindowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focusedApp, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == AXError.success,
              let focusedWindowRef = focusedWindowRef,
              CFGetTypeID(focusedWindowRef) == AXUIElementGetTypeID() else {
            return nil
        }
        let focusedWindow = focusedWindowRef as! AXUIElement

        // Get process ID and app name
        var pid: pid_t = 0
        AXUIElementGetPid(focusedApp, &pid)

        let runningApp = NSWorkspace.shared.runningApplications.first { $0.processIdentifier == pid }
        let appName = runningApp?.localizedName ?? "Unknown"

        return createWindowInfo(
            from: focusedWindow,
            processID: pid,
            applicationName: appName,
            windowIndex: 0
        )
    }

    func createWindowInfo(
        from windowElement: AXUIElement,
        processID: pid_t,
        applicationName: String,
        windowIndex: Int
    ) -> WindowInfo? {

        // Get window title
        var titleRef: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleRef)
        let title = (titleRef as? String) ?? "Untitled"

        // Get window position
        var positionRef: CFTypeRef?
        let positionResult = AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionRef)

        var position = CGPoint.zero
        if positionResult == AXError.success, let positionValue = positionRef {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        }

        // Get window size
        var sizeRef: CFTypeRef?
        let sizeResult = AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef)

        var size = CGSize.zero
        if sizeResult == AXError.success, let sizeValue = sizeRef {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }

        // Get window role
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement, kAXRoleAttribute as CFString, &roleRef)
        let roleString = (roleRef as? String) ?? "AXUnknown"
        let role = WindowRole(rawValue: roleString) ?? .unknown

        // Get window subrole
        var subroleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement, kAXSubroleAttribute as CFString, &subroleRef)
        let subroleString = subroleRef as? String
        let subrole = subroleString.flatMap { WindowSubrole(rawValue: $0) }

        // Create unique ID
        let windowId = "\(processID)_\(windowIndex)_\(title.hashValue)"

        return WindowInfo(
            id: windowId,
            processID: processID,
            applicationName: applicationName,
            windowTitle: title,
            frame: CGRect(origin: position, size: size),
            isMinimized: false, // TODO: Get actual minimized state
            isVisible: true,
            isOnScreen: true,
            level: 0, // TODO: Get actual level
            role: role,
            subrole: subrole
        )
    }

    func performSetWindowFrame(_ windowInfo: WindowInfo, frame: CGRect) throws {
        // Find the window element
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.processIdentifier == windowInfo.processID }) else {
            throw WindowRepositoryError.applicationNotFound(windowInfo.applicationName)
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == AXError.success,
              let windowsArray = windowsRef as? [AXUIElement] else {
            throw WindowRepositoryError.systemError("Could not get windows for application")
        }

        // Find the specific window (try multiple matching strategies)
        for (index, windowElement) in windowsArray.enumerated() {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleRef)
            let title = (titleRef as? String) ?? ""

            // Try to match by title first, then by index as fallback
            let windowId = "\(windowInfo.processID)_\(index)_\(title.hashValue)"

            if title == windowInfo.windowTitle || windowId == windowInfo.id {
                // Set position
                var frameOrigin = frame.origin
                let positionValue = AXValueCreate(.cgPoint, &frameOrigin)!
                let positionResult = AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, positionValue)

                // Set size
                var frameSize = frame.size
                let sizeValue = AXValueCreate(.cgSize, &frameSize)!
                let sizeResult = AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeValue)

                if positionResult != AXError.success || sizeResult != AXError.success {
                    let positionError = positionResult != AXError.success ? "position failed (\(positionResult.rawValue))" : ""
                    let sizeError = sizeResult != AXError.success ? "size failed (\(sizeResult.rawValue))" : ""
                    let errorMessage = [positionError, sizeError].filter { !$0.isEmpty }.joined(separator: ", ")
                    throw WindowRepositoryError.systemError("Could not set window frame: \(errorMessage)")
                }

                return
            }
        }

        throw WindowRepositoryError.windowNotFound(windowInfo.id)
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

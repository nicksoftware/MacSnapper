import Foundation
import ServiceManagement

/// Service for managing launch at login functionality
/// Uses modern Service Management framework (macOS 13+) with fallback for older systems
public final class LaunchAtLoginService: ObservableObject {

    // MARK: - Properties

    private let logger = Logger(category: "LaunchAtLoginService")
    @Published public private(set) var isEnabled = false
    @Published public private(set) var isSupported = true

    // MARK: - Initialization

    public init() {
        checkCurrentStatus()
    }

    // MARK: - Public Interface

    /// Enables or disables launch at login
    /// - Parameter enabled: Whether to enable launch at login
    public func setLaunchAtLogin(enabled: Bool) async {
        logger.info("Setting launch at login: \(enabled)")

        if #available(macOS 13.0, *) {
            await setLaunchAtLoginModern(enabled: enabled)
        } else {
            setLaunchAtLoginLegacy(enabled: enabled)
        }

        await MainActor.run {
            self.isEnabled = enabled
            // Update UserDefaults to keep UI in sync
            UserDefaults.standard.set(enabled, forKey: "MacSnap.LaunchAtLogin")
        }
    }

    /// Checks if launch at login is currently enabled
    public func checkCurrentStatus() {
        if #available(macOS 13.0, *) {
            checkStatusModern()
        } else {
            checkStatusLegacy()
        }
    }

    // MARK: - Modern Implementation (macOS 13+)

    @available(macOS 13.0, *)
    private func setLaunchAtLoginModern(enabled: Bool) async {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                logger.info("Successfully registered app for launch at login")
            } else {
                try await SMAppService.mainApp.unregister()
                logger.info("Successfully unregistered app from launch at login")
            }
        } catch {
            logger.error("Failed to set launch at login: \(error)")
            await MainActor.run {
                self.isSupported = false
            }
        }
    }

    @available(macOS 13.0, *)
    private func checkStatusModern() {
        let status = SMAppService.mainApp.status
        let enabled = status == .enabled

        DispatchQueue.main.async {
            self.isEnabled = enabled
            self.isSupported = status != .notRegistered

            // Sync with UserDefaults
            UserDefaults.standard.set(enabled, forKey: "MacSnap.LaunchAtLogin")
        }

        logger.info("Launch at login status: \(status)")
    }

    // MARK: - Legacy Implementation (macOS 12 and below)

    private func setLaunchAtLoginLegacy(enabled: Bool) {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            logger.error("Could not get bundle identifier")
            return
        }

        // For legacy systems, we store the preference and show instructions
        // Full implementation would require a helper app
        logger.warning("Launch at login on macOS 12 requires helper app implementation")

        // For now, just store the preference
        UserDefaults.standard.set(enabled, forKey: "MacSnap.LaunchAtLogin")

        // Show user instructions for manual setup
        if enabled {
            showLegacyInstructions()
        }
    }

    private func checkStatusLegacy() {
        // On legacy systems, just check UserDefaults
        let enabled = UserDefaults.standard.bool(forKey: "MacSnap.LaunchAtLogin")
        DispatchQueue.main.async {
            self.isEnabled = enabled
            self.isSupported = true // We support it via instructions
        }
    }

    private func showLegacyInstructions() {
        #if canImport(AppKit)
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Launch at Login Setup"
            alert.informativeText = """
            To enable launch at login on your macOS version:

            1. Open System Preferences
            2. Go to Users & Groups
            3. Click Login Items
            4. Click + and add Mac Snap

            This will start Mac Snap automatically when you log in.
            """
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "OK")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        #endif
    }
}

// MARK: - Supporting Extensions

extension LaunchAtLoginService {

    /// Returns a user-friendly status message
    public var statusMessage: String {
        if !isSupported {
            return "Launch at login is not supported on this system"
        }

        return isEnabled ? "App will launch at login" : "App will not launch at login"
    }
}
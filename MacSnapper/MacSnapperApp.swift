//
//  MacSnapperApp.swift
//  MacSnapper
//
//  Created by HTCD on 2025/06/04.
//

import SwiftUI
import Combine
import AppKit

/// Main application entry point
/// Sets up the dependency injection container and provides the root view
@main
struct MacSnapperApp: App {

    // MARK: - Properties

    private let container = DIContainer.shared
    @StateObject private var appDelegate = MacSnapperAppDelegate()

    // MARK: - Scene Configuration

    var body: some Scene {
        WindowGroup {
            ConfigurationView()
                .environmentObject(container.windowManagementUseCase)
                .environmentObject(container.subscriptionService)
                .environmentObject(container.globalHotkeyService)
                .onAppear {
                    setupApp()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About MacSnapper") {
                    appDelegate.showAbout()
                }
            }
            CommandGroup(after: .appSettings) {
                Button("Preferences...") {
                    appDelegate.showPreferences()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        // Menu bar extra for quick access - keeps app running in background
        MenuBarExtra("MacSnapper", systemImage: "rectangle.3.offgrid") {
            MenuBarView()
                .environmentObject(container.windowManagementUseCase)
                .environmentObject(container.subscriptionService)
                .environmentObject(container.globalHotkeyService)
        }
        .menuBarExtraStyle(.window)
    }

    // MARK: - App Setup

    private func setupApp() {
        // Configure app for background operation
        setupBackgroundOperation()

        // Configure logging
        print("🚀 MacSnapper Pro starting up...")
        print("📦 Dependency container initialized")

        // Setup global hotkeys (works in background)
        setupGlobalHotkeys()

        // Configure app appearance
        configureAppearance()

        // Request permissions if needed
        setupPermissions()

        // Setup app lifecycle handlers
        setupAppLifecycle()

        // Show window on first launch or if in regular app mode
        showWindowIfNeeded()
    }

        private func setupBackgroundOperation() {
        #if canImport(AppKit)
        // Check user preference for background operation (default: false for better user experience)
        // Advanced users can enable background mode in settings for optimal performance
        let runInBackground = UserDefaults.standard.object(forKey: "MacSnapper.RunInBackground") as? Bool ?? false

        if runInBackground {
            // Run in background (no dock icon) - fastest hotkey response
            NSApp.setActivationPolicy(.accessory)
            BackgroundServiceManager.shared.enableBackgroundProcessing()
            BackgroundServiceManager.shared.optimizeForBackgroundOperations()
            print("🌙 Running in background mode - hotkeys work globally")
        } else {
            // Run as regular app (with dock icon)
            NSApp.setActivationPolicy(.regular)
            print("🖥️ Running as regular app")
        }
        #endif
    }

    private func setupAppLifecycle() {
        // Handle app becoming active/inactive
        appDelegate.setupLifecycleHandlers()
    }

    private func setupGlobalHotkeys() {
        let hotkeyService = container.globalHotkeyService
        let windowManagement = container.windowManagementUseCase
        let subscriptionService = container.subscriptionService

        // Install event handler for global system-wide hotkeys
        hotkeyService.installEventHandler()

        // Register default hotkeys (works globally regardless of app state)
        hotkeyService.registerDefaultHotkeys()

        // Register premium hotkeys if subscribed
        if subscriptionService.subscriptionStatus.isPremium {
            hotkeyService.registerPremiumHotkeys()
        }

        // Listen for hotkey actions and execute in background
        hotkeyService.hotkeyActions
            .sink { snapType in
                // Execute window snapping in background queue for performance
                Task.detached(priority: .userInitiated) {
                    await windowManagement.snapFocusedWindow(to: snapType)
                }
            }
            .store(in: &appDelegate.cancellables)

        print("🎹 Global hotkeys registered - works in background")
    }

    private func setupPermissions() {
        Task {
            let windowManagement = container.windowManagementUseCase
            if !windowManagement.hasAccessibilityPermissions {
                print("⚠️ Accessibility permissions required")
            }
        }
    }

    private func configureAppearance() {
        // Configure app-wide appearance for premium feel
        #if canImport(AppKit)
        let appearance = NSApp.effectiveAppearance.name
        print("🎨 Using appearance: \(appearance)")
        #endif
    }

    private func showWindowIfNeeded() {
        #if canImport(AppKit)
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "MacSnapper.HasLaunchedBefore")
        let runInBackground = UserDefaults.standard.object(forKey: "MacSnapper.RunInBackground") as? Bool ?? false

        // Show window on first launch or if not in background mode
        if isFirstLaunch || !runInBackground {
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)

                // Bring the main window to front
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                }
            }

            // Mark that we've launched before
            if isFirstLaunch {
                UserDefaults.standard.set(true, forKey: "MacSnapper.HasLaunchedBefore")
                print("👋 First launch - showing welcome window")
            }
        }
        #endif
    }
}

// MARK: - App Delegate

class MacSnapperAppDelegate: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    private var isInBackground = false

    func setupLifecycleHandlers() {
        #if canImport(AppKit)
        // Handle app state changes to ensure hotkeys work in background
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { _ in
                print("📱 MacSnapper became active")
                self.isInBackground = false
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .sink { _ in
                print("📱 MacSnapper went to background - hotkeys still active")
                self.isInBackground = true
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didHideNotification)
            .sink { _ in
                print("📱 MacSnapper hidden - hotkeys still active")
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didUnhideNotification)
            .sink { _ in
                print("📱 MacSnapper unhidden")
            }
            .store(in: &cancellables)
        #endif
    }

    func showAbout() {
        // Show about window
        print("📱 Showing About window")
        #if canImport(AppKit)
        NSApp.activate(ignoringOtherApps: true)
        #endif
    }

    func showPreferences() {
        // Show preferences window
        print("⚙️ Showing Preferences window")
        #if canImport(AppKit)
        NSApp.activate(ignoringOtherApps: true)
        #endif
    }
}

// MARK: - Background Service Manager

/// Ensures MacSnapper continues to work optimally in the background
public class BackgroundServiceManager {

    static let shared = BackgroundServiceManager()

    private init() {}

    /// Ensures the app stays responsive for hotkey processing
    public func enableBackgroundProcessing() {
        #if canImport(AppKit)
        // Keep app responsive for global events
        NSApp.mainMenu?.autoenablesItems = false

        // Ensure app doesn't get suspended
        NSApp.windows.forEach { window in
            window.level = .floating
        }
        #endif
    }

    /// Optimizes for background window management operations
    public func optimizeForBackgroundOperations() {
        // Set process priority for responsive hotkey handling
        Thread.current.qualityOfService = .userInitiated

        // Ensure background queues are ready
        DispatchQueue.global(qos: .userInitiated).async {
            // Warm up background processing
        }
    }
}

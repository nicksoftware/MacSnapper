import SwiftUI

/// General settings view for basic MacSnapper configuration
/// Provides core functionality toggles and behavior settings
struct GeneralSettingsView: View {

    // MARK: - Environment Objects

    @EnvironmentObject private var windowManagement: WindowManagementUseCase
    @EnvironmentObject private var globalHotkeyService: GlobalHotkeyService

    // MARK: - State

    @AppStorage("MacSnapper.LaunchAtLogin") private var launchAtLogin = false
    @AppStorage("MacSnapper.ShowMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("MacSnapper.EnableHotkeys") private var enableHotkeys = true
    @AppStorage("MacSnapper.ShowNotifications") private var showNotifications = true
    @AppStorage("MacSnapper.AnimateWindows") private var animateWindows = true
    @AppStorage("MacSnapper.RestoreOnLaunch") private var restoreOnLaunch = true
    @AppStorage("MacSnapper.RunInBackground") private var runInBackground = true

    @State private var isCheckingPermissions = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Core Settings
                coreSettingsSection

                // Permissions Section
                permissionsSection

                // Behavior Settings
                behaviorSettingsSection

                // System Integration
                systemIntegrationSection
            }
            .padding()
        }
        .navigationTitle("General")
        .onChange(of: enableHotkeys) { oldValue, newValue in
            handleHotkeyToggle(enabled: newValue)
        }
        .onChange(of: runInBackground) { oldValue, newValue in
            handleBackgroundModeToggle(enabled: newValue)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.3.offgrid")
                .font(.system(size: 48))
                .foregroundStyle(.blue.gradient)

            Text("MacSnapper Pro")
                .font(.title2)
                .fontWeight(.bold)

            Text("Professional window management for macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Core Settings Section

    private var coreSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Core Settings", systemImage: "gearshape")

            VStack(spacing: 12) {
                SettingRow(
                    title: "Enable Global Hotkeys",
                    description: "Allow MacSnapper to respond to keyboard shortcuts system-wide",
                    systemImage: "keyboard",
                    isOn: $enableHotkeys
                )

                SettingRow(
                    title: "Animate Window Movements",
                    description: "Smooth animations when snapping windows",
                    systemImage: "arrow.up.and.down.and.arrow.left.and.right",
                    isOn: $animateWindows
                )

                SettingRow(
                    title: "Show Notifications",
                    description: "Display notifications for important actions",
                    systemImage: "bell",
                    isOn: $showNotifications
                )
            }
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Permissions", systemImage: "lock.shield")

            VStack(spacing: 12) {
                PermissionRow(
                    title: "Accessibility Access",
                    description: "Required to manage windows from other applications",
                    status: windowManagement.hasAccessibilityPermissions ? .granted : .required,
                    action: {
                        openAccessibilityPreferences()
                    }
                )

                if !windowManagement.hasAccessibilityPermissions {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)

                        Text("MacSnapper requires accessibility permissions to function properly.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Behavior Settings Section

    private var behaviorSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Behavior", systemImage: "gear.badge")

            VStack(spacing: 12) {
                SettingRow(
                    title: "Restore Window Positions",
                    description: "Remember and restore window positions on launch",
                    systemImage: "arrow.clockwise",
                    isOn: $restoreOnLaunch
                )
            }
        }
    }

    // MARK: - System Integration Section

    private var systemIntegrationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("System Integration", systemImage: "macwindow")

            VStack(spacing: 12) {
                SettingRow(
                    title: "Launch at Login",
                    description: "Start MacSnapper automatically when you log in",
                    systemImage: "power",
                    isOn: $launchAtLogin
                )

                SettingRow(
                    title: "Show Menu Bar Icon",
                    description: "Display MacSnapper icon in the menu bar for quick access",
                    systemImage: "menubar.rectangle",
                    isOn: $showMenuBarIcon
                )

                SettingRow(
                    title: "Run in Background",
                    description: "Keep MacSnapper running in background (no dock icon) for faster hotkey response",
                    systemImage: "square.3.layers.3d.down.right",
                    isOn: $runInBackground
                )

                if runInBackground {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)

                        Text("Background mode provides fastest hotkey response. Hotkeys work even when app is hidden or minimized.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Actions

    private func handleHotkeyToggle(enabled: Bool) {
        if enabled {
            globalHotkeyService.registerDefaultHotkeys()
        } else {
            globalHotkeyService.unregisterAllHotkeys()
        }
    }

    private func handleBackgroundModeToggle(enabled: Bool) {
        #if canImport(AppKit)
        DispatchQueue.main.async {
            if enabled {
                // Run in background (no dock icon) - fastest hotkey response
                NSApp.setActivationPolicy(.accessory)
                BackgroundServiceManager.shared.enableBackgroundProcessing()
                BackgroundServiceManager.shared.optimizeForBackgroundOperations()
            } else {
                // Run as regular app (with dock icon)
                NSApp.setActivationPolicy(.regular)
            }
        }
        #endif
    }

    private func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Setting Row Component

struct SettingRow: View {
    let title: String
    let description: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
        }
        .padding(.horizontal)
        .frame(height: 50)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Permission Row Component

struct PermissionRow: View {
    let title: String
    let description: String
    let status: PermissionStatus
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: status.iconName)
                .foregroundColor(status.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if status == .required {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
        .frame(height: 50)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Permission Status Enum

enum PermissionStatus {
    case granted
    case required

    var iconName: String {
        switch self {
        case .granted: return "checkmark.shield.fill"
        case .required: return "exclamationmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .granted: return .green
        case .required: return .orange
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        GeneralSettingsView()
            .environmentObject(DIContainer.shared.windowManagementUseCase)
            .environmentObject(DIContainer.shared.globalHotkeyService)
    }
    .frame(width: 600, height: 500)
}
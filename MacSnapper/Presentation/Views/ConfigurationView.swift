import SwiftUI

/// Main configuration view for MacSnapper Pro
/// Provides a clean, professional interface for managing settings and premium features
struct ConfigurationView: View {

    // MARK: - Environment Objects

    @EnvironmentObject private var windowManagement: WindowManagementUseCase
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var globalHotkeyService: GlobalHotkeyService

    // MARK: - State

    @State private var selectedTab: ConfigurationTab = .general
    @State private var showingPermissionAlert = false
    @State private var showingUpgradeSheet = false

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            // Sidebar with navigation tabs
            ConfigurationSidebar(selectedTab: $selectedTab)
        } detail: {
            // Main content area
            ConfigurationDetailView(
                selectedTab: selectedTab,
                showingUpgradeSheet: $showingUpgradeSheet
            )
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                StatusIndicator()
            }
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeView()
        }
        .alert("Accessibility Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open System Preferences") {
                openAccessibilityPreferences()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("MacSnapper needs accessibility permissions to manage windows. Please enable it in System Preferences.")
        }
        .task {
            await checkPermissions()
        }
    }

    // MARK: - Private Methods

    private func checkPermissions() async {
        if !windowManagement.hasAccessibilityPermissions {
            showingPermissionAlert = true
        }
    }

    private func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Configuration Sidebar

struct ConfigurationSidebar: View {
    @Binding var selectedTab: ConfigurationTab
    @EnvironmentObject private var subscriptionService: SubscriptionService

    var body: some View {
        List(ConfigurationTab.allCases, id: \.self, selection: $selectedTab) { tab in
            NavigationLink(value: tab) {
                Label {
                    HStack {
                        Text(tab.displayName)

                        if tab.isPremium && !subscriptionService.subscriptionStatus.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                } icon: {
                    Image(systemName: tab.iconName)
                        .foregroundColor(tab.color)
                }
            }
        }
        .navigationTitle("MacSnapper Pro")
        .toolbar {
            ToolbarItem {
                SubscriptionStatusView()
            }
        }
    }
}

// MARK: - Configuration Detail View

struct ConfigurationDetailView: View {
    let selectedTab: ConfigurationTab
    @Binding var showingUpgradeSheet: Bool

    @EnvironmentObject private var subscriptionService: SubscriptionService

    var body: some View {
        Group {
            if selectedTab.isPremium && !subscriptionService.subscriptionStatus.isPremium {
                PremiumFeatureLockedView(
                    feature: selectedTab,
                    showingUpgradeSheet: $showingUpgradeSheet
                )
            } else {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .shortcuts:
                    ShortcutsSettingsView()
                case .snapping:
                    SnappingSettingsView()
                case .displays:
                    DisplaySettingsView()
                case .presets:
                    PresetsSettingsView()
                case .exclusions:
                    ExclusionSettingsView()
                case .about:
                    AboutView()
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding()
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    @EnvironmentObject private var globalHotkeyService: GlobalHotkeyService
    @EnvironmentObject private var windowManagement: WindowManagementUseCase

    var body: some View {
        HStack(spacing: 8) {
            // Hotkey status
            Circle()
                .fill(globalHotkeyService.isEnabled ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(globalHotkeyService.isEnabled ? "Active" : "Inactive")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Subscription Status View

struct SubscriptionStatusView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(subscriptionService.subscriptionStatus.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(subscriptionService.subscriptionStatus.isPremium ? .green : .secondary)

            if case .trial(let expiryDate) = subscriptionService.subscriptionStatus {
                let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
                Text("\(daysLeft) days left")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Premium Feature Locked View

struct PremiumFeatureLockedView: View {
    let feature: ConfigurationTab
    @Binding var showingUpgradeSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "crown.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            VStack(spacing: 12) {
                Text("Premium Feature")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(feature.premiumDescription ?? "This feature requires a premium subscription.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }

            VStack(spacing: 12) {
                Button("Upgrade to Premium") {
                    showingUpgradeSheet = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Start Free Trial") {
                    Task {
                        await DIContainer.shared.subscriptionService.startTrial()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Configuration Tab Enum

enum ConfigurationTab: String, CaseIterable {
    case general = "general"
    case shortcuts = "shortcuts"
    case snapping = "snapping"
    case displays = "displays"
    case presets = "presets"
    case exclusions = "exclusions"
    case about = "about"

    var displayName: String {
        switch self {
        case .general: return "General"
        case .shortcuts: return "Shortcuts"
        case .snapping: return "Snapping"
        case .displays: return "Displays"
        case .presets: return "Presets"
        case .exclusions: return "Exclusions"
        case .about: return "About"
        }
    }

    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .shortcuts: return "keyboard"
        case .snapping: return "rectangle.3.offgrid"
        case .displays: return "display.2"
        case .presets: return "folder"
        case .exclusions: return "minus.circle"
        case .about: return "info.circle"
        }
    }

    var color: Color {
        switch self {
        case .general: return .blue
        case .shortcuts: return .purple
        case .snapping: return .green
        case .displays: return .orange
        case .presets: return .pink
        case .exclusions: return .red
        case .about: return .gray
        }
    }

    var isPremium: Bool {
        switch self {
        case .shortcuts, .displays, .presets, .exclusions:
            return true
        case .general, .snapping, .about:
            return false
        }
    }

    var premiumDescription: String? {
        switch self {
        case .shortcuts:
            return "Customize keyboard shortcuts to match your workflow. Create your own combinations and modify existing ones."
        case .displays:
            return "Advanced multi-monitor support with intelligent window positioning across multiple displays."
        case .presets:
            return "Save and restore custom window layouts. Perfect for different workflows and project setups."
        case .exclusions:
            return "Exclude specific applications from window management. Fine-tune which apps MacSnapper should manage."
        default:
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    ConfigurationView()
        .environmentObject(DIContainer.shared.windowManagementUseCase)
        .environmentObject(DIContainer.shared.subscriptionService)
        .environmentObject(DIContainer.shared.globalHotkeyService)
        .frame(width: 800, height: 600)
}
import SwiftUI

/// Main application view that displays the window management interface
/// Follows MVVM pattern with WindowManagementUseCase as the view model
struct MainView: View {

    // MARK: - Dependencies

    @EnvironmentObject private var windowManagement: WindowManagementUseCase

    // MARK: - State

    @State private var selectedWindow: WindowInfo?
    @State private var showingSettings = false
    @State private var searchText = ""

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            // Sidebar with window list
            WindowListView(
                windows: filteredWindows,
                selectedWindow: $selectedWindow,
                searchText: $searchText
            )
            .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 400)
        } detail: {
            // Main content area
            if let selectedWindow = selectedWindow {
                WindowDetailView(window: selectedWindow)
            } else if windowManagement.hasAccessibilityPermissions {
                EmptySelectionView()
            } else {
                PermissionRequestView()
            }
        }
        .navigationTitle("MacSnapper")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Settings") {
                    showingSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)

                Button("Refresh") {
                    Task {
                        await windowManagement.refreshWindows()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("Error", isPresented: .constant(windowManagement.lastError != nil)) {
            Button("OK") {
                windowManagement.clearError()
            }
        } message: {
            Text(windowManagement.lastError?.localizedDescription ?? "")
        }
        .task {
            // Initial load
            if windowManagement.hasAccessibilityPermissions {
                await windowManagement.refreshWindows()
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredWindows: [WindowInfo] {
        if searchText.isEmpty {
            return windowManagement.availableWindows
        } else {
            return windowManagement.availableWindows.filter { window in
                window.applicationName.localizedCaseInsensitiveContains(searchText) ||
                window.windowTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Window List View

struct WindowListView: View {
    let windows: [WindowInfo]
    @Binding var selectedWindow: WindowInfo?
    @Binding var searchText: String

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBarView(searchText: $searchText)
                .padding()

            // Window list
            List(windows, selection: $selectedWindow) { window in
                WindowRowView(window: window)
                    .tag(window)
            }
            .listStyle(SidebarListStyle())
            .overlay {
                if windows.isEmpty {
                    EmptyWindowListView()
                }
            }
        }
        .navigationTitle("Windows")
    }
}

// MARK: - Window Row View

struct WindowRowView: View {
    let window: WindowInfo

    var body: some View {
        HStack {
            // App icon placeholder
            AppIconView(applicationName: window.applicationName)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(window.applicationName)
                    .font(.headline)
                    .lineLimit(1)

                Text(window.windowTitle.isEmpty ? "Untitled Window" : window.windowTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Window size indicator
            Text("\(Int(window.frame.width))×\(Int(window.frame.height))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - App Icon View

struct AppIconView: View {
    let applicationName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor.opacity(0.2))

            Text(String(applicationName.prefix(1)))
                .font(.caption.weight(.semibold))
                .foregroundColor(.accentColor)
        }
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search windows...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Empty States

struct EmptyWindowListView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "macwindow.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Windows Found")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Open some applications to see their windows here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptySelectionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.3.offgrid")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Select a Window")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Choose a window from the list to see snapping options.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct PermissionRequestView: View {
    @EnvironmentObject private var windowManagement: WindowManagementUseCase

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.hand.raised.trianglebadge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            VStack(spacing: 12) {
                Text("Accessibility Permissions Required")
                    .font(.title2.weight(.semibold))

                Text("MacSnapper needs accessibility permissions to manage windows. This allows the app to move and resize windows from other applications.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            Button {
                Task {
                    await windowManagement.requestAccessibilityPermissions()
                }
            } label: {
                Text("Grant Permissions")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(spacing: 8) {
                Text("After clicking the button above:")
                    .font(.subheadline.weight(.medium))

                VStack(alignment: .leading, spacing: 4) {
                    Label("System Settings will open", systemImage: "1.circle.fill")
                    Label("Go to Privacy & Security → Accessibility", systemImage: "2.circle.fill")
                    Label("Enable MacSnapper in the list", systemImage: "3.circle.fill")
                    Label("Restart MacSnapper", systemImage: "4.circle.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .frame(maxWidth: 400)
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .environmentObject(DIContainer.shared.windowManagementUseCase)
}
import SwiftUI

/// Menu bar view that provides quick access to window management
/// This appears in the menu bar extra for instant access to snapping functions
struct MenuBarView: View {

    // MARK: - Dependencies

    @EnvironmentObject private var windowManagement: WindowManagementUseCase

    // MARK: - State

    @State private var focusedWindowName: String = "No focused window"

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            headerSection

            Divider()

            if windowManagement.hasAccessibilityPermissions {
                // Quick snap actions
                quickSnapSection

                Divider()

                // Focused window section
                focusedWindowSection

                Divider()

                // App controls
                appControlsSection
            } else {
                // Permission request
                permissionSection
            }
        }
        .frame(width: 280)
        .background(Color(NSColor.controlBackgroundColor))
        .onReceive(windowManagement.$focusedWindow) { window in
            updateFocusedWindowName(window)
        }
    }

    // MARK: - View Sections

    private var headerSection: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "rectangle.3.offgrid")
                    .foregroundColor(.accentColor)
                Text("MacSnapper")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            HStack {
                Circle()
                    .fill(windowManagement.hasAccessibilityPermissions ? .green : .orange)
                    .frame(width: 6, height: 6)

                Text(windowManagement.hasAccessibilityPermissions ? "Ready" : "Permissions Required")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private var quickSnapSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Quick Snap")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.top, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
                MenuBarSnapButton(type: .leftHalf, icon: "rectangle.lefthalf.filled", title: "Left Half") {
                    await snapFocusedWindow(.leftHalf)
                }

                MenuBarSnapButton(type: .rightHalf, icon: "rectangle.righthalf.filled", title: "Right Half") {
                    await snapFocusedWindow(.rightHalf)
                }

                MenuBarSnapButton(type: .topHalf, icon: "rectangle.tophalf.filled", title: "Top Half") {
                    await snapFocusedWindow(.topHalf)
                }

                MenuBarSnapButton(type: .bottomHalf, icon: "rectangle.bottomhalf.filled", title: "Bottom Half") {
                    await snapFocusedWindow(.bottomHalf)
                }

                MenuBarSnapButton(type: .maximize, icon: "macwindow", title: "Maximize") {
                    await snapFocusedWindow(.maximize)
                }

                MenuBarSnapButton(type: .center, icon: "rectangle.center.inset.filled", title: "Center") {
                    await snapFocusedWindow(.center)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }

    private var focusedWindowSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focused Window")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.top, 8)

            HStack {
                Image(systemName: "macwindow")
                    .foregroundColor(.accentColor)
                    .frame(width: 16)

                Text(focusedWindowName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private var appControlsSection: some View {
        VStack(spacing: 4) {
            Button {
                NSApp.activate(ignoringOtherApps: true)
                // Open main window
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            } label: {
                HStack {
                    Image(systemName: "macwindow")
                    Text("Open MacSnapper")
                    Spacer()
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())

            Button {
                Task {
                    await windowManagement.refreshWindows()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Windows")
                    Spacer()
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit MacSnapper")
                    Spacer()
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 8)
        }
    }

    private var permissionSection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Image(systemName: "figure.hand.raised.trianglebadge.exclamationmark")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text("Accessibility permissions required to manage windows")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Button {
                Task {
                    await windowManagement.requestAccessibilityPermissions()
                }
            } label: {
                Text("Grant Permissions")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 12)
        }
    }

    // MARK: - Actions

    private func snapFocusedWindow(_ snapType: SnapType) async {
        await windowManagement.snapFocusedWindow(to: snapType)
    }

    private func updateFocusedWindowName(_ window: WindowInfo?) {
        if let window = window {
            focusedWindowName = "\(window.applicationName) - \(window.windowTitle.isEmpty ? "Untitled" : window.windowTitle)"
        } else {
            focusedWindowName = "No focused window"
        }
    }
}

// MARK: - Menu Bar Snap Button

struct MenuBarSnapButton: View {
    let type: SnapType
    let icon: String
    let title: String
    let action: () async -> Void

    @State private var isLoading = false

    var body: some View {
        Button {
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: icon)
                            .foregroundColor(.accentColor)
                    }
                }
                .frame(width: 16, height: 16)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .opacity(0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview {
    MenuBarView()
        .environmentObject(DIContainer.shared.windowManagementUseCase)
}
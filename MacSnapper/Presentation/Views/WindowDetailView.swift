import SwiftUI

/// Detail view that shows snapping options for a selected window
/// This is the core functionality view where users interact with snap actions
struct WindowDetailView: View {

    // MARK: - Properties

    let window: WindowInfo
    @EnvironmentObject private var windowManagement: WindowManagementUseCase

    // MARK: - State

    @State private var availableActions: [SnapAction] = []
    @State private var isLoading = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Window info header
            windowInfoHeader
                .padding()
                .background(Color(NSColor.controlBackgroundColor))

            ScrollView {
                LazyVStack(spacing: 20) {
                    // Quick actions section
                    quickActionsSection

                    // All snap options section
                    snapOptionsSection

                    // Advanced options section
                    advancedOptionsSection
                }
                .padding()
            }
        }
        .navigationTitle("Window Actions")
        .task {
            await loadAvailableActions()
        }
    }

    // MARK: - View Components

    private var windowInfoHeader: some View {
        HStack {
            AppIconView(applicationName: window.applicationName)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(window.applicationName)
                    .font(.headline)

                Text(window.windowTitle.isEmpty ? "Untitled Window" : window.windowTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Size: \(Int(window.frame.width)) × \(Int(window.frame.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Position: \(Int(window.frame.origin.x)), \(Int(window.frame.origin.y))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Quick Actions", subtitle: "Common window arrangements")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(quickActions, id: \.id) { action in
                    SnapActionButton(action: action) {
                        await performSnapAction(action.type)
                    }
                }
            }
        }
    }

    private var snapOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Snap Options", subtitle: "Position and resize windows precisely")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(snapActions, id: \.id) { action in
                    SnapActionButton(action: action) {
                        await performSnapAction(action.type)
                    }
                }
            }
        }
    }

    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Advanced", subtitle: "Additional window controls")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(advancedActions, id: \.id) { action in
                    SnapActionButton(action: action) {
                        await performSnapAction(action.type)
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var quickActions: [SnapAction] {
        availableActions.filter { action in
            [.leftHalf, .rightHalf, .maximize, .center].contains(action.type)
        }
    }

    private var snapActions: [SnapAction] {
        availableActions.filter { action in
            [.topLeftQuarter, .topHalf, .topRightQuarter,
             .leftHalf, .center, .rightHalf,
             .bottomLeftQuarter, .bottomHalf, .bottomRightQuarter].contains(action.type)
        }
    }

    private var advancedActions: [SnapAction] {
        availableActions.filter { action in
            [.leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds].contains(action.type)
        }
    }

    // MARK: - Actions

    private func loadAvailableActions() async {
        isLoading = true
        defer { isLoading = false }

        availableActions = await windowManagement.getAvailableSnapActions()
    }

    private func performSnapAction(_ snapType: SnapType) async {
        await windowManagement.snapWindow(window, to: snapType)
    }
}

// MARK: - Supporting Views

struct SectionHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SnapActionButton: View {
    let action: SnapAction
    let onTap: () async -> Void

    @State private var isLoading = false

    var body: some View {
        Button {
            Task {
                isLoading = true
                await onTap()
                isLoading = false
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: action.type.iconName)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
                .frame(height: 24)

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let shortcut = action.keyboardShortcut {
                    KeyboardShortcutView(shortcut: shortcut)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

struct KeyboardShortcutView: View {
    let shortcut: KeyboardShortcut

    var body: some View {
        HStack(spacing: 2) {
            ForEach(modifierStrings, id: \.self) { modifier in
                Text(modifier)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.tertiaryLabelColor))
                    .cornerRadius(3)
            }

            Text(String(shortcut.key.character))
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color(NSColor.tertiaryLabelColor))
                .cornerRadius(3)
        }
    }

    private var modifierStrings: [String] {
        var strings: [String] = []

        if shortcut.modifiers.contains(.command) {
            strings.append("⌘")
        }
        if shortcut.modifiers.contains(.option) {
            strings.append("⌥")
        }
        if shortcut.modifiers.contains(.control) {
            strings.append("⌃")
        }
        if shortcut.modifiers.contains(.shift) {
            strings.append("⇧")
        }

        return strings
    }
}

// MARK: - Preview

#Preview {
    WindowDetailView(
        window: WindowInfo(
            id: "preview",
            processID: 123,
            applicationName: "Preview App",
            windowTitle: "Sample Document.pdf",
            frame: CGRect(x: 100, y: 100, width: 800, height: 600)
        )
    )
    .environmentObject(DIContainer.shared.windowManagementUseCase)
}
import SwiftUI

/// Snapping settings view showing available snap positions and shortcuts
/// Provides visual representation of all snapping options with keyboard shortcuts
struct SnappingSettingsView: View {

    // MARK: - Environment Objects

    @EnvironmentObject private var windowManagement: WindowManagementUseCase
    @EnvironmentObject private var subscriptionService: SubscriptionService

    // MARK: - State

    @State private var selectedSnapType: SnapType = .leftHalf
    @State private var showingDemo = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Basic Snapping Options
                basicSnappingSection

                // Advanced Snapping (Premium)
                advancedSnappingSection

                // Demo Section
                demoSection
            }
            .padding()
        }
        .navigationTitle("Snapping")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.3.offgrid")
                .font(.system(size: 48))
                .foregroundStyle(.green.gradient)

            Text("Window Snapping")
                .font(.title2)
                .fontWeight(.bold)

            Text("Organize your windows with precision and speed")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Basic Snapping Section

    private var basicSnappingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Basic Snapping", systemImage: "rectangle.split.2x1")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(basicSnapTypes, id: \.self) { snapType in
                    SnapOptionCard(
                        snapType: snapType,
                        isSelected: selectedSnapType == snapType,
                        isPremium: false
                    ) {
                        selectedSnapType = snapType
                    }
                }
            }
        }
    }

    // MARK: - Advanced Snapping Section

    private var advancedSnappingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader("Advanced Snapping", systemImage: "rectangle.split.3x1")

                if !subscriptionService.subscriptionStatus.isPremium {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(advancedSnapTypes, id: \.self) { snapType in
                    SnapOptionCard(
                        snapType: snapType,
                        isSelected: selectedSnapType == snapType,
                        isPremium: !subscriptionService.subscriptionStatus.isPremium
                    ) {
                        if subscriptionService.subscriptionStatus.isPremium {
                            selectedSnapType = snapType
                        }
                    }
                }
            }
        }
    }

    // MARK: - Demo Section

    private var demoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Try It Out", systemImage: "play.circle")

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Selection: \(selectedSnapType.displayName)")
                            .font(.headline)

                        if let shortcut = selectedSnapType.defaultShortcut {
                            Text("Shortcut: \(shortcut)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button(showingDemo ? "Stop Demo" : "Start Demo") {
                        showingDemo.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!windowManagement.hasAccessibilityPermissions)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

                if !windowManagement.hasAccessibilityPermissions {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)

                        Text("Accessibility permissions required to demonstrate window snapping.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.green)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Computed Properties

    private var basicSnapTypes: [SnapType] {
        [.leftHalf, .rightHalf, .topHalf, .bottomHalf, .maximize, .center,
         .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter]
    }

    private var advancedSnapTypes: [SnapType] {
        [.leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds]
    }
}

// MARK: - Snap Option Card

struct SnapOptionCard: View {
    let snapType: SnapType
    let isSelected: Bool
    let isPremium: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Visual representation
                ZStack {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 80, height: 50)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(isPremium ? .orange : .green)
                        .frame(width: snapType.previewWidth, height: snapType.previewHeight)
                        .cornerRadius(2)
                        .opacity(isPremium ? 0.6 : 1.0)
                }

                VStack(spacing: 2) {
                    Text(snapType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let shortcut = snapType.defaultShortcut {
                        Text(shortcut)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if isPremium {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                    }
                }
            }
            .padding()
            .background(isSelected ? .blue.opacity(0.1) : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isPremium)
    }
}

// MARK: - SnapType Extensions

extension SnapType {
    var previewWidth: CGFloat {
        switch self {
        case .leftHalf, .rightHalf:
            return 40
        case .topHalf, .bottomHalf:
            return 80
        case .leftThird, .centerThird, .rightThird:
            return 26
        case .leftTwoThirds:
            return 52
        case .rightTwoThirds:
            return 52
        case .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter:
            return 40
        case .maximize:
            return 76
        case .center:
            return 60
        case .custom:
            return 50
        case .minimize, .restore:
            return 50
        }
    }

    var previewHeight: CGFloat {
        switch self {
        case .leftHalf, .rightHalf:
            return 46
        case .topHalf, .bottomHalf:
            return 23
        case .leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds:
            return 46
        case .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter:
            return 23
        case .maximize:
            return 46
        case .center:
            return 36
        case .custom:
            return 36
        case .minimize, .restore:
            return 36
        }
    }

    var defaultShortcut: String? {
        switch self {
        case .leftHalf:
            return "⌥⌘←"
        case .rightHalf:
            return "⌥⌘→"
        case .topHalf:
            return "⌥⌘↑"
        case .bottomHalf:
            return "⌥⌘↓"
        case .maximize:
            return "⌥⌘F"
        case .center:
            return "⌥⌘C"
        case .topLeftQuarter:
            return "⌥⌘1"
        case .topRightQuarter:
            return "⌥⌘2"
        case .bottomLeftQuarter:
            return "⌥⌘3"
        case .bottomRightQuarter:
            return "⌥⌘4"
        case .leftThird:
            return "⌥⌘Q"
        case .centerThird:
            return "⌥⌘W"
        case .rightThird:
            return "⌥⌘E"
        case .leftTwoThirds:
            return "⌥⌘A"
        case .rightTwoThirds:
            return "⌥⌘S"
        case .custom, .minimize, .restore:
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SnappingSettingsView()
            .environmentObject(DIContainer.shared.windowManagementUseCase)
            .environmentObject(DIContainer.shared.subscriptionService)
    }
    .frame(width: 700, height: 600)
}
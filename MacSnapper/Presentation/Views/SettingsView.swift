import SwiftUI

/// Settings view for app configuration
/// Provides basic app information and placeholder for future settings
struct SettingsView: View {

    // MARK: - State

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            TabView {
                // General settings tab
                generalTab
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }

                // About tab
                aboutTab
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
            .frame(width: 500, height: 400)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - View Components

    private var headerSection: some View {
        HStack {
            Text("MacSnapper Settings")
                .font(.title2.weight(.semibold))

            Spacer()

            Button("Done") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var generalTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Window Management")
                        .font(.headline)

                    Text("MacSnapper is ready to manage your windows! Use the main interface to select windows and choose snap actions, or use the menu bar for quick access to common operations.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Text("Future versions will include customizable keyboard shortcuts, advanced snapping options, and more configuration settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Actions Available:")
                        .font(.subheadline.weight(.medium))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Left/Right Half - Split windows side by side")
                        Text("• Top/Bottom Half - Split windows vertically")
                        Text("• Quarters - Position in corners")
                        Text("• Maximize - Fill entire screen")
                        Text("• Center - Center window on screen")
                        Text("• Thirds - Divide screen in three sections")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var aboutTab: some View {
        VStack(spacing: 20) {
            // App icon and name
            VStack(spacing: 12) {
                Image(systemName: "rectangle.3.offgrid")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)

                Text("MacSnapper")
                    .font(.title.weight(.semibold))

                Text("Professional Window Manager")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Version info
            VStack(spacing: 8) {
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Built with SwiftUI and Clean Architecture")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Credits
            VStack(spacing: 8) {
                Text("Inspired by Rectangle and other great window managers")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("© 2024 Mac Snap. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
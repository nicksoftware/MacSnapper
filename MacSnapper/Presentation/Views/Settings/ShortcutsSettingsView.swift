import SwiftUI

struct ShortcutsSettingsView: View {
    var body: some View {
        VStack {
            Text("Keyboard Shortcuts")
                .font(.title2)
                .fontWeight(.bold)

            Text("Premium Feature - Customize your keyboard shortcuts")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DisplaySettingsView: View {
    var body: some View {
        VStack {
            Text("Multi-Display Settings")
                .font(.title2)
                .fontWeight(.bold)

            Text("Premium Feature - Advanced multi-monitor support")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PresetsSettingsView: View {
    var body: some View {
        VStack {
            Text("Window Presets")
                .font(.title2)
                .fontWeight(.bold)

            Text("Premium Feature - Save and restore window layouts")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ExclusionSettingsView: View {
    var body: some View {
        VStack {
            Text("App Exclusions")
                .font(.title2)
                .fontWeight(.bold)

            Text("Premium Feature - Exclude specific applications")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.3.offgrid")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)

            Text("MacSnapper Pro")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .foregroundColor(.secondary)

            Text("Professional window management for macOS")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
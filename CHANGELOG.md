# Changelog

All notable changes to Mac Snap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Automated DMG installer creation
- GitHub Actions CI/CD pipeline
- Professional logo and branding
- Comprehensive installation guide

## [1.0.0] - 2024-06-05

### Added
- **Core Window Snapping Features**
  - Left/Right half snapping
  - Quarter screen snapping
  - Window maximization and centering
  - Global keyboard shortcuts

- **Premium Features (Subscription Model)**
  - Advanced snapping patterns (thirds)
  - Custom keyboard shortcuts
  - Multi-monitor support
  - Window presets and exclusions
  - 7-day free trial
  - Monthly ($4.99) and Annual ($39.99) subscriptions

- **System Integration**
  - Launch at login functionality
  - Menu bar operation mode
  - Background/foreground mode toggle
  - Accessibility API integration
  - Global hotkey system

- **User Experience**
  - Clean Architecture design pattern
  - SwiftUI modern interface
  - Real-time window management
  - Settings persistence
  - Professional UI/UX design

- **Developer Features**
  - Clean Architecture implementation
  - Dependency injection container
  - Protocol-based design
  - Comprehensive error handling
  - Modular codebase structure

### Technical Details
- **Frameworks:** SwiftUI, StoreKit 2, ServiceManagement, Accessibility
- **Architecture:** Clean Architecture with Domain/Application/Infrastructure layers
- **Minimum macOS:** 15.4
- **Code Signing:** Apple Developer certificates supported
- **Distribution:** DMG installer, App Store ready

### Security & Privacy
- Minimal permissions required (Accessibility only)
- No data collection or tracking
- Local-only operation
- Secure subscription handling

---

## Version History Summary

- **v1.0.0** - Initial release with core snapping features and subscription model
- **Future releases** - Automatic updates, additional snapping patterns, enhanced multi-monitor support

For detailed technical documentation, see [README.md](README.md).
For installation instructions, see [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md).
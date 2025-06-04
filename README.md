# Mac Snap 🪟

A professional macOS window manager built with SwiftUI and Clean Architecture principles. Mac Snap provides powerful window snapping and management capabilities with a beautiful, intuitive interface.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2014.0+-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-green.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

## ✨ Features

### Core Window Management
- **Precise Window Snapping**: Left/Right halves, quarters, thirds, and custom positions
- **Multiple Screen Support**: Intelligent screen detection and window positioning
- **Real-time Window Monitoring**: Live updates of window state changes
- **Focused Window Control**: Quick actions on the currently active window

### User Interface
- **Modern SwiftUI Design**: Native macOS appearance with dark/light mode support
- **Menu Bar Integration**: Quick access to common actions without opening the main app
- **Sidebar Navigation**: Searchable window list with detailed information
- **Visual Feedback**: Loading states, animations, and clear status indicators

### Developer Experience
- **Clean Architecture**: Separation of concerns with clear layer boundaries
- **SOLID Principles**: Single responsibility, dependency inversion, and open/closed design
- **Comprehensive Testing**: Unit test structure with dependency injection support
- **Type Safety**: Strong typing throughout with proper error handling

## 🏗️ Architecture

Mac Snap follows Clean Architecture principles with clear separation between layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   MainView      │  │  WindowDetail   │  │  MenuBarView │ │
│  │   (SwiftUI)     │  │     View        │  │   (SwiftUI)  │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   APPLICATION LAYER                         │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │          WindowManagementUseCase                        │ │
│  │       (Business Logic Orchestration)                    │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │  ScreenService  │  │   DIContainer   │                   │
│  │                 │  │ (Dependency     │                   │
│  │                 │  │  Injection)     │                   │
│  └─────────────────┘  └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   WindowInfo    │  │   SnapAction    │  │  Repository  │ │
│  │   (Entity)      │  │   (Entity)      │  │  Protocols   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 INFRASTRUCTURE LAYER                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │        AccessibilityWindowRepository                    │ │
│  │         (macOS Accessibility APIs)                      │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

#### 🎨 Presentation Layer
- **SwiftUI Views**: User interface components
- **View Models**: UI state management (using UseCase as ViewModel)
- **User Interactions**: Button taps, menu selections, keyboard shortcuts

#### 🔄 Application Layer
- **Use Cases**: Business logic orchestration
- **Services**: Cross-cutting concerns (screen management, etc.)
- **Dependency Injection**: Service registration and resolution

#### 🏛️ Domain Layer
- **Entities**: Core business objects (`WindowInfo`, `SnapAction`)
- **Protocols**: Contracts for external dependencies
- **Business Rules**: Pure business logic without external dependencies

#### 🔧 Infrastructure Layer
- **Repository Implementations**: Data access using macOS APIs
- **External Services**: Accessibility APIs, system integration
- **Platform-specific Code**: macOS-specific implementations

## 🛠️ Design Patterns Used

### Repository Pattern
```swift
protocol WindowRepositoryProtocol {
    func getAllWindows() async throws -> [WindowInfo]
    func setWindowFrame(_ window: WindowInfo, frame: CGRect) async throws
    // ... other methods
}
```

### Dependency Injection
```swift
class DIContainer {
    func register<T>(_ type: T.Type, service: T)
    func resolve<T>(_ type: T.Type) throws -> T
}
```

### Observer Pattern
```swift
var windowUpdates: AnyPublisher<[WindowInfo], Never>
var focusedWindowUpdates: AnyPublisher<WindowInfo?, Never>
```

### Command Pattern
```swift
struct SnapAction {
    let type: SnapType
    let targetFrame: CGRect
    let keyboardShortcut: KeyboardShortcut?
}
```

### Strategy Pattern
```swift
enum SnapType {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeftQuarter, topRightQuarter
    // ... different snapping strategies
}
```

## 📁 Project Structure

```
MacSnapper/
├── MacSnapperApp.swift              # App entry point
├── Domain/                          # Business logic layer
│   ├── Entities/
│   │   ├── WindowInfo.swift         # Core window entity
│   │   └── SnapAction.swift         # Snap action entity
│   └── Protocols/
│       └── WindowRepositoryProtocol.swift # Repository contract
├── Application/                     # Use cases and services
│   ├── UseCases/
│   │   └── WindowManagementUseCase.swift # Main business logic
│   └── DependencyInjection/
│       └── DIContainer.swift        # Dependency management
├── Infrastructure/                  # External integrations
│   └── Services/
│       └── AccessibilityWindowRepository.swift # macOS integration
└── Presentation/                    # UI layer
    └── Views/
        ├── MainView.swift           # Main application window
        ├── WindowDetailView.swift   # Window management interface
        ├── MenuBarView.swift        # Menu bar quick actions
        └── SettingsView.swift       # App configuration
```

## 🚀 Getting Started

### Prerequisites
- macOS 14.0 or later
- Xcode 16.0 or later
- Swift 5.9 or later

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/MacSnap.git
cd MacSnap
   ```

2. **Open in Xcode**
   ```bash
   open MacSnap.xcodeproj
   ```

3. **Build and Run**
   - Select the Mac Snap target
   - Press `Cmd+R` to build and run

### First Launch Setup

1. **Grant Accessibility Permissions**
   - Mac Snap will prompt for accessibility permissions on first launch
   - Click "Grant Permissions" and follow the system prompts
   - Go to System Settings > Privacy & Security > Accessibility
   - Enable Mac Snap in the list

2. **Start Managing Windows**
   - Open some applications to see their windows in the sidebar
   - Select a window to see available snap actions
   - Use the menu bar for quick access to common operations

## 🎯 Usage

### Main Window Interface
- **Window List**: Browse all manageable windows with search
- **Detail View**: Select a window to see snapping options
- **Quick Actions**: Common operations like left/right half, maximize
- **Advanced Options**: Thirds, quarters, and custom positioning

### Menu Bar Quick Actions
- **Instant Access**: Right-click the menu bar icon for quick actions
- **Focused Window**: Snap the currently active window without opening the main app
- **Status Indicator**: Visual feedback on permission status

### Keyboard Shortcuts (Planned)
- `Cmd+Opt+←`: Snap left half
- `Cmd+Opt+→`: Snap right half
- `Cmd+Opt+↑`: Snap top half
- `Cmd+Opt+↓`: Snap bottom half
- `Cmd+Opt+F`: Maximize window
- `Cmd+Opt+C`: Center window

## 🧪 Testing

The architecture supports comprehensive testing through dependency injection:

```swift
// Example: Testing the use case with mocked dependencies
func testWindowSnapping() async {
    let mockRepository = MockWindowRepository()
    let mockScreenService = MockScreenService()
    let useCase = WindowManagementUseCase(
        windowRepository: mockRepository,
        screenService: mockScreenService
    )

    // Test business logic in isolation
    await useCase.snapWindow(testWindow, to: .leftHalf)

    XCTAssertTrue(mockRepository.setWindowFrameCalled)
}
```

## 🛡️ Error Handling

MacSnapper implements comprehensive error handling:

```swift
enum WindowRepositoryError: LocalizedError {
    case accessibilityPermissionsDenied
    case windowNotFound(String)
    case systemError(String)

    var errorDescription: String? { /* ... */ }
    var recoverySuggestion: String? { /* ... */ }
}
```

## 🔄 Future Enhancements

### Planned Features
- [ ] Customizable keyboard shortcuts
- [ ] Window arrangement presets
- [ ] Multi-monitor advanced positioning
- [ ] Window history and undo functionality
- [ ] Integration with Spaces and Mission Control
- [ ] Scripting API for automation

### Architecture Improvements
- [ ] Event Sourcing for window state changes
- [ ] CQRS pattern for complex queries
- [ ] Plugin architecture for custom snap behaviors
- [ ] Performance optimizations for large window counts

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Follow the architecture patterns** established in the codebase
3. **Write tests** for new functionality
4. **Update documentation** for any API changes
5. **Submit a pull request** with a clear description

### Code Style
- Follow Swift naming conventions
- Use MARK comments for organization
- Document public APIs with DocC comments
- Maintain the layered architecture boundaries

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by [Rectangle](https://rectangleapp.com/) and other great window managers
- Built with Apple's Accessibility APIs
- Architecture influenced by Clean Architecture principles by Uncle Bob
- SwiftUI design patterns from Apple's Human Interface Guidelines

---

**MacSnapper** - Professional window management for macOS developers and power users.
import Foundation
import CoreGraphics

/// Represents a window snapping action that can be performed
/// This is the core domain concept for window manipulation
public struct SnapAction: Identifiable, Equatable {

    // MARK: - Properties

    public let id = UUID()
    public let type: SnapType
    public let targetFrame: CGRect
    public let description: String
    public let keyboardShortcut: KeyboardShortcut?

    // MARK: - Initialization

    public init(
        type: SnapType,
        targetFrame: CGRect,
        description: String,
        keyboardShortcut: KeyboardShortcut? = nil
    ) {
        self.type = type
        self.targetFrame = targetFrame
        self.description = description
        self.keyboardShortcut = keyboardShortcut
    }
}

// MARK: - Supporting Types

/// Different types of window snapping operations
public enum SnapType: String, CaseIterable {
    case leftHalf = "left_half"
    case rightHalf = "right_half"
    case topHalf = "top_half"
    case bottomHalf = "bottom_half"
    case topLeftQuarter = "top_left_quarter"
    case topRightQuarter = "top_right_quarter"
    case bottomLeftQuarter = "bottom_left_quarter"
    case bottomRightQuarter = "bottom_right_quarter"
    case center = "center"
    case maximize = "maximize"
    case minimize = "minimize"
    case restore = "restore"
    case leftThird = "left_third"
    case centerThird = "center_third"
    case rightThird = "right_third"
    case leftTwoThirds = "left_two_thirds"
    case rightTwoThirds = "right_two_thirds"
    case custom = "custom"

    /// Human-readable description of the snap action
    public var displayName: String {
        switch self {
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .topHalf: return "Top Half"
        case .bottomHalf: return "Bottom Half"
        case .topLeftQuarter: return "Top Left Quarter"
        case .topRightQuarter: return "Top Right Quarter"
        case .bottomLeftQuarter: return "Bottom Left Quarter"
        case .bottomRightQuarter: return "Bottom Right Quarter"
        case .center: return "Center Window"
        case .maximize: return "Maximize"
        case .minimize: return "Minimize"
        case .restore: return "Restore"
        case .leftThird: return "Left Third"
        case .centerThird: return "Center Third"
        case .rightThird: return "Right Third"
        case .leftTwoThirds: return "Left Two Thirds"
        case .rightTwoThirds: return "Right Two Thirds"
        case .custom: return "Custom"
        }
    }

    /// SF Symbol icon name for the snap action
    public var iconName: String {
        switch self {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .topLeftQuarter: return "rectangle.topquarter.lefthalf.filled"
        case .topRightQuarter: return "rectangle.topquarter.righthalf.filled"
        case .bottomLeftQuarter: return "rectangle.bottomquarter.lefthalf.filled"
        case .bottomRightQuarter: return "rectangle.bottomquarter.righthalf.filled"
        case .center: return "rectangle.center.inset.filled"
        case .maximize: return "macwindow"
        case .minimize: return "minus.rectangle"
        case .restore: return "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left"
        case .leftThird: return "rectangle.split.1x3.fill"
        case .centerThird: return "rectangle.split.1x3.fill"
        case .rightThird: return "rectangle.split.1x3.fill"
        case .leftTwoThirds: return "rectangle.split.2x1.fill"
        case .rightTwoThirds: return "rectangle.split.2x1.fill"
        case .custom: return "rectangle.dashed"
        }
    }

    /// Unique ID for hotkey registration (safe for UInt32)
    public var uniqueID: UInt32 {
        switch self {
        case .leftHalf: return 1001
        case .rightHalf: return 1002
        case .topHalf: return 1003
        case .bottomHalf: return 1004
        case .topLeftQuarter: return 1005
        case .topRightQuarter: return 1006
        case .bottomLeftQuarter: return 1007
        case .bottomRightQuarter: return 1008
        case .center: return 1009
        case .maximize: return 1010
        case .minimize: return 1011
        case .restore: return 1012
        case .leftThird: return 1013
        case .centerThird: return 1014
        case .rightThird: return 1015
        case .leftTwoThirds: return 1016
        case .rightTwoThirds: return 1017
        case .custom: return 1018
        }
    }
}

/// Represents a keyboard shortcut for a snap action
public struct KeyboardShortcut: Equatable, Hashable {
    public let modifiers: EventModifiers
    public let key: KeyEquivalent

    public init(modifiers: EventModifiers, key: KeyEquivalent) {
        self.modifiers = modifiers
        self.key = key
    }
}

// MARK: - Convenience Types

public struct EventModifiers: OptionSet, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let command = EventModifiers(rawValue: 1 << 0)
    public static let option = EventModifiers(rawValue: 1 << 1)
    public static let control = EventModifiers(rawValue: 1 << 2)
    public static let shift = EventModifiers(rawValue: 1 << 3)
}

public struct KeyEquivalent: Hashable {
    public let character: Character

    public init(_ character: Character) {
        self.character = character
    }
}

// MARK: - Extensions

extension SnapAction {

    /// Creates a snap action for the given type and screen bounds
    public static func create(
        type: SnapType,
        screenBounds: CGRect,
        keyboardShortcut: KeyboardShortcut? = nil
    ) -> SnapAction {
        let targetFrame = calculateFrame(for: type, in: screenBounds)
        return SnapAction(
            type: type,
            targetFrame: targetFrame,
            description: type.displayName,
            keyboardShortcut: keyboardShortcut
        )
    }

    /// Calculates the target frame for a snap type within the given screen bounds
    private static func calculateFrame(for type: SnapType, in bounds: CGRect) -> CGRect {
        let width = bounds.width
        let height = bounds.height
        let x = bounds.minX
        let y = bounds.minY

        switch type {
        case .leftHalf:
            return CGRect(x: x, y: y, width: width / 2, height: height)
        case .rightHalf:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height)
        case .topHalf:
            return CGRect(x: x, y: y, width: width, height: height / 2)
        case .bottomHalf:
            return CGRect(x: x, y: y + height / 2, width: width, height: height / 2)
        case .topLeftQuarter:
            return CGRect(x: x, y: y, width: width / 2, height: height / 2)
        case .topRightQuarter:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height / 2)
        case .bottomLeftQuarter:
            return CGRect(x: x, y: y + height / 2, width: width / 2, height: height / 2)
        case .bottomRightQuarter:
            return CGRect(x: x + width / 2, y: y + height / 2, width: width / 2, height: height / 2)
        case .leftThird:
            return CGRect(x: x, y: y, width: width / 3, height: height)
        case .centerThird:
            return CGRect(x: x + width / 3, y: y, width: width / 3, height: height)
        case .rightThird:
            return CGRect(x: x + 2 * width / 3, y: y, width: width / 3, height: height)
        case .leftTwoThirds:
            return CGRect(x: x, y: y, width: 2 * width / 3, height: height)
        case .rightTwoThirds:
            return CGRect(x: x + width / 3, y: y, width: 2 * width / 3, height: height)
        case .center:
            let centerWidth = width * 0.8
            let centerHeight = height * 0.8
            return CGRect(
                x: x + (width - centerWidth) / 2,
                y: y + (height - centerHeight) / 2,
                width: centerWidth,
                height: centerHeight
            )
        case .maximize, .restore:
            return bounds
        case .minimize:
            return CGRect.zero
        case .custom:
            return bounds
        }
    }
}
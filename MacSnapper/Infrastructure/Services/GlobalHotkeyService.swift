import Foundation
import Combine
import AppKit
import Carbon

/// Service for managing global keyboard shortcuts
/// Real implementation using Carbon Event Manager for global hotkey registration
public final class GlobalHotkeyService: ObservableObject {

    // MARK: - Properties

    private let logger = Logger(category: "GlobalHotkeyService")
    private var registeredHotkeys: [SnapType: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    internal let hotkeyActionSubject = PassthroughSubject<SnapType, Never>()

    // Event monitoring for local monitoring fallback
    private var localEventMonitor: Any?

    // MARK: - Published Properties

    @Published public private(set) var isEnabled = false
    @Published public private(set) var registrationError: String?

    // MARK: - Public Interface

    /// Publisher that emits snap actions when hotkeys are triggered
    public var hotkeyActions: AnyPublisher<SnapType, Never> {
        hotkeyActionSubject.eraseToAnyPublisher()
    }

    /// Registers default hotkeys for window snapping
    public func registerDefaultHotkeys() {
        logger.info("Registering default hotkeys")

        let defaultHotkeys: [(SnapType, UInt32, UInt32)] = [
            // Basic snapping with Option+Command
            (.leftHalf, 123, UInt32(optionKey | cmdKey)),      // ⌥⌘ + Left Arrow
            (.rightHalf, 124, UInt32(optionKey | cmdKey)),     // ⌥⌘ + Right Arrow
            (.topHalf, 126, UInt32(optionKey | cmdKey)),       // ⌥⌘ + Up Arrow
            (.bottomHalf, 125, UInt32(optionKey | cmdKey)),    // ⌥⌘ + Down Arrow
            (.maximize, 3, UInt32(optionKey | cmdKey)),        // ⌥⌘ + F
            (.maximize, 36, UInt32(optionKey | cmdKey)),       // ⌥⌘ + Enter (Return)
            (.center, 8, UInt32(optionKey | cmdKey)),          // ⌥⌘ + C

            // Quarters
            (.topLeftQuarter, 18, UInt32(optionKey | cmdKey)),     // ⌥⌘ + 1
            (.topRightQuarter, 19, UInt32(optionKey | cmdKey)),    // ⌥⌘ + 2
            (.bottomLeftQuarter, 20, UInt32(optionKey | cmdKey)),  // ⌥⌘ + 3
            (.bottomRightQuarter, 21, UInt32(optionKey | cmdKey))  // ⌥⌘ + 4
        ]

        for (snapType, keyCode, modifiers) in defaultHotkeys {
            _ = registerHotkey(snapType: snapType, keyCode: keyCode, modifiers: modifiers)
        }

        isEnabled = !registeredHotkeys.isEmpty
        logger.info("Registered \(registeredHotkeys.count) default hotkeys")
    }

    /// Registers premium hotkeys (subscription required)
    public func registerPremiumHotkeys() {
        logger.info("Registering premium hotkeys")

        let premiumHotkeys: [(SnapType, UInt32, UInt32)] = [
            // Thirds with Option+Command
            (.leftThird, 12, UInt32(optionKey | cmdKey)),        // ⌥⌘ + Q
            (.centerThird, 13, UInt32(optionKey | cmdKey)),      // ⌥⌘ + W
            (.rightThird, 14, UInt32(optionKey | cmdKey)),       // ⌥⌘ + E
            (.leftTwoThirds, 0, UInt32(optionKey | cmdKey)),     // ⌥⌘ + A
            (.rightTwoThirds, 1, UInt32(optionKey | cmdKey))     // ⌥⌘ + S
        ]

        for (snapType, keyCode, modifiers) in premiumHotkeys {
            _ = registerHotkey(snapType: snapType, keyCode: keyCode, modifiers: modifiers)
        }

        logger.info("Registered \(premiumHotkeys.count) premium hotkeys")
    }

    /// Unregisters all hotkeys
    public func unregisterAllHotkeys() {
        logger.info("Unregistering all hotkeys")

        for (_, hotkey) in registeredHotkeys {
            UnregisterEventHotKey(hotkey)
        }

        registeredHotkeys.removeAll()
        isEnabled = false
    }

    /// Registers a custom hotkey
    public func registerCustomHotkey(snapType: SnapType, keyCode: UInt32, modifiers: UInt32) -> Bool {
        return registerHotkey(snapType: snapType, keyCode: keyCode, modifiers: modifiers)
    }

    /// Installs the global event handler
    public func installEventHandler() {
        logger.info("Installing global event handler")

        let eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        ]

        let callback: EventHandlerProcPtr = { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let service = Unmanaged<GlobalHotkeyService>.fromOpaque(userData).takeUnretainedValue()
            return service.handleHotkeyEvent(theEvent)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            eventTypes,
            selfPtr,
            &eventHandler
        )

        if status != noErr {
            logger.error("Failed to install event handler: \(status)")
            registrationError = "Failed to install global event handler"
            // Fallback to local monitoring
            installLocalEventMonitor()
        } else {
            logger.info("Global event handler installed successfully")
        }
    }

    /// Removes the global event handler
    public func removeEventHandler() {
        logger.info("Removing global event handler")

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }

        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }

        unregisterAllHotkeys()
    }

    // MARK: - Private Methods

    private func registerHotkey(snapType: SnapType, keyCode: UInt32, modifiers: UInt32) -> Bool {
        let hotkeyID = EventHotKeyID(signature: OSType(fourCharCode("SNAP")), id: snapType.uniqueID)
        var hotkeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status == noErr, let hotkey = hotkeyRef {
            registeredHotkeys[snapType] = hotkey
            logger.info("Registered hotkey for \(snapType.displayName)")
            return true
        } else {
            logger.error("Failed to register hotkey for \(snapType.displayName): \(status)")
            return false
        }
    }

    private func handleHotkeyEvent(_ event: EventRef?) -> OSStatus {
        guard let event = event else { return OSStatus(eventNotHandledErr) }

        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            OSType(kEventParamDirectObject),
            OSType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )

        guard status == noErr else {
            logger.error("Failed to get hotkey ID: \(status)")
            return OSStatus(eventNotHandledErr)
        }

        // Find the snap type for this hotkey ID
        for (snapType, _) in registeredHotkeys {
            let expectedID = EventHotKeyID(signature: OSType(fourCharCode("SNAP")), id: snapType.uniqueID)

            if hotkeyID.signature == expectedID.signature && hotkeyID.id == expectedID.id {
                logger.info("Hotkey triggered for \(snapType.displayName)")
                DispatchQueue.main.async {
                    self.hotkeyActionSubject.send(snapType)
                }
                return noErr
            }
        }

        return OSStatus(eventNotHandledErr)
    }

    private func installLocalEventMonitor() {
        logger.info("Installing local event monitor as fallback")

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self else { return event }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let keyCode = event.keyCode

            // Check if this matches any registered hotkeys
            if modifiers.contains([.option, .command]) {
                let snapType = self.getSnapTypeForKeyCode(keyCode)
                if let snapType = snapType, self.registeredHotkeys.keys.contains(snapType) {
                    self.logger.info("Local hotkey triggered for \(snapType.displayName)")
                    self.hotkeyActionSubject.send(snapType)
                    return nil // Consume the event
                }
            }

            return event
        }
    }

    private func getSnapTypeForKeyCode(_ keyCode: UInt16) -> SnapType? {
        switch keyCode {
        case 123: return .leftHalf      // Left Arrow
        case 124: return .rightHalf     // Right Arrow
        case 126: return .topHalf       // Up Arrow
        case 125: return .bottomHalf    // Down Arrow
        case 3: return .maximize        // F
        case 36: return .maximize       // Enter/Return
        case 8: return .center          // C
        case 18: return .topLeftQuarter     // 1
        case 19: return .topRightQuarter    // 2
        case 20: return .bottomLeftQuarter  // 3
        case 21: return .bottomRightQuarter // 4
        case 12: return .leftThird      // Q
        case 13: return .centerThird    // W
        case 14: return .rightThird     // E
        case 0: return .leftTwoThirds   // A
        case 1: return .rightTwoThirds  // S
        default: return nil
        }
    }

    private func fourCharCode(_ string: String) -> FourCharCode {
        let utf8 = string.utf8
        var result: FourCharCode = 0
        for (i, byte) in utf8.enumerated() {
            result += FourCharCode(byte) << (8 * (3 - i))
            if i >= 3 { break }
        }
        return result
    }
}

// MARK: - Logger

private struct Logger {
    let category: String

    func debug(_ message: String) {
        print("🔍 [\(category)] \(message)")
    }

    func info(_ message: String) {
        print("ℹ️ [\(category)] \(message)")
    }

    func warning(_ message: String) {
        print("⚠️ [\(category)] \(message)")
    }

    func error(_ message: String) {
        print("❌ [\(category)] \(message)")
    }
}
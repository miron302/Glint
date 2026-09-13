import Carbon
import AppKit

/// Registers a system-wide hotkey with the classic Carbon Event Manager API.
/// This deliberately avoids Accessibility permissions and CGEventTap — it's
/// the same lightweight mechanism apps have used for global shortcuts for
/// two decades, and it keeps Glint's permission footprint minimal.
final class HotkeyManager {

    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var onTrigger: (() -> Void)?

    private let hotKeyID = EventHotKeyID(signature: OSType(0x474C4E54), id: 1) // 'GLNT'

    func register(keyCode: UInt32, modifiers: UInt32, onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        unregister()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.onTrigger?()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}

/// Helper for the settings UI: captures the next key combo the user presses
/// so they can bind any shortcut without typing key codes by hand.
final class HotkeyRecorder {
    static func recordNextKeyPress(completion: @escaping (UInt32, UInt32) -> Void) -> Any? {
        return NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let carbonModifiers = carbonFlags(from: event.modifierFlags)
            completion(UInt32(event.keyCode), carbonModifiers)
            return nil
        }
    }

    static func carbonFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(commandMask) }
        if flags.contains(.option) { result |= UInt32(optionMask) }
        if flags.contains(.shift) { result |= UInt32(shiftMask) }
        if flags.contains(.control) { result |= UInt32(controlMask) }
        return result
    }

    /// Human readable label like "⌥ Space" for display in settings.
    static func label(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & UInt32(controlMask) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionMask) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftMask) != 0 { parts.append("⇧") }
        if modifiers & UInt32(commandMask) != 0 { parts.append("⌘") }
        parts.append(keyName(for: keyCode))
        return parts.joined()
    }

    private static func keyName(for keyCode: UInt32) -> String {
        let map: [UInt32: String] = [
            49: "Space", 36: "Return", 48: "Tab", 53: "Escape",
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J",
            40: "K", 45: "N", 46: "M", 18: "1", 19: "2", 20: "3", 21: "4",
            23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0"
        ]
        return map[keyCode] ?? "Key \(keyCode)"
    }
}

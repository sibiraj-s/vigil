import AppKit
import Carbon.HIToolbox

/// A global keyboard shortcut that starts, or ends, a session.
struct Shortcut: Identifiable, Codable, Hashable {
    var id = UUID()
    /// The preset to toggle; `nil` toggles the last-used session.
    var preset: Preset?
    /// Carbon virtual key code; `nil` until the user records keys.
    var keyCode: Int?
    /// Carbon modifier mask (`cmdKey`, `optionKey`, …).
    var modifiers = 0
    /// The key's printed name, e.g. "0" or "F5".
    var keyName = ""

    /// Presets a shortcut can start. "While an app runs…" needs a choice, so it stays menu-only.
    static let presets: [Preset] = Preset.allCases.filter { $0 != .whileApp }

    static let defaults: [Shortcut] = [
        Shortcut(preset: .indefinitely, keyCode: kVK_ANSI_0, modifiers: cmdKey | optionKey, keyName: "0"),
        Shortcut(preset: .hour1, keyCode: kVK_ANSI_1, modifiers: cmdKey | optionKey, keyName: "1"),
    ]

    /// e.g. "⌥⌘0", or `nil` when no keys are recorded.
    var display: String? {
        guard keyCode != nil else { return nil }
        var text = ""
        if modifiers & controlKey != 0 { text += "⌃" }
        if modifiers & optionKey != 0 { text += "⌥" }
        if modifiers & shiftKey != 0 { text += "⇧" }
        if modifiers & cmdKey != 0 { text += "⌘" }
        return text + keyName
    }

    var actionLabel: String {
        guard let preset else { return "Start or end last session" }
        switch preset {
        case .untilTime: return "Until last chosen time"
        case .whileDownloading: return "While a download finishes"
        default: return preset.label
        }
    }

    func hasSameKeys(as other: Shortcut) -> Bool {
        keyCode != nil && keyCode == other.keyCode && modifiers == other.modifiers
    }

    // MARK: - Recording

    static func carbonModifiers(_ flags: NSEvent.ModifierFlags) -> Int {
        var mask = 0
        if flags.contains(.command) { mask |= cmdKey }
        if flags.contains(.option) { mask |= optionKey }
        if flags.contains(.control) { mask |= controlKey }
        if flags.contains(.shift) { mask |= shiftKey }
        return mask
    }

    static let functionKeys: [Int: String] = [
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        kVK_F13: "F13", kVK_F14: "F14", kVK_F15: "F15", kVK_F16: "F16", kVK_F17: "F17", kVK_F18: "F18",
        kVK_F19: "F19", kVK_F20: "F20",
    ]

    static func keyName(for event: NSEvent) -> String {
        let code = Int(event.keyCode)
        if let name = functionKeys[code] { return name }
        switch code {
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_ForwardDelete: return "⌦"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        // Not charactersIgnoringModifiers: it keeps Shift, so ⇧⌘1 would read ⇧⌘!.
        default: return event.characters(byApplyingModifiers: [])?.uppercased() ?? "?"
        }
    }
}

import AppKit
import Carbon.HIToolbox
import Testing
@testable import Vigil

struct ShortcutTests {
    @Test func displayListsModifiersInMacOSOrder() {
        let shortcut = Shortcut(keyCode: kVK_ANSI_K, modifiers: cmdKey | shiftKey | optionKey | controlKey, keyName: "K")
        #expect(shortcut.display == "⌃⌥⇧⌘K")
        #expect(Shortcut(keyCode: kVK_F5, keyName: "F5").display == "F5")
    }

    @Test func displayIsNilWithoutKeys() {
        #expect(Shortcut(preset: .hour1).display == nil)
    }

    @Test func sameKeysNeedsRecordedKeys() {
        let a = Shortcut(preset: .hour1, keyCode: kVK_ANSI_1, modifiers: cmdKey | optionKey, keyName: "1")
        let b = Shortcut(preset: .hours2, keyCode: kVK_ANSI_1, modifiers: cmdKey | optionKey, keyName: "1")
        let shifted = Shortcut(keyCode: kVK_ANSI_1, modifiers: cmdKey | optionKey | shiftKey, keyName: "1")
        #expect(a.hasSameKeys(as: b))
        #expect(!a.hasSameKeys(as: shifted))
        // Two rows with no keys yet don't clash.
        #expect(!Shortcut(preset: .hour1).hasSameKeys(as: Shortcut(preset: .hours2)))
    }

    @Test func carbonModifiersMapEveryFlag() {
        #expect(Shortcut.carbonModifiers([]) == 0)
        #expect(Shortcut.carbonModifiers([.command, .option]) == cmdKey | optionKey)
        #expect(Shortcut.carbonModifiers([.control, .shift, .capsLock]) == controlKey | shiftKey)
    }

    @Test func presetsLeaveOutTheOneThatNeedsAnApp() {
        #expect(!Shortcut.presets.contains(.whileApp))
        #expect(Shortcut.presets.contains(.untilTime))
    }

    @Test func defaultsDontClash() {
        let defaults = Shortcut.defaults
        for (i, a) in defaults.enumerated() {
            for b in defaults[(i + 1)...] { #expect(!a.hasSameKeys(as: b)) }
        }
    }
}

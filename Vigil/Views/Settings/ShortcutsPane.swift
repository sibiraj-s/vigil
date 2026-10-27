import AppKit
import Carbon.HIToolbox
import SwiftUI

struct ShortcutsPane: View {
    @Environment(AwakeController.self) private var awake

    var body: some View {
        @Bindable var prefs = awake.prefs
        PaneScroll {
            PaneHeader(title: "Shortcuts", subtitle: "Work from any app. Press a shortcut again to end its session.") {
                Button {
                    prefs.shortcuts.append(Shortcut(preset: unusedPreset))
                } label: {
                    HStack(spacing: 6) {
                        DesignIconView(.plus)
                        Text("Add shortcut")
                    }
                }
                .buttonStyle(OutlineButtonStyle())
            }

            Card {
                if prefs.shortcuts.isEmpty {
                    Text("No shortcuts yet.")
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                }
                ForEach(prefs.shortcuts) { shortcut in
                    ShortcutRow(shortcut: binding(for: shortcut), problem: problem(for: shortcut)) {
                        prefs.shortcuts.removeAll { $0.id == shortcut.id }
                    }
                    if shortcut.id != prefs.shortcuts.last?.id { CardDivider() }
                }
            }

            Text("Click a shortcut to record new keys. Press Esc to cancel, or ⌫ to clear it.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
        }
        .onChange(of: prefs.shortcuts) { awake.registerHotKeys() }
    }

    /// Looks the row up by id. `ForEach($array)` bindings hold an index, which a removed row's
    /// views still read while disappearing, trapping with "Index out of range".
    private func binding(for shortcut: Shortcut) -> Binding<Shortcut> {
        let prefs = awake.prefs
        return Binding {
            prefs.shortcuts.first { $0.id == shortcut.id } ?? shortcut
        } set: { newValue in
            guard let index = prefs.shortcuts.firstIndex(where: { $0.id == shortcut.id }) else { return }
            prefs.shortcuts[index] = newValue
        }
    }

    /// The first preset without a shortcut, so new rows start somewhere useful.
    private var unusedPreset: Preset? {
        Shortcut.presets.first { preset in !awake.prefs.shortcuts.contains { $0.preset == preset } }
    }

    private func problem(for shortcut: Shortcut) -> String? {
        let others = awake.prefs.shortcuts.filter { $0.id != shortcut.id }
        if others.contains(where: { $0.hasSameKeys(as: shortcut) }) { return "Used by another shortcut" }
        if awake.unavailableShortcuts.contains(shortcut.id) { return "macOS refused this shortcut" }
        return nil
    }
}

private struct ShortcutRow: View {
    @Binding var shortcut: Shortcut
    let problem: String?
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // A native pop-up: custom-styled menus don't draw their items reliably in dark mode.
            Picker("Action", selection: $shortcut.preset) {
                Text("Start or end last session").tag(Preset?.none)
                Divider()
                ForEach(Shortcut.presets) { preset in
                    Text(Shortcut(preset: preset).actionLabel).tag(Optional(preset))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(Color.primary)
            .frame(width: 210, alignment: .leading)

            Spacer(minLength: 0)

            if let problem {
                Text(problem)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.accentDeep)
            }

            ShortcutRecorder(shortcut: $shortcut)

            Button(action: onDelete) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Remove shortcut")
            .accessibilityLabel("Remove shortcut")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

/// Click, then press a key combination to record it.
private struct ShortcutRecorder: View {
    @Environment(AwakeController.self) private var awake
    @Binding var shortcut: Shortcut
    @State private var monitor: Any?

    /// Lives on the controller, so starting another recorder ends this one.
    private var recording: Bool { awake.recordingShortcut == shortcut.id }

    var body: some View {
        Button {
            recording ? stop() : start()
        } label: {
            Text(label)
                .font(.system(size: 12, weight: shortcut.display == nil || recording ? .regular : .medium))
                .foregroundStyle(recording ? Theme.accentText : shortcut.display == nil ? Theme.textSecondary : Theme.text)
                .frame(minWidth: 96)
                .frame(height: 26)
                .padding(.horizontal, 8)
                .fieldBackground(highlighted: recording)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(shortcut.display.map { "Shortcut \($0)" } ?? "Record shortcut")
        .onChange(of: recording) { _, isRecording in isRecording ? installMonitor() : removeMonitor() }
        // Key events stop arriving once focus leaves, so end the recording rather than leave shortcuts paused.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            if recording { stop() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            if recording { stop() }
        }
        .onDisappear {
            if recording { stop() }
            removeMonitor()
        }
    }

    private var label: String {
        if recording { return "Type shortcut…" }
        return shortcut.display ?? "Record shortcut"
    }

    private func start() {
        awake.recordingShortcut = shortcut.id
    }

    private func stop() {
        awake.recordingShortcut = nil
    }

    private func installMonitor() {
        removeMonitor()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil
        }
    }

    private func removeMonitor() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    private func handle(_ event: NSEvent) {
        let code = Int(event.keyCode)
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])

        if code == kVK_Escape, flags.isEmpty { return stop() }
        if code == kVK_Delete, flags.isEmpty {
            shortcut.keyCode = nil
            shortcut.modifiers = 0
            shortcut.keyName = ""
            return stop()
        }

        // Plain keys would fire while typing anywhere; require ⌘, ⌥ or ⌃ (function keys are fine alone).
        let isFunctionKey = Shortcut.functionKeys[code] != nil
        guard isFunctionKey || !flags.isDisjoint(with: [.command, .option, .control]) else {
            NSSound.beep()
            return
        }

        shortcut.keyCode = code
        shortcut.modifiers = Shortcut.carbonModifiers(flags)
        shortcut.keyName = Shortcut.keyName(for: event)
        stop()
    }
}

import AppKit
import SwiftUI

/// The panel that drops down from the menu bar icon.
struct MenuContentView: View {
    @Environment(AwakeController.self) private var awake
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    @State private var page = Page.main

    enum Page {
        case main, untilTime, pickApp
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            switch page {
            case .main: mainPage
            case .untilTime: UntilTimePage(page: $page)
            case .pickApp: PickAppPage(page: $page)
            }
        }
        .padding(5)
        .frame(width: 288)
        .font(.system(size: 12))
        .foregroundStyle(Theme.text)
        .background(Theme.panel)
        .tint(Theme.accent)
    }

    @ViewBuilder
    private var mainPage: some View {
        StatusHeader()

        MenuDivider(vertical: 0)

        SectionLabel("Keep awake")
        ForEach(Preset.allCases) { preset in
            PresetRow(preset: preset) {
                if preset.needsInput {
                    page = preset == .untilTime ? .untilTime : .pickApp
                } else {
                    awake.start(preset)
                }
            }
        }

        MenuDivider()

        Button {
            awake.prefs.letDisplaySleep.toggle()
            awake.evaluate()
        } label: {
            MenuRowLabel("Let the display sleep") {
                SwitchTrack(isOn: awake.prefs.letDisplaySleep, compact: true)
            }
        }
        .buttonStyle(MenuItemStyle(height: 28))
        .accessibilityValue(awake.prefs.letDisplaySleep ? "On" : "Off")

        Button {
            showSettings(.triggers)
        } label: {
            MenuRowLabel("Triggers") {
                Text("\(awake.enabledTriggerCount) on ›").font(.system(size: 11)).foregroundStyle(Theme.textTertiary)
            }
        }
        .buttonStyle(MenuItemStyle())

        MenuDivider()

        Button {
            showSettings(nil)
        } label: {
            MenuRowLabel("Settings…") { ShortcutHint("⌘,") }
        }
        .buttonStyle(MenuItemStyle())
        .keyboardShortcut(",", modifiers: .command)

        Button {
            dismiss()
            Updater.shared.checkNow()
        } label: {
            MenuRowLabel("Check for Updates…") { EmptyView() }
        }
        .buttonStyle(MenuItemStyle())
        .disabled(Updater.shared.isEnabled && !Updater.shared.canCheck)

        Button {
            NSApp.terminate(nil)
        } label: {
            MenuRowLabel("Quit Vigil") { ShortcutHint("⌘Q") }
        }
        .buttonStyle(MenuItemStyle())
        .keyboardShortcut("q", modifiers: .command)
    }

    private func showSettings(_ pane: SettingsPane?) {
        if let pane { awake.settingsPane = pane }
        // Close the panel first; it would otherwise stay open over the settings window.
        dismiss()
        openWindow(id: SettingsView.windowID)
        NSApp.activate()
        // Activation is only a request and can lose to the frontmost app, so raise the window
        // explicitly once it exists.
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue.hasPrefix(SettingsView.windowID) == true }) else { return }
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }
}

// MARK: - Header

private struct StatusHeader: View {
    @Environment(AwakeController.self) private var awake

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(awake.isAwake ? Theme.accent : Theme.neutralFill)
                    .frame(width: 32, height: 32)
                    .overlay {
                        EyeView(glyph: .open, color: awake.isAwake ? .white : Theme.textTertiary)
                            .frame(width: 20, height: 14)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .semibold))
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Button(buttonTitle) {
                awake.toggle(nil)
            }
            .buttonStyle(ProminentStyle(filled: !awake.isAwake))
            .disabled(!awake.isAwake && awake.batteryGuardTripped)
        }
        .padding(EdgeInsets(top: 10, leading: 11, bottom: 12, trailing: 11))
    }

    private var buttonTitle: String {
        if awake.isAwake { return "End session" }
        return awake.pausedTriggers.isEmpty ? "Start session" : "Resume trigger"
    }

    private var title: String {
        awake.isAwake ? "Mac is staying awake" : "Mac sleeps normally"
    }

    private var subtitle: String {
        if let session = awake.session {
            switch session.preset {
            case .indefinitely:
                return "No time limit"
            case .untilTime:
                guard let end = session.endDate else { return "" }
                let day = Calendar.current.isDateInToday(end) ? "today" : "tomorrow"
                return "Until \(end.formatted(date: .omitted, time: .shortened)) \(day)"
            case .whileApp:
                return "While \(session.app?.name ?? "the app") is running"
            case .whileDownloading:
                return "Until ~/Downloads stops changing"
            default:
                guard let end = session.endDate, let remaining = awake.remaining else { return "" }
                return "\(Self.longDuration(remaining)) left · until \(end.formatted(date: .omitted, time: .shortened))"
            }
        }
        if let trigger = awake.activeTriggers.first {
            return trigger.shortTitle
        }
        if awake.batteryGuardTripped {
            return "Paused · battery below \(awake.prefs.batteryGuardThreshold)%"
        }
        if let trigger = awake.pausedTriggers.first {
            return "Paused · \(trigger.shortTitle)"
        }
        return "Following your Energy settings"
    }

    static func longDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded(.up))
        if minutes < 60 { return "\(minutes) min" }
        let rest = minutes % 60
        return rest == 0 ? "\(minutes / 60) h" : "\(minutes / 60) h \(rest) min"
    }
}

// MARK: - Rows

private struct PresetRow: View {
    @Environment(AwakeController.self) private var awake
    let preset: Preset
    let action: () -> Void

    var body: some View {
        let selected = awake.session?.preset == preset
        Button(action: action) {
            HStack(spacing: 8) {
                DesignIconView(.check)
                    .frame(width: 14)
                    .opacity(selected ? 1 : 0)
                Text(preset.label)
                Spacer(minLength: 8)
                Text(hint)
                    .font(.system(size: 11))
                    .foregroundStyle(selected ? Color.white.opacity(0.85) : Theme.textTertiary)
            }
        }
        .buttonStyle(MenuItemStyle(selected: selected))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var hint: String {
        switch preset {
        case .untilTime: awake.prefs.lastUntilTime.formatted(date: .omitted, time: .shortened)
        case .whileApp: awake.prefs.lastApp?.name ?? ""
        default:
            // Only advertise keys that actually work.
            awake.prefs.shortcuts.first {
                $0.preset == preset && $0.keyCode != nil && !awake.unavailableShortcuts.contains($0.id)
            }?.display ?? ""
        }
    }
}

/// A row label indented to line up with the preset rows' text.
private struct MenuRowLabel<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: Trailing

    init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            trailing
        }
        .padding(.leading, 21)
    }
}

private struct ShortcutHint: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text).font(.system(size: 11)).foregroundStyle(Theme.textTertiary)
    }
}

private struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.44)
            .foregroundStyle(Theme.textTertiary)
            .padding(EdgeInsets(top: 6, leading: 11, bottom: 3, trailing: 11))
            .accessibilityAddTraits(.isHeader)
    }
}

private struct MenuDivider: View {
    var vertical: CGFloat = 1

    var body: some View {
        Rectangle()
            .fill(Theme.divider)
            .frame(height: 1)
            .padding(.horizontal, 8)
            .padding(.vertical, vertical)
    }
}

// MARK: - Sub-pages

private struct SubpageHeader: View {
    let title: String
    @Binding var page: MenuContentView.Page

    var body: some View {
        HStack(spacing: 6) {
            Button {
                page = .main
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 11, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .keyboardShortcut(.cancelAction)
            Text(title).font(.system(size: 13, weight: .semibold))
        }
        .padding(EdgeInsets(top: 6, leading: 5, bottom: 6, trailing: 11))
    }
}

private struct UntilTimePage: View {
    @Environment(AwakeController.self) private var awake
    @Binding var page: MenuContentView.Page
    @State private var time = Date.now

    var body: some View {
        SubpageHeader(title: "Keep awake until", page: $page)
        VStack(alignment: .leading, spacing: 10) {
            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.field)
                .labelsHidden()
            Text(summary).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            Button("Start session") {
                awake.start(.untilTime, until: time)
                page = .main
            }
            .buttonStyle(ProminentStyle(filled: true))
            .keyboardShortcut(.defaultAction)
        }
        .padding(EdgeInsets(top: 0, leading: 11, bottom: 10, trailing: 11))
        .onAppear { time = awake.prefs.lastUntilTime }
    }

    private var summary: String {
        let end = AwakeController.nextOccurrence(of: time, after: .now)
        let day = Calendar.current.isDateInToday(end) ? "today" : "tomorrow"
        return "Stays awake until \(end.formatted(date: .omitted, time: .shortened)) \(day)."
    }
}

private struct PickAppPage: View {
    @Environment(AwakeController.self) private var awake
    @Binding var page: MenuContentView.Page
    @State private var apps: [AppRef] = []

    var body: some View {
        SubpageHeader(title: "While an app runs", page: $page)
        ScrollView {
            VStack(spacing: 2) {
                ForEach(apps) { app in
                    Button {
                        awake.start(.whileApp, app: app)
                        page = .main
                    } label: {
                        HStack(spacing: 8) {
                            Image(nsImage: SystemProbe.icon(for: app))
                                .resizable()
                                .frame(width: 18, height: 18)
                            Text(app.name)
                            Spacer()
                        }
                    }
                    .buttonStyle(MenuItemStyle())
                }
            }
        }
        .frame(maxHeight: 320)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { apps = SystemProbe.runningRegularApps() }
    }
}

// MARK: - Styles

/// Menu-like row: highlights on hover, filled with the accent when selected.
struct MenuItemStyle: ButtonStyle {
    var selected = false
    var height: CGFloat = 26

    func makeBody(configuration: Configuration) -> some View {
        MenuItemBody(configuration: configuration, selected: selected, height: height)
    }

    private struct MenuItemBody: View {
        let configuration: Configuration
        let selected: Bool
        let height: CGFloat
        @State private var hovering = false
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .foregroundStyle(selected ? Color.white : Theme.text)
                .padding(.horizontal, 11)
                .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(fill))
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
                .opacity(isEnabled ? 1 : 0.4)
        }

        private var fill: Color {
            if selected { return Theme.accent }
            if configuration.isPressed { return Theme.pressed }
            return hovering && isEnabled ? Theme.hover : .clear
        }
    }
}

/// Full-width 32pt button; accent-filled to start, neutral to end.
struct ProminentStyle: ButtonStyle {
    var filled: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(filled ? Color.white : Theme.text)
            .frame(maxWidth: .infinity, minHeight: 29)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(filled ? Theme.accent : Theme.neutralFill)
            )
            .opacity(configuration.isPressed ? 0.8 : isEnabled ? 1 : 0.5)
            .contentShape(Rectangle())
    }
}

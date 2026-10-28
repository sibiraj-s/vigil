import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    static let windowID = "settings"

    @Environment(AwakeController.self) private var awake

    var body: some View {
        HStack(spacing: 0) {
            Sidebar()
            Group {
                switch awake.settingsPane {
                case .general: GeneralPane()
                case .triggers: TriggersPane()
                case .power: PowerPane()
                case .shortcuts: ShortcutsPane()
                case .about: AboutPane()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        // No window-wide text color: native menus would inherit it unresolved for dark mode.
        .font(.system(size: 12))
        .background(Theme.window)
        .toggleStyle(DesignSwitchStyle())
        .tint(Theme.accent)
        // Fill the whole window, including the area under the hidden title bar.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .frame(width: 720, height: 486)
    }
}

private struct Sidebar: View {
    @Environment(AwakeController.self) private var awake

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(SettingsPane.allCases) { pane in
                let selected = awake.settingsPane == pane
                Button {
                    awake.settingsPane = pane
                } label: {
                    HStack(spacing: 9) {
                        DesignIconView(pane.icon)
                        Text(pane.title)
                    }
                    .font(.system(size: 12, weight: selected ? .medium : .regular))
                    .foregroundStyle(selected ? Color.white : Theme.text)
                    .padding(.horizontal, 9)
                    .frame(maxWidth: .infinity, minHeight: 27, alignment: .leading)
                    .background(selected ? Theme.accent : .clear, in: RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
            Spacer()
        }
        // Leaves room for the window's close/minimize/zoom buttons, which sit in the sidebar.
        .padding(.top, 40)
        .padding(.horizontal, 9)
        .frame(width: 180)
        .frame(maxHeight: .infinity)
        .background(Theme.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Theme.sidebarBorder).frame(width: 1)
        }
    }
}

// MARK: - Shared pieces

struct PaneHeader<Accessory: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 18, weight: .bold))
                Text(subtitle).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            accessory
        }
    }
}

extension PaneHeader where Accessory == EmptyView {
    init(title: String, subtitle: String) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.cardBorder))
    }
}

struct CardDivider: View {
    var body: some View {
        Rectangle().fill(Theme.rowDivider).frame(height: 1)
    }
}

struct CardRow<Trailing: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

/// The design's outlined secondary button.
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 11)
            .frame(height: 27)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(configuration.isPressed ? Theme.sidebar : Theme.outlineButton)
            )
            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Theme.outlineBorder))
            .contentShape(Rectangle())
    }
}

/// The design's accent-filled primary button.
struct FilledButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isEnabled ? Color.white : Theme.textTertiary)
            .padding(.horizontal, 12)
            .frame(height: 27)
            .background(RoundedRectangle(cornerRadius: 7).fill(isEnabled ? Theme.accent : Theme.neutralFill))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .contentShape(Rectangle())
    }
}

struct PaneScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
        }
        .scrollIndicators(.automatic)
    }
}

// MARK: - Panes

private struct GeneralPane: View {
    @Environment(AwakeController.self) private var awake
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?
    @Bindable private var updater = Updater.shared

    var body: some View {
        @Bindable var prefs = awake.prefs
        PaneScroll {
            PaneHeader(title: "General", subtitle: "How Vigil starts and shows itself.")
            Card {
                CardRow(title: "Appearance", subtitle: "Match your Mac, or always use light or dark.") {
                    Picker("Appearance", selection: $prefs.appearance) {
                        ForEach(AppearanceMode.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                }
                CardDivider()
                CardRow(title: "Open at login", subtitle: loginError ?? "Start Vigil when you log in to your Mac.") {
                    Toggle("Open at login", isOn: $launchAtLogin).labelsHidden()
                }
                CardDivider()
                CardRow(title: "Show remaining time", subtitle: "Count down timed sessions next to the menu bar icon.") {
                    Toggle("Show remaining time", isOn: $prefs.showRemainingTime).labelsHidden()
                }
                CardDivider()
                CardRow(title: "Let the display sleep", subtitle: "During manual sessions, keep the Mac awake but let the screen turn off and the screen saver start.") {
                    Toggle("Let the display sleep", isOn: $prefs.letDisplaySleep).labelsHidden()
                }
                CardDivider()
                CardRow(title: "End session stops", subtitle: "Whether ending a session also pauses triggers that are keeping the Mac awake.") {
                    Picker("End session stops", selection: $prefs.endBehavior) {
                        ForEach(EndBehavior.allCases) { Text($0.label).tag($0) }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
                CardDivider()
                // Shown, but off, in builds that can't update, so the layout can be checked in Debug.
                CardRow(
                    title: "Check for updates automatically",
                    subtitle: updater.isEnabled
                        ? "Look for a new version once a day and offer to install it."
                        : "Not available in this build."
                ) {
                    Toggle("Check for updates automatically", isOn: updater.isEnabled ? $updater.automaticallyChecks : .constant(false))
                        .labelsHidden()
                        .disabled(!updater.isEnabled)
                }
            }
        }
        .onChange(of: launchAtLogin) { _, enabled in
            do {
                if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                loginError = nil
            } catch {
                loginError = error.localizedDescription
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
        .onChange(of: prefs.letDisplaySleep) { awake.evaluate() }
        .onChange(of: prefs.appearance) { awake.applyAppearance() }
    }
}

private struct PowerPane: View {
    @Environment(AwakeController.self) private var awake

    var body: some View {
        @Bindable var prefs = awake.prefs
        PaneScroll {
            PaneHeader(title: "Battery & Power", subtitle: "Protect your battery while Vigil keeps the Mac awake.")
            Card {
                CardRow(
                    title: "Battery guard",
                    subtitle: "End any session when battery drops below \(prefs.batteryGuardThreshold)% and the charger is unplugged."
                ) {
                    Toggle("Battery guard", isOn: $prefs.batteryGuardEnabled).labelsHidden()
                }
                CardDivider()
                HStack(spacing: 12) {
                    Text("Threshold")
                    Slider(
                        value: Binding(
                            get: { Double(prefs.batteryGuardThreshold) },
                            set: { prefs.batteryGuardThreshold = Int($0) }
                        ),
                        in: 5...50,
                        step: 5
                    )
                    Text("\(prefs.batteryGuardThreshold)%")
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .disabled(!prefs.batteryGuardEnabled)
            }
            if let battery = SystemProbe.battery() {
                Text("Battery is at \(battery.percent)%, \(battery.onBattery ? "on battery power" : "on power adapter").")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .onChange(of: prefs.batteryGuardEnabled) { awake.evaluate() }
        .onChange(of: prefs.batteryGuardThreshold) { awake.evaluate() }
    }
}


private struct AboutPane: View {
    private let updater = Updater.shared

    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.accent)
                .frame(width: 72, height: 72)
                .overlay { EyeView(glyph: .open, color: .white).frame(width: 44) }
            Text("Vigil").font(.system(size: 18, weight: .bold))
            Text("Version \(Self.version)").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            Text("Keeps your Mac awake for as long as you need.")
                .foregroundStyle(Theme.textSecondary)
            Button(updater.isEnabled ? "Check for Updates…" : "Releases") { updater.checkNow() }
                .buttonStyle(OutlineButtonStyle())
                .disabled(updater.isEnabled && !updater.canCheck)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct TriggersPane: View {
    @Environment(AwakeController.self) private var awake
    @State private var editing: Trigger?

    var body: some View {
        @Bindable var prefs = awake.prefs
        PaneScroll {
            PaneHeader(title: "Triggers", subtitle: "Start a session automatically when any enabled condition is true.") {
                Button {
                    editing = Trigger(condition: .apps([]))
                } label: {
                    HStack(spacing: 6) {
                        DesignIconView(.plus)
                        Text("New trigger")
                    }
                }
                .buttonStyle(OutlineButtonStyle())
            }

            Card {
                if prefs.triggers.isEmpty {
                    Text("No triggers yet.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                }
                ForEach($prefs.triggers) { $trigger in
                    TriggerRow(trigger: $trigger, isActive: awake.isActive(trigger)) {
                        editing = trigger
                    } onDelete: {
                        prefs.triggers.removeAll { $0.id == trigger.id }
                    }
                    if trigger.id != prefs.triggers.last?.id { CardDivider() }
                }
            }

            Card {
                CardRow(
                    title: "Battery guard",
                    subtitle: "End any session when battery drops below \(prefs.batteryGuardThreshold)% and the charger is unplugged."
                ) {
                    Toggle("Battery guard", isOn: $prefs.batteryGuardEnabled).labelsHidden()
                }
            }
        }
        .sheet(item: $editing) { trigger in
            TriggerEditor(
                trigger: trigger,
                isNew: !prefs.triggers.contains { $0.id == trigger.id },
                others: prefs.triggers.filter { $0.id != trigger.id }
            ) { saved in
                if let index = prefs.triggers.firstIndex(where: { $0.id == saved.id }) {
                    prefs.triggers[index] = saved
                } else {
                    prefs.triggers.append(saved)
                }
                if saved.enabled, saved.condition.kind == .wifi {
                    LocationAccess.shared.requestIfNeeded()
                }
            }
        }
        .onChange(of: prefs.triggers) { awake.evaluate() }
        .onChange(of: prefs.batteryGuardEnabled) { awake.evaluate() }
    }
}

private struct TriggerRow: View {
    @Binding var trigger: Trigger
    let isActive: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onEdit) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(trigger.enabled ? Theme.accentSoft : Theme.sidebar)
                        .frame(width: 29, height: 29)
                        .overlay {
                            DesignIconView(trigger.condition.kind.icon)
                                .foregroundStyle(trigger.enabled ? Theme.accentText : Theme.textSecondary)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trigger.title).font(.system(size: 12, weight: .semibold))
                        Text(trigger.subtitle).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Edit trigger")

            if isActive {
                Text("Active now")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.accentDeep)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accentSoft, in: Capsule())
            }
            Toggle(trigger.title, isOn: $trigger.enabled).labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contextMenu {
            Button("Edit…", action: onEdit)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}

// MARK: - Editor

private struct TriggerEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var trigger: Trigger
    let isNew: Bool
    /// The other triggers, to catch duplicates.
    let others: [Trigger]
    let onSave: (Trigger) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Picker("Condition", selection: kind) {
                    ForEach(Trigger.Kind.allCases) { kind in
                        Text(kind.label).tag(kind)
                    }
                }

                conditionFields

                Section {
                    Toggle("Keep the display on", isOn: $trigger.keepDisplayOn)
                    Toggle("Enabled", isOn: $trigger.enabled)
                } footer: {
                    Text("Keeping the display on also stops the screen saver from starting.")
                }
            }
            .formStyle(.grouped)
            .toggleStyle(.switch)
            .scrollContentBackground(.hidden)

            CardDivider()
            HStack(spacing: 8) {
                if isDuplicate {
                    Text("A trigger with this condition already exists.")
                        .foregroundStyle(Theme.accentDeep)
                }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .buttonStyle(OutlineButtonStyle())
                    .keyboardShortcut(.cancelAction)
                Button(isNew ? "Add Trigger" : "Save") {
                    var saved = trigger
                    // Matching compares the exact name, so stray spaces would stop it from ever firing.
                    if case .wifi(let ssid) = saved.condition {
                        saved.condition = .wifi(ssid: ssid.trimmingCharacters(in: .whitespaces))
                    }
                    onSave(saved)
                    dismiss()
                }
                .buttonStyle(FilledButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid || isDuplicate)
            }
            .padding(14)
        }
        .frame(width: 440, height: 420)
        .font(.system(size: 12))
        .background(Theme.window)
        // The lighter amber in dark mode keeps menu values and switches readable.
        .tint(Theme.accentText)
    }

    private var kind: Binding<Trigger.Kind> {
        Binding(
            get: { trigger.condition.kind },
            set: { if $0 != trigger.condition.kind { trigger.condition = $0.defaultCondition } }
        )
    }

    private var isDuplicate: Bool {
        others.contains { $0.condition.isEquivalent(to: trigger.condition) }
    }

    /// Connected external displays, plus the saved one if it is unplugged right now.
    private func displayChoices(including saved: DisplayRef?) -> [DisplayRef] {
        var choices = SystemProbe.externalDisplays()
        if let saved, !choices.contains(where: { $0.id == saved.id }) { choices.append(saved) }
        return choices
    }

    /// Mounted external drives, plus the saved one if it is unplugged right now.
    private func driveChoices(including saved: DriveRef?) -> [DriveRef] {
        var choices = SystemProbe.externalDrives()
        if let saved, !choices.contains(where: { $0.id == saved.id }) { choices.append(saved) }
        return choices
    }

    private var isValid: Bool {
        switch trigger.condition {
        case .apps(let apps): !apps.isEmpty
        case .wifi(let ssid): !ssid.trimmingCharacters(in: .whitespaces).isEmpty
        case .schedule(let schedule): !schedule.weekdays.isEmpty
        default: true
        }
    }

    @ViewBuilder
    private var conditionFields: some View {
        switch trigger.condition {
        case .apps(let apps):
            Section("While any of these apps is running") {
                ForEach(apps) { app in
                    HStack {
                        Image(nsImage: SystemProbe.icon(for: app)).resizable().frame(width: 18, height: 18)
                        Text(app.name)
                        Spacer()
                        Button {
                            trigger.condition = .apps(apps.filter { $0 != app })
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(app.name)")
                    }
                }
                Menu("Add App") {
                    ForEach(SystemProbe.runningRegularApps().filter { !apps.contains($0) }) { app in
                        Button(app.name) { trigger.condition = .apps(apps + [app]) }
                    }
                    Divider()
                    Button("Choose from Applications…") {
                        if let app = Self.chooseApp() { trigger.condition = .apps(apps + [app]) }
                    }
                }
            }

        case .externalDisplay(let display):
            // Tag by id: a renamed display is still the same display.
            let choices = displayChoices(including: display)
            Section {
                Picker("Display", selection: Binding(
                    get: { display?.id },
                    set: { id in trigger.condition = .externalDisplay(display: choices.first { $0.id == id }) }
                )) {
                    Text("Any external display").tag(String?.none)
                    ForEach(choices) { choice in
                        Text(choice.name).tag(Optional(choice.id))
                    }
                }
            } footer: {
                Text("Active while the display is connected. The built-in display never counts.")
            }

        case .power(let onCharger):
            Section {
                Picker("Power source", selection: Binding(
                    get: { onCharger },
                    set: { trigger.condition = .power(onCharger: $0) }
                )) {
                    Text("Plugged in").tag(true)
                    Text("On battery").tag(false)
                }
            } footer: {
                Text("Macs without a battery always count as plugged in.")
            }

        case .drive(let drive):
            // Tag by id: a renamed volume is still the same drive.
            let choices = driveChoices(including: drive)
            Section {
                Picker("Drive", selection: Binding(
                    get: { drive?.id },
                    set: { id in trigger.condition = .drive(choices.first { $0.id == id }) }
                )) {
                    Text("Any external drive").tag(String?.none)
                    ForEach(choices) { choice in
                        Text(choice.name).tag(Optional(choice.id))
                    }
                }
            } footer: {
                Text("Active while the drive is mounted. Useful for backups and long copies.")
            }

        case .wifi(let ssid):
            Section {
                TextField("Network name", text: Binding(
                    get: { ssid },
                    set: { trigger.condition = .wifi(ssid: $0) }
                ))
                Button("Use Current Network") {
                    LocationAccess.shared.requestIfNeeded()
                    if let current = SystemProbe.currentSSID() { trigger.condition = .wifi(ssid: current) }
                }
            } footer: {
                Text("macOS only shares the network name with apps that have Location access.")
            }

        case .schedule(let schedule):
            Section {
                WeekdayPicker(selection: Binding(
                    get: { schedule.weekdays },
                    set: { var s = schedule; s.weekdays = $0; trigger.condition = .schedule(s) }
                ))
                DatePicker("From", selection: minuteBinding(schedule, \.start), displayedComponents: .hourAndMinute)
                DatePicker("To", selection: minuteBinding(schedule, \.end), displayedComponents: .hourAndMinute)
            }
        }
    }

    private func minuteBinding(_ schedule: Trigger.Schedule, _ keyPath: WritableKeyPath<Trigger.Schedule, Int>) -> Binding<Date> {
        Binding(
            get: {
                let minutes = schedule[keyPath: keyPath]
                return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                var updated = schedule
                updated[keyPath: keyPath] = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
                trigger.condition = .schedule(updated)
            }
        )
    }

    private static func chooseApp() -> AppRef? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(filePath: "/Applications")
        panel.prompt = "Choose"
        guard panel.runModal() == .OK, let url = panel.url,
              let id = Bundle(url: url)?.bundleIdentifier
        else { return nil }
        let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
        return AppRef(bundleID: id, name: name)
    }
}

private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    var body: some View {
        LabeledContent("Days") {
            HStack(spacing: 4) {
                let symbols = Calendar.current.veryShortWeekdaySymbols
                let first = Calendar.current.firstWeekday
                ForEach(0..<7, id: \.self) { offset in
                    let day = (first - 1 + offset) % 7 + 1
                    let isOn = selection.contains(day)
                    Button(symbols[day - 1]) {
                        if isOn { selection.remove(day) } else { selection.insert(day) }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 26, height: 26)
                    .background(isOn ? Theme.accent : Theme.sidebar, in: Circle())
                    .foregroundStyle(isOn ? Color.white : Theme.text)
                    .accessibilityLabel(Calendar.current.weekdaySymbols[day - 1])
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
        }
    }
}

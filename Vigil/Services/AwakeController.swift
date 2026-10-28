import AppKit
import Observation

/// Decides whether the Mac should stay awake and holds the matching power assertion.
@Observable
final class AwakeController {
    let prefs: Preferences

    private(set) var session: ManualSession?
    private(set) var activeTriggers: [Trigger] = []
    private(set) var batteryGuardTripped = false
    private(set) var now = Date.now

    /// Shortcuts whose keys clash with another shortcut or another app.
    private(set) var unavailableShortcuts: Set<Shortcut.ID> = []

    /// The shortcut whose keys are being recorded. Shortcuts pause meanwhile, so pressing an existing one doesn't fire it.
    var recordingShortcut: Shortcut.ID? {
        didSet { if recordingShortcut != oldValue { registerHotKeys() } }
    }

    /// The Settings pane to show next time the window opens.
    var settingsPane: SettingsPane = .general

    /// Triggers the user ended by hand; they stay off until their condition clears or the user starts a session.
    private(set) var suppressedTriggers: Set<Trigger.ID> = []
    @ObservationIgnored private let assertion = PowerAssertion()
    @ObservationIgnored private let downloads = FolderActivity.downloads
    @ObservationIgnored private var heartbeat: Task<Void, Never>?
    @ObservationIgnored private var activity: NSObjectProtocol?

    init(prefs: Preferences = Preferences()) {
        self.prefs = prefs
    }

    func start() {
        guard heartbeat == nil else { return }
        // Keep the heartbeat on time; App Nap would otherwise stretch it to minutes.
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Tracking keep-awake sessions and triggers"
        )
        applyAppearance()
        registerHotKeys()
        observeWorkspace()
        if prefs.triggers.contains(where: { $0.enabled && $0.condition.kind == .wifi }) {
            LocationAccess.shared.requestIfNeeded()
        }
        evaluate()
        heartbeat = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                self?.evaluate()
            }
        }
    }

    // MARK: - State

    var isAwake: Bool { session != nil || !activeTriggers.isEmpty }

    var remaining: TimeInterval? {
        session?.endDate.map { max(0, $0.timeIntervalSince(now)) }
    }

    var enabledTriggerCount: Int { prefs.triggers.filter(\.enabled).count }

    func isActive(_ trigger: Trigger) -> Bool {
        activeTriggers.contains { $0.id == trigger.id }
    }

    /// Triggers whose condition holds but which the user ended by hand.
    var pausedTriggers: [Trigger] {
        prefs.triggers.filter { suppressedTriggers.contains($0.id) }
    }

    // MARK: - Actions

    func start(_ preset: Preset, until time: Date? = nil, app: AppRef? = nil) {
        guard !batteryGuardTripped else { return }
        let now = Date.now
        var endDate = preset.duration.map { now.addingTimeInterval($0) }

        switch preset {
        case .untilTime:
            guard let time else { return }
            endDate = Self.nextOccurrence(of: time, after: now)
            prefs.lastUntilTime = time
        case .whileApp:
            guard let app else { return }
            prefs.lastApp = app
        case .whileDownloading:
            downloads.poll(now: now)
        default:
            break
        }

        prefs.lastPreset = preset
        session = ManualSession(preset: preset, started: now, endDate: endDate, app: app)
        // Asking to stay awake brings back paused triggers, so they take over once this session ends.
        suppressedTriggers = []
        evaluate()
    }

    /// Starts the last-used preset, or an indefinite session if it needs input we don't have.
    func startDefault() {
        startUsingLastInput(prefs.lastPreset)
    }

    /// Starts `preset`, filling in the time or app last chosen for presets that need one.
    private func startUsingLastInput(_ preset: Preset) {
        switch preset {
        case .untilTime: start(.untilTime, until: prefs.lastUntilTime)
        case .whileApp:
            if let app = prefs.lastApp, SystemProbe.isRunning([app]) {
                start(.whileApp, app: app)
            } else {
                start(.indefinitely)
            }
        default: start(preset)
        }
    }

    /// Ends the manual session and, unless `prefs.endBehavior` leaves them running, silences any
    /// trigger that is currently holding the Mac awake. With no session running, triggers always stop.
    func end() {
        if session == nil || prefs.endBehavior == .everything {
            suppressedTriggers.formUnion(activeTriggers.map(\.id))
        }
        session = nil
        evaluate()
    }

    /// Lets paused triggers hold the Mac awake again.
    func resumeTriggers() {
        guard !batteryGuardTripped else { return }
        suppressedTriggers = []
        evaluate()
    }

    /// Ends the session if `preset` is running, else starts it. `nil` means the last-used session, or
    /// resuming paused triggers when there are any.
    func toggle(_ preset: Preset?) {
        if let preset {
            if session?.preset == preset { end() } else { startUsingLastInput(preset) }
        } else if isAwake {
            end()
        } else if !pausedTriggers.isEmpty {
            resumeTriggers()
        } else {
            startDefault()
        }
    }

    func applyAppearance() {
        NSApplication.shared.appearance = prefs.appearance.nsAppearance
    }

    // MARK: - Evaluation

    func evaluate() {
        let now = Date.now
        self.now = now

        if session?.preset == .whileDownloading {
            downloads.poll(now: now)
        }

        if let battery = SystemProbe.battery() {
            batteryGuardTripped = prefs.batteryGuardEnabled
                && battery.onBattery
                && battery.percent < prefs.batteryGuardThreshold
        } else {
            batteryGuardTripped = false
        }

        if let session, batteryGuardTripped || hasEnded(session, now: now) {
            self.session = nil
        }

        let met = prefs.triggers.filter { $0.enabled && isMet($0.condition, now: now) }
        let suppressed = suppressedTriggers.intersection(met.map(\.id))
        if suppressed != suppressedTriggers { suppressedTriggers = suppressed }
        let active = batteryGuardTripped ? [] : met.filter { !suppressedTriggers.contains($0.id) }
        if active != activeTriggers { activeTriggers = active }

        var level = AwakeLevel.none
        if session != nil { level = prefs.letDisplaySleep ? .system : .display }
        for trigger in activeTriggers {
            level = max(level, trigger.keepDisplayOn ? .display : .system)
        }
        assertion.set(level, reason: "Vigil is keeping your Mac awake")
    }

    private func hasEnded(_ session: ManualSession, now: Date) -> Bool {
        if let endDate = session.endDate, now >= endDate { return true }
        switch session.preset {
        case .whileApp:
            return session.app.map { !SystemProbe.isRunning([$0]) } ?? true
        case .whileDownloading:
            return !downloads.isBusy(now: now, grace: 120, since: session.started)
        default:
            return false
        }
    }

    private func isMet(_ condition: Trigger.Condition, now: Date) -> Bool {
        switch condition {
        case .apps(let apps): SystemProbe.isRunning(apps)
        case .externalDisplay(let display): SystemProbe.isConnected(display)
        case .power(let onCharger): SystemProbe.isOnCharger() == onCharger
        case .drive(let drive): SystemProbe.isMounted(drive)
        case .wifi(let ssid): !ssid.isEmpty && SystemProbe.currentSSID() == ssid
        case .schedule(let schedule): schedule.contains(now)
        }
    }

    static func nextOccurrence(of time: Date, after now: Date) -> Date {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.nextDate(after: now, matching: parts, matchingPolicy: .nextTime) ?? now
    }

    // MARK: - System hooks

    /// Re-registers every shortcut; call after `prefs.shortcuts` changes.
    func registerHotKeys() {
        HotKeys.shared.unregisterAll()
        guard recordingShortcut == nil else { return }
        var unavailable = Set<Shortcut.ID>()
        var registered: [Shortcut] = []
        for shortcut in prefs.shortcuts {
            guard let keyCode = shortcut.keyCode else { continue }
            if registered.contains(where: { $0.hasSameKeys(as: shortcut) }) {
                unavailable.insert(shortcut.id)
                continue
            }
            let preset = shortcut.preset
            let ok = HotKeys.shared.register(keyCode: keyCode, modifiers: shortcut.modifiers) { [weak self] in
                self?.toggle(preset)
            }
            if ok { registered.append(shortcut) } else { unavailable.insert(shortcut.id) }
        }
        if unavailable != unavailableShortcuts { unavailableShortcuts = unavailable }
    }

    private func observeWorkspace() {
        let center = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didMountNotification, NSWorkspace.didUnmountNotification,
        ] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.evaluate() }
            }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.evaluate() }
        }
    }
}

enum SettingsPane: String, CaseIterable, Identifiable {
    case general, triggers, power, shortcuts, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .triggers: "Triggers"
        case .power: "Battery & Power"
        case .shortcuts: "Shortcuts"
        case .about: "About"
        }
    }

    var icon: DesignIcon {
        switch self {
        case .general: .general
        case .triggers: .triggers
        case .power: .battery
        case .shortcuts: .shortcuts
        case .about: .about
        }
    }
}

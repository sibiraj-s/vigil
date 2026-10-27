import Foundation
import Observation

/// User settings, persisted in UserDefaults.
@Observable
final class Preferences {
    private enum Key {
        static let letDisplaySleep = "letDisplaySleep"
        static let showRemainingTime = "showRemainingTime"
        static let batteryGuardEnabled = "batteryGuardEnabled"
        static let batteryGuardThreshold = "batteryGuardThreshold"
        static let lastPreset = "lastPreset"
        static let lastUntilTime = "lastUntilTime"
        static let lastApp = "lastApp"
        static let triggers = "triggers"
        static let appearance = "appearance"
        static let shortcuts = "shortcuts"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var letDisplaySleep: Bool {
        didSet { defaults.set(letDisplaySleep, forKey: Key.letDisplaySleep) }
    }

    var showRemainingTime: Bool {
        didSet { defaults.set(showRemainingTime, forKey: Key.showRemainingTime) }
    }

    var batteryGuardEnabled: Bool {
        didSet { defaults.set(batteryGuardEnabled, forKey: Key.batteryGuardEnabled) }
    }

    /// Battery percentage below which sessions end while unplugged.
    var batteryGuardThreshold: Int {
        didSet { defaults.set(batteryGuardThreshold, forKey: Key.batteryGuardThreshold) }
    }

    var lastPreset: Preset {
        didSet { defaults.set(lastPreset.rawValue, forKey: Key.lastPreset) }
    }

    /// Time of day last chosen for "Until a time…".
    var lastUntilTime: Date {
        didSet { defaults.set(lastUntilTime, forKey: Key.lastUntilTime) }
    }

    var lastApp: AppRef? {
        didSet { save(lastApp, forKey: Key.lastApp) }
    }

    var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    var shortcuts: [Shortcut] {
        didSet { save(shortcuts, forKey: Key.shortcuts) }
    }

    var triggers: [Trigger] {
        didSet { save(triggers, forKey: Key.triggers) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.showRemainingTime: true,
            Key.batteryGuardEnabled: true,
            Key.batteryGuardThreshold: 20,
        ])
        letDisplaySleep = defaults.bool(forKey: Key.letDisplaySleep)
        showRemainingTime = defaults.bool(forKey: Key.showRemainingTime)
        batteryGuardEnabled = defaults.bool(forKey: Key.batteryGuardEnabled)
        batteryGuardThreshold = defaults.integer(forKey: Key.batteryGuardThreshold)
        lastPreset = defaults.string(forKey: Key.lastPreset).flatMap(Preset.init) ?? .hour1
        lastUntilTime = defaults.object(forKey: Key.lastUntilTime) as? Date
            ?? Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: .now) ?? .now
        lastApp = Self.load(AppRef.self, from: defaults, forKey: Key.lastApp)
        appearance = defaults.string(forKey: Key.appearance).flatMap(AppearanceMode.init) ?? .system
        // Decode one by one so an entry of a removed kind is dropped instead of resetting the list.
        shortcuts = Self.load([Lossy<Shortcut>].self, from: defaults, forKey: Key.shortcuts)?.compactMap(\.value)
            ?? Shortcut.defaults
        triggers = Self.load([Lossy<Trigger>].self, from: defaults, forKey: Key.triggers)?.compactMap(\.value)
            ?? Trigger.defaults
    }

    private func save<T: Encodable>(_ value: T?, forKey key: String) {
        guard let value else { return defaults.removeObject(forKey: key) }
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, from defaults: UserDefaults, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

/// Decodes to `nil` instead of failing, so one bad element doesn't sink a whole array.
private struct Lossy<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

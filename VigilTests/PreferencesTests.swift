import Foundation
import Testing
@testable import Vigil

/// Each test gets its own defaults domain, so nothing touches the real settings.
struct PreferencesTests {
    private let suite = "VigilTests.\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: suite)!
    }

    /// Removes this test's defaults domain from disk.
    private func cleanUp() {
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func freshInstallGetsDefaults() {
        defer { cleanUp() }
        let prefs = Preferences(defaults: defaults)
        #expect(prefs.shortcuts == Shortcut.defaults)
        #expect(prefs.triggers == Trigger.defaults)
        #expect(prefs.showRemainingTime)
        #expect(prefs.batteryGuardEnabled)
        #expect(prefs.batteryGuardThreshold == 20)
        #expect(prefs.lastPreset == .hour1)
    }

    @Test func changesSurviveARelaunch() {
        defer { cleanUp() }
        let prefs = Preferences(defaults: defaults)
        prefs.shortcuts = [Shortcut(preset: .hours5)]
        prefs.triggers = [Trigger(condition: .wifi(ssid: "Home"))]
        prefs.lastPreset = .minutes30
        prefs.lastApp = AppRef(bundleID: "com.apple.Safari", name: "Safari")

        let reloaded = Preferences(defaults: defaults)
        #expect(reloaded.shortcuts == prefs.shortcuts)
        #expect(reloaded.triggers == prefs.triggers)
        #expect(reloaded.lastPreset == .minutes30)
        #expect(reloaded.lastApp == prefs.lastApp)
    }

    @Test func undecodableEntriesAreDroppedNotTheWholeList() throws {
        defer { cleanUp() }
        let shortcut = Shortcut(preset: .hours2)
        let trigger = Trigger(condition: .power(onCharger: false))
        try store([shortcut], adding: ["preset": "removedPreset"], forKey: "shortcuts")
        try store([trigger], adding: ["condition": ["teleport": [:]]], forKey: "triggers")

        let prefs = Preferences(defaults: defaults)
        #expect(prefs.shortcuts == [shortcut])
        #expect(prefs.triggers == [trigger])
    }

    @Test func corruptDataFallsBackToDefaults() {
        defer { cleanUp() }
        defaults.set(Data("not json".utf8), forKey: "shortcuts")
        defaults.set(Data("not json".utf8), forKey: "triggers")
        let prefs = Preferences(defaults: defaults)
        #expect(prefs.shortcuts == Shortcut.defaults)
        #expect(prefs.triggers == Trigger.defaults)
    }

    /// Saves `values` as the app would, plus one entry that a newer or older build wrote.
    private func store<T: Encodable>(_ values: [T], adding foreign: [String: Any], forKey key: String) throws {
        var array = try JSONSerialization.jsonObject(with: JSONEncoder().encode(values)) as! [Any]
        array.insert(foreign, at: 0)
        defaults.set(try JSONSerialization.data(withJSONObject: array), forKey: key)
    }
}

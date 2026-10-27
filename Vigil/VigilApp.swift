import SwiftUI

@main struct VigilApp: App {
    @State private var awake: AwakeController

    init() {
        // Start right away rather than on first open of the menu, so triggers and shortcuts work from launch.
        let awake = AwakeController()
        awake.start()
        Updater.shared.start()
        _awake = State(initialValue: awake)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environment(awake)
        } label: {
            Image(nsImage: MenuBarIcon.image(glyph, text: menuBarText))
        }
        .menuBarExtraStyle(.window)

        Window("Vigil Settings", id: SettingsView.windowID) {
            SettingsView()
                .environment(awake)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }

    private var glyph: EyeGlyph {
        if awake.session != nil { return .open }
        return awake.activeTriggers.isEmpty ? .closed : .trigger
    }

    /// Compact countdown, e.g. "42m" or "1h59".
    private var menuBarText: String? {
        guard awake.prefs.showRemainingTime, let remaining = awake.remaining else { return nil }
        let minutes = Int((remaining / 60).rounded(.up))
        if minutes < 60 { return "\(minutes)m" }
        return String(format: "%dh%02d", minutes / 60, minutes % 60)
    }
}

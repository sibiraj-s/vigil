import AppKit
import Observation
import Sparkle

/// Finds, downloads and installs new versions of Vigil with Sparkle, from the appcast
/// attached to the latest GitHub release.
@Observable
final class Updater {
    static let shared = Updater()
    static let releasesPage = URL(string: "https://github.com/sibiraj-s/vigil/releases/latest")!

    /// Only builds signed for release carry the key that verifies updates; others (local
    /// and ad hoc builds) link to the releases page instead. Development builds aren't
    /// versioned, so every release would look newer.
    #if DEBUG
    let isEnabled = false
    #else
    let isEnabled = !(Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? "").isEmpty
    #endif

    /// False while a check or an update is in progress.
    private(set) var canCheck = false

    /// Sparkle's own setting: it checks once a day by default and saves the choice itself.
    var automaticallyChecks: Bool {
        get {
            access(keyPath: \.automaticallyChecks)
            return controller.updater.automaticallyChecksForUpdates
        }
        set {
            withMutation(keyPath: \.automaticallyChecks) { controller.updater.automaticallyChecksForUpdates = newValue }
        }
    }

    @ObservationIgnored private let controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
    @ObservationIgnored private var observation: NSKeyValueObservation?

    private init() {}

    func start() {
        guard isEnabled else { return }
        controller.startUpdater()
        observation = controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { updater, _ in
            let canCheck = updater.canCheckForUpdates
            MainActor.assumeIsolated { Updater.shared.canCheck = canCheck }
        }
    }

    /// "Check for Updates…": Sparkle's window reports the result.
    func checkNow() {
        if !isEnabled {
            NSWorkspace.shared.open(Self.releasesPage)
        } else if canCheck {
            // A menu bar app isn't active by default; Sparkle's window would open behind others.
            NSApp.activate()
            controller.checkForUpdates(nil)
        }
    }
}

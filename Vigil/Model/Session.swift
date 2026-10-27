import Foundation

/// The choices in the "Keep awake" section of the menu.
enum Preset: String, CaseIterable, Identifiable, Codable {
    case indefinitely
    case minutes15
    case minutes30
    case hour1
    case hours2
    case hours5
    case untilTime
    case whileApp
    case whileDownloading

    var id: String { rawValue }

    var label: String {
        switch self {
        case .indefinitely: "Indefinitely"
        case .minutes15: "15 minutes"
        case .minutes30: "30 minutes"
        case .hour1: "1 hour"
        case .hours2: "2 hours"
        case .hours5: "5 hours"
        case .untilTime: "Until a time…"
        case .whileApp: "While an app runs…"
        case .whileDownloading: "While a download finishes…"
        }
    }

    var duration: TimeInterval? {
        switch self {
        case .minutes15: 15 * 60
        case .minutes30: 30 * 60
        case .hour1: 60 * 60
        case .hours2: 2 * 60 * 60
        case .hours5: 5 * 60 * 60
        default: nil
        }
    }

    /// Presets that need more input before a session can start.
    var needsInput: Bool { self == .untilTime || self == .whileApp }
}

struct AppRef: Codable, Hashable, Identifiable {
    var bundleID: String
    var name: String

    var id: String { bundleID }
}

/// A display identified by maker, model and serial number, so it is recognized across reconnects.
/// Identical monitors that report no serial share an id and count as one display.
struct DisplayRef: Codable, Hashable, Identifiable {
    var id: String
    var name: String
}

/// A mounted volume, identified by its UUID when it has one.
struct DriveRef: Codable, Hashable, Identifiable {
    var id: String
    var name: String
}

/// A session the user started from the menu or a shortcut.
struct ManualSession: Equatable {
    var preset: Preset
    var started: Date
    var endDate: Date?
    var app: AppRef?
}

/// How strongly Vigil is holding the Mac awake.
enum AwakeLevel: Int, Comparable {
    case none
    case system
    case display

    static func < (lhs: AwakeLevel, rhs: AwakeLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

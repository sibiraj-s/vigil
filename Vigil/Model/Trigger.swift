import Foundation

/// A condition that starts a session automatically while it holds.
struct Trigger: Identifiable, Codable, Hashable {
    var id = UUID()
    var enabled = true
    var keepDisplayOn = false
    var condition: Condition

    enum Kind: String, CaseIterable, Identifiable {
        case apps, externalDisplay, power, drive, wifi, schedule

        var id: String { rawValue }

        var label: String {
            switch self {
            case .apps: "Apps"
            case .externalDisplay: "Displays"
            case .power: "Power"
            case .drive: "Drives"
            case .wifi: "Network"
            case .schedule: "Schedule"
            }
        }

        var icon: DesignIcon {
            switch self {
            case .apps: .apps
            case .externalDisplay: .display
            case .power: .power
            case .drive: .drive
            case .wifi: .wifi
            case .schedule: .schedule
            }
        }

        var defaultCondition: Condition {
            switch self {
            case .apps: .apps([])
            case .externalDisplay: .externalDisplay(display: nil)
            case .power: .power(onCharger: true)
            case .drive: .drive(nil)
            case .wifi: .wifi(ssid: "")
            case .schedule: .schedule(Schedule())
            }
        }
    }

    enum Condition: Codable, Hashable {
        case apps([AppRef])
        /// `nil` matches any external display.
        case externalDisplay(display: DisplayRef?)
        /// `true` while on the power adapter, `false` while on battery.
        case power(onCharger: Bool)
        /// `nil` matches any external drive.
        case drive(DriveRef?)
        case wifi(ssid: String)
        case schedule(Schedule)

        /// Whether two conditions would fire in exactly the same situations.
        func isEquivalent(to other: Condition) -> Bool {
            switch (self, other) {
            case let (.apps(a), .apps(b)): Set(a.map(\.bundleID)) == Set(b.map(\.bundleID))
            case let (.wifi(a), .wifi(b)): a.trimmingCharacters(in: .whitespaces) == b.trimmingCharacters(in: .whitespaces)
            case let (.externalDisplay(a), .externalDisplay(b)): a?.id == b?.id
            case let (.drive(a), .drive(b)): a?.id == b?.id
            default: self == other
            }
        }

        var kind: Kind {
            switch self {
            case .apps: .apps
            case .externalDisplay: .externalDisplay
            case .power: .power
            case .drive: .drive
            case .wifi: .wifi
            case .schedule: .schedule
            }
        }
    }

    struct Schedule: Codable, Hashable {
        /// Calendar weekdays, 1 = Sunday.
        var weekdays: Set<Int> = [2, 3, 4, 5, 6]
        /// Minutes after midnight.
        var start = 9 * 60
        var end = 18 * 60

        func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
            let parts = calendar.dateComponents([.weekday, .hour, .minute], from: date)
            guard let weekday = parts.weekday, weekdays.contains(weekday) else { return false }
            let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            if start <= end { return minute >= start && minute < end }
            return minute >= start || minute < end
        }

        var daysLabel: String {
            switch weekdays {
            case [2, 3, 4, 5, 6]: return "Weekdays"
            case [1, 7]: return "Weekends"
            case Set(1...7): return "Every day"
            default:
                let symbols = Calendar.current.shortWeekdaySymbols
                return weekdays.sorted().map { symbols[$0 - 1] }.joined(separator: ", ")
            }
        }

        var hoursLabel: String {
            "\(Self.format(start)) – \(Self.format(end))"
        }

        static func format(_ minutes: Int) -> String {
            let date = Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
            return date.formatted(date: .omitted, time: .shortened)
        }
    }

    var title: String {
        switch condition {
        case .apps(let apps):
            var names: [String] = []
            for app in apps where !names.contains(app.name) { names.append(app.name) }
            switch names.count {
            case 0: return "While an app is running"
            case 1: return "While \(names[0]) is running"
            default: return "While \(names.dropLast().joined(separator: ", ")) or \(names.last!) is running"
            }
        case .externalDisplay(let display):
            return display.map { "When “\($0.name)” is connected" } ?? "When an external display is connected"
        case .power(let onCharger):
            return onCharger ? "While plugged in" : "While on battery"
        case .drive(let drive):
            return drive.map { "When “\($0.name)” is mounted" } ?? "When an external drive is mounted"
        case .wifi(let ssid):
            return ssid.isEmpty ? "On a Wi‑Fi network" : "On Wi‑Fi “\(ssid)”"
        case .schedule(let schedule):
            return "\(schedule.daysLabel) \(schedule.hoursLabel)"
        }
    }

    /// One-line status for the menu header when this trigger holds the Mac awake.
    var shortTitle: String {
        switch condition {
        case .apps(let apps):
            let running = apps.first { SystemProbe.isRunning([$0]) }
            return "While \(running?.name ?? "an app") is running"
        case .externalDisplay(let display): return "\(display?.name ?? "External display") connected"
        case .power(let onCharger): return onCharger ? "Plugged in" : "On battery"
        case .drive(let drive): return "\(drive.map { "“\($0.name)”" } ?? "External drive") mounted"
        case .wifi(let ssid): return "On Wi‑Fi “\(ssid)”"
        case .schedule(let schedule): return "Scheduled until \(Schedule.format(schedule.end))"
        }
    }

    var subtitle: String {
        var parts = [condition.kind.label]
        if keepDisplayOn { parts.append("keeps display on") }
        return parts.joined(separator: " · ")
    }

    static let defaults: [Trigger] = [
        Trigger(keepDisplayOn: true, condition: .apps([
            AppRef(bundleID: "us.zoom.xos", name: "Zoom"),
            AppRef(bundleID: "com.microsoft.teams2", name: "Teams"),
            AppRef(bundleID: "com.microsoft.teams", name: "Teams"),
        ])),
        Trigger(condition: .externalDisplay(display: nil)),
        Trigger(enabled: false, condition: .power(onCharger: true)),
        Trigger(enabled: false, condition: .schedule(Schedule())),
    ]
}

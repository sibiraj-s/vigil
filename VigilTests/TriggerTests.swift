import Foundation
import Testing
@testable import Vigil

struct TriggerTests {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// 2026-10-26 is a Monday (weekday 2).
    private func date(day: Int = 26, _ hour: Int, _ minute: Int = 0) -> Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    // MARK: - Schedule

    @Test func scheduleCoversItsHoursOnItsDays() {
        let schedule = Trigger.Schedule(weekdays: [2], start: 9 * 60, end: 18 * 60)
        #expect(schedule.contains(date(9), calendar: Self.calendar))
        #expect(schedule.contains(date(17, 59), calendar: Self.calendar))
        #expect(!schedule.contains(date(8, 59), calendar: Self.calendar))
        // The end is exclusive.
        #expect(!schedule.contains(date(18), calendar: Self.calendar))
        // Tuesday isn't one of its days.
        #expect(!schedule.contains(date(day: 27, 10), calendar: Self.calendar))
    }

    @Test func overnightScheduleWrapsPastMidnight() {
        let schedule = Trigger.Schedule(weekdays: [2], start: 22 * 60, end: 6 * 60)
        #expect(schedule.contains(date(23), calendar: Self.calendar))
        #expect(schedule.contains(date(5, 59), calendar: Self.calendar))
        #expect(!schedule.contains(date(12), calendar: Self.calendar))
    }

    @Test func daysLabelNamesCommonSets() {
        #expect(Trigger.Schedule(weekdays: [2, 3, 4, 5, 6]).daysLabel == "Weekdays")
        #expect(Trigger.Schedule(weekdays: [1, 7]).daysLabel == "Weekends")
        #expect(Trigger.Schedule(weekdays: Set(1...7)).daysLabel == "Every day")
    }

    // MARK: - Equivalence

    @Test func appsAreEquivalentByBundleIDInAnyOrder() {
        let zoom = AppRef(bundleID: "us.zoom.xos", name: "Zoom")
        let teams = AppRef(bundleID: "com.microsoft.teams2", name: "Teams")
        let renamed = AppRef(bundleID: "us.zoom.xos", name: "zoom.us")
        #expect(Trigger.Condition.apps([zoom, teams]).isEquivalent(to: .apps([teams, renamed])))
        #expect(!Trigger.Condition.apps([zoom]).isEquivalent(to: .apps([teams])))
    }

    @Test func devicesAreEquivalentByIDNotName() {
        let drive = DriveRef(id: "UUID-1", name: "Backup")
        #expect(Trigger.Condition.drive(drive).isEquivalent(to: .drive(DriveRef(id: "UUID-1", name: "TM"))))
        #expect(!Trigger.Condition.drive(drive).isEquivalent(to: .drive(nil)))
        let display = DisplayRef(id: "1-2-3", name: "Studio Display")
        #expect(Trigger.Condition.externalDisplay(display: display)
            .isEquivalent(to: .externalDisplay(display: DisplayRef(id: "1-2-3", name: "Studio Display (1)"))))
    }

    @Test func differentKindsAreNeverEquivalent() {
        #expect(!Trigger.Condition.power(onCharger: true).isEquivalent(to: .drive(nil)))
        #expect(!Trigger.Condition.power(onCharger: true).isEquivalent(to: .power(onCharger: false)))
    }

    // MARK: - Titles

    @Test func appsTitleListsEachNameOnce() {
        let title = { (names: [String]) in
            Trigger(condition: .apps(names.enumerated().map { AppRef(bundleID: "app.\($0.offset)", name: $0.element) })).title
        }
        #expect(title([]) == "While an app is running")
        #expect(title(["Zoom"]) == "While Zoom is running")
        #expect(title(["Zoom", "Teams", "Teams"]) == "While Zoom or Teams is running")
        #expect(title(["Zoom", "Teams", "Slack"]) == "While Zoom, Teams or Slack is running")
    }

    @Test func defaultsAreDistinct() {
        let defaults = Trigger.defaults
        for (i, a) in defaults.enumerated() {
            for b in defaults[(i + 1)...] { #expect(!a.condition.isEquivalent(to: b.condition)) }
        }
    }
}

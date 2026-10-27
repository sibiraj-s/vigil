import Foundation
import Testing
@testable import Vigil

struct SessionTests {
    private func today(_ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now)!
    }

    @Test func untilTimeLaterTodayEndsToday() {
        let now = today(9)
        let end = AwakeController.nextOccurrence(of: today(17, 30), after: now)
        #expect(Calendar.current.isDate(end, inSameDayAs: now))
        #expect(Calendar.current.dateComponents([.hour, .minute], from: end) == DateComponents(hour: 17, minute: 30))
    }

    @Test func untilTimeAlreadyPassedEndsTomorrow() {
        let now = today(20)
        let end = AwakeController.nextOccurrence(of: today(8), after: now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        #expect(Calendar.current.isDate(end, inSameDayAs: tomorrow))
        #expect(end > now)
    }

    @Test func onlyTimedPresetsHaveADuration() {
        #expect(Preset.hour1.duration == 3600)
        #expect(Preset.minutes15.duration == 900)
        for preset in [Preset.indefinitely, .untilTime, .whileApp, .whileDownloading] {
            #expect(preset.duration == nil)
        }
    }

    @Test func presetsThatNeedInput() {
        #expect(Preset.allCases.filter(\.needsInput) == [.untilTime, .whileApp])
    }
}

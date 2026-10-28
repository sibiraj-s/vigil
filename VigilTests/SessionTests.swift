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

/// End and resume behaviour with a trigger that always holds.
struct EndSessionTests {
    private let suite = "VigilTests.\(UUID().uuidString)"
    private let awake: AwakeController

    init() {
        let prefs = Preferences(defaults: UserDefaults(suiteName: suite)!)
        prefs.batteryGuardEnabled = false
        var always = Trigger.Schedule()
        always.weekdays = Set(1...7)
        always.start = 0
        always.end = 24 * 60
        prefs.triggers = [Trigger(condition: .schedule(always))]
        awake = AwakeController(prefs: prefs)
        awake.evaluate()
    }

    private func cleanUp() {
        UserDefaults().removePersistentDomain(forName: suite)
    }

    @Test func endingASessionLeavesTriggersRunning() {
        defer { cleanUp() }
        awake.start(.indefinitely)
        awake.end()
        #expect(awake.session == nil)
        #expect(awake.activeTriggers.count == 1)
        #expect(awake.isAwake)
    }

    @Test func endingEverythingPausesTriggersWithTheSession() {
        defer { cleanUp() }
        awake.prefs.endBehavior = .everything
        awake.start(.indefinitely)
        awake.end()
        #expect(awake.session == nil)
        #expect(!awake.isAwake)
        #expect(awake.pausedTriggers.count == 1)
    }

    @Test func endingWithNoSessionPausesTriggers() {
        defer { cleanUp() }
        awake.start(.indefinitely)
        awake.end()
        awake.end()
        #expect(!awake.isAwake)
        #expect(awake.pausedTriggers.count == 1)
    }

    @Test func toggleResumesPausedTriggers() {
        defer { cleanUp() }
        awake.end()
        #expect(!awake.isAwake)
        awake.toggle(nil)
        #expect(awake.session == nil)
        #expect(awake.activeTriggers.count == 1)
    }

    @Test func startingASessionUnpausesTriggers() {
        defer { cleanUp() }
        awake.end()
        awake.start(.indefinitely)
        awake.end()
        #expect(awake.activeTriggers.count == 1)
        #expect(awake.pausedTriggers.isEmpty)
    }
}

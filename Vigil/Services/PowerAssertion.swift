import Foundation
import IOKit.pwr_mgt

/// Holds a single IOKit power assertion matching the requested level.
final class PowerAssertion {
    private var assertionID: IOPMAssertionID = 0
    private(set) var level: AwakeLevel = .none

    func set(_ newLevel: AwakeLevel, reason: String) {
        guard newLevel != level else { return }
        release()
        guard newLevel != .none else { return }

        let type = newLevel == .display
            ? kIOPMAssertionTypePreventUserIdleDisplaySleep
            : kIOPMAssertionTypePreventUserIdleSystemSleep
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )
        if result == kIOReturnSuccess {
            level = newLevel
        } else {
            assertionID = 0
        }
    }

    private func release() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
        level = .none
    }

    deinit {
        if assertionID != 0 { IOPMAssertionRelease(assertionID) }
    }
}

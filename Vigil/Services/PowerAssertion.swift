import Foundation
import IOKit.pwr_mgt

/// Holds a single IOKit power assertion matching the requested level.
final class PowerAssertion {
    private var assertionID: IOPMAssertionID = 0
    private(set) var level: AwakeLevel = .none

    func set(_ newLevel: AwakeLevel, reason: String) {
        guard newLevel != level else { return }
        guard newLevel != .none else { return release() }

        let type = newLevel == .display
            ? kIOPMAssertionTypePreventUserIdleDisplaySleep
            : kIOPMAssertionTypePreventUserIdleSystemSleep
        var newID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &newID
        )
        // Swap only once the new assertion exists, so the Mac is never left unprotected in between.
        // On failure the old one stays, and the next call retries since `level` still differs.
        guard result == kIOReturnSuccess else { return }
        release()
        assertionID = newID
        level = newLevel
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

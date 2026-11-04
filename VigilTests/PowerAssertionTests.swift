import Foundation
import IOKit.pwr_mgt
import Testing

@testable import Vigil

/// Uses real IOKit assertions, released before each test returns.
struct PowerAssertionTests {
    private static let reason = "VigilTests \(UUID().uuidString)"

    /// The types of this test's assertions currently held by this process.
    private func heldTypes() -> [String] {
        var byProcess: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&byProcess) == kIOReturnSuccess,
            let all = byProcess?.takeRetainedValue() as? [Int: [[String: Any]]]
        else { return [] }
        let own = all[Int(ProcessInfo.processInfo.processIdentifier)] ?? []
        return
            own
            .filter { $0[kIOPMAssertionNameKey] as? String == Self.reason }
            .compactMap { $0[kIOPMAssertionTypeKey] as? String }
    }

    @Test func switchingLevelsHoldsExactlyOneAssertion() {
        let assertion = PowerAssertion()
        defer { assertion.set(.none, reason: Self.reason) }

        assertion.set(.system, reason: Self.reason)
        #expect(heldTypes() == [kIOPMAssertionTypePreventUserIdleSystemSleep])

        assertion.set(.display, reason: Self.reason)
        #expect(assertion.level == .display)
        #expect(heldTypes() == [kIOPMAssertionTypePreventUserIdleDisplaySleep])

        assertion.set(.system, reason: Self.reason)
        #expect(heldTypes() == [kIOPMAssertionTypePreventUserIdleSystemSleep])

        assertion.set(.none, reason: Self.reason)
        #expect(assertion.level == .none)
        #expect(heldTypes().isEmpty)
    }
}

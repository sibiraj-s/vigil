import Foundation
import Testing

/// Settings for the running test, in a domain of its own so nothing touches the real ones.
///
/// The domain is named after the test, and is the same every run. cfprefsd keeps a file handle
/// open for each separate domain that's emptied; a new name for each test, such as a UUID, adds
/// more every run, and once cfprefsd runs out no app on the Mac can save its settings.
///
/// Not for parameterized tests: their cases run at once, under one name.
nonisolated struct TestDefaults {
    let name: String
    let defaults: UserDefaults

    /// Empties the domain first, of what a run that stopped partway left.
    init(_ suite: String) {
        guard let test = Test.current else { preconditionFailure("TestDefaults is only for use in a test") }
        let testName = test.name.filter { $0.isLetter || $0.isNumber }
        name = "VigilTests.\(Self.processSlot).\(suite).\(testName)"
        defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
    }

    /// Removes the domain from disk.
    func remove() {
        defaults.removePersistentDomain(forName: name)
    }

    /// The lowest number no other test process holds, held until this one exits. Runs one after
    /// another use the same names; runs at the same time, such as Xcode's and xcodebuild's, use
    /// different ones.
    private static let processSlot: Int = {
        var slot = 1
        while true {
            let lock = FileManager.default.temporaryDirectory.appending(path: "VigilTests.\(slot).lock")
            // Left open, so the lock lasts until the process exits.
            let file = open(lock.path, O_CREAT | O_RDWR | O_CLOEXEC, 0o600)
            guard file >= 0 else { preconditionFailure("Can't open \(lock.path): \(String(cString: strerror(errno)))") }
            if flock(file, LOCK_EX | LOCK_NB) == 0 { return slot }
            let error = errno
            close(file)
            // Anything but another process holding it would fail the same way for every slot.
            guard error == EWOULDBLOCK else { preconditionFailure("Can't lock \(lock.path): \(String(cString: strerror(error)))") }
            slot += 1
        }
    }()
}

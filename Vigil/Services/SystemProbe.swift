import AppKit
import CoreGraphics
import CoreLocation
import CoreWLAN
import DiskArbitration
import IOKit.ps
import UniformTypeIdentifiers

/// Point-in-time reads of the system state that triggers depend on.
enum SystemProbe {
    struct Battery {
        var percent: Int
        var onBattery: Bool
    }

    static func battery() -> Battery? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
            else { continue }
            let current = description[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maximum = max(description[kIOPSMaxCapacityKey] as? Int ?? 100, 1)
            let state = description[kIOPSPowerSourceStateKey] as? String
            return Battery(percent: current * 100 / maximum, onBattery: state == kIOPSBatteryPowerValue)
        }
        return nil
    }

    /// Whether the Mac is running on the power adapter. Macs without a battery always are.
    static func isOnCharger() -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let source = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue()
        else { return true }
        return (source as String) == kIOPSACPowerValue
    }

    static func externalDrives() -> [DriveRef] {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeUUIDStringKey, .volumeIsInternalKey, .volumeIsRootFileSystemKey]
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        return urls.compactMap { url in
            // Network volumes report no "internal" value, so only explicit externals count.
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.volumeIsInternal == false,
                  values.volumeIsRootFileSystem != true,
                  !isDiskImage(url)
            else { return nil }
            let name = values.volumeName ?? url.lastPathComponent
            return DriveRef(id: values.volumeUUIDString ?? name, name: name)
        }
    }

    private static let diskSession = DASessionCreate(kCFAllocatorDefault)

    /// Mounted .dmg files also report as external, but they aren't drives anyone plugged in.
    private static func isDiskImage(_ url: URL) -> Bool {
        guard let diskSession,
              let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, diskSession, url as CFURL),
              let description = DADiskCopyDescription(disk) as? [String: Any]
        else { return false }
        return description[kDADiskDescriptionDeviceModelKey as String] as? String == "Disk Image"
    }

    /// Whether `drive` is mounted, or any external drive when it is `nil`.
    static func isMounted(_ drive: DriveRef?) -> Bool {
        let mounted = externalDrives()
        guard let drive else { return !mounted.isEmpty }
        return mounted.contains { $0.id == drive.id }
    }

    static func externalDisplays() -> [DisplayRef] {
        let displays = NSScreen.screens.compactMap { screen -> DisplayRef? in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
                  CGDisplayIsBuiltin(number.uint32Value) == 0
            else { return nil }
            let id = number.uint32Value
            return DisplayRef(
                id: "\(CGDisplayVendorNumber(id))-\(CGDisplayModelNumber(id))-\(CGDisplaySerialNumber(id))",
                name: screen.localizedName
            )
        }
        // Identical monitors often report serial 0 and so share an id; macOS offers nothing stable to tell
        // them apart, so they count as one display.
        var seen = Set<String>()
        return displays.filter { seen.insert($0.id).inserted }
    }

    /// Whether `display` is connected, or any external display when it is `nil`.
    static func isConnected(_ display: DisplayRef?) -> Bool {
        let connected = externalDisplays()
        guard let display else { return !connected.isEmpty }
        return connected.contains { $0.id == display.id }
    }

    /// The current network name. macOS only reveals it once Location access is granted.
    static func currentSSID() -> String? {
        CWWiFiClient.shared().interface()?.ssid()
    }

    static func isRunning(_ apps: [AppRef]) -> Bool {
        let ids = Set(apps.map(\.bundleID))
        return NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier.map(ids.contains) ?? false
        }
    }

    static func runningRegularApps() -> [AppRef] {
        let own = Bundle.main.bundleIdentifier
        var seen = Set<String>()
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> AppRef? in
                guard let id = app.bundleIdentifier, id != own, seen.insert(id).inserted else { return nil }
                return AppRef(bundleID: id, name: app.localizedName ?? id)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func icon(for app: AppRef) -> NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }
}

/// Asks for Location access, which macOS requires before revealing the Wi-Fi network name.
final class LocationAccess: NSObject, CLLocationManagerDelegate {
    static let shared = LocationAccess()

    private let manager = CLLocationManager()

    override private init() {
        super.init()
        manager.delegate = self
    }

    func requestIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
}

/// Detects activity in a folder by polling a fingerprint of its contents.
final class FolderActivity {
    let url: URL
    private var fingerprint: Int?
    private(set) var lastChange: Date?

    init(url: URL) {
        self.url = url
    }

    static let downloads = FolderActivity(
        url: (FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? URL(filePath: NSHomeDirectory()).appending(path: "Downloads"))
            .resolvingSymlinksInPath()
    )

    func poll(now: Date = .now) {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return }

        var hasher = Hasher()
        for case let item as URL in enumerator {
            // In-progress downloads can be bundles (Safari) or plain files (Chrome); two levels covers both.
            if enumerator.level >= 2 { enumerator.skipDescendants() }
            let values = try? item.resourceValues(forKeys: Set(keys))
            hasher.combine(item.path)
            hasher.combine(values?.fileSize)
            hasher.combine(values?.contentModificationDate)
        }
        let newFingerprint = hasher.finalize()
        if let fingerprint, fingerprint != newFingerprint {
            lastChange = now
        }
        fingerprint = newFingerprint
    }

    /// Whether the folder changed within `grace` seconds of `now`, counting `since` as a change.
    func isBusy(now: Date, grace: TimeInterval, since: Date? = nil) -> Bool {
        let latest = [lastChange, since].compactMap { $0 }.max()
        guard let latest else { return false }
        return now.timeIntervalSince(latest) < grace
    }
}

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

func fail(_ message: String, code: Int32 = 1) -> Never {
    fputs(message + "\n", stderr)
    exit(code)
}

let args = Array(CommandLine.arguments.dropFirst())
let usage = "Usage: center-app <bundle-id> [width height]"
if args == ["--help"] {
    print(usage)
    print("       center-app --check-accessibility")
    print("       center-app --watch-wake <bundle-id>...")
    print("       center-app --recenter-visible <bundle-id>...")
    exit(0)
}
if args == ["--check-accessibility"] {
    guard AXIsProcessTrusted() else {
        fail("Accessibility is not granted for this execution context.")
    }
    print("Accessibility is granted.")
    exit(0)
}
func axValue(_ element: AXUIElement, attribute: String, type: AXValueType) -> AXValue? {
    var raw: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success,
          let raw, CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
    let value = unsafeBitCast(raw, to: AXValue.self)
    return AXValueGetType(value) == type ? value : nil
}

func windowPoint(_ window: AXUIElement) -> CGPoint? {
    guard let value = axValue(window, attribute: kAXPositionAttribute as String, type: .cgPoint) else {
        return nil
    }
    var point = CGPoint.zero
    return AXValueGetValue(value, .cgPoint, &point) ? point : nil
}

func windowSize(_ window: AXUIElement) -> CGSize? {
    guard let value = axValue(window, attribute: kAXSizeAttribute as String, type: .cgSize) else {
        return nil
    }
    var size = CGSize.zero
    return AXValueGetValue(value, .cgSize, &size) ? size : nil
}

func appWindows(_ app: AXUIElement) -> [AXUIElement] {
    var raw: CFTypeRef?
    guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &raw) == .success else {
        return []
    }
    return raw as? [AXUIElement] ?? []
}

func targetWindow(for bundleID: String, windowID: CGWindowID?) -> AXUIElement? {
    // Electron apps can have several helper processes sharing a bundle ID.
    let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        .map { AXUIElementCreateApplication($0.processIdentifier) }
    if let windowID {
        for app in apps {
            if let window = appWindows(app).first(where: {
                var id: CGWindowID = 0
                return getWindowID($0, &id) == .success && id == windowID
            }) {
                return window
            }
        }
        return nil
    }

    for app in apps {
        var raw: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &raw) == .success,
           let raw, CFGetTypeID(raw) == AXUIElementGetTypeID() {
            return (raw as! AXUIElement)
        }
    }
    for app in apps {
        if let window = appWindows(app).first {
            return window
        }
    }
    return nil
}

func center(_ window: AXUIElement, requestedSize: CGSize? = nil) -> Bool {
    guard let originalPosition = windowPoint(window), let originalSize = windowSize(window) else {
        return false
    }
    let windowCenter = CGPoint(
        x: originalPosition.x + originalSize.width / 2,
        y: originalPosition.y + originalSize.height / 2
    )
    var displayCount: UInt32 = 0
    guard CGGetActiveDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else { return false }
    var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
    guard CGGetActiveDisplayList(displayCount, &displays, &displayCount) == .success else { return false }
    let screen = displays.map { CGDisplayBounds($0) }.first(where: { $0.contains(windowCenter) })
        ?? CGDisplayBounds(CGMainDisplayID())

    if var size = requestedSize {
        guard let value = AXValueCreate(.cgSize, &size),
              AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value) == .success else {
            return false
        }
        Thread.sleep(forTimeInterval: 0.05)
    }
    guard let actualSize = windowSize(window) else { return false }
    // Center the actual size: apps may enforce their own minimum/maximum dimensions.
    var position = CGPoint(x: screen.midX - actualSize.width / 2, y: screen.midY - actualSize.height / 2)
    if requestedSize == nil, abs(originalPosition.x - position.x) <= 1, abs(originalPosition.y - position.y) <= 1 {
        return true
    }
    guard let value = AXValueCreate(.cgPoint, &position),
          AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value) == .success,
          let actualPosition = windowPoint(window) else { return false }
    return abs(actualPosition.x - position.x) <= 1 && abs(actualPosition.y - position.y) <= 1
}

// AeroSpace uses the same AX function to associate windows with WindowServer IDs.
@_silgen_name("_AXUIElementGetWindow")
func getWindowID(_ window: AXUIElement, _ id: UnsafeMutablePointer<CGWindowID>) -> AXError

struct ManagedWindow: Decodable {
    let id: CGWindowID
    let pid: pid_t
    let bundleID: String
    let layout: String
    let visible: Bool
    let fullscreen: Bool

    enum CodingKeys: String, CodingKey {
        case id = "window-id"
        case pid = "app-pid"
        case bundleID = "app-bundle-id"
        case layout = "window-layout"
        case visible = "workspace-is-visible"
        case fullscreen = "window-is-fullscreen"
    }
}

func visibleFloatingWindows(for bundleIDs: Set<String>) throws -> [ManagedWindow] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
    process.arguments = [
        "list-windows", "--all", "--json", "--format",
        "%{window-id} %{app-pid} %{app-bundle-id} %{window-layout} %{workspace-is-visible} %{window-is-fullscreen}"
    ]
    let output = Pipe()
    process.standardOutput = output
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw CocoaError(.executableLoad) }
    let windows = try JSONDecoder().decode([ManagedWindow].self, from: data)
    return windows.filter { $0.visible && !$0.fullscreen && $0.layout == "floating" && bundleIDs.contains($0.bundleID) }
}

func isWindowFlagSet(_ window: AXUIElement, _ attribute: String) -> Bool {
    var raw: CFTypeRef?
    return AXUIElementCopyAttributeValue(window, attribute as CFString, &raw) == .success && raw as? Bool == true
}

func recenterVisible(for bundleIDs: Set<String>, retryIDs: Set<CGWindowID>? = nil) throws -> Set<CGWindowID> {
    let targets = try visibleFloatingWindows(for: bundleIDs).filter { retryIDs?.contains($0.id) ?? true }
    let byProcess = Dictionary(grouping: targets, by: \.pid)
    var remaining = Set(targets.map(\.id))
    for (pid, windows) in byProcess {
        let ids = Set(windows.map(\.id))
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.5)
        for window in appWindows(app) {
            var id: CGWindowID = 0
            guard getWindowID(window, &id) == .success, ids.contains(id) else { continue }
            if isWindowFlagSet(window, kAXMinimizedAttribute) || isWindowFlagSet(window, "AXFullScreen") || center(window) {
                remaining.remove(id)
            }
        }
    }
    return remaining
}

final class WakeObserver {
    private let bundleIDs: Set<String>
    private var pending: DispatchWorkItem?

    init(bundleIDs: Set<String>) {
        self.bundleIDs = bundleIDs
    }

    func cancel() {
        pending?.cancel()
        pending = nil
    }

    func schedule(attempt: Int = 1, retryIDs: Set<CGWindowID>? = nil) {
        cancel()
        let work = DispatchWorkItem { [weak self] in self?.recenter(attempt: attempt, retryIDs: retryIDs) }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + (attempt == 1 ? 1 : 2), execute: work)
    }

    private func recenter(attempt: Int, retryIDs: Set<CGWindowID>?) {
        // AX windows can be unavailable while macOS is showing the lock screen.
        let session = CGSessionCopyCurrentDictionary() as? [String: Any]
        if session?["CGSSessionScreenIsLocked"] as? Bool == true {
            schedule(attempt: attempt, retryIDs: retryIDs)
            return
        }
        do {
            let remaining = try recenterVisible(for: bundleIDs, retryIDs: retryIDs)
            guard !remaining.isEmpty else { return }
            if attempt < 3 {
                schedule(attempt: attempt + 1, retryIDs: remaining)
            } else {
                fputs("Could not recenter windows \(remaining.sorted()) after wake.\n", stderr)
            }
        } catch {
            if attempt < 3 {
                schedule(attempt: attempt + 1, retryIDs: retryIDs)
            } else {
                fputs("Could not list AeroSpace windows after wake: \(error)\n", stderr)
            }
        }
    }
}

if let command = args.first, command == "--watch-wake" || command == "--recenter-visible" {
    let bundleIDs = Set(args.dropFirst())
    guard !bundleIDs.isEmpty else { fail("Specify at least one bundle ID.", code: 2) }
    guard AXIsProcessTrusted() else { fail("Accessibility is not granted for this execution context.") }
    if command == "--recenter-visible" {
        do {
            let remaining = try recenterVisible(for: bundleIDs)
            guard remaining.isEmpty else { fail("Could not recenter windows \(remaining.sorted()).") }
            exit(0)
        } catch {
            fail("Could not list AeroSpace windows: \(error)")
        }
    }

    let observer = WakeObserver(bundleIDs: bundleIDs)
    let notifications = NSWorkspace.shared.notificationCenter
    let wake = notifications.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
        observer.schedule()
    }
    let sleep = notifications.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { _ in
        observer.cancel()
    }
    // The startup command execs this process directly under AeroSpace.
    let parent = DispatchSource.makeProcessSource(identifier: getppid(), eventMask: .exit, queue: .main)
    parent.setEventHandler { exit(0) }
    parent.resume()
    withExtendedLifetime((wake, sleep, parent)) {
        RunLoop.main.run()
    }
    exit(0)
}

// Omit width/height to preserve the window's current size.
guard args.count == 1 || args.count == 3, !args[0].isEmpty else {
    fail(usage, code: 2)
}
let bundleID = args[0]
let windowID: CGWindowID?
if let contextID = ProcessInfo.processInfo.environment["AEROSPACE_WINDOW_ID"] {
    guard let id = CGWindowID(contextID), id != kCGNullWindowID else {
        fail("Invalid AEROSPACE_WINDOW_ID.", code: 2)
    }
    windowID = id
} else {
    windowID = nil
}
let requestedSize: CGSize?
if args.count == 3 {
    guard let width = Double(args[1]), let height = Double(args[2]),
          width.isFinite, height.isFinite, width > 0, height > 0 else {
        fail("Width and height must be finite positive numbers.", code: 2)
    }
    requestedSize = CGSize(width: width, height: height)
} else {
    requestedSize = nil
}

// Detection may fire before the app exposes its window to Accessibility.
for _ in 0..<15 {
    if let window = targetWindow(for: bundleID, windowID: windowID),
       center(window, requestedSize: requestedSize) { exit(0) }
    Thread.sleep(forTimeInterval: 0.1)
}
fail("Could not center \(bundleID). Check its window and Accessibility permission.")

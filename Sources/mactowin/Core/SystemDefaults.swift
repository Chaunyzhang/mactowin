import Foundation
import CoreGraphics

/// 读写系统/Finder 的 defaults 配置（路径栏、搜索范围、双击标题栏、鼠标加速等）
enum SystemDefaults {
    static func string(_ domain: String, _ key: String) -> String? {
        guard let output = run("/usr/bin/defaults", ["read", domain, key]) else { return nil }
        let value = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    static func bool(_ domain: String, _ key: String) -> Bool {
        string(domain, key) == "1"
    }

    static func setBool(_ domain: String, _ key: String, _ value: Bool) {
        _ = run("/usr/bin/defaults", ["write", domain, key, "-bool", value ? "true" : "false"])
    }

    static func setString(_ domain: String, _ key: String, _ value: String) {
        _ = run("/usr/bin/defaults", ["write", domain, key, "-string", value])
    }

    static func setFloat(_ domain: String, _ key: String, _ value: Double) {
        _ = run("/usr/bin/defaults", ["write", domain, key, "-float", String(value)])
    }

    static func restartFinder() {
        _ = run("/usr/bin/killall", ["Finder"])
    }

    @discardableResult
    private static func run(_ path: String, _ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        guard process.terminationStatus == 0 else { return nil }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    }
}

// MARK: - 鼠标滚轮独立反向（Batch D）

/// 只翻转鼠标滚轮（触控板保持「自然」）。
/// 原理：触控板滚动事件是连续的（isContinuous=1），鼠标滚轮是分段的。
/// 若系统「自然滚动」已关（本来就是 Windows 方向），不再翻转。
final class ScrollReverser {
    static let shared = ScrollReverser()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isRunning = false

    private var systemNaturalScrolling: Bool {
        // nil（未设置过）= 系统默认开启自然滚动
        UserDefaults.standard.object(forKey: "com.apple.swipescrolldirection") as? Bool ?? true
    }

    func syncWithSettings() {
        let s = SettingsStore.shared
        if s.appEnabled && s.mouseScrollReversedEnabled { start() } else { stop() }
    }

    func start() {
        guard !isRunning, InputMapper.accessibilityGranted else { return }
        let mask: CGEventMask = 1 << CGEventType.scrollWheel.rawValue
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, _ -> Unmanaged<CGEvent>? in
                let manager = ScrollReverser.shared
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = manager.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passRetained(event)
                }
                guard type == .scrollWheel else { return Unmanaged.passRetained(event) }
                // 触控板（连续滚动）不处理；系统已是 Windows 方向也不处理
                let isTrackpad = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
                if isTrackpad || !manager.systemNaturalScrolling {
                    return Unmanaged.passRetained(event)
                }
                manager.flip(event)
                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        ) else { return }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
    }

    func stop() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
    }

    private func flip(_ event: CGEvent) {
        for field: CGEventField in [.scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2] {
            let value = event.getIntegerValueField(field)
            if value != 0 { event.setIntegerValueField(field, value: -value) }
        }
        for field: CGEventField in [.scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2] {
            let value = event.getIntegerValueField(field)
            if value != 0 { event.setIntegerValueField(field, value: -value) }
        }
        for field: CGEventField in [.scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis2] {
            let value = event.getDoubleValueField(field)
            if value != 0 { event.setDoubleValueField(field, value: -value) }
        }
    }
}

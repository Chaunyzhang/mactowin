import AppKit
import ApplicationServices

/// 全局输入映射（Windows 习惯），统一走一个 CGEventTap，各功能独立开关。
///
/// 全局生效：
/// - ⌃⌥←/→/↑/↓  窗口左半/右半/最大化/最小化（Batch C）
/// - Ctrl+C/V/X/Z/A/S/Y/W/T/F → ⌘ 系（Batch B，终端除外）
/// - Home/End → 行首/行尾（Batch B，仅文本焦点，访达/终端除外）
///
/// 访达专属：
/// - ⌘X 剪切 / ⌘V 移动
/// - ⌫ 返回上级
/// - Enter 打开 / F2 改名
/// - fn+Delete 删除文件（⌘⌫）
/// - ⌘L 地址栏（⌘⇧G）
/// - ⌥Enter 显示简介（⌘I）
///
/// 需要辅助功能权限。
final class InputMapper {
    static let shared = InputMapper()

    /// 合成事件标记，防止自己发出的事件被再次映射造成循环
    static let marker: Int64 = 0x4D32576E // 'M2Wn'

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let lock = NSLock()
    private var _cutPaths: [String] = []

    private(set) var isRunning = false

    private var cutPaths: [String] {
        get { lock.lock(); defer { lock.unlock() }; return _cutPaths }
        set { lock.lock(); _cutPaths = newValue; lock.unlock() }
    }

    // MARK: - 权限

    static var accessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func syncWithSettings() {
        let s = SettingsStore.shared
        guard s.appEnabled else { stop(); return }
        let anyEnabled = s.windowsCutPasteEnabled || s.backspaceGoesUpEnabled
            || s.enterOpensEnabled || s.forwardDeleteEnabled
            || s.cmdLAddressBarEnabled || s.altEnterInfoEnabled
            || s.homeEndEnabled || s.ctrlCompatEnabled || s.windowSnappingEnabled
        if anyEnabled { start() } else { stop() }
    }

    // MARK: - 事件监听

    func start() {
        guard !isRunning, AXIsProcessTrusted() else { return }
        let mask: CGEventMask = 1 << CGEventType.keyDown.rawValue
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, _ -> Unmanaged<CGEvent>? in
                let manager = InputMapper.shared
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = manager.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passRetained(event)
                }
                guard type == .keyDown else { return Unmanaged.passRetained(event) }
                return manager.handleKeyDown(event) ? Unmanaged.passRetained(event) : nil
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
        cutPaths = []
    }

    // MARK: - 按键分发

    /// 返回 true 表示事件放行
    private func handleKeyDown(_ event: CGEvent) -> Bool {
        // 自己发出的合成事件直接放行
        if event.getIntegerValueField(.eventSourceUserData) == Self.marker { return true }

        let s = SettingsStore.shared
        let frontmostID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let isFinder = frontmostID == "com.apple.finder"
        let isTerminal = FrontmostApp.isTerminal

        let flags = event.flags
        let cmd = flags.contains(.maskCommand)
        let shift = flags.contains(.maskShift)
        let ctrl = flags.contains(.maskControl)
        let opt = flags.contains(.maskAlternate)
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // ---- 全局：⌃⌥ 方向键窗口管理 ----
        if s.windowSnappingEnabled, ctrl, opt, !cmd, !shift {
            switch keyCode {
            case 123: WindowSnapper.snap(.left); return false
            case 124: WindowSnapper.snap(.right); return false
            case 126: WindowSnapper.snap(.maximize); return false
            case 125: Keyboard.post(key: 46, modifiers: .maskCommand); return false // ⌘M
            default: break
            }
        }

        // ---- 全局：Ctrl → ⌘ 兼容（终端除外，仅 ⌃ / ⌃⇧）----
        if s.ctrlCompatEnabled, ctrl, !cmd, !opt, !isTerminal {
            // A S F Z X C V W T Y
            let mappable: Set<Int64> = [0, 1, 3, 6, 7, 8, 9, 13, 16, 17]
            if mappable.contains(keyCode) {
                var mods: CGEventFlags = .maskCommand
                if shift { mods.insert(.maskShift) }
                Keyboard.post(key: CGKeyCode(keyCode), modifiers: mods)
                return false
            }
        }

        // ---- 全局：Home/End → 行首/行尾（仅文本焦点，访达/终端除外）----
        if s.homeEndEnabled, !cmd, !ctrl, !opt, !isFinder, !isTerminal,
           (keyCode == 115 || keyCode == 119), frontmostFocusIsText() {
            var mods: CGEventFlags = .maskCommand
            if shift { mods.insert(.maskShift) }
            Keyboard.post(key: keyCode == 115 ? 123 : 124, modifiers: mods) // ⌘← / ⌘→
            return false
        }

        // ---- 访达专属 ----
        guard isFinder else { return true }
        if finderShouldPassThrough() { return true }

        // 无修饰键
        if !cmd, !shift, !ctrl, !opt {
            switch keyCode {
            case 36:  // Return → 打开（⌘O）
                if s.enterOpensEnabled { Keyboard.post(key: 31, modifiers: .maskCommand); return false }
            case 120: // F2 → 改名（Return）
                if s.enterOpensEnabled { Keyboard.post(key: 36, modifiers: []); return false }
            case 51:  // ⌫ → 返回上级
                if s.backspaceGoesUpEnabled { performGoUp(); return false }
            case 117: // fn+Delete → 删除（⌘⌫）
                if s.forwardDeleteEnabled { Keyboard.post(key: 51, modifiers: .maskCommand); return false }
            default: break
            }
            return true
        }

        // ⌥Return → 显示简介（⌘I）
        if opt, !cmd, !shift, !ctrl, keyCode == 36 {
            if s.altEnterInfoEnabled { Keyboard.post(key: 34, modifiers: .maskCommand); return false }
            return true
        }

        // 仅 ⌘ 的组合
        guard cmd, !shift, !ctrl, !opt else { return true }

        // ⌘L → 前往文件夹（⌘⇧G）
        if keyCode == 37 {
            if s.cmdLAddressBarEnabled {
                Keyboard.post(key: 5, modifiers: [.maskCommand, .maskShift])
                return false
            }
            return true
        }

        // ⌘X / ⌘C / ⌘V 剪切粘贴
        guard s.windowsCutPasteEnabled else { return true }
        switch keyCode {
        case 7:
            performCut()
            return false
        case 8:
            cutPaths = []
            return true
        case 9:
            if cutPaths.isEmpty { return true }
            performPaste()
            return false
        default:
            return true
        }
    }

    // MARK: - 焦点检测（AX）

    private struct FocusInfo {
        var role: String?
        var windowRole: String?
        var windowSubrole: String?
        var isText: Bool {
            ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"].contains(role ?? "")
        }
        var isDialog: Bool {
            windowRole == "AXSheet"
                || ["AXDialog", "AXSystemDialog", "AXFloatingWindow"].contains(windowSubrole ?? "")
        }
    }

    private func focusInfo(of pid: pid_t) -> FocusInfo {
        var info = FocusInfo()
        let appElement = AXUIElementCreateApplication(pid)
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused else { return info }
        let axElement = element as! AXUIElement

        var role: CFTypeRef?
        if AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &role) == .success {
            info.role = role as? String
        }
        var window: CFTypeRef?
        if AXUIElementCopyAttributeValue(axElement, kAXWindowAttribute as CFString, &window) == .success,
           let w = window {
            var wRole: CFTypeRef?
            if AXUIElementCopyAttributeValue(w as! AXUIElement, kAXRoleAttribute as CFString, &wRole) == .success {
                info.windowRole = wRole as? String
            }
            var wSubrole: CFTypeRef?
            if AXUIElementCopyAttributeValue(w as! AXUIElement, kAXSubroleAttribute as CFString, &wSubrole) == .success {
                info.windowSubrole = wSubrole as? String
            }
        }
        return info
    }

    /// 前台 App 焦点是否在文本框（用于 Home/End 映射）
    private func frontmostFocusIsText() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        return focusInfo(of: app.processIdentifier).isText
    }

    /// 访达里正在输入文字或处于对话框时不拦截按键
    private func finderShouldPassThrough() -> Bool {
        guard let finderApp = NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.apple.finder").first else {
            return false
        }
        let info = focusInfo(of: finderApp.processIdentifier)
        return info.isText || info.isDialog
    }

    // MARK: - ⌫ 返回上级

    private func performGoUp() {
        DispatchQueue.global(qos: .userInitiated).async {
            // 普通文件夹窗口：发送原生 ⌘↑（同一窗口内导航到上级）
            // 「最近使用 / 搜索结果」等特殊视图：打开选中项所在的文件夹
            let source = """
            tell application "Finder"
                try
                    target of front Finder window as alias
                    return "normal"
                on error
                    if (count of selection) > 0 then
                        try
                            open container of (item 1 of (get selection))
                            return "opened"
                        on error
                            return "fail"
                        end try
                    end if
                    return "fail"
                end try
            end tell
            """
            let script = NSAppleScript(source: source)
            var error: NSDictionary?
            let result = script?.executeAndReturnError(&error)
            guard error == nil else { return }
            switch result?.stringValue {
            case "normal":
                Keyboard.postCommandUp()
            case "fail":
                DispatchQueue.main.async { Feedback.failure() }
            default:
                break
            }
        }
    }

    // MARK: - 剪切 / 粘贴

    private func performCut() {
        FinderBridge.finderSelectionPaths { [weak self] paths in
            guard let self else { return }
            if paths.isEmpty {
                Feedback.failure()
                return
            }
            self.cutPaths = paths
            Feedback.cut()
        }
    }

    private func performPaste() {
        let paths = cutPaths
        FinderBridge.currentLocationPath { [weak self] destPath in
            guard let self else { return }
            guard let destPath else {
                Feedback.failure()
                return
            }
            let destDir = URL(fileURLWithPath: destPath)
            let fm = FileManager.default
            var movedCount = 0

            for path in paths {
                let src = URL(fileURLWithPath: path)
                guard fm.fileExists(atPath: src.path) else { continue }
                // 原地粘贴 = 无操作（与 Windows 一致）
                if src.deletingLastPathComponent().standardizedFileURL.path
                    == destDir.standardizedFileURL.path { continue }

                var dst = destDir.appendingPathComponent(src.lastPathComponent)
                if fm.fileExists(atPath: dst.path) {
                    dst = FileNaming.uniqueURL(
                        for: src.deletingPathExtension().lastPathComponent,
                        ext: src.pathExtension,
                        in: destDir
                    )
                }
                do {
                    try fm.moveItem(at: src, to: dst)
                    movedCount += 1
                } catch {
                    // 跨设备移动失败时尝试 copy + delete
                    if let _ = try? fm.copyItem(at: src, to: dst) {
                        try? fm.removeItem(at: src)
                        movedCount += 1
                    }
                }
            }

            self.cutPaths = []
            movedCount > 0 ? Feedback.success() : Feedback.failure()
            NSWorkspace.shared.noteFileSystemChanged(destDir.path)
        }
    }
}

// MARK: - 窗口分屏（Batch C）

enum WindowSnapper {
    enum Placement {
        case left, right, maximize
    }

    static func snap(_ placement: Placement) {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
              let w = windowRef else { return }
        let window = w as! AXUIElement

        // 当前位置 → 找到所在屏幕
        var position = CGPoint.zero
        var posRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
           let p = posRef {
            AXValueGetValue(p as! AXValue, .cgPoint, &position)
        }
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(position) }) ?? NSScreen.main else { return }

        let vf = screen.visibleFrame // Cocoa 坐标（左下原点）
        let cocoaTarget: CGRect
        switch placement {
        case .left:
            cocoaTarget = CGRect(x: vf.minX, y: vf.minY, width: vf.width / 2, height: vf.height)
        case .right:
            cocoaTarget = CGRect(x: vf.midX, y: vf.minY, width: vf.width / 2, height: vf.height)
        case .maximize:
            cocoaTarget = vf
        }

        // AX 坐标（左上原点）：y 需要按主屏高度翻转
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
        let axOrigin = CGPoint(x: cocoaTarget.minX, y: primaryHeight - cocoaTarget.maxY)

        setPosition(window, axOrigin)
        setSize(window, cocoaTarget.size)
        setPosition(window, axOrigin) // 有些窗口受最小尺寸限制，再校正一次
    }

    private static func setPosition(_ window: AXUIElement, _ point: CGPoint) {
        var p = point
        if let value = AXValueCreate(.cgPoint, &p) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
        }
    }

    private static func setSize(_ window: AXUIElement, _ size: CGSize) {
        var s = size
        if let value = AXValueCreate(.cgSize, &s) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
        }
    }
}

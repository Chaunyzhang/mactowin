import AppKit

/// 合成键盘事件（需要辅助功能权限）
/// 所有合成事件都带 marker 标记，InputMapper 收到后直接放行，避免循环映射
enum Keyboard {
    /// 模拟按下 ⌘V
    static func postCommandV() {
        post(key: 0x09, modifiers: .maskCommand)
    }

    /// 模拟按下 ⌘↑（Finder「前往 > 上级文件夹」）
    static func postCommandUp() {
        post(key: 0x7E, modifiers: .maskCommand)
    }

    static func post(key: CGKeyCode, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        keyDown?.flags = modifiers
        keyDown?.setIntegerValueField(.eventSourceUserData, value: InputMapper.marker)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        keyUp?.flags = modifiers
        keyUp?.setIntegerValueField(.eventSourceUserData, value: InputMapper.marker)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

enum FrontmostApp {
    /// 常见终端 App 的 bundle id
    private static let terminalIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.github.wez.wezterm",
        "net.kovidgoyal.kitty",
        "org.alacritty",
        "com.mitchellh.ghostty",
        "co.zeit.hyper",
    ]

    static var isTerminal: Bool {
        guard let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return false }
        return terminalIDs.contains(id)
    }
}

enum ShellPath {
    /// 包含空格或特殊字符时用单引号包裹，可直接粘进 shell
    static func escaped(_ path: String) -> String {
        let safe = path.range(of: #"^[A-Za-z0-9_\-./]+$"#, options: .regularExpression) != nil
        if safe { return path }
        return "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

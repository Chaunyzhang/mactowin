import AppKit
import Carbon.HIToolbox

// MARK: - 热键动作

enum HotkeyAction: UInt32, CaseIterable {
    case saveImage = 1       // 默认 ⌥⌘V
    case toggleHistory = 2   // 默认 ⌘⇧V
    case copyFinderPath = 3  // 默认 ⌃⌥C
}

// MARK: - 热键定义

struct Hotkey: Codable, Equatable {
    var keyCode: UInt32
    var carbonModifiers: UInt32
    var display: String

    init(keyCode: UInt32, carbonModifiers: UInt32, display: String) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.display = display
    }

    static func `default`(for action: HotkeyAction) -> Hotkey {
        switch action {
        case .saveImage:
            return Hotkey(keyCode: UInt32(kVK_ANSI_V), carbonModifiers: UInt32(optionKey | cmdKey), display: "⌥⌘V")
        case .toggleHistory:
            return Hotkey(keyCode: UInt32(kVK_ANSI_V), carbonModifiers: UInt32(cmdKey | shiftKey), display: "⇧⌘V")
        case .copyFinderPath:
            return Hotkey(keyCode: UInt32(kVK_ANSI_C), carbonModifiers: UInt32(controlKey | optionKey), display: "⌃⌥C")
        }
    }

    /// 从键盘事件创建（修饰键必须至少有一个）
    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        guard carbon != 0 else { return nil }

        keyCode = UInt32(event.keyCode)
        carbonModifiers = carbon
        display = Hotkey.makeDisplay(keyCode: UInt32(event.keyCode), carbonModifiers: carbon, event: event)
    }

    static func makeDisplay(keyCode: UInt32, carbonModifiers: UInt32, event: NSEvent? = nil) -> String {
        var result = ""
        if carbonModifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        result += keyName(keyCode: keyCode, event: event)
        return result
    }

    private static func keyName(keyCode: UInt32, event: NSEvent?) -> String {
        let specials: [UInt32: String] = [
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋", 76: "⌤",
            117: "⌦", 115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
        ]
        if let name = specials[keyCode] { return name }
        if let chars = event?.charactersIgnoringModifiers, !chars.isEmpty {
            return chars.uppercased()
        }
        return "?"
    }
}

// MARK: - SettingsStore 热键存取

extension SettingsStore {
    func hotkey(for action: HotkeyAction) -> Hotkey {
        hotkeyBindings[action] ?? .default(for: action)
    }

    func isHotkeyTaken(_ hotkey: Hotkey, byOtherThan action: HotkeyAction) -> Bool {
        hotkeyBindings.contains { $0.key != action && $0.value == hotkey }
    }

    func setHotkey(_ hotkey: Hotkey, for action: HotkeyAction) {
        hotkeyBindings[action] = hotkey
        persistHotkeys()
        HotkeyManager.shared.reregister()
    }

    func resetHotkeys() {
        hotkeyBindings = [:]
        UserDefaults.standard.removeObject(forKey: "hotkeyBindings")
        HotkeyManager.shared.reregister()
    }

    func loadHotkeys() -> [HotkeyAction: Hotkey] {
        guard let data = UserDefaults.standard.data(forKey: "hotkeyBindings"),
              let raw = try? JSONDecoder().decode([UInt32: Hotkey].self, from: data) else {
            return [:]
        }
        var result: [HotkeyAction: Hotkey] = [:]
        for (key, value) in raw {
            if let action = HotkeyAction(rawValue: key) {
                result[action] = value
            }
        }
        return result
    }

    private func persistHotkeys() {
        var raw: [UInt32: Hotkey] = [:]
        for (action, hotkey) in hotkeyBindings {
            raw[action.rawValue] = hotkey
        }
        if let data = try? JSONEncoder().encode(raw) {
            UserDefaults.standard.set(data, forKey: "hotkeyBindings")
        }
    }
}

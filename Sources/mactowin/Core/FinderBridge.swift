import AppKit

/// 通过 Apple Events 与 Finder 交互（首次使用会触发系统授权弹窗）
enum FinderBridge {
    private static func run(_ source: String) -> NSAppleEventDescriptor? {
        let script = NSAppleScript(source: source)
        var error: NSDictionary?
        let result = script?.executeAndReturnError(&error)
        if error != nil { return nil }
        return result
    }

    /// Finder 当前的「插入位置」路径：鼠标点了桌面就是桌面，点了某个窗口就是该窗口的文件夹。
    /// 与 Finder 原生「新建文件夹」「粘贴」的目标位置一致。
    static func currentLocationPath(completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let source = """
            tell application "Finder"
                try
                    return POSIX path of (insertion location as alias)
                on error
                    try
                        return POSIX path of (desktop as alias)
                    on error
                        return ""
                    end try
                end try
            end tell
            """
            var path = run(source)?.stringValue
            if path?.isEmpty ?? true { path = nil }
            DispatchQueue.main.async { completion(path) }
        }
    }

    /// Finder 当前选中项的 POSIX 路径列表
    static func finderSelectionPaths(completion: @escaping ([String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let source = """
            tell application "Finder"
                set sel to selection
                if (count of sel) is 0 then return {}
                set out to {}
                repeat with i in sel
                    try
                        set end of out to POSIX path of (i as alias)
                    end try
                end repeat
                return out
            end tell
            """
            var paths: [String] = []
            if let list = run(source), list.numberOfItems > 0 {
                for i in 1...list.numberOfItems {
                    if let s = list.atIndex(i)?.stringValue {
                        paths.append(s)
                    }
                }
            }
            DispatchQueue.main.async { completion(paths) }
        }
    }
}

enum Directories {
    static var desktop: URL {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    }

    static var downloads: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    }

    /// 根据设置解析图片保存目录
    static func imageSaveDirectory(completion: @escaping (URL) -> Void) {
        switch SettingsStore.shared.imageSaveLocation {
        case .desktop:
            completion(desktop)
        case .downloads:
            completion(downloads)
        case .finderWindow:
            FinderBridge.currentLocationPath { path in
                completion(path.map { URL(fileURLWithPath: $0) } ?? desktop)
            }
        }
    }
}

enum Feedback {
    static func success() { NSSound(named: NSSound.Name("Glass"))?.play() }
    static func failure() { NSSound(named: NSSound.Name("Basso"))?.play() }
    static func cut() { NSSound(named: NSSound.Name("Pop"))?.play() }
}

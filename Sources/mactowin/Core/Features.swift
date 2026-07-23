import AppKit

// MARK: - 功能1：图片粘贴保存为 PNG（⌥⌘V）

final class ImagePasteSaver {
    static let shared = ImagePasteSaver()

    func saveClipboardImage() {
        guard let png = ClipboardReader.currentImagePNG() else {
            Feedback.failure()
            return
        }
        // 终端场景：图片 → 存 PNG → 自动把路径填进终端
        let inTerminal = FrontmostApp.isTerminal
        Directories.imageSaveDirectory { dir in
            let url = FileNaming.uniqueURL(for: "image", ext: "png", in: dir)
            do {
                try png.write(to: url, options: .atomic)
                Feedback.success()
                if inTerminal {
                    // 把路径放到剪贴板，并模拟 ⌘V 粘进终端
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(ShellPath.escaped(url.path), forType: .string)
                    if InputMapper.accessibilityGranted {
                        Keyboard.postCommandV()
                    }
                } else if SettingsStore.shared.copyFileAfterImageSave {
                    // 可选：保存后把新文件放进剪贴板，方便立即 ⌘V 到别处
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.writeObjects([url as NSURL])
                }
            } catch {
                Feedback.failure()
            }
        }
    }
}

// MARK: - 复制当前位置路径（默认 ⌃⌥C，可在设置中修改）

enum CopyPathAction {
    static func copyCurrentFinderPath() {
        FinderBridge.currentLocationPath { path in
            let target = path ?? Directories.desktop.path
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(target, forType: .string)
            Feedback.success()
        }
    }
}

// MARK: - 功能3：新建文本文件（服务菜单 + 菜单栏）

enum NewTextFile {
    static func createInCurrentFolder() {
        FinderBridge.currentLocationPath { path in
            let dir = path.map { URL(fileURLWithPath: $0) } ?? Directories.desktop
            let url = FileNaming.uniqueURL(for: "新建文本文档", ext: "txt", in: dir)
            do {
                try "".write(to: url, atomically: true, encoding: .utf8)
                NSWorkspace.shared.activateFileViewerSelecting([url])
                Feedback.success()
            } catch {
                Feedback.failure()
            }
        }
    }
}

/// NSServices 服务提供者：右键 → 服务 →「mactowin: 在此新建文本文件」
final class NewTextFileServiceProvider: NSObject {
    @objc func newTextFileHere(_ pboard: NSPasteboard,
                               userData: String?,
                               error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        NewTextFile.createInCurrentFolder()
    }
}

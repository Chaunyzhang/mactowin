import Foundation

enum FileNaming {
    /// 在目录中生成不冲突的文件名：image.png → image 2.png → image 3.png …
    /// ext 传空字符串时不加扩展名（用于文件夹）
    static func uniqueURL(for name: String, ext: String, in dir: URL) -> URL {
        func make(_ base: String) -> URL {
            ext.isEmpty
                ? dir.appendingPathComponent(base)
                : dir.appendingPathComponent("\(base).\(ext)")
        }
        var candidate = make(name)
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = make("\(name) \(n)")
            n += 1
        }
        return candidate
    }
}

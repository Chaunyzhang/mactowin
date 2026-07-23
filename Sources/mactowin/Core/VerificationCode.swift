import AppKit
import SQLite3

// MARK: - 验证码提取（纯函数，可测试）

enum VerificationCodeExtractor {
    private static let keywords = [
        "验证码", "校验码", "动态码", "动态密码", "确认码", "认证码", "安全码",
        "code", "Code", "CODE", "verification", "Verification", "OTP", "otp",
    ]

    /// 从短信文本提取 4-8 位验证码
    /// 有关键词（验证码/code 等）时取第一组数字；无关键词时保守只认 6 位独立数字
    static func extract(from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"(?<!\d)\d{4,8}(?!\d)"#) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range).compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
        guard !matches.isEmpty else { return nil }

        let hasKeyword = keywords.contains { text.contains($0) }
        if hasKeyword {
            return matches.first
        }
        return matches.first { $0.count == 6 }
    }
}

// MARK: - 短信监听（读取「信息」App 数据库，需要完全磁盘访问权限）

final class VerificationCodeWatcher: ObservableObject {
    static let shared = VerificationCodeWatcher()
    /// 最近收到的验证码，常驻菜单栏直到下一条验证码替换（持久化，重启不丢）
    @Published private(set) var recentCode: (code: String, date: Date)? {
        didSet {
            if let recentCode {
                defaults.set(recentCode.code, forKey: "recentSMSCode")
                defaults.set(recentCode.date.timeIntervalSince1970, forKey: "recentSMSCodeDate")
            }
        }
    }

    private let defaults = UserDefaults.standard

    private init() {
        if let code = defaults.string(forKey: "recentSMSCode"), !code.isEmpty {
            let ts = defaults.double(forKey: "recentSMSCodeDate")
            recentCode = (code, Date(timeIntervalSince1970: ts))
        }
    }

    private var timer: Timer?
    private var lastSeenRowID: Int64 = 0

    private(set) var isRunning = false

    static var messagesDBPath: String {
        NSHomeDirectory() + "/Library/Messages/chat.db"
    }

    /// 是否已授予完全磁盘访问（能读到信息数据库）
    static var messagesDBReadable: Bool {
        FileManager.default.isReadableFile(atPath: messagesDBPath)
    }

    private var lastDecision: Bool?

    func syncWithSettings() {
        let s = SettingsStore.shared
        let wantRun = s.appEnabled && s.smsCodeEnabled && Self.messagesDBReadable
        if wantRun != lastDecision {
            let line = "\(Date()): 短信监听\(wantRun ? "启动" : "停止")（appEnabled=\(s.appEnabled) smsCode=\(s.smsCodeEnabled) dbReadable=\(Self.messagesDBReadable)）"
            NSLog("mactowin: \(line)")
            writeStatus(line)
            lastDecision = wantRun
        }
        if wantRun { start() } else { stop() }
    }

    /// 状态写到文件，便于命令行诊断（NSLog 经 LaunchServices 启动时不进统一日志）
    private func writeStatus(_ line: String) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("mactowin")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? (line + "\n").write(to: dir.appendingPathComponent("watcher-status.txt"),
                                 atomically: true, encoding: .utf8)
    }

    func copyRecentToClipboard() {
        guard let recentCode else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(recentCode.code, forType: .string)
        Feedback.success()
    }

    // MARK: - 监听

    private func start() {
        guard !isRunning else { return }
        lastSeenRowID = currentMaxRowID()
        NSLog("mactowin: 短信监听已启动（lastSeenRowID=\(lastSeenRowID)）")
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.poll()
        }
        isRunning = true
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func poll() {
        // 不做 mtime 门控：chat.db 是 WAL 模式，新消息先写 chat.db-wal，
        // 主库文件的修改时间可能很久不变，直接查询最可靠（开销极小）
        queryNewMessages()
    }

    // MARK: - SQLite

    private func openDB() -> OpaquePointer? {
        var db: OpaquePointer?
        let result = sqlite3_open_v2(
            "file://\(Self.messagesDBPath)?mode=ro",
            &db,
            SQLITE_OPEN_READONLY | SQLITE_OPEN_URI,
            nil
        )
        guard result == SQLITE_OK else {
            if let db { sqlite3_close(db) }
            return nil
        }
        return db
    }

    private func currentMaxRowID() -> Int64 {
        guard let db = openDB() else { return 0 }
        defer { sqlite3_close(db) }
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, "SELECT IFNULL(MAX(ROWID), 0) FROM message", -1, &stmt, nil) == SQLITE_OK,
              sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return sqlite3_column_int64(stmt, 0)
    }

    private func queryNewMessages() {
        guard let db = openDB() else { return }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        let sql = """
        SELECT ROWID, text, attributedBody FROM message
        WHERE is_from_me = 0 AND ROWID > ?
        ORDER BY ROWID ASC
        """
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_int64(stmt, 1, lastSeenRowID)

        var newestCode: String?
        var newCount = 0
        while sqlite3_step(stmt) == SQLITE_ROW {
            let rowID = sqlite3_column_int64(stmt, 0)
            lastSeenRowID = max(lastSeenRowID, rowID)
            newCount += 1

            var text: String?
            if let cText = sqlite3_column_text(stmt, 1) {
                text = String(cString: cText)
            } else if let blob = sqlite3_column_blob(stmt, 2) {
                // text 为空时从富文本归档里取正文
                let length = Int(sqlite3_column_bytes(stmt, 2))
                let data = Data(bytes: blob, count: length)
                text = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data)?.string
            }
            guard let text else { continue }
            if let code = VerificationCodeExtractor.extract(from: text) {
                newestCode = code // 取最新一条含验证码的
            }
        }
        if newCount > 0 {
            let line = "\(Date()): 检测到 \(newCount) 条新消息，验证码：\(newestCode ?? "无")"
            NSLog("mactowin: \(line)")
            writeStatus(line)
        }

        if let code = newestCode {
            DispatchQueue.main.async { [weak self] in
                self?.recentCode = (code, Date())
                // 自动复制到剪贴板，收到后直接 ⌘V 即可
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(code, forType: .string)
                Feedback.success()
            }
        }
    }
}

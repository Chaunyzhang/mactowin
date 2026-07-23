import XCTest
@testable import mactowin

final class FileNamingTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mactowinTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testNoConflictReturnsOriginalName() {
        let url = FileNaming.uniqueURL(for: "image", ext: "png", in: tempDir)
        XCTAssertEqual(url.lastPathComponent, "image.png")
    }

    func testConflictAppendsNumber() throws {
        try Data().write(to: tempDir.appendingPathComponent("image.png"))
        let url = FileNaming.uniqueURL(for: "image", ext: "png", in: tempDir)
        XCTAssertEqual(url.lastPathComponent, "image 2.png")
    }

    func testMultipleConflictsIncrement() throws {
        try Data().write(to: tempDir.appendingPathComponent("image.png"))
        try Data().write(to: tempDir.appendingPathComponent("image 2.png"))
        let url = FileNaming.uniqueURL(for: "image", ext: "png", in: tempDir)
        XCTAssertEqual(url.lastPathComponent, "image 3.png")
    }

    func testEmptyExtensionForFolders() throws {
        try FileManager.default.createDirectory(
            at: tempDir.appendingPathComponent("文件夹"),
            withIntermediateDirectories: false
        )
        let url = FileNaming.uniqueURL(for: "文件夹", ext: "", in: tempDir)
        XCTAssertEqual(url.lastPathComponent, "文件夹 2")
    }
}

final class ClipboardHistoryStoreTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mactowin-history-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func makeStore() -> ClipboardHistoryStore {
        ClipboardHistoryStore(storageDir: tempDir)
    }

    func testAddInsertsAtFront() {
        let store = makeStore()
        store.add(.text("第一条"))
        store.add(.text("第二条"))
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items[0].content, .text("第二条"))
    }

    func testDuplicateMovesToFront() {
        let store = makeStore()
        store.add(.text("A"))
        store.add(.text("B"))
        store.add(.text("A"))
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items[0].content, .text("A"))
        XCTAssertEqual(store.items[1].content, .text("B"))
    }

    func testLimitIsRespected() {
        let store = makeStore()
        let settings = SettingsStore.shared
        let old = settings.historyLimit
        settings.historyLimit = 5
        defer { settings.historyLimit = old }

        for i in 1...10 {
            store.add(.text("item \(i)"))
        }
        XCTAssertEqual(store.items.count, 5)
        XCTAssertEqual(store.items.first?.content, .text("item 10"))
    }

    func testDifferentContentTypesAreDistinct() {
        let store = makeStore()
        store.add(.text("A"))
        store.add(.image(Data([1, 2, 3])))
        store.add(.files([URL(fileURLWithPath: "/tmp/x")]))
        XCTAssertEqual(store.items.count, 3)
    }

    func testPersistenceRoundtrip() {
        let store1 = makeStore()
        store1.add(.text("持久化的文本"))
        store1.add(.image(Data([9, 8, 7])))
        store1.add(.files([URL(fileURLWithPath: "/tmp/a.txt")]))

        // 新实例模拟重启后加载
        let store2 = makeStore()
        XCTAssertEqual(store2.items.count, 3)
        XCTAssertEqual(store2.items[0].content, .files([URL(fileURLWithPath: "/tmp/a.txt")]))
        XCTAssertEqual(store2.items[1].content, .image(Data([9, 8, 7])))
        XCTAssertEqual(store2.items[2].content, .text("持久化的文本"))
    }

    func testClearRemovesPersistedData() {
        let store1 = makeStore()
        store1.add(.image(Data([1, 2, 3])))
        store1.clear()

        let store2 = makeStore()
        XCTAssertTrue(store2.items.isEmpty)
    }
}

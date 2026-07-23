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
    override func setUp() {
        ClipboardHistoryStore.shared.clear()
    }

    override func tearDown() {
        ClipboardHistoryStore.shared.clear()
    }

    func testAddInsertsAtFront() {
        let store = ClipboardHistoryStore.shared
        store.add(.text("第一条"))
        store.add(.text("第二条"))
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items[0].content, .text("第二条"))
    }

    func testDuplicateMovesToFront() {
        let store = ClipboardHistoryStore.shared
        store.add(.text("A"))
        store.add(.text("B"))
        store.add(.text("A"))
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items[0].content, .text("A"))
        XCTAssertEqual(store.items[1].content, .text("B"))
    }

    func testLimitIsRespected() {
        let store = ClipboardHistoryStore.shared
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
        let store = ClipboardHistoryStore.shared
        store.add(.text("A"))
        store.add(.image(Data([1, 2, 3])))
        store.add(.files([URL(fileURLWithPath: "/tmp/x")]))
        XCTAssertEqual(store.items.count, 3)
    }
}

import XCTest
@testable import mactowin

final class ShellPathTests: XCTestCase {
    func testSimplePathNotQuoted() {
        XCTAssertEqual(ShellPath.escaped("/Users/test/Desktop/image.png"),
                       "/Users/test/Desktop/image.png")
    }

    func testPathWithSpaceIsQuoted() {
        XCTAssertEqual(ShellPath.escaped("/Users/test/My Documents/image 2.png"),
                       "'/Users/test/My Documents/image 2.png'")
    }

    func testPathWithChineseIsQuoted() {
        XCTAssertEqual(ShellPath.escaped("/Users/test/桌面/image.png"),
                       "'/Users/test/桌面/image.png'")
    }

    func testPathWithSingleQuoteIsEscaped() {
        XCTAssertEqual(ShellPath.escaped("/tmp/it's here.png"),
                       "'/tmp/it'\\''s here.png'")
    }
}

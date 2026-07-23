import XCTest
@testable import mactowin

final class VerificationCodeExtractorTests: XCTestCase {
    func testChineseKeywordWithSixDigits() {
        XCTAssertEqual(
            VerificationCodeExtractor.extract(from: "【支付宝】您的验证码为 834521，请勿泄露。"),
            "834521"
        )
    }

    func testKeywordWithFourDigits() {
        XCTAssertEqual(
            VerificationCodeExtractor.extract(from: "您的动态密码是 1234，5 分钟内有效"),
            "1234"
        )
    }

    func testEnglishCode() {
        XCTAssertEqual(
            VerificationCodeExtractor.extract(from: "Your verification code is 902134."),
            "902134"
        )
    }

    func testSixDigitsWithoutKeyword() {
        XCTAssertEqual(
            VerificationCodeExtractor.extract(from: "884210 输入此码完成登录"),
            "884210"
        )
    }

    func testFourDigitsWithoutKeywordRejected() {
        // 无关键词时只认 6 位，避免把年份/数量当验证码
        XCTAssertNil(VerificationCodeExtractor.extract(from: "你的订单 1234 已发货"))
    }

    func testNoDigits() {
        XCTAssertNil(VerificationCodeExtractor.extract(from: "你好，周末一起吃饭？"))
    }

    func testLongNumberNotMatched() {
        // 手机号（11 位）不应被当作验证码
        XCTAssertNil(VerificationCodeExtractor.extract(from: "联系客服 13812345678 咨询"))
    }

    func testFirstMatchWinsWithKeyword() {
        XCTAssertEqual(
            VerificationCodeExtractor.extract(from: "验证码 112233，有效期 10 分钟，退订回 6688"),
            "112233"
        )
    }
}

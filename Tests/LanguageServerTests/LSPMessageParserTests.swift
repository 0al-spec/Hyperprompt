import XCTest
@testable import LanguageServer

final class LSPMessageParserTests: XCTestCase {
    func testParsesSingleMessage() {
        let body = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}"
        let message = "Content-Length: \(body.utf8.count)\r\n\r\n\(body)"
        var parser = LSPMessageParser()
        parser.append(Data(message.utf8))

        let parsed = parser.nextMessage()
        XCTAssertNotNil(parsed)
        XCTAssertEqual(String(data: parsed ?? Data(), encoding: .utf8), body)
    }

    func testParsesMultipleMessages() {
        let bodyOne = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}"
        let bodyTwo = "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"shutdown\"}"
        let messageOne = "Content-Length: \(bodyOne.utf8.count)\r\n\r\n\(bodyOne)"
        let messageTwo = "Content-Length: \(bodyTwo.utf8.count)\r\n\r\n\(bodyTwo)"

        var parser = LSPMessageParser()
        parser.append(Data((messageOne + messageTwo).utf8))

        let parsedOne = parser.nextMessage()
        let parsedTwo = parser.nextMessage()

        XCTAssertEqual(String(data: parsedOne ?? Data(), encoding: .utf8), bodyOne)
        XCTAssertEqual(String(data: parsedTwo ?? Data(), encoding: .utf8), bodyTwo)
    }
}

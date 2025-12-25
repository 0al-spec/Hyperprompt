#if Editor
import XCTest
import Parser
@testable import EditorEngine

final class LinkSpanTests: XCTestCase {
    func testSingleLinkSpanOffsets() {
        let content = "\"docs/readme.md\"\n"
        let parsed = EditorParser.parse(content: content, filePath: "main.hc")

        XCTAssertEqual(parsed.linkSpans.count, 1)
        let span = parsed.linkSpans[0]

        XCTAssertEqual(span.literal, "docs/readme.md")
        XCTAssertEqual(span.referenceHint, .fileReference)
        XCTAssertEqual(span.lineRange, 1..<2)
        XCTAssertEqual(span.columnRange, 2..<(2 + "docs/readme.md".count))
        XCTAssertEqual(span.byteRange, 1..<(1 + "docs/readme.md".utf8.count))
    }

    func testUtf8ByteOffsets() {
        let content = "\"café.md\"\n"
        let parsed = EditorParser.parse(content: content, filePath: "utf8.hc")

        XCTAssertEqual(parsed.linkSpans.count, 1)
        let span = parsed.linkSpans[0]

        XCTAssertEqual(span.literal, "café.md")
        XCTAssertEqual(span.referenceHint, .fileReference)
        XCTAssertEqual(span.columnRange, 2..<(2 + "café.md".count))
        XCTAssertEqual(span.byteRange, 1..<(1 + "café.md".utf8.count))
        let byteCount = span.byteRange.upperBound - span.byteRange.lowerBound
        let columnCount = span.columnRange.upperBound - span.columnRange.lowerBound
        XCTAssertGreaterThan(byteCount, columnCount)
    }

    func testParseErrorReturnsDiagnostics() {
        let content = "\"root\"\n        \"child\"\n"
        let parsed = EditorParser.parse(content: content, filePath: "broken.hc")

        XCTAssertEqual(parsed.linkSpans.count, 2)
        XCTAssertTrue(parsed.hasDiagnostics)

        let hasDepthError = parsed.diagnostics.contains { error in
            guard let parserError = error as? ParserError else {
                return false
            }
            if case .invalidDepthJump = parserError {
                return true
            }
            return false
        }
        XCTAssertTrue(hasDepthError)
        XCTAssertNotNil(parsed.ast)
    }
}
#endif

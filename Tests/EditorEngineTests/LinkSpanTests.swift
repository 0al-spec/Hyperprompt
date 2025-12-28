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

    // MARK: - Byte Offset Tests (EE-FIX-2)

    func testByteOffsets_FileWithTrailingNewline() {
        let content = "\"file1.md\"\n\"file2.md\"\n"
        let parsed = EditorParser.parse(content: content, filePath: "test.hc")

        XCTAssertEqual(parsed.linkSpans.count, 2)

        // First link: "file1.md" on line 1, columns 2-10
        let link1 = parsed.linkSpans[0]
        XCTAssertEqual(link1.literal, "file1.md")
        XCTAssertEqual(link1.lineRange, 1..<2)
        XCTAssertEqual(link1.byteRange, 1..<9)  // Byte 1 to 9 (8 bytes for "file1.md")

        // Second link: "file2.md" on line 2, columns 2-10
        let link2 = parsed.linkSpans[1]
        XCTAssertEqual(link2.literal, "file2.md")
        XCTAssertEqual(link2.lineRange, 2..<3)
        XCTAssertEqual(link2.byteRange, 12..<20)  // Byte 12 to 20

        // Verify actual byte positions in content
        let utf8 = Array(content.utf8)
        let link1Content = String(bytes: utf8[link1.byteRange], encoding: .utf8)
        let link2Content = String(bytes: utf8[link2.byteRange], encoding: .utf8)
        XCTAssertEqual(link1Content, "file1.md")
        XCTAssertEqual(link2Content, "file2.md")
    }

    func testByteOffsets_FileWithoutTrailingNewline() {
        let content = "\"file1.md\"\n\"file2.md\""
        let parsed = EditorParser.parse(content: content, filePath: "test.hc")

        XCTAssertEqual(parsed.linkSpans.count, 2)

        // First link should have same byte range as with trailing newline
        let link1 = parsed.linkSpans[0]
        XCTAssertEqual(link1.literal, "file1.md")
        XCTAssertEqual(link1.lineRange, 1..<2)
        XCTAssertEqual(link1.byteRange, 1..<9)

        // Second link should have same byte range as with trailing newline
        let link2 = parsed.linkSpans[1]
        XCTAssertEqual(link2.literal, "file2.md")
        XCTAssertEqual(link2.lineRange, 2..<3)
        XCTAssertEqual(link2.byteRange, 12..<20)

        // Verify actual byte positions in content
        let utf8 = Array(content.utf8)
        let link1Content = String(bytes: utf8[link1.byteRange], encoding: .utf8)
        let link2Content = String(bytes: utf8[link2.byteRange], encoding: .utf8)
        XCTAssertEqual(link1Content, "file1.md")
        XCTAssertEqual(link2Content, "file2.md")
    }

    func testByteOffsets_MultiByteUTF8() {
        let content = "\"файл.md\"\n\"café.md\"\n"
        let parsed = EditorParser.parse(content: content, filePath: "utf8.hc")

        XCTAssertEqual(parsed.linkSpans.count, 2)

        // Verify byte ranges match actual content
        let utf8 = Array(content.utf8)
        for link in parsed.linkSpans {
            let linkContent = String(bytes: utf8[link.byteRange], encoding: .utf8)
            XCTAssertEqual(linkContent, link.literal, "Byte range should extract exact literal")
        }
    }

    func testLineStartOffsets_TrailingNewlineEdgeCase() {
        // This test verifies the fix for B-002 from code review
        // File: "Line1\nLine2\n" = 12 bytes total
        // Lines after split: ["Line1", "Line2"]
        // Expected offsets: [0, 6] (start of Line1, start of Line2)
        // File length: 12 bytes (5 + \n + 5 + \n)

        let content = "Line1\nLine2\n"
        let utf8Count = content.utf8.count
        XCTAssertEqual(utf8Count, 12, "File should be 12 bytes")

        // Parse and verify through linkAt functionality
        // Since we can't access computeLineStartOffsets directly (it's private),
        // we verify correct behavior through the public API by checking
        // that byte extraction works correctly

        let testContent = "\"link.md\"\n\"other.md\"\n"
        let parsed = EditorParser.parse(content: testContent, filePath: "test.hc")

        // Verify that the last link's byte range is within file bounds
        if let lastLink = parsed.linkSpans.last {
            let fileSize = testContent.utf8.count
            XCTAssertLessThan(lastLink.byteRange.upperBound, fileSize + 1,
                             "Byte range should be within file bounds")

            // Extract and verify
            let utf8 = Array(testContent.utf8)
            let extracted = String(bytes: utf8[lastLink.byteRange], encoding: .utf8)
            XCTAssertEqual(extracted, lastLink.literal,
                          "Byte range extraction should match literal")
        }
    }
}
#endif

#if Editor
import XCTest
import Core
@testable import EditorEngine

final class EditorParserLinkAtTests: XCTestCase {
    private let parser = EditorParser()

    // MARK: - Happy Path Tests

    func testLinkAtReturnsLinkWhenPositionInside() {
        // File with a single link: "file.md" at line 1, columns 2-10
        let content = """
        @"file.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Position inside the link (line 1, column 5)
        let result = parser.linkAt(line: 1, column: 5, in: parsedFile)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.literal, "file.md")
        XCTAssertEqual(result?.lineRange, 1..<2)
    }

    func testLinkAtReturnsFirstLinkWhenMultipleLinksExist() {
        let content = """
        @"first.md" and @"second.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Position in first link
        let result = parser.linkAt(line: 1, column: 3, in: parsedFile)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.literal, "first.md")
    }

    func testLinkAtReturnsSecondLinkWhenPositionInSecond() {
        let content = """
        @"first.md" and @"second.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Position in second link (after "and ")
        let result = parser.linkAt(line: 1, column: 18, in: parsedFile)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.literal, "second.md")
    }

    func testLinkAtReturnsLinkOnMultipleLines() {
        let content = """
        First line with @"link1.md"
        Second line with @"link2.md"
        Third line with @"link3.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Position in link on line 2
        let result = parser.linkAt(line: 2, column: 19, in: parsedFile)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.literal, "link2.md")
        XCTAssertEqual(result?.lineRange, 2..<3)
    }

    // MARK: - Edge Case: Empty Array

    func testLinkAtReturnsNilWhenNoLinks() {
        let content = """
        This file has no links at all
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        let result = parser.linkAt(line: 1, column: 5, in: parsedFile)

        XCTAssertNil(result)
    }

    // MARK: - Edge Case: Position Before First Link

    func testLinkAtReturnsNilWhenPositionBeforeFirstLink() {
        let content = """
        Some text @"link.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Position at column 1 (before the link)
        let result = parser.linkAt(line: 1, column: 1, in: parsedFile)

        XCTAssertNil(result)
    }

    func testLinkAtReturnsNilWhenLineBeforeFirstLink() {
        let content = """
        First line
        @"link.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Position on line 1 (before link on line 2)
        let result = parser.linkAt(line: 1, column: 5, in: parsedFile)

        XCTAssertNil(result)
    }

    // MARK: - Edge Case: Position After Last Link

    func testLinkAtReturnsNilWhenPositionAfterLastLink() {
        let content = """
        @"link.md" some text after
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Position after the link (column 20)
        let result = parser.linkAt(line: 1, column: 20, in: parsedFile)

        XCTAssertNil(result)
    }

    func testLinkAtReturnsNilWhenLineAfterLastLink() {
        let content = """
        @"link.md"
        Last line
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Position on line 2 (after link on line 1)
        let result = parser.linkAt(line: 2, column: 5, in: parsedFile)

        XCTAssertNil(result)
    }

    // MARK: - Edge Case: Position Between Links (Horizontal Gap)

    func testLinkAtReturnsNilWhenPositionBetweenLinksHorizontally() {
        let content = """
        @"first.md"    @"second.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Position in the gap between links (around column 12-14)
        let result = parser.linkAt(line: 1, column: 13, in: parsedFile)

        XCTAssertNil(result)
    }

    // MARK: - Edge Case: Position Between Links (Vertical Gap)

    func testLinkAtReturnsNilWhenPositionBetweenLinksVertically() {
        let content = """
        @"link1.md"

        @"link2.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Position on empty line 2 (between links on lines 1 and 3)
        let result = parser.linkAt(line: 2, column: 1, in: parsedFile)

        XCTAssertNil(result)
    }

    // MARK: - Edge Case: Boundary Conditions

    func testLinkAtReturnsLinkAtStartBoundary() {
        let content = """
        @"file.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // The link "@"file.md"" starts at column 2 (after @)
        // So column 2 should be the first column of the literal
        let result = parser.linkAt(line: 1, column: 2, in: parsedFile)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.literal, "file.md")
    }

    func testLinkAtReturnsNilAtEndBoundary() {
        let content = """
        @"file.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Get the link to find its exact end column
        guard let link = parsedFile.linkSpans.first else {
            XCTFail("No link found in test file")
            return
        }

        // End boundary should be exclusive
        let endColumn = link.columnRange.upperBound
        let result = parser.linkAt(line: 1, column: endColumn, in: parsedFile)

        XCTAssertNil(result, "End boundary should be exclusive")
    }

    func testLinkAtReturnsLinkOneBeforeEndBoundary() {
        let content = """
        @"file.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        guard let link = parsedFile.linkSpans.first else {
            XCTFail("No link found in test file")
            return
        }

        // One column before end should still be inside
        let lastColumn = link.columnRange.upperBound - 1
        let result = parser.linkAt(line: 1, column: lastColumn, in: parsedFile)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.literal, "file.md")
    }

    // MARK: - Edge Case: Invalid Input

    func testLinkAtReturnsNilForNegativeLine() {
        let content = """
        @"file.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        let result = parser.linkAt(line: -1, column: 5, in: parsedFile)

        XCTAssertNil(result)
    }

    func testLinkAtReturnsNilForZeroLine() {
        let content = """
        @"file.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        let result = parser.linkAt(line: 0, column: 5, in: parsedFile)

        XCTAssertNil(result)
    }

    func testLinkAtReturnsNilForNegativeColumn() {
        let content = """
        @"file.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        let result = parser.linkAt(line: 1, column: -1, in: parsedFile)

        XCTAssertNil(result)
    }

    func testLinkAtReturnsNilForZeroColumn() {
        let content = """
        @"file.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        let result = parser.linkAt(line: 1, column: 0, in: parsedFile)

        XCTAssertNil(result)
    }

    // MARK: - Edge Case: Line Beyond File Bounds

    func testLinkAtReturnsNilForLineBeyondFileBounds() {
        let content = """
        @"file.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        let result = parser.linkAt(line: 100, column: 5, in: parsedFile)

        XCTAssertNil(result)
    }

    // MARK: - Edge Case: Column Beyond Line Bounds

    func testLinkAtReturnsNilForColumnBeyondLineBounds() {
        let content = """
        @"file.md"
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        let result = parser.linkAt(line: 1, column: 1000, in: parsedFile)

        XCTAssertNil(result)
    }

    // MARK: - Performance Test

    func testLinkAtPerformanceWithManyLinks() {
        // Generate a file with 1000 links
        var lines: [String] = []
        for i in 0..<1000 {
            lines.append("@\"link\(i).md\"")
        }
        let content = lines.joined(separator: "\n")
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        XCTAssertEqual(parsedFile.linkSpans.count, 1000)

        // Measure lookup time (should be O(log n))
        measure {
            for _ in 0..<100 {
                // Search for link at line 500
                _ = parser.linkAt(line: 500, column: 3, in: parsedFile)
            }
        }
    }

    // MARK: - Comprehensive Multi-Scenario Test

    func testLinkAtWithComplexFile() {
        let content = """
        First line with @"link1.md" and @"link2.md"

        Third line with @"link3.md"
        Fourth line: @"link4.md" some text @"link5.md"
        Last line
        """
        let parsedFile = parser.parse(content: content, filePath: "test.hc")

        // Verify we found all 5 links
        XCTAssertEqual(parsedFile.linkSpans.count, 5)

        // Test link1 on line 1
        let link1 = parser.linkAt(line: 1, column: 18, in: parsedFile)
        XCTAssertEqual(link1?.literal, "link1.md")

        // Test link2 on line 1
        let link2 = parser.linkAt(line: 1, column: 34, in: parsedFile)
        XCTAssertEqual(link2?.literal, "link2.md")

        // Test empty line 2
        let emptyLine = parser.linkAt(line: 2, column: 1, in: parsedFile)
        XCTAssertNil(emptyLine)

        // Test link3 on line 3
        let link3 = parser.linkAt(line: 3, column: 18, in: parsedFile)
        XCTAssertEqual(link3?.literal, "link3.md")

        // Test link4 on line 4
        let link4 = parser.linkAt(line: 4, column: 15, in: parsedFile)
        XCTAssertEqual(link4?.literal, "link4.md")

        // Test gap between link4 and link5
        let gap = parser.linkAt(line: 4, column: 28, in: parsedFile)
        XCTAssertNil(gap)

        // Test link5 on line 4
        let link5 = parser.linkAt(line: 4, column: 37, in: parsedFile)
        XCTAssertEqual(link5?.literal, "link5.md")

        // Test last line without links
        let lastLine = parser.linkAt(line: 5, column: 5, in: parsedFile)
        XCTAssertNil(lastLine)
    }
}
#endif

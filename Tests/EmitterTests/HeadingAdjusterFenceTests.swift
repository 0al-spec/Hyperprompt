import XCTest
@testable import Emitter

final class HeadingAdjusterFenceTests: XCTestCase {
    private let adjuster = HeadingAdjuster()

    func testBacktickFencePreservesHeadingsAndAdjustsOutside() {
        let input = [
            "# Outside",
            "",
            "```swift",
            "# Inside",
            "Title",
            "---",
            "```",
            "",
            "## After",
        ].joined(separator: "\n")

        let expected = [
            "## Outside",
            "",
            "```swift",
            "# Inside",
            "Title",
            "---",
            "```",
            "",
            "### After",
            "",
        ].joined(separator: "\n")

        XCTAssertEqual(adjuster.adjustHeadings(in: input, offset: 1), expected)
    }

    func testTildeFencePreservesContent() {
        let input = [
            "~~~json",
            "# not-a-heading",
            "Setext-like",
            "===",
            "~~~",
            "# Real heading",
        ].joined(separator: "\n")

        let expected = [
            "~~~json",
            "# not-a-heading",
            "Setext-like",
            "===",
            "~~~",
            "### Real heading",
            "",
        ].joined(separator: "\n")

        XCTAssertEqual(adjuster.adjustHeadings(in: input, offset: 2), expected)
    }

    func testShorterAndOppositeFencesDoNotCloseBlock() {
        let input = [
            "````",
            "# first",
            "```",
            "# second",
            "~~~~",
            "# third",
            "````",
            "# outside",
        ].joined(separator: "\n")

        let expected = [
            "````",
            "# first",
            "```",
            "# second",
            "~~~~",
            "# third",
            "````",
            "## outside",
            "",
        ].joined(separator: "\n")

        XCTAssertEqual(adjuster.adjustHeadings(in: input, offset: 1), expected)
    }

    func testLongerFenceAndTrailingWhitespaceCloseBlock() {
        let input = [
            "```text",
            "# inside",
            "````   \t",
            "# outside",
        ].joined(separator: "\n")

        let expected = [
            "```text",
            "# inside",
            "````   \t",
            "## outside",
            "",
        ].joined(separator: "\n")

        XCTAssertEqual(adjuster.adjustHeadings(in: input, offset: 1), expected)
    }

    func testClosingFenceWithTrailingTextDoesNotCloseBlock() {
        let input = [
            "```",
            "```not-a-close",
            "# still inside",
            "```",
            "# outside",
        ].joined(separator: "\n")

        let expected = [
            "```",
            "```not-a-close",
            "# still inside",
            "```",
            "## outside",
            "",
        ].joined(separator: "\n")

        XCTAssertEqual(adjuster.adjustHeadings(in: input, offset: 1), expected)
    }

    func testUnclosedFencePreservesRemainder() {
        let input = [
            "# outside",
            "```",
            "# inside",
            "Title",
            "---",
        ].joined(separator: "\n")

        let expected = [
            "## outside",
            "```",
            "# inside",
            "Title",
            "---",
            "",
        ].joined(separator: "\n")

        XCTAssertEqual(adjuster.adjustHeadings(in: input, offset: 1), expected)
    }

    func testFenceIndentationBoundary() {
        let recognized = [
            "   ```",
            "# inside",
            "   ```",
            "# outside",
        ].joined(separator: "\n")

        XCTAssertEqual(
            adjuster.adjustHeadings(in: recognized, offset: 1),
            [
                "   ```",
                "# inside",
                "   ```",
                "## outside",
                "",
            ].joined(separator: "\n")
        )

        let fourSpaces = [
            "    ```",
            "# heading",
        ].joined(separator: "\n")

        XCTAssertEqual(
            adjuster.adjustHeadings(in: fourSpaces, offset: 1),
            [
                "    ```",
                "## heading",
                "",
            ].joined(separator: "\n")
        )
    }

    func testBacktickInInfoStringDoesNotOpenFence() {
        let input = [
            "```lang`variant",
            "# heading",
        ].joined(separator: "\n")

        XCTAssertEqual(
            adjuster.adjustHeadings(in: input, offset: 1),
            [
                "```lang`variant",
                "## heading",
                "",
            ].joined(separator: "\n")
        )
    }

    func testIndentedCodeIsNotTreatedAsHeading() {
        XCTAssertEqual(
            adjuster.adjustHeadings(in: "    # code\n   # heading", offset: 1),
            "    # code\n## heading\n"
        )
    }

    func testCRLFFenceContentIsPreservedWithLFOutput() {
        let input = "```json\r\n# value\r\n```\r\n# heading\r\n"
        XCTAssertEqual(
            adjuster.adjustHeadings(in: input, offset: 1),
            "```json\n# value\n```\n## heading\n"
        )
    }

    func testAdjustmentReportsSourceLineSpans() {
        let input = [
            "# First",
            "Setext",
            "---",
            "```",
            "# fenced",
            "```",
        ].joined(separator: "\n")

        let result = adjuster.adjustHeadingsWithOrigins(in: input, offset: 1)

        XCTAssertEqual(
            result.lineOrigins,
            [
                SourceLineSpan(startLine: 1, endLine: 1),
                SourceLineSpan(startLine: 2, endLine: 3),
                SourceLineSpan(startLine: 4, endLine: 4),
                SourceLineSpan(startLine: 5, endLine: 5),
                SourceLineSpan(startLine: 6, endLine: 6),
            ]
        )
        XCTAssertEqual(
            result.markdown,
            "## First\n### Setext\n```\n# fenced\n```\n"
        )
    }
}

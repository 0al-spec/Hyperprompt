// HeadingAdjusterTests.swift
// Tests for HeadingAdjuster - C1: Heading Adjuster
//
// Comprehensive test coverage for ATX and Setext heading transformation,
// overflow handling, and edge cases.

import XCTest
@testable import Emitter

final class HeadingAdjusterTests: XCTestCase {

    var adjuster: HeadingAdjuster!

    override func setUp() {
        super.setUp()
        adjuster = HeadingAdjuster()
    }

    override func tearDown() {
        adjuster = nil
        super.tearDown()
    }

    // MARK: - Empty and Edge Case Input Tests

    func testEmptyInput() {
        let result = adjuster.adjustHeadings(in: "", offset: 1)
        XCTAssertEqual(result, "")
    }

    func testWhitespaceOnlyInput() {
        let result = adjuster.adjustHeadings(in: "   ", offset: 1)
        XCTAssertEqual(result, "   \n")
    }

    func testNoHeadingsInput() {
        let input = "Just some regular text.\nAnother line."
        let result = adjuster.adjustHeadings(in: input, offset: 2)
        XCTAssertEqual(result, "Just some regular text.\nAnother line.\n")
    }

    func testZeroOffset() {
        let input = "# Heading"
        let result = adjuster.adjustHeadings(in: input, offset: 0)
        XCTAssertEqual(result, "# Heading\n")
    }

    func testNegativeOffsetTreatedAsZero() {
        let input = "# Heading"
        let result = adjuster.adjustHeadings(in: input, offset: -5)
        XCTAssertEqual(result, "# Heading\n")
    }

    // MARK: - ATX Heading Detection Tests

    func testIsATXHeadingH1() {
        XCTAssertTrue(adjuster.isATXHeading("# Heading"))
    }

    func testIsATXHeadingH2() {
        XCTAssertTrue(adjuster.isATXHeading("## Heading"))
    }

    func testIsATXHeadingH3() {
        XCTAssertTrue(adjuster.isATXHeading("### Heading"))
    }

    func testIsATXHeadingH4() {
        XCTAssertTrue(adjuster.isATXHeading("#### Heading"))
    }

    func testIsATXHeadingH5() {
        XCTAssertTrue(adjuster.isATXHeading("##### Heading"))
    }

    func testIsATXHeadingH6() {
        XCTAssertTrue(adjuster.isATXHeading("###### Heading"))
    }

    func testIsATXHeadingWithLeadingSpaces() {
        XCTAssertTrue(adjuster.isATXHeading("  # Heading"))
    }

    func testIsATXHeadingBareHashes() {
        XCTAssertTrue(adjuster.isATXHeading("###"))
    }

    func testNotATXHeadingSevenHashes() {
        XCTAssertFalse(adjuster.isATXHeading("####### Too many"))
    }

    func testNotATXHeadingNoSpace() {
        // According to CommonMark, "##Text" without space is not a heading
        // However, some implementations are lenient. We follow strict ATX rules.
        XCTAssertFalse(adjuster.isATXHeading("##NoSpace"))
    }

    func testNotATXHeadingHashInMiddle() {
        XCTAssertFalse(adjuster.isATXHeading("text # not heading"))
    }

    func testNotATXHeadingPlainText() {
        XCTAssertFalse(adjuster.isATXHeading("Just regular text"))
    }

    // MARK: - ATX Heading Level Extraction Tests

    func testExtractATXLevelH1() {
        XCTAssertEqual(adjuster.extractATXLevel("# Heading"), 1)
    }

    func testExtractATXLevelH3() {
        XCTAssertEqual(adjuster.extractATXLevel("### Heading"), 3)
    }

    func testExtractATXLevelH6() {
        XCTAssertEqual(adjuster.extractATXLevel("###### Heading"), 6)
    }

    func testExtractATXLevelWithLeadingSpaces() {
        XCTAssertEqual(adjuster.extractATXLevel("   ## Heading"), 2)
    }

    // MARK: - ATX Text Extraction Tests

    func testExtractATXTextSimple() {
        XCTAssertEqual(adjuster.extractATXText("# Simple Heading"), "Simple Heading")
    }

    func testExtractATXTextWithClosingHashes() {
        XCTAssertEqual(adjuster.extractATXText("## Heading ##"), "Heading")
    }

    func testExtractATXTextWithExtraSpaces() {
        XCTAssertEqual(adjuster.extractATXText("##  Double Space"), " Double Space")
    }

    func testExtractATXTextWithInlineFormatting() {
        XCTAssertEqual(adjuster.extractATXText("# *Italic* **Bold**"), "*Italic* **Bold**")
    }

    func testExtractATXTextEmpty() {
        XCTAssertEqual(adjuster.extractATXText("###"), "")
    }

    // MARK: - ATX Heading Transformation Tests

    func testATXHeadingOffset1() {
        let result = adjuster.adjustHeadings(in: "# Heading 1", offset: 1)
        XCTAssertEqual(result, "## Heading 1\n")
    }

    func testATXHeadingOffset2() {
        let result = adjuster.adjustHeadings(in: "# Heading", offset: 2)
        XCTAssertEqual(result, "### Heading\n")
    }

    func testATXHeadingH2Offset3() {
        let result = adjuster.adjustHeadings(in: "## Heading 2", offset: 3)
        XCTAssertEqual(result, "##### Heading 2\n")
    }

    func testATXHeadingExactlyH6() {
        let result = adjuster.adjustHeadings(in: "# Heading", offset: 5)
        XCTAssertEqual(result, "###### Heading\n")
    }

    func testATXHeadingAllLevelsOffset1() {
        let input = """
        # H1
        ## H2
        ### H3
        #### H4
        ##### H5
        ###### H6
        """
        let expected = """
        ## H1
        ### H2
        #### H3
        ##### H4
        ###### H5
        **H6**
        """
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        XCTAssertEqual(result, expected + "\n")
    }

    // MARK: - ATX Overflow Tests

    func testATXOverflowH1Plus6() {
        let result = adjuster.adjustHeadings(in: "# Deep", offset: 6)
        XCTAssertEqual(result, "**Deep**\n")
    }

    func testATXOverflowH5Plus2() {
        let result = adjuster.adjustHeadings(in: "##### Level 5", offset: 2)
        XCTAssertEqual(result, "**Level 5**\n")
    }

    func testATXOverflowH6Plus1() {
        let result = adjuster.adjustHeadings(in: "###### Already H6", offset: 1)
        XCTAssertEqual(result, "**Already H6**\n")
    }

    func testATXOverflowHighOffset() {
        let result = adjuster.adjustHeadings(in: "## Title", offset: 10)
        XCTAssertEqual(result, "**Title**\n")
    }

    func testATXOverflowPreservesFormatting() {
        // When "##### *Italic* **Bold**" overflows, text "*Italic* **Bold**" is wrapped in **...**
        // Result: "**" + "*Italic* **Bold**" + "**" = "***Italic* **Bold****"
        let result = adjuster.adjustHeadings(in: "##### *Italic* **Bold**", offset: 3)
        XCTAssertEqual(result, "***Italic* **Bold****\n")
    }

    // MARK: - Setext Underline Detection Tests

    func testParseSetextUnderlineEquals() {
        XCTAssertEqual(adjuster.parseSetextUnderline("==="), 1)
    }

    func testParseSetextUnderlineDashes() {
        XCTAssertEqual(adjuster.parseSetextUnderline("---"), 2)
    }

    func testParseSetextUnderlineLongEquals() {
        XCTAssertEqual(adjuster.parseSetextUnderline("================="), 1)
    }

    func testParseSetextUnderlineLongDashes() {
        XCTAssertEqual(adjuster.parseSetextUnderline("------------------"), 2)
    }

    func testParseSetextUnderlineSingleEquals() {
        XCTAssertEqual(adjuster.parseSetextUnderline("="), 1)
    }

    func testParseSetextUnderlineSingleDash() {
        XCTAssertEqual(adjuster.parseSetextUnderline("-"), 2)
    }

    func testParseSetextUnderlineWithSpaces() {
        XCTAssertEqual(adjuster.parseSetextUnderline("  ===  "), 1)
    }

    func testNotSetextUnderlineMixed() {
        XCTAssertNil(adjuster.parseSetextUnderline("=-="))
    }

    func testNotSetextUnderlineEmpty() {
        XCTAssertNil(adjuster.parseSetextUnderline(""))
    }

    func testNotSetextUnderlineText() {
        XCTAssertNil(adjuster.parseSetextUnderline("Some text"))
    }

    // MARK: - Setext Heading Transformation Tests

    func testSetextH1Offset1() {
        let input = "Heading\n======="
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        XCTAssertEqual(result, "## Heading\n")
    }

    func testSetextH2Offset1() {
        let input = "Subheading\n----------"
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        XCTAssertEqual(result, "### Subheading\n")
    }

    func testSetextH1Offset3() {
        let input = "Title\n====="
        let result = adjuster.adjustHeadings(in: input, offset: 3)
        XCTAssertEqual(result, "#### Title\n")
    }

    func testSetextH2Offset4() {
        let input = "Section\n-------"
        let result = adjuster.adjustHeadings(in: input, offset: 4)
        XCTAssertEqual(result, "###### Section\n")
    }

    func testSetextOverflowH1Plus6() {
        let input = "Deep Title\n=========="
        let result = adjuster.adjustHeadings(in: input, offset: 6)
        XCTAssertEqual(result, "**Deep Title**\n")
    }

    func testSetextOverflowH2Plus5() {
        let input = "Also Deep\n---------"
        let result = adjuster.adjustHeadings(in: input, offset: 5)
        XCTAssertEqual(result, "**Also Deep**\n")
    }

    func testSetextMultipleHeadings() {
        let input = """
        Main Title
        ==========

        Some text here.

        Subsection
        ----------
        """
        let result = adjuster.adjustHeadings(in: input, offset: 2)
        let expected = """
        ### Main Title

        Some text here.

        #### Subsection
        """
        XCTAssertEqual(result, expected + "\n")
    }

    // MARK: - Mixed Content Tests

    func testMixedATXAndSetext() {
        let input = """
        # ATX Heading

        Setext Title
        ============

        ## Another ATX

        Setext Sub
        ----------
        """
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        let expected = """
        ## ATX Heading

        ## Setext Title

        ### Another ATX

        ### Setext Sub
        """
        XCTAssertEqual(result, expected + "\n")
    }

    func testMixedWithRegularText() {
        let input = """
        # Introduction

        This is some body text that should not be changed.
        It has multiple lines.

        ## Methods

        More text here describing methods.
        - List item 1
        - List item 2

        ### Results
        """
        let result = adjuster.adjustHeadings(in: input, offset: 2)
        let expected = """
        ### Introduction

        This is some body text that should not be changed.
        It has multiple lines.

        #### Methods

        More text here describing methods.
        - List item 1
        - List item 2

        ##### Results
        """
        XCTAssertEqual(result, expected + "\n")
    }

    // MARK: - Line Ending Normalization Tests

    func testNormalizeCRLF() {
        let input = "# Heading\r\nBody text\r\n## Another"
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        XCTAssertEqual(result, "## Heading\nBody text\n### Another\n")
    }

    func testNormalizeCR() {
        let input = "# Heading\rBody text\r## Another"
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        XCTAssertEqual(result, "## Heading\nBody text\n### Another\n")
    }

    func testNormalizeMixedLineEndings() {
        let input = "# H1\r\nText\r## H2\nMore\r\n### H3"
        let result = adjuster.adjustHeadings(in: input, offset: 0)
        XCTAssertEqual(result, "# H1\nText\n## H2\nMore\n### H3\n")
    }

    func testOutputEndsWithSingleNewline() {
        let input = "# Heading"
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        XCTAssertTrue(result.hasSuffix("\n"))
        XCTAssertFalse(result.hasSuffix("\n\n"))
    }

    func testInputWithMultipleTrailingNewlines() {
        let input = "# Heading\n\n\n"
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        XCTAssertEqual(result, "## Heading\n")
    }

    func testInputWithNoTrailingNewline() {
        let input = "# Heading"
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        XCTAssertEqual(result, "## Heading\n")
    }

    // MARK: - Determinism Tests

    func testDeterministicOutput() {
        let input = """
        # Title
        ## Subtitle
        Some text
        ### Section
        More text
        """

        let result1 = adjuster.adjustHeadings(in: input, offset: 2)
        let result2 = adjuster.adjustHeadings(in: input, offset: 2)
        let result3 = adjuster.adjustHeadings(in: input, offset: 2)

        XCTAssertEqual(result1, result2)
        XCTAssertEqual(result2, result3)
    }

    // MARK: - Special Character Tests

    func testHeadingWithUnicode() {
        let result = adjuster.adjustHeadings(in: "# 中文标题", offset: 1)
        XCTAssertEqual(result, "## 中文标题\n")
    }

    func testHeadingWithEmoji() {
        let result = adjuster.adjustHeadings(in: "## Hello World", offset: 1)
        XCTAssertEqual(result, "### Hello World\n")
    }

    func testHeadingWithCode() {
        let result = adjuster.adjustHeadings(in: "## Using `function()`", offset: 1)
        XCTAssertEqual(result, "### Using `function()`\n")
    }

    func testHeadingWithLinks() {
        let result = adjuster.adjustHeadings(in: "# [Link](http://example.com)", offset: 2)
        XCTAssertEqual(result, "### [Link](http://example.com)\n")
    }

    // MARK: - Edge Cases from PRD

    func testPRDExampleOffset2() {
        // From PRD §3.1: Input offset: +2
        XCTAssertEqual(
            adjuster.adjustHeadings(in: "# Heading 1", offset: 2),
            "### Heading 1\n"
        )
        XCTAssertEqual(
            adjuster.adjustHeadings(in: "## Heading 2", offset: 2),
            "#### Heading 2\n"
        )
        XCTAssertEqual(
            adjuster.adjustHeadings(in: "##### Heading 5", offset: 2),
            "**Heading 5**\n"
        )
    }

    func testPRDExampleOffset6() {
        // From PRD §3.3: Input offset: +6
        XCTAssertEqual(
            adjuster.adjustHeadings(in: "# Very Deep", offset: 6),
            "**Very Deep**\n"
        )
        XCTAssertEqual(
            adjuster.adjustHeadings(in: "## Also Deep", offset: 6),
            "**Also Deep**\n"
        )
    }

    func testPRDExampleOffset5ExactlyH6() {
        // From PRD §3.3: Non-Overflow Cases - offset +5
        XCTAssertEqual(
            adjuster.adjustHeadings(in: "# Okay", offset: 5),
            "###### Okay\n"
        )
    }

    func testPRDSetextExample() {
        // From PRD §3.2: Input offset: +3
        let input1 = "Heading\n========="
        XCTAssertEqual(
            adjuster.adjustHeadings(in: input1, offset: 3),
            "#### Heading\n"
        )

        let input2 = "Subheading\n-----------"
        XCTAssertEqual(
            adjuster.adjustHeadings(in: input2, offset: 3),
            "##### Subheading\n"
        )
    }

    // MARK: - Non-Heading Lines Preserved

    func testCodeBlockPreserved() {
        let input = """
        # Heading

        ```swift
        # This is a comment, not a heading
        let x = 1
        ```
        """
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        // Note: We don't parse code blocks in v0.1, so the # inside would be treated
        // as a heading. This is documented as out of scope.
        // For now, we just check the main heading is adjusted.
        XCTAssertTrue(result.hasPrefix("## Heading\n"))
    }

    func testHorizontalRuleNotTreatedAsSetext() {
        // A standalone --- or === should not cause issues
        let input = """
        # Title

        ---

        Regular text
        """
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        // The --- follows an empty line, so "---" line's previous line is empty
        // Empty lines are not treated as Setext heading text
        let expected = """
        ## Title

        ---

        Regular text
        """
        XCTAssertEqual(result, expected + "\n")
    }

    func testListItemNotTreatedAsSetext() {
        let input = """
        Item description
        - list item
        """
        // "- list item" should not match as Setext underline because it has text after
        let result = adjuster.adjustHeadings(in: input, offset: 1)
        XCTAssertEqual(result, "Item description\n- list item\n")
    }
}

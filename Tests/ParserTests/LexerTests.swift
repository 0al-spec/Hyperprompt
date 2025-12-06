import XCTest
@testable import Parser
@testable import Core

/// Unit tests for the Lexer component.
///
/// Tests cover:
/// - Blank line classification
/// - Comment line classification
/// - Node line classification
/// - Indentation validation (tabs, alignment)
/// - Literal extraction
/// - Single-line enforcement
/// - Line ending normalization
/// - Error cases
final class LexerTests: XCTestCase {
    var lexer: Lexer!

    override func setUp() {
        super.setUp()
        lexer = Lexer()
    }

    override func tearDown() {
        lexer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Tokenize content and return tokens.
    func tokenize(_ content: String, file: String = "test.hc") throws -> [Token] {
        try lexer.tokenize(content: content, filePath: file)
    }

    /// Assert that tokenization throws a specific error.
    func assertThrows<E: Error & Equatable>(
        _ content: String,
        error expectedError: E,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try tokenize(content), file: file, line: line) { error in
            guard let lexerError = error as? E else {
                XCTFail("Expected \(E.self), got \(type(of: error))", file: file, line: line)
                return
            }
            XCTAssertEqual(lexerError, expectedError, file: file, line: line)
        }
    }

    // MARK: - Empty Input Tests

    func testEmptyContent() throws {
        let tokens = try tokenize("")
        XCTAssertTrue(tokens.isEmpty)
    }

    func testOnlyNewline() throws {
        let tokens = try tokenize("\n")
        XCTAssertEqual(tokens.count, 1)
        guard case .blank = tokens[0] else {
            XCTFail("Expected blank token")
            return
        }
    }

    // MARK: - Blank Line Tests

    func testBlankLine_Empty() throws {
        let tokens = try tokenize("", file: "test.hc")
        XCTAssertTrue(tokens.isEmpty)
    }

    func testBlankLine_Spaces() throws {
        let tokens = try tokenize("    ")
        XCTAssertEqual(tokens.count, 1)
        guard case .blank(let location) = tokens[0] else {
            XCTFail("Expected blank token")
            return
        }
        XCTAssertEqual(location.line, 1)
    }

    func testBlankLine_ManySpaces() throws {
        let tokens = try tokenize("        ")  // 8 spaces
        XCTAssertEqual(tokens.count, 1)
        guard case .blank = tokens[0] else {
            XCTFail("Expected blank token")
            return
        }
    }

    func testMultipleBlankLines() throws {
        let tokens = try tokenize("\n\n\n")
        XCTAssertEqual(tokens.count, 3)
        for token in tokens {
            guard case .blank = token else {
                XCTFail("Expected blank token")
                return
            }
        }
    }

    // MARK: - Comment Line Tests

    func testCommentLine_NoIndent() throws {
        let tokens = try tokenize("# This is a comment")
        XCTAssertEqual(tokens.count, 1)
        guard case .comment(let indent, let location) = tokens[0] else {
            XCTFail("Expected comment token")
            return
        }
        XCTAssertEqual(indent, 0)
        XCTAssertEqual(location.line, 1)
    }

    func testCommentLine_WithIndent() throws {
        let tokens = try tokenize("    # Indented comment")
        XCTAssertEqual(tokens.count, 1)
        guard case .comment(let indent, _) = tokens[0] else {
            XCTFail("Expected comment token")
            return
        }
        XCTAssertEqual(indent, 4)
    }

    func testCommentLine_DeepIndent() throws {
        let tokens = try tokenize("        # Deep comment")  // 8 spaces
        XCTAssertEqual(tokens.count, 1)
        guard case .comment(let indent, _) = tokens[0] else {
            XCTFail("Expected comment token")
            return
        }
        XCTAssertEqual(indent, 8)
    }

    func testCommentLine_EmptyComment() throws {
        let tokens = try tokenize("#")
        XCTAssertEqual(tokens.count, 1)
        guard case .comment(let indent, _) = tokens[0] else {
            XCTFail("Expected comment token")
            return
        }
        XCTAssertEqual(indent, 0)
    }

    // MARK: - Node Line Tests

    func testNodeLine_Simple() throws {
        let tokens = try tokenize("\"Hello\"")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(let indent, let literal, let location) = tokens[0] else {
            XCTFail("Expected node token")
            return
        }
        XCTAssertEqual(indent, 0)
        XCTAssertEqual(literal, "Hello")
        XCTAssertEqual(location.line, 1)
    }

    func testNodeLine_WithIndent() throws {
        let tokens = try tokenize("    \"Child\"")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(let indent, let literal, _) = tokens[0] else {
            XCTFail("Expected node token")
            return
        }
        XCTAssertEqual(indent, 4)
        XCTAssertEqual(literal, "Child")
    }

    func testNodeLine_DeepIndent() throws {
        let tokens = try tokenize("        \"Deep Child\"")  // 8 spaces
        XCTAssertEqual(tokens.count, 1)
        guard case .node(let indent, let literal, _) = tokens[0] else {
            XCTFail("Expected node token")
            return
        }
        XCTAssertEqual(indent, 8)
        XCTAssertEqual(literal, "Deep Child")
    }

    func testNodeLine_EmptyLiteral() throws {
        let tokens = try tokenize("\"\"")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(let indent, let literal, _) = tokens[0] else {
            XCTFail("Expected node token")
            return
        }
        XCTAssertEqual(indent, 0)
        XCTAssertEqual(literal, "")
    }

    func testNodeLine_WithSpaces() throws {
        let tokens = try tokenize("\"Hello World\"")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(_, let literal, _) = tokens[0] else {
            XCTFail("Expected node token")
            return
        }
        XCTAssertEqual(literal, "Hello World")
    }

    func testNodeLine_FilePath() throws {
        let tokens = try tokenize("\"docs/README.md\"")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(_, let literal, _) = tokens[0] else {
            XCTFail("Expected node token")
            return
        }
        XCTAssertEqual(literal, "docs/README.md")
    }

    func testNodeLine_HypercodeExtension() throws {
        let tokens = try tokenize("\"components/header.hc\"")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(_, let literal, _) = tokens[0] else {
            XCTFail("Expected node token")
            return
        }
        XCTAssertEqual(literal, "components/header.hc")
    }

    func testNodeLine_TrailingWhitespace() throws {
        let tokens = try tokenize("\"literal\"   ")  // trailing spaces allowed
        XCTAssertEqual(tokens.count, 1)
        guard case .node(_, let literal, _) = tokens[0] else {
            XCTFail("Expected node token")
            return
        }
        XCTAssertEqual(literal, "literal")
    }

    // MARK: - Line Ending Normalization Tests

    func testLineEnding_LF() throws {
        let tokens = try tokenize("\"Line1\"\n\"Line2\"")
        XCTAssertEqual(tokens.count, 2)
    }

    func testLineEnding_CRLF() throws {
        let tokens = try tokenize("\"Line1\"\r\n\"Line2\"")
        XCTAssertEqual(tokens.count, 2)
    }

    func testLineEnding_CR() throws {
        let tokens = try tokenize("\"Line1\"\r\"Line2\"")
        XCTAssertEqual(tokens.count, 2)
    }

    func testLineEnding_Mixed() throws {
        let tokens = try tokenize("\"A\"\n\"B\"\r\n\"C\"\r\"D\"")
        XCTAssertEqual(tokens.count, 4)
    }

    func testLineEnding_TrailingLF() throws {
        let tokens = try tokenize("\"Single\"\n")
        XCTAssertEqual(tokens.count, 1)
    }

    func testLineEnding_TrailingCRLF() throws {
        let tokens = try tokenize("\"Single\"\r\n")
        XCTAssertEqual(tokens.count, 1)
    }

    // MARK: - Complex Document Tests

    func testComplexDocument() throws {
        let content = """
        "Root"
            "Child 1"
            "Child 2"
                "Grandchild"
        """
        let tokens = try tokenize(content)
        XCTAssertEqual(tokens.count, 4)

        guard case .node(let indent0, let lit0, _) = tokens[0] else { XCTFail(); return }
        XCTAssertEqual(indent0, 0)
        XCTAssertEqual(lit0, "Root")

        guard case .node(let indent1, let lit1, _) = tokens[1] else { XCTFail(); return }
        XCTAssertEqual(indent1, 4)
        XCTAssertEqual(lit1, "Child 1")

        guard case .node(let indent2, let lit2, _) = tokens[2] else { XCTFail(); return }
        XCTAssertEqual(indent2, 4)
        XCTAssertEqual(lit2, "Child 2")

        guard case .node(let indent3, let lit3, _) = tokens[3] else { XCTFail(); return }
        XCTAssertEqual(indent3, 8)
        XCTAssertEqual(lit3, "Grandchild")
    }

    func testDocumentWithComments() throws {
        let content = """
        # Header comment
        "Root"
            # Child comment
            "Child"
        """
        let tokens = try tokenize(content)
        XCTAssertEqual(tokens.count, 4)

        guard case .comment(let indent0, _) = tokens[0] else { XCTFail(); return }
        XCTAssertEqual(indent0, 0)

        guard case .node(let indent1, let lit1, _) = tokens[1] else { XCTFail(); return }
        XCTAssertEqual(indent1, 0)
        XCTAssertEqual(lit1, "Root")

        guard case .comment(let indent2, _) = tokens[2] else { XCTFail(); return }
        XCTAssertEqual(indent2, 4)

        guard case .node(let indent3, let lit3, _) = tokens[3] else { XCTFail(); return }
        XCTAssertEqual(indent3, 4)
        XCTAssertEqual(lit3, "Child")
    }

    func testDocumentWithBlankLines() throws {
        // Note: Swift multiline string literals don't include trailing blank line
        // unless explicitly added. This test uses \n to be explicit.
        let content = "\"Root\"\n\n    \"Child\"\n\n"
        let tokens = try tokenize(content)
        XCTAssertEqual(tokens.count, 4)

        guard case .node = tokens[0] else { XCTFail(); return }
        guard case .blank = tokens[1] else { XCTFail(); return }
        guard case .node = tokens[2] else { XCTFail(); return }
        guard case .blank = tokens[3] else { XCTFail(); return }
    }

    // MARK: - Token Properties Tests

    func testTokenLocation() throws {
        let content = "\"A\"\n\"B\"\n\"C\""
        let tokens = try tokenize(content, file: "test.hc")

        XCTAssertEqual(tokens[0].location.line, 1)
        XCTAssertEqual(tokens[0].location.filePath, "test.hc")

        XCTAssertEqual(tokens[1].location.line, 2)
        XCTAssertEqual(tokens[2].location.line, 3)
    }

    func testTokenDepth() throws {
        let content = """
        "Root"
            "Child"
                "Grandchild"
        """
        let tokens = try tokenize(content)

        XCTAssertEqual(tokens[0].depth, 0)
        XCTAssertEqual(tokens[1].depth, 1)
        XCTAssertEqual(tokens[2].depth, 2)
    }

    func testTokenIsSemantic() throws {
        // Explicit newlines to ensure blank line is included
        let content = "\"Node\"\n# Comment\n\n"
        let tokens = try tokenize(content)

        XCTAssertEqual(tokens.count, 3)
        XCTAssertTrue(tokens[0].isSemantic)   // node
        XCTAssertFalse(tokens[1].isSemantic)  // comment
        XCTAssertFalse(tokens[2].isSemantic)  // blank
    }

    // MARK: - Error Tests: Tab in Indentation

    func testError_TabInIndentation() throws {
        let content = "\t\"literal\""
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .tabInIndentation(let location) = lexerError else {
                XCTFail("Expected tabInIndentation")
                return
            }
            XCTAssertEqual(location.line, 1)
        }
    }

    func testError_TabInIndentation_AfterSpaces() throws {
        let content = "  \t\"literal\""  // 2 spaces then tab
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .tabInIndentation = lexerError else {
                XCTFail("Expected tabInIndentation")
                return
            }
        }
    }

    func testError_TabInComment() throws {
        let content = "\t# comment"
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .tabInIndentation = lexerError else {
                XCTFail("Expected tabInIndentation")
                return
            }
        }
    }

    // MARK: - Error Tests: Misaligned Indentation

    func testError_MisalignedIndentation_1Space() throws {
        let content = " \"literal\""
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .misalignedIndentation(let location, let actual) = lexerError else {
                XCTFail("Expected misalignedIndentation")
                return
            }
            XCTAssertEqual(location.line, 1)
            XCTAssertEqual(actual, 1)
        }
    }

    func testError_MisalignedIndentation_2Spaces() throws {
        let content = "  \"literal\""
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .misalignedIndentation(_, let actual) = lexerError else {
                XCTFail("Expected misalignedIndentation")
                return
            }
            XCTAssertEqual(actual, 2)
        }
    }

    func testError_MisalignedIndentation_3Spaces() throws {
        let content = "   \"literal\""
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .misalignedIndentation(_, let actual) = lexerError else {
                XCTFail("Expected misalignedIndentation")
                return
            }
            XCTAssertEqual(actual, 3)
        }
    }

    func testError_MisalignedIndentation_5Spaces() throws {
        let content = "     \"literal\""
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .misalignedIndentation(_, let actual) = lexerError else {
                XCTFail("Expected misalignedIndentation")
                return
            }
            XCTAssertEqual(actual, 5)
        }
    }

    func testError_MisalignedComment() throws {
        let content = "  # comment"  // 2 spaces
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .misalignedIndentation = lexerError else {
                XCTFail("Expected misalignedIndentation")
                return
            }
        }
    }

    // MARK: - Error Tests: Unclosed Quote

    func testError_UnclosedQuote_NoClosing() throws {
        let content = "\"unclosed"
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .unclosedQuote(let location) = lexerError else {
                XCTFail("Expected unclosedQuote")
                return
            }
            XCTAssertEqual(location.line, 1)
        }
    }

    func testError_UnclosedQuote_OnlyOpenQuote() throws {
        let content = "\""
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .unclosedQuote = lexerError else {
                XCTFail("Expected unclosedQuote")
                return
            }
        }
    }

    // MARK: - Error Tests: Invalid Line Format

    func testError_InvalidLineFormat_BareLiteral() throws {
        let content = "no quotes"
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .invalidLineFormat(let location) = lexerError else {
                XCTFail("Expected invalidLineFormat")
                return
            }
            XCTAssertEqual(location.line, 1)
        }
    }

    func testError_InvalidLineFormat_StartsWithNumber() throws {
        let content = "123"
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .invalidLineFormat = lexerError else {
                XCTFail("Expected invalidLineFormat")
                return
            }
        }
    }

    // MARK: - Error Tests: Trailing Content

    func testError_TrailingContent() throws {
        let content = "\"literal\" extra"
        XCTAssertThrowsError(try tokenize(content)) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }
            guard case .trailingContent(let location) = lexerError else {
                XCTFail("Expected trailingContent")
                return
            }
            XCTAssertEqual(location.line, 1)
        }
    }

    // MARK: - Unicode Tests

    func testUnicode_Emoji() throws {
        let tokens = try tokenize("\"Hello 🌍\"")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(_, let literal, _) = tokens[0] else { XCTFail(); return }
        XCTAssertEqual(literal, "Hello 🌍")
    }

    func testUnicode_CJK() throws {
        let tokens = try tokenize("\"你好世界\"")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(_, let literal, _) = tokens[0] else { XCTFail(); return }
        XCTAssertEqual(literal, "你好世界")
    }

    func testUnicode_Arabic() throws {
        let tokens = try tokenize("\"مرحبا بالعالم\"")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(_, let literal, _) = tokens[0] else { XCTFail(); return }
        XCTAssertEqual(literal, "مرحبا بالعالم")
    }

    func testUnicode_MixedScript() throws {
        let tokens = try tokenize("\"Hello 你好 مرحبا\"")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(_, let literal, _) = tokens[0] else { XCTFail(); return }
        XCTAssertEqual(literal, "Hello 你好 مرحبا")
    }

    // MARK: - Error Message Quality Tests

    func testErrorMessage_TabInIndentation() {
        let error = LexerError.tabInIndentation(location: SourceLocation(filePath: "test.hc", line: 5))
        XCTAssertTrue(error.message.contains("Tab"))
        XCTAssertTrue(error.message.contains("4 spaces"))
        XCTAssertEqual(error.category, .syntax)
    }

    func testErrorMessage_MisalignedIndentation() {
        let error = LexerError.misalignedIndentation(
            location: SourceLocation(filePath: "test.hc", line: 3),
            actual: 2
        )
        XCTAssertTrue(error.message.contains("multiple of 4"))
        XCTAssertTrue(error.message.contains("2 spaces"))
    }

    func testErrorMessage_UnclosedQuote() {
        let error = LexerError.unclosedQuote(location: SourceLocation(filePath: "test.hc", line: 1))
        XCTAssertTrue(error.message.contains("Unclosed"))
        XCTAssertTrue(error.message.contains("double quotes"))
    }

    // MARK: - Lexer Normalization Unit Tests

    func testNormalizeLineEndings_LF() {
        let result = lexer.normalizeLineEndings("a\nb\nc")
        XCTAssertEqual(result, "a\nb\nc")
    }

    func testNormalizeLineEndings_CRLF() {
        let result = lexer.normalizeLineEndings("a\r\nb\r\nc")
        XCTAssertEqual(result, "a\nb\nc")
    }

    func testNormalizeLineEndings_CR() {
        let result = lexer.normalizeLineEndings("a\rb\rc")
        XCTAssertEqual(result, "a\nb\nc")
    }

    func testNormalizeLineEndings_Mixed() {
        let result = lexer.normalizeLineEndings("a\nb\r\nc\rd")
        XCTAssertEqual(result, "a\nb\nc\nd")
    }

    // MARK: - Split Lines Tests

    func testSplitIntoLines_Empty() {
        let result = lexer.splitIntoLines("")
        XCTAssertTrue(result.isEmpty)
    }

    func testSplitIntoLines_Single() {
        let result = lexer.splitIntoLines("line")
        XCTAssertEqual(result, ["line"])
    }

    func testSplitIntoLines_Multiple() {
        let result = lexer.splitIntoLines("a\nb\nc")
        XCTAssertEqual(result, ["a", "b", "c"])
    }

    func testSplitIntoLines_TrailingNewline() {
        let result = lexer.splitIntoLines("a\nb\n")
        XCTAssertEqual(result, ["a", "b"])
    }

    func testSplitIntoLines_MultipleTrailingNewlines() {
        let result = lexer.splitIntoLines("a\n\n")
        XCTAssertEqual(result, ["a", ""])
    }

    // MARK: - Blank Line Detection Tests

    func testIsBlankLine_Empty() {
        XCTAssertTrue(lexer.isBlankLine(""))
    }

    func testIsBlankLine_Spaces() {
        XCTAssertTrue(lexer.isBlankLine("    "))
    }

    func testIsBlankLine_WithContent() {
        XCTAssertFalse(lexer.isBlankLine("x"))
        XCTAssertFalse(lexer.isBlankLine("  x"))
        XCTAssertFalse(lexer.isBlankLine("#"))
    }
}

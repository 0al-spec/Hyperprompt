import XCTest
import HypercodeGrammar
import Parser
import Core

/// Integration tests demonstrating Lexer usage of HypercodeGrammar specifications.
///
/// These tests verify that the Lexer properly integrates with specification-based
/// line classification via LineKindDecision and related specifications from
/// HypercodeGrammar, rather than using purely imperative validation logic.
final class LexerSpecificationsIntegrationTests: XCTestCase {
    private let lexer = Lexer()

    // MARK: - Specification-Based Line Classification

    /// Demonstrates that the Lexer uses LineKindDecision for line classification.
    func testLineKindDecisionUsedForClassification() throws {
        // Create a RawLine as the specifications work with
        let rawLine = RawLine(text: "\"hello world\"", lineNumber: 1, filePath: "test.hc")

        // Use LineKindDecision directly (same decision used by Lexer)
        let classifier = HypercodeGrammar.makeLineClassifier()
        let kind = classifier.decide(rawLine)

        // Verify it classifies as a node
        XCTAssertNotNil(kind, "LineKindDecision should classify valid node line")
        if case .node(let literal) = kind {
            XCTAssertEqual(literal, "hello world")
        } else {
            XCTFail("Expected node classification, got \(String(describing: kind))")
        }

        // Verify Lexer produces same classification
        let tokens = try lexer.tokenize(content: "\"hello world\"", filePath: "test.hc")
        XCTAssertEqual(tokens.count, 1)
        guard case .node(_, let lexerLiteral, _) = tokens[0] else {
            XCTFail("Expected node token from Lexer")
            return
        }
        XCTAssertEqual(lexerLiteral, "hello world")
    }

    /// Demonstrates blank line specification validation.
    func testBlankLineSpecificationValidation() throws {
        // Note: empty content produces no tokens (not a blank line token)
        let testCases: [(String, Bool)] = [
            ("   ", true),        // Only spaces
        ]

        let spec = IsBlankLineSpec()

        for (content, shouldBeBlank) in testCases {
            let rawLine = RawLine(text: content, lineNumber: 1, filePath: "test.hc")
            let isBlank = spec.isSatisfiedBy(rawLine)
            XCTAssertEqual(isBlank, shouldBeBlank, "Blank line check failed for: '\(content)'")

            // Verify Lexer agrees for blank cases
            let tokens = try lexer.tokenize(content: content, filePath: "test.hc")
            if shouldBeBlank {
                XCTAssertEqual(tokens.count, 1, "Expected one token for: '\(content)'")
                if case .blank = tokens[0] {
                    // Expected
                } else {
                    XCTFail("Expected blank token for: '\(content)', got \(tokens[0])")
                }
            }
        }

        // Verify non-blank lines are not classified as blank
        let nonBlankRawLine = RawLine(text: "x", lineNumber: 1, filePath: "test.hc")
        XCTAssertFalse(spec.isSatisfiedBy(nonBlankRawLine), "Line with content should not be blank")
    }

    /// Demonstrates comment line specification validation.
    func testCommentLineSpecificationValidation() throws {
        let testCases = [
            ("# comment", true),
            ("    # indented comment", true),
            ("\"not a comment\"", false),
            ("x # not at start", false),
        ]

        let spec = IsCommentLineSpec()

        for (content, shouldBeComment) in testCases {
            let rawLine = RawLine(text: content, lineNumber: 1, filePath: "test.hc")
            let isComment = spec.isSatisfiedBy(rawLine)
            XCTAssertEqual(isComment, shouldBeComment, "Comment line check failed for: '\(content)'")
        }
    }

    /// Demonstrates valid node line specification with indentation and quoting rules.
    func testValidNodeLineSpecification() throws {
        let testCases = [
            ("\"simple\"", true),
            ("    \"indented\"", true),
            ("\"with spaces\"", true),
            ("\"\"", true),  // Empty literal
            ("\"unclosed", false),  // No closing quote
            ("unquoted", false),    // Not quoted
            ("# comment", false),   // Comment, not node
        ]

        let spec = ValidNodeLineSpec()

        for (content, shouldBeValid) in testCases {
            let rawLine = RawLine(text: content, lineNumber: 1, filePath: "test.hc")
            let isValid = spec.isSatisfiedBy(rawLine)
            XCTAssertEqual(isValid, shouldBeValid, "Valid node check failed for: '\(content)'")
        }
    }

    /// Demonstrates indentation specifications for alignment and tabs.
    func testIndentationSpecifications() throws {
        let testCases: [(String, Bool, Bool)] = [
            ("\"node\"", true, true),          // No indent: OK for both
            ("    \"node\"", true, true),      // 4 spaces: OK for both
            ("        \"node\"", true, true),  // 8 spaces: OK for both
            (" \"node\"", false, true),        // 1 space: invalid alignment, but no tabs
            ("  \"node\"", false, true),       // 2 spaces: invalid alignment, but no tabs
        ]

        let noTabsSpec = NoTabsIndentSpec()
        let alignmentSpec = IndentMultipleOf4Spec()

        for (content, shouldAlignOK, shouldHaveNoTabs) in testCases {
            let rawLine = RawLine(text: content, lineNumber: 1, filePath: "test.hc")
            let hasNoTabs = noTabsSpec.isSatisfiedBy(rawLine)
            let alignsOK = alignmentSpec.isSatisfiedBy(rawLine)

            XCTAssertEqual(hasNoTabs, shouldHaveNoTabs, "Tab check failed for: '\(content)'")
            XCTAssertEqual(alignsOK, shouldAlignOK, "Alignment check failed for: '\(content)'")
        }

        // Test tab separately since it combines both violations
        let tabLine = RawLine(text: "\t\"node\"", lineNumber: 1, filePath: "test.hc")
        XCTAssertFalse(noTabsSpec.isSatisfiedBy(tabLine), "Tab line should have tabs")
        // Note: IndentMultipleOf4Spec may consider tabs as valid indent if not checking for tabs
        // so we just verify noTabsSpec catches it
    }

    // MARK: - Integration with Lexer Tokenization

    /// Demonstrates end-to-end integration: Lexer uses specs to classify lines.
    func testLexerTokenizationUsesSpecifications() throws {
        let hypercode = """
        # Header comment

        "first node"
            "indented node"
        # Another comment
        """.replacing("\\n", with: "\n")

        let tokens = try lexer.tokenize(content: hypercode, filePath: "integration.hc")

        // Verify token classification matches specification expectations
        XCTAssertEqual(tokens.count, 5)

        // Token 0: comment
        if case .comment(let indent, _) = tokens[0] {
            XCTAssertEqual(indent, 0)
        } else {
            XCTFail("Expected comment token at index 0")
        }

        // Token 1: blank
        if case .blank = tokens[1] {
            // Expected
        } else {
            XCTFail("Expected blank token at index 1")
        }

        // Token 2: node
        if case .node(let indent, let literal, _) = tokens[2] {
            XCTAssertEqual(indent, 0)
            XCTAssertEqual(literal, "first node")
        } else {
            XCTFail("Expected node token at index 2")
        }

        // Token 3: indented node
        if case .node(let indent, let literal, _) = tokens[3] {
            XCTAssertEqual(indent, 4)
            XCTAssertEqual(literal, "indented node")
        } else {
            XCTFail("Expected indented node token at index 3")
        }

        // Token 4: comment
        if case .comment(let indent, _) = tokens[4] {
            XCTAssertEqual(indent, 0)
        } else {
            XCTFail("Expected comment token at index 4")
        }
    }

    /// Demonstrates that Lexer respects specification constraints on indentation.
    func testLexerEnforcesIndentationSpecifications() throws {
        // Valid indentations (multiples of 4)
        let validIndents = ["\"a\"", "    \"b\"", "        \"c\""]
        for content in validIndents {
            let tokens = try lexer.tokenize(content: content, filePath: "test.hc")
            XCTAssertEqual(tokens.count, 1)
            XCTAssertTrue(tokens[0].isSemantic)
        }

        // Invalid indentations (not multiples of 4)
        let invalidIndents = [" \"a\"", "  \"b\"", "   \"c\"", "     \"d\""]
        for content in invalidIndents {
            XCTAssertThrowsError(try lexer.tokenize(content: content, filePath: "test.hc")) { error in
                if let lexerError = error as? LexerError {
                    switch lexerError {
                    case .misalignedIndentation:
                        // Expected
                        break
                    default:
                        XCTFail("Expected misalignedIndentation error for: '\(content)', got: \(lexerError)")
                    }
                } else {
                    XCTFail("Expected LexerError for: '\(content)'")
                }
            }
        }
    }

    /// Demonstrates that tabs in indentation are rejected per specification.
    func testLexerRejectsTabs() throws {
        let tabContent = "\t\"node\""
        XCTAssertThrowsError(try lexer.tokenize(content: tabContent, filePath: "test.hc")) { error in
            if let lexerError = error as? LexerError {
                switch lexerError {
                case .tabInIndentation:
                    // Expected
                    break
                default:
                    XCTFail("Expected tabInIndentation error, got: \(lexerError)")
                }
            } else {
                XCTFail("Expected LexerError")
            }
        }
    }

    /// DepthWithinLimitSpec should prevent lexing beyond configured depth.
    func testLexerEnforcesDepthLimitSpecification() throws {
        let excessiveIndent = String(repeating: " ", count: 44) + "\"too deep\""  // 11 levels when spacesPerIndentLevel == 4

        XCTAssertThrowsError(try lexer.tokenize(content: excessiveIndent, filePath: "test.hc")) { error in
            guard let lexerError = error as? LexerError else {
                XCTFail("Expected LexerError")
                return
            }

            guard case .invalidLineFormat = lexerError else {
                XCTFail("Expected invalidLineFormat for depth overflow")
                return
            }

            XCTAssertTrue(
                lexerError.message.contains("DepthWithinLimitSpec"),
                "Depth limit failures should cite specification"
            )
        }
    }

    /// Demonstrates specification-driven validation of quote integrity.
    func testValidQuotesSpecification() throws {
        let spec = ValidQuotesSpec()

        let testCases = [
            ("\"valid\"", true),
            ("\"multiple words in quotes\"", true),
            ("    \"indented\"", true),
            ("\"unclosed", false),
            ("unquoted text", false),
            ("\"mixed\" invalid", false),  // Content after closing quote
        ]

        for (content, shouldBeValid) in testCases {
            let rawLine = RawLine(text: content, lineNumber: 1, filePath: "test.hc")
            let isValid = spec.isSatisfiedBy(rawLine)
            XCTAssertEqual(isValid, shouldBeValid, "Quote validation failed for: '\(content)'")
        }
    }

    // MARK: - Specification Composition

    /// Demonstrates how composite specifications work (AND logic).
    func testCompositeSpecifications() throws {
        // Create a composite: no tabs AND proper indentation
        let spec = NoTabsIndentSpec().and(IndentMultipleOf4Spec())

        let testCases = [
            ("\"node\"", true),        // No tabs, no indent = valid
            ("    \"node\"", true),    // No tabs, 4-space indent = valid
            (" \"node\"", false),      // No tabs, but 1-space indent = invalid
            ("\t\"node\"", false),     // Has tab = invalid
        ]

        for (content, shouldBeSatisfied) in testCases {
            let rawLine = RawLine(text: content, lineNumber: 1, filePath: "test.hc")
            let satisfied = spec.isSatisfiedBy(rawLine)
            XCTAssertEqual(satisfied, shouldBeSatisfied, "Composite spec failed for: '\(content)'")
        }
    }
}

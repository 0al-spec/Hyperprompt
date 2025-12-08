import Core
import XCTest

@testable import HypercodeGrammar

final class DomainTypesTests: XCTestCase {
    func testRawLineLocationBuildsFromFilePath() {
        let raw = RawLine(text: "content", lineNumber: 3, filePath: "file.hc")
        XCTAssertEqual(raw.location.filePath, "file.hc")
        XCTAssertEqual(raw.location.line, 3)
    }

    func testParsedLineCalculatesDepth() {
        let location = SourceLocation(filePath: "file.hc", line: 1)
        let parsed = ParsedLine(
            kind: .node(literal: "n"), indentSpaces: 8, literal: "n", location: location)
        XCTAssertEqual(parsed.depth, 2)
        XCTAssertFalse(parsed.isSkippable)
    }

    func testParsedLineSkippableForCommentAndBlank() {
        let location = SourceLocation(filePath: "file.hc", line: 1)
        let blank = ParsedLine(kind: .blank, indentSpaces: 0, literal: nil, location: location)
        let comment = ParsedLine(
            kind: .comment(prefix: "#"), indentSpaces: 0, literal: nil, location: location)
        XCTAssertTrue(blank.isSkippable)
        XCTAssertTrue(comment.isSkippable)
    }
}

final class LexicalSpecsTests: XCTestCase {
    func testBlankLineDetectionIgnoresNewlines() {
        let spec = IsBlankLineSpec()
        XCTAssertTrue(spec.isSatisfiedBy(RawLine(text: "    ", lineNumber: 1, filePath: "a")))
        XCTAssertTrue(spec.isSatisfiedBy(RawLine(text: "", lineNumber: 1, filePath: "a")))
        XCTAssertFalse(spec.isSatisfiedBy(RawLine(text: " text", lineNumber: 1, filePath: "a")))
    }

    func testLineBreakDetection() {
        XCTAssertTrue(ContainsLFSpec().isSatisfiedBy("a\nb"))
        XCTAssertFalse(ContainsLFSpec().isSatisfiedBy("ab"))
        XCTAssertTrue(ContainsCRSpec().isSatisfiedBy("a\rb"))
        XCTAssertFalse(ContainsCRSpec().isSatisfiedBy("ab"))
    }

    func testSingleLineContentSpec() {
        let spec = SingleLineContentSpec()
        XCTAssertTrue(spec.isSatisfiedBy("single line"))
        XCTAssertFalse(spec.isSatisfiedBy("with\nnewline"))
        XCTAssertFalse(spec.isSatisfiedBy("with\rcarriage"))
    }

    func testQuoteSpecsRecognizeBoundaries() {
        let raw = RawLine(text: " \"node\"", lineNumber: 1, filePath: "a")
        XCTAssertTrue(StartsWithDoubleQuoteSpec().isSatisfiedBy(raw))
        XCTAssertTrue(EndsWithDoubleQuoteSpec().isSatisfiedBy(raw))
        XCTAssertTrue(ContentWithinQuotesIsSingleLineSpec().isSatisfiedBy(raw))
        XCTAssertTrue(ValidQuotesSpec().isSatisfiedBy(raw))
    }
}

final class SyntacticSpecsTests: XCTestCase {
    func testCommentRecognition() {
        let comment = RawLine(text: "    # note", lineNumber: 1, filePath: "f")
        XCTAssertTrue(IsCommentLineSpec().isSatisfiedBy(comment))
        XCTAssertTrue(IsSkippableLineSpec().isSatisfiedBy(comment))
        XCTAssertFalse(IsSemanticLineSpec().isSatisfiedBy(comment))
    }

    func testNodeRecognition() {
        let node = RawLine(text: "    \"node\"", lineNumber: 1, filePath: "f")
        XCTAssertTrue(IsNodeLineSpec().isSatisfiedBy(node))
        XCTAssertTrue(ValidNodeLineSpec().isSatisfiedBy(node))
    }

    func testIndentAndDepthValidations() {
        let node = RawLine(text: "        \"depth\"", lineNumber: 1, filePath: "f")
        XCTAssertTrue(IndentMultipleOf4Spec().isSatisfiedBy(node))
        XCTAssertTrue(NoTabsIndentSpec().isSatisfiedBy(node))
        XCTAssertTrue(DepthWithinLimitSpec(maxDepth: 10).isSatisfiedBy(node))

        let deepNode = RawLine(
            text: String(repeating: " ", count: 48) + "\"too deep\"", lineNumber: 1, filePath: "f")
        XCTAssertFalse(DepthWithinLimitSpec(maxDepth: 10).isSatisfiedBy(deepNode))

        let tabNode = RawLine(text: "\t\"bad\"", lineNumber: 1, filePath: "f")
        XCTAssertFalse(NoTabsIndentSpec().isSatisfiedBy(tabNode))
    }

    func testLineKindDecision() {
        let classifier = HypercodeGrammar.makeLineClassifier()
        let blank = RawLine(text: "   ", lineNumber: 1, filePath: "f")
        let comment = RawLine(text: "# hi", lineNumber: 2, filePath: "f")
        let node = RawLine(text: "\"value\"", lineNumber: 3, filePath: "f")

        XCTAssertEqual(classifier.decide(blank), .blank)
        XCTAssertEqual(classifier.decide(comment), .comment(prefix: "#"))
        XCTAssertEqual(classifier.decide(node), .node(literal: "value"))
    }
}

final class PathSpecsTests: XCTestCase {
    func testExtensionSpecifications() {
        let md = "docs/readme.md"
        let hc = "src/file.hc"
        let txt = "notes.txt"

        XCTAssertTrue(HasMarkdownExtensionSpec().isSatisfiedBy(md))
        XCTAssertTrue(HasHypercodeExtensionSpec().isSatisfiedBy(hc))
        XCTAssertTrue(IsAllowedExtensionSpec().isSatisfiedBy(md))
        XCTAssertFalse(IsAllowedExtensionSpec().isSatisfiedBy(txt))
    }

    func testPathSafetySpecifications() {
        let root = "/workspace"
        let secure = "docs/readme.md"
        let traversal = "../secrets.md"
        let sibling = "/workspace-logs/output.txt"

        XCTAssertTrue(NoTraversalSpec().isSatisfiedBy(secure))
        XCTAssertFalse(NoTraversalSpec().isSatisfiedBy(traversal))
        XCTAssertTrue(WithinRootSpec(rootPath: root).isSatisfiedBy(secure))
        XCTAssertFalse(WithinRootSpec(rootPath: root).isSatisfiedBy("/etc/passwd"))
        XCTAssertFalse(WithinRootSpec(rootPath: root).isSatisfiedBy(sibling))
    }

    func testPathTypeDecisionClassifiesPaths() {
        let decision = HypercodeGrammar.makePathClassifier(rootPath: "/workspace")
        XCTAssertEqual(decision.decide("docs/readme.md"), .allowed(extension: "md"))
        XCTAssertEqual(decision.decide("docs/node.hc"), .allowed(extension: "hc"))
        XCTAssertEqual(decision.decide("docs/notes.txt"), .forbidden(extension: "txt"))
        XCTAssertEqual(
            decision.decide("../escape.md"), .invalid(reason: "Path escapes root or is malformed"))
    }
}

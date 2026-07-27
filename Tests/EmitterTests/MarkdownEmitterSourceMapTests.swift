import XCTest
import Core
import Parser
@testable import Emitter

final class MarkdownEmitterSourceMapTests: XCTestCase {
    func testEmissionProducesExactLineOriginsInOnePass() throws {
        let root = Node(
            literal: "Abstract Specification",
            depth: 0,
            location: SourceLocation(filePath: "root.hc", line: 1),
            resolution: .inlineText
        )
        let markdown = Node(
            literal: "body.md",
            depth: 1,
            location: SourceLocation(filePath: "root.hc", line: 2),
            resolution: .markdownFile(
                path: "body.md",
                content: [
                    "# Body",
                    "Setext",
                    "---",
                    "```json",
                    "# preserved",
                    "```",
                ].joined(separator: "\n")
            )
        )
        let sibling = Node(
            literal: "Appendix",
            depth: 1,
            location: SourceLocation(filePath: "root.hc", line: 3),
            resolution: .inlineText
        )
        root.children = [markdown, sibling]

        let result = MarkdownEmitter().emitWithSourceMap(root)

        XCTAssertEqual(
            result.markdown,
            [
                "# Abstract Specification",
                "## Body",
                "### Setext",
                "```json",
                "# preserved",
                "```",
                "",
                "## Appendix",
                "",
            ].joined(separator: "\n")
        )
        XCTAssertNoThrow(try result.sourceMap.validate(for: result.markdown))
        XCTAssertEqual(
            result.sourceMap.mappings,
            [
                CompilationSourceMapping(
                    generatedLine: 1,
                    kind: .hypercodeHeading,
                    source: CompilationSourceSpan(
                        path: "root.hc",
                        startLine: 1,
                        endLine: 1
                    )
                ),
                CompilationSourceMapping(
                    generatedLine: 2,
                    kind: .markdown,
                    source: CompilationSourceSpan(path: "body.md", startLine: 1, endLine: 1)
                ),
                CompilationSourceMapping(
                    generatedLine: 3,
                    kind: .markdown,
                    source: CompilationSourceSpan(path: "body.md", startLine: 2, endLine: 3)
                ),
                CompilationSourceMapping(
                    generatedLine: 4,
                    kind: .markdown,
                    source: CompilationSourceSpan(path: "body.md", startLine: 4, endLine: 4)
                ),
                CompilationSourceMapping(
                    generatedLine: 5,
                    kind: .markdown,
                    source: CompilationSourceSpan(path: "body.md", startLine: 5, endLine: 5)
                ),
                CompilationSourceMapping(
                    generatedLine: 6,
                    kind: .markdown,
                    source: CompilationSourceSpan(path: "body.md", startLine: 6, endLine: 6)
                ),
                CompilationSourceMapping(
                    generatedLine: 7,
                    kind: .generatedSeparator,
                    source: nil
                ),
                CompilationSourceMapping(
                    generatedLine: 8,
                    kind: .hypercodeHeading,
                    source: CompilationSourceSpan(
                        path: "root.hc",
                        startLine: 3,
                        endLine: 3
                    )
                ),
            ]
        )
    }

    func testEmptyFinalIncludeDoesNotLeaveTrailingSeparator() throws {
        let root = Node(
            literal: "Specification",
            depth: 0,
            location: SourceLocation(filePath: "root.hc", line: 1),
            resolution: .inlineText
        )
        let body = Node(
            literal: "Body",
            depth: 1,
            location: SourceLocation(filePath: "root.hc", line: 2),
            resolution: .inlineText
        )
        let emptyInclude = Node(
            literal: "empty.md",
            depth: 1,
            location: SourceLocation(filePath: "root.hc", line: 3),
            resolution: .markdownFile(path: "empty.md", content: "")
        )
        root.children = [body, emptyInclude]

        let result = MarkdownEmitter().emitWithSourceMap(root)

        XCTAssertEqual(result.markdown, "# Specification\n## Body\n")
        XCTAssertEqual(result.sourceMap.mappings.map(\.generatedLine), [1, 2])
        XCTAssertNoThrow(try result.sourceMap.validate(for: result.markdown))
    }
}

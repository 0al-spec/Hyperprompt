#if Editor
import XCTest
@testable import Core

final class SourceMapAdapterTests: XCTestCase {
    func testCompilerMapAdaptsToLegacyEditorCoordinates() {
        let compilerMap = CompilationSourceMap(
            outputSha256: String(repeating: "a", count: 64),
            mappings: [
                CompilationSourceMapping(
                    generatedLine: 1,
                    kind: .hypercodeHeading,
                    source: CompilationSourceSpan(
                        path: "root.hc",
                        startLine: 3,
                        endLine: 3
                    )
                ),
                CompilationSourceMapping(
                    generatedLine: 2,
                    kind: .generatedSeparator,
                    source: nil
                ),
                CompilationSourceMapping(
                    generatedLine: 3,
                    kind: .markdown,
                    source: CompilationSourceSpan(
                        path: "sections/body.md",
                        startLine: 7,
                        endLine: 8
                    )
                ),
            ]
        )

        let sourceMap = SourceMap(
            compilationSourceMap: compilerMap,
            rootPath: "/workspace"
        )

        XCTAssertEqual(
            sourceMap.lookup(outputLine: 0),
            SourceLocation(filePath: "/workspace/root.hc", line: 3)
        )
        XCTAssertNil(sourceMap.lookup(outputLine: 1))
        XCTAssertEqual(
            sourceMap.lookup(outputLine: 2),
            SourceLocation(filePath: "/workspace/sections/body.md", line: 7)
        )
        XCTAssertEqual(sourceMap.count, 2)
    }

    func testEmptyCompilerMapProducesEmptyLegacyMap() {
        let sourceMap = SourceMap(
            compilationSourceMap: CompilationSourceMap(
                outputSha256: ContentHasher.sha256Hex(""),
                mappings: []
            ),
            rootPath: "/workspace"
        )

        XCTAssertEqual(sourceMap.count, 0)
    }
}
#endif

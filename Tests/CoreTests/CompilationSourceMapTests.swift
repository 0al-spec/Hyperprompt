import Foundation
import XCTest
@testable import Core

final class CompilationSourceMapTests: XCTestCase {
    func testEncodingIsDeterministicAndEndsWithOneLF() throws {
        let map = CompilationSourceMap(
            outputSha256: String(repeating: "a", count: 64),
            mappings: [
                CompilationSourceMapping(
                    generatedLine: 2,
                    kind: .generatedSeparator,
                    source: nil
                ),
                CompilationSourceMapping(
                    generatedLine: 1,
                    kind: .hypercodeHeading,
                    source: CompilationSourceSpan(
                        path: "root.hc",
                        startLine: 1,
                        endLine: 1
                    )
                ),
            ]
        )

        let first = try map.toJSON()
        let second = try map.toJSON()

        XCTAssertEqual(first, second)
        XCTAssertTrue(first.hasSuffix("\n"))
        XCTAssertFalse(first.hasSuffix("\n\n"))
        XCTAssertLessThan(
            try XCTUnwrap(first.range(of: "\"lineBase\"")?.lowerBound),
            try XCTUnwrap(first.range(of: "\"mappings\"")?.lowerBound)
        )
        XCTAssertEqual(map.mappings.map(\.generatedLine), [1, 2])
    }

    func testValidationRequiresCompleteOneBasedCoverageAndMatchingHash() throws {
        let markdown = "# Heading\n\n"
        let valid = CompilationSourceMap(
            outputSha256: ContentHasher.sha256Hex(markdown),
            mappings: [
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
                    kind: .generatedSeparator,
                    source: nil
                ),
            ]
        )

        XCTAssertNoThrow(try valid.validate(for: markdown))

        let missingLine = CompilationSourceMap(
            outputSha256: ContentHasher.sha256Hex(markdown),
            mappings: [valid.mappings[0]]
        )
        XCTAssertThrowsError(try missingLine.validate(for: markdown))

        let wrongHash = CompilationSourceMap(
            outputSha256: String(repeating: "0", count: 64),
            mappings: valid.mappings
        )
        XCTAssertThrowsError(try wrongHash.validate(for: markdown))
    }

    func testValidationCountsFinalLineWithoutTrailingLF() {
        let markdown = "# Heading"
        let map = CompilationSourceMap(
            outputSha256: ContentHasher.sha256Hex(markdown),
            mappings: [
                CompilationSourceMapping(
                    generatedLine: 1,
                    kind: .hypercodeHeading,
                    source: CompilationSourceSpan(
                        path: "root.hc",
                        startLine: 1,
                        endLine: 1
                    )
                )
            ]
        )

        XCTAssertNoThrow(try map.validate(for: markdown))
    }

    func testValidationRejectsNonRootRelativeSourcePaths() {
        let markdown = "# Heading\n"

        for path in ["/etc/passwd", "../outside.md", "a/../../b.md", #"a\b.md"#] {
            let map = CompilationSourceMap(
                outputSha256: ContentHasher.sha256Hex(markdown),
                mappings: [
                    CompilationSourceMapping(
                        generatedLine: 1,
                        kind: .markdown,
                        source: CompilationSourceSpan(
                            path: path,
                            startLine: 1,
                            endLine: 1
                        )
                    )
                ]
            )

            XCTAssertThrowsError(try map.validate(for: markdown), "path: \(path)") {
                guard case CompilationSourceMapError.invalidSourcePath = $0 else {
                    return XCTFail("Expected invalidSourcePath for \(path), got \($0)")
                }
            }
        }
    }
}

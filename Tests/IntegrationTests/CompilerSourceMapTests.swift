import Foundation
import XCTest
@testable import CompilerDriver
@testable import Core

final class CompilerSourceMapTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("hyperprompt-source-map-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testOptInSourceMapIsWrittenAndContainsOnlyRootRelativePaths() throws {
        let project = try makeProject(at: tempDirectory.appendingPathComponent("project"))
        let output = tempDirectory.appendingPathComponent("compiled.md")
        let manifest = tempDirectory.appendingPathComponent("compiled.manifest.json")
        let sourceMap = tempDirectory.appendingPathComponent("compiled.map.json")

        let result = try CompilerDriver().compile(
            CompilerArguments(
                input: project.appendingPathComponent("root.hc").path,
                output: output.path,
                manifest: manifest.path,
                sourceMap: sourceMap.path,
                root: project.path,
                mode: .strict,
                verbose: false,
                stats: false,
                dryRun: false
            )
        )
        let compilationSourceMap = try XCTUnwrap(result.sourceMap)
        let sourceMapJSON = try XCTUnwrap(result.sourceMapJSON)

        XCTAssertEqual(
            try String(contentsOf: sourceMap, encoding: .utf8),
            sourceMapJSON
        )
        XCTAssertNoThrow(try compilationSourceMap.validate(for: result.markdown))
        XCTAssertFalse(sourceMapJSON.contains(project.path))
        XCTAssertEqual(
            compilationSourceMap.mappings,
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
                    source: CompilationSourceSpan(
                        path: "body.md",
                        startLine: 1,
                        endLine: 1
                    )
                ),
                CompilationSourceMapping(
                    generatedLine: 3,
                    kind: .markdown,
                    source: CompilationSourceSpan(
                        path: "body.md",
                        startLine: 2,
                        endLine: 3
                    )
                ),
                CompilationSourceMapping(
                    generatedLine: 4,
                    kind: .generatedSeparator,
                    source: nil
                ),
                CompilationSourceMapping(
                    generatedLine: 5,
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

    func testDryRunBuildsAndValidatesMapWithoutWritingAnyArtifact() throws {
        let project = try makeProject(at: tempDirectory.appendingPathComponent("dry-run"))
        let output = tempDirectory.appendingPathComponent("dry-run.md")
        let manifest = tempDirectory.appendingPathComponent("dry-run.manifest.json")
        let sourceMap = tempDirectory.appendingPathComponent("dry-run.map.json")

        let result = try CompilerDriver().compile(
            CompilerArguments(
                input: project.appendingPathComponent("root.hc").path,
                output: output.path,
                manifest: manifest.path,
                sourceMap: sourceMap.path,
                root: project.path,
                mode: .strict,
                verbose: false,
                stats: false,
                dryRun: true
            )
        )
        let compilationSourceMap = try XCTUnwrap(result.sourceMap)

        XCTAssertNoThrow(try compilationSourceMap.validate(for: result.markdown))
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: manifest.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: sourceMap.path))
    }

    func testProgrammaticJSONIsAvailableWhenCollectionIsEnabledWithoutSidecar() throws {
        let project = try makeProject(
            at: tempDirectory.appendingPathComponent("programmatic-json")
        )
        let result = try CompilerDriver().compile(
            CompilerArguments(
                input: project.appendingPathComponent("root.hc").path,
                output: tempDirectory.appendingPathComponent("programmatic.md").path,
                manifest: tempDirectory
                    .appendingPathComponent("programmatic.manifest.json")
                    .path,
                collectSourceMap: true,
                root: project.path,
                mode: .strict,
                verbose: false,
                stats: false,
                dryRun: true
            )
        )
        let compilationSourceMap = try XCTUnwrap(result.sourceMap)
        let sourceMapJSON = try XCTUnwrap(result.sourceMapJSON)

        let decoded = try JSONDecoder().decode(
            CompilationSourceMap.self,
            from: Data(sourceMapJSON.utf8)
        )
        XCTAssertEqual(decoded, compilationSourceMap)
    }

    func testDefaultFastPathSkipsMapAndMatchesMappedMarkdown() throws {
        let project = try makeProject(
            at: tempDirectory.appendingPathComponent("fast-path")
        )
        let driver = CompilerDriver()
        let fast = try driver.compile(
            CompilerArguments(
                input: project.appendingPathComponent("root.hc").path,
                output: tempDirectory.appendingPathComponent("fast.md").path,
                manifest: tempDirectory
                    .appendingPathComponent("fast.manifest.json")
                    .path,
                root: project.path,
                mode: .strict,
                verbose: false,
                stats: false,
                dryRun: true
            )
        )
        let mapped = try driver.compile(
            CompilerArguments(
                input: project.appendingPathComponent("root.hc").path,
                output: tempDirectory.appendingPathComponent("mapped.md").path,
                manifest: tempDirectory
                    .appendingPathComponent("mapped.manifest.json")
                    .path,
                collectSourceMap: true,
                root: project.path,
                mode: .strict,
                verbose: false,
                stats: false,
                dryRun: true
            )
        )

        XCTAssertNil(fast.sourceMap)
        XCTAssertNil(fast.sourceMapJSON)
        XCTAssertEqual(fast.markdown, mapped.markdown)
        XCTAssertNotNil(mapped.sourceMap)
        XCTAssertNotNil(mapped.sourceMapJSON)
    }

    func testSourceMapAndMarkdownAreIndependentOfCheckoutDirectory() throws {
        let firstProject = try makeProject(
            at: tempDirectory.appendingPathComponent("checkout-a")
        )
        let secondProject = try makeProject(
            at: tempDirectory.appendingPathComponent("checkout-b")
        )

        let first = try compileDryRun(project: firstProject, suffix: "a")
        let second = try compileDryRun(project: secondProject, suffix: "b")

        XCTAssertEqual(first.markdown, second.markdown)
        XCTAssertEqual(first.sourceMapJSON, second.sourceMapJSON)
    }

    private func makeProject(at directory: URL) throws -> URL {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try [
            "\"Abstract Specification\"",
            "    \"body.md\"",
            "    \"Appendix\"",
            "",
        ].joined(separator: "\n").write(
            to: directory.appendingPathComponent("root.hc"),
            atomically: true,
            encoding: .utf8
        )
        try [
            "# Body",
            "Setext",
            "---",
            "",
        ].joined(separator: "\n").write(
            to: directory.appendingPathComponent("body.md"),
            atomically: true,
            encoding: .utf8
        )
        return directory
    }

    private func compileDryRun(project: URL, suffix: String) throws -> CompilationResult {
        try CompilerDriver().compile(
            CompilerArguments(
                input: project.appendingPathComponent("root.hc").path,
                output: tempDirectory.appendingPathComponent("\(suffix).md").path,
                manifest: tempDirectory
                    .appendingPathComponent("\(suffix).manifest.json")
                    .path,
                sourceMap: tempDirectory.appendingPathComponent("\(suffix).map.json").path,
                root: project.path,
                mode: .strict,
                verbose: false,
                stats: false,
                dryRun: true
            )
        )
    }
}

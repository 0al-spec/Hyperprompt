#if Editor
import XCTest
import Core
@testable import EditorEngine

final class EditorCompilerTests: XCTestCase {
    func testCompileReturnsOutput() throws {
        let tempDir = try makeTempDir()
        let input = tempDir.appendingPathComponent("main.hc")
        try "\"Root\"\n".write(to: input, atomically: true, encoding: .utf8)

        let compiler = EditorCompiler()
        let result = compiler.compile(entryFile: input.path)

        XCTAssertNotNil(result.output)
        XCTAssertTrue(result.diagnostics.isEmpty)
    }

    func testCompileMissingFileReturnsDiagnostics() {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let input = tempDir.appendingPathComponent("missing-\(UUID().uuidString).hc")

        let compiler = EditorCompiler()
        let result = compiler.compile(entryFile: input.path)

        XCTAssertNil(result.output)
        XCTAssertFalse(result.diagnostics.isEmpty)
    }

    func testLenientModeAllowsMissingReference() throws {
        let tempDir = try makeTempDir()
        let input = tempDir.appendingPathComponent("main.hc")
        try "\"missing.md\"\n".write(to: input, atomically: true, encoding: .utf8)

        let compiler = EditorCompiler()
        let options = CompileOptions(mode: .lenient)
        let result = compiler.compile(entryFile: input.path, options: options)

        XCTAssertNotNil(result.output)
        XCTAssertTrue(result.diagnostics.isEmpty)
    }

    func testStrictModeReportsMissingReference() throws {
        let tempDir = try makeTempDir()
        let input = tempDir.appendingPathComponent("main.hc")
        try "\"missing.md\"\n".write(to: input, atomically: true, encoding: .utf8)

        let compiler = EditorCompiler()
        let options = CompileOptions(mode: .strict)
        let result = compiler.compile(entryFile: input.path, options: options)

        XCTAssertNil(result.output)
        XCTAssertFalse(result.diagnostics.isEmpty)
    }

    func testEmitManifestToggle() throws {
        let tempDir = try makeTempDir()
        let input = tempDir.appendingPathComponent("main.hc")
        try "\"Root\"\n".write(to: input, atomically: true, encoding: .utf8)

        let compiler = EditorCompiler()
        let options = CompileOptions(manifestPolicy: .omit)
        let result = compiler.compile(entryFile: input.path, options: options)

        XCTAssertNotNil(result.output)
        XCTAssertNil(result.manifest)
    }

    func testCollectStatsReturnsStatistics() throws {
        let tempDir = try makeTempDir()
        let input = tempDir.appendingPathComponent("main.hc")
        try "\"Root\"\n".write(to: input, atomically: true, encoding: .utf8)

        let compiler = EditorCompiler()
        let options = CompileOptions(statisticsPolicy: .include)
        let result = compiler.compile(entryFile: input.path, options: options)

        XCTAssertNotNil(result.output)
        XCTAssertNotNil(result.statistics)
    }

    func testWriteOutputWritesFiles() throws {
        let tempDir = try makeTempDir()
        let input = tempDir.appendingPathComponent("main.hc")
        try "\"Root\"\n".write(to: input, atomically: true, encoding: .utf8)

        let output = tempDir.appendingPathComponent("main.md")
        let manifest = tempDir.appendingPathComponent("main.md.manifest.json")

        let compiler = EditorCompiler()
        let options = CompileOptions(
            outputPath: output.path,
            manifestPath: manifest.path,
            outputWritePolicy: .write
        )
        let result = compiler.compile(entryFile: input.path, options: options)

        XCTAssertNotNil(result.output)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifest.path))
    }

    func testSourceMapUsesCompilerMappingsWithoutGeneratedSeparators() throws {
        let tempDir = try makeTempDir()
        let input = tempDir.appendingPathComponent("main.hc")
        let body = tempDir.appendingPathComponent("body.md")
        try [
            "\"Specification\"",
            "    \"body.md\"",
            "    \"Appendix\"",
            "",
        ].joined(separator: "\n").write(
            to: input,
            atomically: true,
            encoding: .utf8
        )
        try "# Body\n".write(to: body, atomically: true, encoding: .utf8)

        let result = EditorCompiler().compile(
            entryFile: input.path,
            options: CompileOptions(workspaceRoot: tempDir.path)
        )
        let sourceMap = try XCTUnwrap(result.sourceMap)

        XCTAssertEqual(
            sourceMap.lookup(outputLine: 0),
            SourceLocation(filePath: input.path, line: 1)
        )
        XCTAssertEqual(
            sourceMap.lookup(outputLine: 1),
            SourceLocation(filePath: body.path, line: 1)
        )
        XCTAssertNil(sourceMap.lookup(outputLine: 2))
        XCTAssertEqual(
            sourceMap.lookup(outputLine: 3),
            SourceLocation(filePath: input.path, line: 3)
        )
    }
}

private func makeTempDir() throws -> URL {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("hyperprompt-editor-tests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    return tempDir
}
#endif

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
        let options = CompileOptions(emitManifest: false)
        let result = compiler.compile(entryFile: input.path, options: options)

        XCTAssertNotNil(result.output)
        XCTAssertNil(result.manifest)
    }
}

private func makeTempDir() throws -> URL {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("hyperprompt-editor-tests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    return tempDir
}

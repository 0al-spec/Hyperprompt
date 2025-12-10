import XCTest
import Foundation
@testable import CLI
@testable import Core

/// End-to-end integration tests for CompilerDriver
///
/// Tests cover:
/// - Valid input compilation (V01, V03)
/// - Invalid input error handling (I01, I02, I03, I10)
/// - Dry-run mode
/// - Verbose logging
/// - Exit code mapping
final class CompilerDriverTests: XCTestCase {

    var tempDir: URL!
    var fixturesDir: URL!

    override func setUp() {
        super.setUp()

        // Create temporary directory for test outputs
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("hyperprompt-tests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Locate fixtures directory
        // Assuming tests run from package root
        let currentFile = URL(fileURLWithPath: #file)
        fixturesDir = currentFile
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
    }

    override func tearDown() {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func fixtureURL(_ path: String) -> URL {
        return fixturesDir.appendingPathComponent(path)
    }

    private func tempURL(_ path: String) -> URL {
        return tempDir.appendingPathComponent(path)
    }

    private func compileFile(_ inputPath: URL, outputPath: URL, dryRun: Bool = false, verbose: Bool = false, stats: Bool = true) throws -> CompilationResult {
        let driver = CompilerDriver()
        let args = CompilerArguments(
            input: inputPath.path,
            output: outputPath.path,
            manifest: outputPath.deletingPathExtension().appendingPathExtension("json").path,
            root: inputPath.deletingLastPathComponent().path,
            mode: .strict,
            verbose: verbose,
            stats: stats,
            dryRun: dryRun
        )
        return try driver.compile(args)
    }

    private func readFile(_ url: URL) throws -> String {
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Valid Input Tests

    func testV01_SingleRootNode() throws {
        let input = fixtureURL("Valid/V01.hc")
        let output = tempURL("V01.md")
        let expected = fixtureURL("Valid/V01.expected.md")

        // Compile
        let result = try compileFile(input, outputPath: output)

        // Verify output file was written
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))

        // Compare with golden file
        let actualMD = try readFile(output)
        let expectedMD = try readFile(expected)
        XCTAssertEqual(actualMD, expectedMD, "V01 markdown output should match golden file")

        // Verify result contains markdown
        XCTAssertTrue(result.markdown.contains("# Root Node"))
    }

    func testV03_NestedHierarchy() throws {
        let input = fixtureURL("Valid/V03.hc")
        let output = tempURL("V03.md")
        let expected = fixtureURL("Valid/V03.expected.md")

        // Compile
        let result = try compileFile(input, outputPath: output)

        // Verify output file was written
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))

        // Compare with golden file
        let actualMD = try readFile(output)
        let expectedMD = try readFile(expected)
        XCTAssertEqual(actualMD, expectedMD, "V03 markdown output should match golden file")

        // Verify nested structure
        XCTAssertTrue(result.markdown.contains("# Level 0"))
        XCTAssertTrue(result.markdown.contains("## Level 1"))
        XCTAssertTrue(result.markdown.contains("### Level 2"))
    }

    // MARK: - Invalid Input Tests

    func testI01_TabIndentation() throws {
        let input = fixtureURL("Invalid/I01.hc")
        let output = tempURL("I01.md")

        // Compilation should fail with syntax error (exit code 2)
        XCTAssertThrowsError(try compileFile(input, outputPath: output)) { error in
            guard let compilerError = error as? CompilerError else {
                XCTFail("Expected CompilerError, got \(error)")
                return
            }
            XCTAssertEqual(compilerError.category, .syntax)
            XCTAssertTrue(compilerError.message.contains("tab") ||
                         compilerError.message.contains("indent"),
                         "Error should mention tab or indentation issue")
        }

        // No output file should be written
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
    }

    func testI02_MisalignedIndentation() throws {
        let input = fixtureURL("Invalid/I02.hc")
        let output = tempURL("I02.md")

        // Compilation should fail with syntax error
        XCTAssertThrowsError(try compileFile(input, outputPath: output)) { error in
            guard let compilerError = error as? CompilerError else {
                XCTFail("Expected CompilerError, got \(error)")
                return
            }
            XCTAssertEqual(compilerError.category, .syntax)
            XCTAssertTrue(compilerError.message.contains("indent") ||
                         compilerError.message.contains("divisible") ||
                         compilerError.message.contains("align"),
                         "Error should mention indentation alignment issue")
        }
    }

    func testI03_UnclosedQuote() throws {
        let input = fixtureURL("Invalid/I03.hc")
        let output = tempURL("I03.md")

        // Compilation should fail with syntax error
        XCTAssertThrowsError(try compileFile(input, outputPath: output)) { error in
            guard let compilerError = error as? CompilerError else {
                XCTFail("Expected CompilerError, got \(error)")
                return
            }
            XCTAssertEqual(compilerError.category, .syntax)
            XCTAssertTrue(compilerError.message.contains("quote") ||
                         compilerError.message.contains("unclosed") ||
                         compilerError.message.contains("EOF"),
                         "Error should mention unclosed quote or EOF")
        }
    }

    func testI10_MultipleRoots() throws {
        let input = fixtureURL("Invalid/I10.hc")
        let output = tempURL("I10.md")

        // Compilation should fail with syntax error
        XCTAssertThrowsError(try compileFile(input, outputPath: output)) { error in
            guard let compilerError = error as? CompilerError else {
                XCTFail("Expected CompilerError, got \(error)")
                return
            }
            XCTAssertEqual(compilerError.category, .syntax)
            XCTAssertTrue(compilerError.message.contains("multiple") ||
                         compilerError.message.contains("root"),
                         "Error should mention multiple roots")
        }
    }

    // MARK: - Mode Tests

    func testDryRunMode() throws {
        let input = fixtureURL("Valid/V01.hc")
        let output = tempURL("V01-dryrun.md")

        // Compile in dry-run mode
        let result = try compileFile(input, outputPath: output, dryRun: true)

        // Result should contain markdown
        XCTAssertTrue(result.markdown.contains("# Root Node"))

        // BUT no output file should be written
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path),
                      "Dry-run mode should not write output files")
    }

    func testVerboseMode() throws {
        let input = fixtureURL("Valid/V01.hc")
        let output = tempURL("V01-verbose.md")

        // In verbose mode, driver should write to stderr
        // We can't easily capture stderr in unit tests, but we can verify compilation succeeds
        let result = try compileFile(input, outputPath: output, verbose: true)

        XCTAssertTrue(result.markdown.contains("# Root Node"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
    }

    // MARK: - Statistics Tests

    func testStatisticsCollection() throws {
        let input = fixtureURL("Valid/V03.hc")
        let output = tempURL("V03-stats.md")

        let result = try compileFile(input, outputPath: output, stats: true)

        // Verify statistics are collected
        guard let stats = result.statistics else {
            XCTFail("Statistics should be collected when stats=true")
            return
        }

        XCTAssertGreaterThan(stats.durationMs, 0, "Compilation should take some time")
        XCTAssertGreaterThan(stats.totalInputBytes, 0, "Should have input bytes")
        XCTAssertGreaterThan(stats.outputBytes, 0, "Should have output bytes")

        // For V03 (3-level hierarchy):
        XCTAssertEqual(stats.maxDepth, 2, "V03 has max depth 2 (0-indexed)")
    }

    // MARK: - Error Code Mapping Tests

    func testErrorCodeMapping() {
        // Test that different error categories map to correct exit codes
        // (This would be tested via CLI integration, but we verify the error categories)

        let syntaxError = ConcreteCompilerError.syntaxError(
            message: "Test syntax error",
            location: nil
        )
        XCTAssertEqual(syntaxError.category, .syntax)

        let resolutionError = ConcreteCompilerError.resolutionError(
            message: "Test resolution error",
            location: nil
        )
        XCTAssertEqual(resolutionError.category, .resolution)

        let ioError = ConcreteCompilerError.ioError(
            message: "Test IO error",
            location: nil
        )
        XCTAssertEqual(ioError.category, .io)

        let internalError = ConcreteCompilerError.internalError(
            message: "Test internal error",
            location: nil
        )
        XCTAssertEqual(internalError.category, .internal)
    }
}

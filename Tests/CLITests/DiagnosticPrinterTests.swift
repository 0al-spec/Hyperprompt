import XCTest
@testable import CLI
@testable import Core

/// Tests for DiagnosticPrinter formatting and error display.
///
/// Verifies:
/// - Error message format: `<file>:<line>: error: <message>`
/// - Context line extraction and display
/// - Caret indicator positioning
/// - ANSI color support (enabled/disabled)
/// - Multi-error aggregation and grouping
/// - Edge cases (missing files, long lines, UTF-8)
final class DiagnosticPrinterTests: XCTestCase {

    // MARK: - Test Fixtures

    /// Mock error for testing
    struct MockError: CompilerError {
        let category: ErrorCategory
        let message: String
        let location: SourceLocation?
    }

    /// Mock file system for controlled testing
    class MockFileSystem: FileSystem {
        var files: [String: String] = [:]

        func readFile(at path: String) throws -> String {
            guard let content = files[path] else {
                throw ConcreteCompilerError.ioError(message: "File not found: \(path)", location: nil)
            }
            return content
        }

        func fileExists(at path: String) -> Bool {
            return files[path] != nil
        }

        func canonicalizePath(_ path: String) throws -> String {
            return path
        }

        func currentDirectory() -> String {
            return "/test"
        }

        func writeFile(at path: String, content: String) throws {
            files[path] = content
        }

        func listDirectory(at path: String) throws -> [String] {
            let normalizedPath = path.hasSuffix("/") ? path : path + "/"
            var results: Set<String> = []
            for filePath in files.keys {
                if filePath.hasPrefix(normalizedPath) {
                    let relativePath = String(filePath.dropFirst(normalizedPath.count))
                    if let firstComponent = relativePath.split(separator: "/").first {
                        results.insert(String(firstComponent))
                    }
                }
            }
            return Array(results)
        }

        func isDirectory(at path: String) -> Bool {
            let normalizedPath = path.hasSuffix("/") ? path : path + "/"
            return files.keys.contains { $0.hasPrefix(normalizedPath) }
        }

        func fileAttributes(at path: String) -> FileAttributes? {
            guard let content = files[path] else { return nil }
            return FileAttributes(size: content.utf8.count, modificationDate: Date())
        }
    }

    // MARK: - Basic Error Formatting Tests

    func testBasicErrorFormatWithLocation() {
        let printer = DiagnosticPrinter(colorize: false)
        let error = MockError(
            category: .syntax,
            message: "Tab character in indentation",
            location: SourceLocation(filePath: "test.hc", line: 5)
        )

        let output = printer.format(error: error)

        // Should contain file:line: error: message format
        XCTAssertTrue(output.contains("test.hc:5: error: Tab character in indentation"))
    }

    func testBasicErrorFormatWithoutLocation() {
        let printer = DiagnosticPrinter(colorize: false)
        let error = MockError(
            category: .internal,
            message: "Unexpected compiler error",
            location: nil
        )

        let output = printer.format(error: error)

        // Should contain error: message format (no location)
        XCTAssertTrue(output.contains("error: Unexpected compiler error"))
        // Should not have file:line: prefix (but "error:" is expected)
        XCTAssertFalse(output.contains(".hc:"))  // No file:line prefix
        XCTAssertTrue(output.hasPrefix("error:") || output.contains("\u{001B}"))  // Either plain or with color codes
    }

    func testErrorFormatWithRelativePath() {
        let printer = DiagnosticPrinter(colorize: false)
        let error = MockError(
            category: .syntax,
            message: "Invalid syntax",
            location: SourceLocation(filePath: "src/nested/file.hc", line: 42)
        )

        let output = printer.format(error: error)

        XCTAssertTrue(output.contains("src/nested/file.hc:42: error:"))
    }

    // MARK: - Context Line Extraction Tests

    func testContextLineExtraction() {
        let fs = MockFileSystem()
        fs.files["test.hc"] = "line 1\nline 2 with content\nline 3\n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let error = MockError(
            category: .syntax,
            message: "Error on line 2",
            location: SourceLocation(filePath: "test.hc", line: 2)
        )

        let output = printer.format(error: error)

        // Should include the context line
        XCTAssertTrue(output.contains("line 2 with content"))
    }

    func testContextLineWithQuotes() {
        let fs = MockFileSystem()
        fs.files["test.hc"] = "\"quoted content\"\n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let error = MockError(
            category: .syntax,
            message: "Test error",
            location: SourceLocation(filePath: "test.hc", line: 1)
        )

        let output = printer.format(error: error)

        XCTAssertTrue(output.contains("\"quoted content\""))
    }

    func testMissingSourceFile() {
        let fs = MockFileSystem()
        // No file created

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let error = MockError(
            category: .io,
            message: "File not found",
            location: SourceLocation(filePath: "missing.hc", line: 1)
        )

        let output = printer.format(error: error)

        // Should still format the error, just without context
        XCTAssertTrue(output.contains("missing.hc:1: error: File not found"))
        // Should not crash or throw
    }

    // MARK: - Caret Positioning Tests

    func testCaretPositioningAtQuote() {
        let fs = MockFileSystem()
        fs.files["test.hc"] = "    \"content\"\n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let error = MockError(
            category: .syntax,
            message: "Test",
            location: SourceLocation(filePath: "test.hc", line: 1)
        )

        let output = printer.format(error: error)

        // Should have caret positioned at the quote (column 4)
        let lines = output.components(separatedBy: "\n")
        XCTAssertTrue(lines.count >= 3, "Should have at least 3 lines (error, context, caret)")

        // Find the caret line (last non-empty line)
        let caretLine = lines.reversed().first { !$0.isEmpty } ?? ""
        XCTAssertTrue(caretLine.contains("^"), "Should contain caret indicator")
    }

    func testCaretPositioningAtStart() {
        let fs = MockFileSystem()
        fs.files["test.hc"] = "content\n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let error = MockError(
            category: .syntax,
            message: "Test",
            location: SourceLocation(filePath: "test.hc", line: 1)
        )

        let output = printer.format(error: error)

        let lines = output.components(separatedBy: "\n")
        let caretLine = lines.reversed().first { !$0.isEmpty } ?? ""

        // Caret should be at column 0 (no leading spaces)
        XCTAssertTrue(caretLine.hasPrefix("^"))
    }

    // MARK: - Color Support Tests

    func testColorizedOutput() {
        let fs = MockFileSystem()
        fs.files["test.hc"] = "\"content\"\n"

        let printer = DiagnosticPrinter(colorize: true, fileSystem: fs)
        let error = MockError(
            category: .syntax,
            message: "Test error",
            location: SourceLocation(filePath: "test.hc", line: 1)
        )

        let output = printer.format(error: error)

        // Should contain ANSI escape codes
        XCTAssertTrue(output.contains("\u{001B}["), "Should contain ANSI escape codes")
    }

    func testPlainTextOutput() {
        let fs = MockFileSystem()
        fs.files["test.hc"] = "\"content\"\n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let error = MockError(
            category: .syntax,
            message: "Test error",
            location: SourceLocation(filePath: "test.hc", line: 1)
        )

        let output = printer.format(error: error)

        // Should NOT contain ANSI escape codes
        XCTAssertFalse(output.contains("\u{001B}["), "Should not contain ANSI escape codes")
    }

    // MARK: - Multi-Error Tests

    func testMultipleErrors() {
        let fs = MockFileSystem()
        fs.files["test.hc"] = "line 1\nline 2\nline 3\n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let errors = [
            MockError(
                category: .syntax,
                message: "Error 1",
                location: SourceLocation(filePath: "test.hc", line: 1)
            ),
            MockError(
                category: .syntax,
                message: "Error 2",
                location: SourceLocation(filePath: "test.hc", line: 3)
            )
        ]

        let output = printer.formatMultiple(errors: errors)

        // Should contain both errors
        XCTAssertTrue(output.contains("Error 1"))
        XCTAssertTrue(output.contains("Error 2"))

        // Should contain summary
        XCTAssertTrue(output.contains("Total: 2 errors"))
    }

    func testMultipleErrorsSortedByLine() {
        let fs = MockFileSystem()
        fs.files["test.hc"] = "line 1\nline 2\nline 3\n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let errors = [
            MockError(
                category: .syntax,
                message: "Error on line 3",
                location: SourceLocation(filePath: "test.hc", line: 3)
            ),
            MockError(
                category: .syntax,
                message: "Error on line 1",
                location: SourceLocation(filePath: "test.hc", line: 1)
            )
        ]

        let output = printer.formatMultiple(errors: errors)

        // Errors should appear in line order (1 before 3)
        let line1Index = output.range(of: "Error on line 1")?.lowerBound
        let line3Index = output.range(of: "Error on line 3")?.lowerBound

        XCTAssertNotNil(line1Index)
        XCTAssertNotNil(line3Index)
        if let idx1 = line1Index, let idx3 = line3Index {
            XCTAssertLessThan(idx1, idx3, "Line 1 error should appear before line 3 error")
        }
    }

    func testMultipleErrorsGroupedByFile() {
        let fs = MockFileSystem()
        fs.files["a.hc"] = "line 1\n"
        fs.files["b.hc"] = "line 1\n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let errors = [
            MockError(
                category: .syntax,
                message: "Error in b.hc",
                location: SourceLocation(filePath: "b.hc", line: 1)
            ),
            MockError(
                category: .syntax,
                message: "Error in a.hc",
                location: SourceLocation(filePath: "a.hc", line: 1)
            )
        ]

        let output = printer.formatMultiple(errors: errors)

        // Files should be sorted alphabetically (a.hc before b.hc)
        let aIndex = output.range(of: "a.hc")?.lowerBound
        let bIndex = output.range(of: "b.hc")?.lowerBound

        XCTAssertNotNil(aIndex)
        XCTAssertNotNil(bIndex)
        if let idxA = aIndex, let idxB = bIndex {
            XCTAssertLessThan(idxA, idxB, "a.hc should appear before b.hc")
        }
    }

    func testSingleErrorSummary() {
        let printer = DiagnosticPrinter(colorize: false)
        let errors = [
            MockError(
                category: .syntax,
                message: "Single error",
                location: SourceLocation(filePath: "test.hc", line: 1)
            )
        ]

        let output = printer.formatMultiple(errors: errors)

        // Should use singular "error" not "errors"
        XCTAssertTrue(output.contains("Total: 1 error"))
        XCTAssertFalse(output.contains("1 errors"))
    }

    func testEmptyErrorArray() {
        let printer = DiagnosticPrinter(colorize: false)
        let output = printer.formatMultiple(errors: [])

        // Should return empty string for no errors
        XCTAssertEqual(output, "")
    }

    // MARK: - Edge Cases

    func testVeryLongLine() {
        let fs = MockFileSystem()
        let longLine = String(repeating: "x", count: 150)
        fs.files["test.hc"] = "\"\(longLine)\"\n"

        let printer = DiagnosticPrinter(colorize: false, maxLineLength: 100, fileSystem: fs)
        let error = MockError(
            category: .syntax,
            message: "Test",
            location: SourceLocation(filePath: "test.hc", line: 1)
        )

        let output = printer.format(error: error)

        // Should truncate the line
        let lines = output.components(separatedBy: "\n")
        let contextLine = lines.first { $0.contains("x") } ?? ""

        XCTAssertTrue(contextLine.contains("..."), "Long line should be truncated with ...")
        XCTAssertLessThanOrEqual(contextLine.count, 104)  // 100 + "..." + margin
    }

    func testUTF8Content() {
        let fs = MockFileSystem()
        fs.files["test.hc"] = "\"hello 👋 world\"\n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let error = MockError(
            category: .syntax,
            message: "Test",
            location: SourceLocation(filePath: "test.hc", line: 1)
        )

        let output = printer.format(error: error)

        // Should preserve emoji
        XCTAssertTrue(output.contains("👋"))
    }

    func testLineEndingNormalization() {
        let fs = MockFileSystem()
        // FileSystem should already normalize to LF, but test it works
        fs.files["test.hc"] = "line 1\nline 2\n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let error = MockError(
            category: .syntax,
            message: "Test",
            location: SourceLocation(filePath: "test.hc", line: 2)
        )

        let output = printer.format(error: error)

        XCTAssertTrue(output.contains("line 2"))
    }

    func testTrailingWhitespaceTrimmed() {
        let fs = MockFileSystem()
        fs.files["test.hc"] = "\"content\"    \n"

        let printer = DiagnosticPrinter(colorize: false, fileSystem: fs)
        let error = MockError(
            category: .syntax,
            message: "Test",
            location: SourceLocation(filePath: "test.hc", line: 1)
        )

        let output = printer.format(error: error)

        // Context line should not have trailing spaces
        let lines = output.components(separatedBy: "\n")
        let contextLine = lines.first { $0.contains("content") } ?? ""

        XCTAssertFalse(contextLine.hasSuffix("    "), "Trailing whitespace should be trimmed")
    }

    func testErrorWithoutLocationInMultiple() {
        let printer = DiagnosticPrinter(colorize: false)
        let errors = [
            MockError(
                category: .internal,
                message: "No location error",
                location: nil
            ),
            MockError(
                category: .syntax,
                message: "With location",
                location: SourceLocation(filePath: "test.hc", line: 1)
            )
        ]

        let output = printer.formatMultiple(errors: errors)

        // Should handle both error types
        XCTAssertTrue(output.contains("No location error"))
        XCTAssertTrue(output.contains("With location"))
        XCTAssertTrue(output.contains("Total: 2 errors"))
    }

    // MARK: - Stream Output Tests

    func testWriteToStream() {
        var output = ""
        var stream = StringOutputStream(output: &output)

        let printer = DiagnosticPrinter(colorize: false)
        let error = MockError(
            category: .syntax,
            message: "Test error",
            location: SourceLocation(filePath: "test.hc", line: 1)
        )

        printer.write(error: error, to: &stream)

        XCTAssertTrue(output.contains("test.hc:1: error: Test error"))
    }

    func testWriteMultipleToStream() {
        var output = ""
        var stream = StringOutputStream(output: &output)

        let printer = DiagnosticPrinter(colorize: false)
        let errors = [
            MockError(
                category: .syntax,
                message: "Error 1",
                location: SourceLocation(filePath: "test.hc", line: 1)
            ),
            MockError(
                category: .syntax,
                message: "Error 2",
                location: SourceLocation(filePath: "test.hc", line: 2)
            )
        ]

        printer.write(errors: errors, to: &stream)

        XCTAssertTrue(output.contains("Error 1"))
        XCTAssertTrue(output.contains("Error 2"))
        XCTAssertTrue(output.contains("Total: 2 errors"))
    }
}

// MARK: - Test Helpers

/// Simple string-based output stream for testing
private struct StringOutputStream: TextOutputStream {
    var output: UnsafeMutablePointer<String>

    init(output: inout String) {
        self.output = withUnsafeMutablePointer(to: &output) { $0 }
    }

    mutating func write(_ string: String) {
        output.pointee += string
    }
}

import XCTest
@testable import Core

/// Unit tests for CompilerError protocol and default implementations.
final class CompilerErrorTests: XCTestCase {
    /// Test error with location produces correct diagnostic format.
    func testErrorWithLocation() {
        let location = SourceLocation(filePath: "test.hc", line: 42)
        let error = TestError(
            category: .syntax,
            message: "Unclosed quotation mark",
            location: location
        )

        let expectedDiagnostic = """
        Error [Syntax]: test.hc:42
        Unclosed quotation mark
        """
        XCTAssertEqual(error.diagnosticInfo, expectedDiagnostic)
    }

    /// Test error without location produces correct diagnostic format.
    func testErrorWithoutLocation() {
        let error = TestError(
            category: .io,
            message: "Failed to open file",
            location: nil
        )

        let expectedDiagnostic = "Error [IO]: Failed to open file"
        XCTAssertEqual(error.diagnosticInfo, expectedDiagnostic)
    }

    /// Test diagnostic format includes all components.
    func testDiagnosticFormat() {
        let location = SourceLocation(filePath: "/path/to/file.hc", line: 15)
        let error = TestError(
            category: .resolution,
            message: "Circular dependency detected",
            location: location
        )

        let diagnostic = error.diagnosticInfo

        // Verify all components present
        XCTAssertTrue(diagnostic.contains("Error [Resolution]"))
        XCTAssertTrue(diagnostic.contains("/path/to/file.hc:15"))
        XCTAssertTrue(diagnostic.contains("Circular dependency detected"))
    }

    /// Test that exitCode property delegates to category.
    func testExitCodeDelegation() {
        let errorIO = TestError(category: .io, message: "IO error", location: nil)
        let errorSyntax = TestError(category: .syntax, message: "Syntax error", location: nil)
        let errorResolution = TestError(category: .resolution, message: "Resolution error", location: nil)
        let errorInternal = TestError(category: .internal, message: "Internal error", location: nil)

        XCTAssertEqual(errorIO.exitCode, 1)
        XCTAssertEqual(errorSyntax.exitCode, 2)
        XCTAssertEqual(errorResolution.exitCode, 3)
        XCTAssertEqual(errorInternal.exitCode, 4)
    }

    /// Test error categories are correctly reflected in diagnostics.
    func testAllCategoriesInDiagnostics() {
        let categories: [(ErrorCategory, String)] = [
            (.io, "IO"),
            (.syntax, "Syntax"),
            (.resolution, "Resolution"),
            (.internal, "Internal")
        ]

        for (category, expectedString) in categories {
            let error = TestError(
                category: category,
                message: "Test message",
                location: nil
            )
            XCTAssertTrue(error.diagnosticInfo.contains("Error [\(expectedString)]"))
        }
    }

    /// Test that location is optional (nil allowed).
    func testLocationIsOptional() {
        let error = TestError(
            category: .internal,
            message: "Unexpected condition",
            location: nil
        )

        XCTAssertNil(error.location)
        // Should not crash when accessing diagnosticInfo
        _ = error.diagnosticInfo
    }

    /// Test multiline message formatting.
    func testMultilineMessage() {
        let location = SourceLocation(filePath: "test.hc", line: 10)
        let message = """
        Multiple issues found:
        1. Invalid indentation
        2. Unclosed quote
        """
        let error = TestError(
            category: .syntax,
            message: message,
            location: location
        )

        let diagnostic = error.diagnosticInfo
        XCTAssertTrue(diagnostic.contains("Error [Syntax]: test.hc:10"))
        XCTAssertTrue(diagnostic.contains("Multiple issues found:"))
        XCTAssertTrue(diagnostic.contains("1. Invalid indentation"))
        XCTAssertTrue(diagnostic.contains("2. Unclosed quote"))
    }
}

// MARK: - Test Error Implementation

/// Concrete error type for testing CompilerError protocol.
private struct TestError: CompilerError {
    let category: ErrorCategory
    let message: String
    let location: SourceLocation?
}

import XCTest
@testable import Core

/// Unit tests for ErrorCategory enum.
final class ErrorCategoryTests: XCTestCase {
    /// Test that all four categories exist.
    func testAllCasesExist() {
        let allCases = ErrorCategory.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.io))
        XCTAssertTrue(allCases.contains(.syntax))
        XCTAssertTrue(allCases.contains(.resolution))
        XCTAssertTrue(allCases.contains(.internal))
    }

    /// Test raw values match specification.
    func testRawValues() {
        XCTAssertEqual(ErrorCategory.io.rawValue, "IO")
        XCTAssertEqual(ErrorCategory.syntax.rawValue, "Syntax")
        XCTAssertEqual(ErrorCategory.resolution.rawValue, "Resolution")
        XCTAssertEqual(ErrorCategory.internal.rawValue, "Internal")
    }

    /// Test exit codes match specification.
    ///
    /// Exit code mapping:
    /// - IO → 1
    /// - Syntax → 2
    /// - Resolution → 3
    /// - Internal → 4
    func testExitCodes() {
        XCTAssertEqual(ErrorCategory.io.exitCode, 1)
        XCTAssertEqual(ErrorCategory.syntax.exitCode, 2)
        XCTAssertEqual(ErrorCategory.resolution.exitCode, 3)
        XCTAssertEqual(ErrorCategory.internal.exitCode, 4)
    }

    /// Test that we can iterate over all cases.
    func testCaseIterable() {
        var count = 0
        for category in ErrorCategory.allCases {
            count += 1
            // Verify each category has a valid exit code
            XCTAssertTrue(category.exitCode >= 1 && category.exitCode <= 4)
        }
        XCTAssertEqual(count, 4)
    }

    /// Test string representation through rawValue.
    func testStringRepresentation() {
        XCTAssertEqual("\(ErrorCategory.io.rawValue)", "IO")
        XCTAssertEqual("\(ErrorCategory.syntax.rawValue)", "Syntax")
        XCTAssertEqual("\(ErrorCategory.resolution.rawValue)", "Resolution")
        XCTAssertEqual("\(ErrorCategory.internal.rawValue)", "Internal")
    }

    /// Test that each category has unique exit code.
    func testUniqueExitCodes() {
        let exitCodes = ErrorCategory.allCases.map { $0.exitCode }
        let uniqueExitCodes = Set(exitCodes)
        XCTAssertEqual(exitCodes.count, uniqueExitCodes.count,
                       "Exit codes must be unique for each category")
    }
}

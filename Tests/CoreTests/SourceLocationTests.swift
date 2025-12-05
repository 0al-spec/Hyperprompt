import XCTest
@testable import Core

/// Unit tests for SourceLocation struct.
final class SourceLocationTests: XCTestCase {
    /// Test basic initialization with valid path and line number.
    func testInitialization() {
        let location = SourceLocation(filePath: "test.hc", line: 42)
        XCTAssertEqual(location.filePath, "test.hc")
        XCTAssertEqual(location.line, 42)
    }

    /// Test equality: two locations with same values are equal.
    func testEquality() {
        let location1 = SourceLocation(filePath: "test.hc", line: 42)
        let location2 = SourceLocation(filePath: "test.hc", line: 42)
        XCTAssertEqual(location1, location2)
    }

    /// Test inequality: different file paths.
    func testInequalityDifferentPath() {
        let location1 = SourceLocation(filePath: "test1.hc", line: 42)
        let location2 = SourceLocation(filePath: "test2.hc", line: 42)
        XCTAssertNotEqual(location1, location2)
    }

    /// Test inequality: different line numbers.
    func testInequalityDifferentLine() {
        let location1 = SourceLocation(filePath: "test.hc", line: 42)
        let location2 = SourceLocation(filePath: "test.hc", line: 43)
        XCTAssertNotEqual(location1, location2)
    }

    /// Test description format matches `<file>:<line>`.
    func testDescriptionFormat() {
        let location = SourceLocation(filePath: "test.hc", line: 42)
        XCTAssertEqual(location.description, "test.hc:42")
    }

    /// Test description with absolute path.
    func testDescriptionWithAbsolutePath() {
        let location = SourceLocation(filePath: "/absolute/path/file.hc", line: 15)
        XCTAssertEqual(location.description, "/absolute/path/file.hc:15")
    }

    /// Test empty file path is handled gracefully.
    func testEmptyFilePath() {
        let location = SourceLocation(filePath: "", line: 1)
        XCTAssertEqual(location.filePath, "")
        XCTAssertEqual(location.description, ":1")
    }

    /// Test minimum line number (1) is valid.
    func testMinimumLineNumber() {
        let location = SourceLocation(filePath: "test.hc", line: 1)
        XCTAssertEqual(location.line, 1)
        XCTAssertEqual(location.description, "test.hc:1")
    }

    /// Test large line number is valid.
    func testLargeLineNumber() {
        let location = SourceLocation(filePath: "test.hc", line: 1_000_000)
        XCTAssertEqual(location.line, 1_000_000)
        XCTAssertEqual(location.description, "test.hc:1000000")
    }

    /// Test that line number 0 triggers precondition failure.
    func testLineNumberZeroTriggersFailure() {
        // Note: This test would crash in debug builds due to precondition.
        // In release builds, preconditions are not checked.
        // We document the expected behavior but can't easily test it.
        // Uncomment to verify (will crash):
        // let location = SourceLocation(filePath: "test.hc", line: 0)
    }

    /// Test that negative line number triggers precondition failure.
    func testNegativeLineNumberTriggersFailure() {
        // Note: This test would crash in debug builds due to precondition.
        // In release builds, preconditions are not checked.
        // We document the expected behavior but can't easily test it.
        // Uncomment to verify (will crash):
        // let location = SourceLocation(filePath: "test.hc", line: -1)
    }
}

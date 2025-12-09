import XCTest
@testable import Emitter

/// Main test suite for Emitter module
/// HeadingAdjuster tests are in HeadingAdjusterTests.swift
final class EmitterTests: XCTestCase {

    // MARK: - Integration Smoke Tests

    func testHeadingAdjusterExists() {
        // Verify HeadingAdjuster can be instantiated
        let adjuster = HeadingAdjuster()
        XCTAssertNotNil(adjuster)
    }

    func testHeadingAdjusterBasicFunctionality() {
        // Quick smoke test for basic functionality
        let adjuster = HeadingAdjuster()
        let result = adjuster.adjustHeadings(in: "# Test", offset: 1)
        XCTAssertEqual(result, "## Test\n")
    }
}

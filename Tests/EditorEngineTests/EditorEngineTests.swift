import XCTest
@testable import EditorEngine

/// Basic tests for EditorEngine module
final class EditorEngineTests: XCTestCase {

    /// Test that EditorEngine module is available
    func testModuleAvailable() {
        XCTAssertTrue(EditorEngine.isAvailable, "EditorEngine module should be available")
    }

    /// Test EditorEngine version
    func testVersion() {
        XCTAssertEqual(EditorEngine.version, "0.2.0-experimental")
    }
}

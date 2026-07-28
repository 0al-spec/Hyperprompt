import XCTest
@testable import Core

final class HyperpromptVersionTests: XCTestCase {
    func testCurrentReleaseVersion() {
        XCTAssertEqual(HyperpromptVersion.current, "0.2.0")
    }
}

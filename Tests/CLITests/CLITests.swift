import XCTest
@testable import CLI
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Placeholder test file for CLI module
/// Tests will be added when CLI is fully implemented
final class CLITests: XCTestCase {
    func testPlaceholder() {
        // Placeholder test
        XCTAssertTrue(true)
    }

    func testSignalExitCodes() {
        XCTAssertEqual(Hyperprompt.interruptionExitCode(forSignal: SIGINT), 130)
        XCTAssertEqual(Hyperprompt.interruptionExitCode(forSignal: SIGTERM), 143)
        XCTAssertEqual(Hyperprompt.interruptionExitCode(forSignal: 0), 1)
    }
}

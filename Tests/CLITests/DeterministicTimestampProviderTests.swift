import XCTest
@testable import CLI

final class DeterministicTimestampProviderTests: XCTestCase {
    func testUsesExplicitHyperpromptTimestamp() {
        let provider = DeterministicTimestampProvider(
            environment: ["HYPERPROMPT_BUILD_TIMESTAMP": "1733751045"],
            fileManager: .default
        )

        let timestamp = provider.resolveTimestampString(for: "/tmp/nonexistent")
        XCTAssertEqual(timestamp, "2024-12-09T13:30:45Z")
    }

    func testFallsBackToSourceDateEpoch() {
        let provider = DeterministicTimestampProvider(
            environment: ["SOURCE_DATE_EPOCH": "1700000000"],
            fileManager: .default
        )

        let timestamp = provider.resolveTimestampString(for: "/tmp/nonexistent")
        XCTAssertEqual(timestamp, "2023-11-14T22:13:20Z")
    }

    func testUsesModificationDateWhenNoExplicitEpoch() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFile = tempDirectory.appendingPathComponent(UUID().uuidString)
        let contents = "test"
        try contents.write(to: tempFile, atomically: true, encoding: .utf8)

        let expectedDate = Date(timeIntervalSince1970: 1_700_000_100)  // Stable, non-current timestamp
        try FileManager.default.setAttributes([.modificationDate: expectedDate], ofItemAtPath: tempFile.path)

        let provider = DeterministicTimestampProvider(environment: [:], fileManager: .default)
        let timestamp = provider.resolveTimestampString(for: tempFile.path)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")

        XCTAssertEqual(timestamp, formatter.string(from: expectedDate))
    }

    func testFallsBackToEpochWhenNoSourcesFound() {
        let provider = DeterministicTimestampProvider(environment: [:], fileManager: .default)

        let timestamp = provider.resolveTimestampString(for: "/path/that/does/not/exist")
        XCTAssertEqual(timestamp, "1970-01-01T00:00:00Z")
    }
}

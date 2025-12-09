import XCTest
@testable import Core
@testable import Emitter

final class ManifestGeneratorTests: XCTestCase {
    var generator: ManifestGenerator!
    var builder: ManifestBuilder!

    override func setUp() {
        super.setUp()
        generator = ManifestGenerator()
        builder = ManifestBuilder()
    }

    override func tearDown() {
        generator = nil
        builder = nil
        super.tearDown()
    }

    // MARK: - Manifest Generation Tests

    func testGenerateEmptyManifest() throws {
        // Given: Empty builder
        // When: Generate manifest
        let manifest = generator.generate(
            builder: builder,
            version: "0.1.0",
            root: "/test/root",
            timestamp: Date(timeIntervalSince1970: 1733751045)  // Fixed timestamp for testing
        )

        // Then: Manifest should have empty sources
        XCTAssertEqual(manifest.root, "/test/root")
        XCTAssertEqual(manifest.version, "0.1.0")
        XCTAssertEqual(manifest.sources.count, 0)
        // Verify timestamp format (actual value will be "2024-12-09T13:30:45Z" for this Unix timestamp)
        XCTAssertTrue(manifest.timestamp.hasSuffix("Z"))
        XCTAssertTrue(manifest.timestamp.contains("T"))
    }

    func testGenerateManifestWithSingleEntry() throws {
        // Given: Builder with one entry
        builder.add(entry: ManifestEntry(
            path: "input.hc",
            sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            size: 1024,
            type: .hypercode
        ))

        // When: Generate manifest
        let manifest = generator.generate(
            builder: builder,
            version: "0.1.0",
            root: "/test/root",
            timestamp: Date(timeIntervalSince1970: 1733751045)
        )

        // Then: Manifest should contain the entry
        XCTAssertEqual(manifest.sources.count, 1)
        XCTAssertEqual(manifest.sources[0].path, "input.hc")
        XCTAssertEqual(manifest.sources[0].sha256, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(manifest.sources[0].size, 1024)
        XCTAssertEqual(manifest.sources[0].type, .hypercode)
    }

    func testGenerateManifestWithMultipleEntries() throws {
        // Given: Builder with multiple entries (unsorted)
        builder.add(entry: ManifestEntry(
            path: "z_last.md",
            sha256: "abc123",
            size: 2048,
            type: .markdown
        ))
        builder.add(entry: ManifestEntry(
            path: "a_first.hc",
            sha256: "def456",
            size: 1024,
            type: .hypercode
        ))
        builder.add(entry: ManifestEntry(
            path: "m_middle.md",
            sha256: "ghi789",
            size: 512,
            type: .markdown
        ))

        // When: Generate manifest
        let manifest = generator.generate(
            builder: builder,
            version: "0.1.0",
            root: "/test/root",
            timestamp: Date(timeIntervalSince1970: 1733751045)
        )

        // Then: Entries should be sorted alphabetically by path
        XCTAssertEqual(manifest.sources.count, 3)
        XCTAssertEqual(manifest.sources[0].path, "a_first.hc")
        XCTAssertEqual(manifest.sources[1].path, "m_middle.md")
        XCTAssertEqual(manifest.sources[2].path, "z_last.md")
    }

    func testGenerateManifestDeterministicOrdering() throws {
        // Given: Builder with entries
        builder.add(entry: ManifestEntry(path: "b.hc", sha256: "hash2", size: 200, type: .hypercode))
        builder.add(entry: ManifestEntry(path: "a.md", sha256: "hash1", size: 100, type: .markdown))
        builder.add(entry: ManifestEntry(path: "c.hc", sha256: "hash3", size: 300, type: .hypercode))

        // When: Generate manifest twice
        let manifest1 = generator.generate(
            builder: builder,
            version: "0.1.0",
            root: "/test",
            timestamp: Date(timeIntervalSince1970: 1733751045)
        )

        let manifest2 = generator.generate(
            builder: builder,
            version: "0.1.0",
            root: "/test",
            timestamp: Date(timeIntervalSince1970: 1733751045)
        )

        // Then: Both should have identical ordering
        XCTAssertEqual(manifest1.sources.map { $0.path }, manifest2.sources.map { $0.path })
        XCTAssertEqual(manifest1.sources.map { $0.path }, ["a.md", "b.hc", "c.hc"])
    }

    // MARK: - JSON Serialization Tests

    func testToJSONEmptyManifest() throws {
        // Given: Empty manifest
        let manifest = Manifest(
            root: "/test/root",
            sources: [],
            timestamp: "2025-12-09T14:30:45Z",
            version: "0.1.0"
        )

        // When: Convert to JSON
        let json = try generator.toJSON(manifest: manifest)

        // Then: JSON should be valid and have correct structure
        XCTAssertTrue(json.hasSuffix("\n"))  // Ends with LF
        XCTAssertFalse(json.hasSuffix("\n\n"))  // Only one LF

        // Parse JSON to verify structure
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Manifest.self, from: data)
        XCTAssertEqual(decoded.root, "/test/root")
        XCTAssertEqual(decoded.sources.count, 0)
        XCTAssertEqual(decoded.version, "0.1.0")
    }

    func testToJSONWithEntry() throws {
        // Given: Manifest with one entry
        let manifest = Manifest(
            root: "/test/root",
            sources: [
                ManifestEntry(
                    path: "input.hc",
                    sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
                    size: 1024,
                    type: .hypercode
                )
            ],
            timestamp: "2025-12-09T14:30:45Z",
            version: "0.1.0"
        )

        // When: Convert to JSON
        let json = try generator.toJSON(manifest: manifest)

        // Then: JSON should contain all fields
        XCTAssertTrue(json.contains("\"root\""))
        XCTAssertTrue(json.contains("\"sources\""))
        XCTAssertTrue(json.contains("\"timestamp\""))
        XCTAssertTrue(json.contains("\"version\""))
        XCTAssertTrue(json.contains("\"path\""))
        XCTAssertTrue(json.contains("\"sha256\""))
        XCTAssertTrue(json.contains("\"size\""))
        XCTAssertTrue(json.contains("\"type\""))
        XCTAssertTrue(json.contains("input.hc"))
        XCTAssertTrue(json.contains("hypercode"))
    }

    func testToJSONAlphabeticalKeyOrdering() throws {
        // Given: Manifest with entry
        let manifest = Manifest(
            root: "/test",
            sources: [
                ManifestEntry(path: "test.md", sha256: "abc", size: 100, type: .markdown)
            ],
            timestamp: "2025-12-09T14:30:45Z",
            version: "0.1.0"
        )

        // When: Convert to JSON
        let json = try generator.toJSON(manifest: manifest)

        // Then: Keys should appear in alphabetical order
        // Top-level: root, sources, timestamp, version
        let rootIndex = json.range(of: "\"root\"")!.lowerBound
        let sourcesIndex = json.range(of: "\"sources\"")!.lowerBound
        let timestampIndex = json.range(of: "\"timestamp\"")!.lowerBound
        let versionIndex = json.range(of: "\"version\"")!.lowerBound

        XCTAssertTrue(rootIndex < sourcesIndex)
        XCTAssertTrue(sourcesIndex < timestampIndex)
        XCTAssertTrue(timestampIndex < versionIndex)

        // Entry keys: path, sha256, size, type
        let pathIndex = json.range(of: "\"path\"")!.lowerBound
        let sha256Index = json.range(of: "\"sha256\"")!.lowerBound
        let sizeIndex = json.range(of: "\"size\"")!.lowerBound
        let typeIndex = json.range(of: "\"type\"")!.lowerBound

        XCTAssertTrue(pathIndex < sha256Index)
        XCTAssertTrue(sha256Index < sizeIndex)
        XCTAssertTrue(sizeIndex < typeIndex)
    }

    func testToJSONDeterministicOutput() throws {
        // Given: Same manifest
        let manifest = Manifest(
            root: "/test",
            sources: [
                ManifestEntry(path: "a.hc", sha256: "hash1", size: 100, type: .hypercode),
                ManifestEntry(path: "b.md", sha256: "hash2", size: 200, type: .markdown)
            ],
            timestamp: "2025-12-09T14:30:45Z",
            version: "0.1.0"
        )

        // When: Convert to JSON multiple times
        let json1 = try generator.toJSON(manifest: manifest)
        let json2 = try generator.toJSON(manifest: manifest)
        let json3 = try generator.toJSON(manifest: manifest)

        // Then: All outputs should be byte-for-byte identical
        XCTAssertEqual(json1, json2)
        XCTAssertEqual(json2, json3)
    }

    func testToJSONValidJSONFormat() throws {
        // Given: Manifest with multiple entries
        let manifest = Manifest(
            root: "/test/project",
            sources: [
                ManifestEntry(path: "docs/intro.md", sha256: "hash1", size: 500, type: .markdown),
                ManifestEntry(path: "src/main.hc", sha256: "hash2", size: 1000, type: .hypercode)
            ],
            timestamp: "2025-12-09T14:30:45Z",
            version: "0.1.0"
        )

        // When: Convert to JSON
        let json = try generator.toJSON(manifest: manifest)

        // Then: JSON should be parseable by standard decoder
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Manifest.self, from: data)

        XCTAssertEqual(decoded.root, manifest.root)
        XCTAssertEqual(decoded.version, manifest.version)
        XCTAssertEqual(decoded.timestamp, manifest.timestamp)
        XCTAssertEqual(decoded.sources.count, manifest.sources.count)
    }

    func testToJSONSpecialCharactersInPaths() throws {
        // Given: Manifest with special characters in paths
        let manifest = Manifest(
            root: "/test/root",
            sources: [
                ManifestEntry(path: "path with spaces.md", sha256: "hash1", size: 100, type: .markdown),
                ManifestEntry(path: "path/with/slashes.hc", sha256: "hash2", size: 200, type: .hypercode),
                ManifestEntry(path: "unicode_файл.md", sha256: "hash3", size: 300, type: .markdown)
            ],
            timestamp: "2025-12-09T14:30:45Z",
            version: "0.1.0"
        )

        // When: Convert to JSON
        let json = try generator.toJSON(manifest: manifest)

        // Then: JSON should be valid and preserve characters
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Manifest.self, from: data)

        XCTAssertEqual(decoded.sources[0].path, "path with spaces.md")
        XCTAssertEqual(decoded.sources[1].path, "path/with/slashes.hc")
        XCTAssertEqual(decoded.sources[2].path, "unicode_файл.md")
    }

    // MARK: - Timestamp Tests

    func testTimestampFormatISO8601() throws {
        // Given: Generator
        // When: Generate manifest with specific timestamp
        let manifest = generator.generate(
            builder: builder,
            version: "0.1.0",
            root: "/test",
            timestamp: Date(timeIntervalSince1970: 1733751045)  // 2024-12-09T13:30:45Z
        )

        // Then: Timestamp should be in ISO 8601 format
        XCTAssertTrue(manifest.timestamp.hasSuffix("Z"))  // UTC timezone
        XCTAssertTrue(manifest.timestamp.contains("T"))   // Date-time separator
        // Verify it's a valid ISO 8601 timestamp
        let formatter = ISO8601DateFormatter()
        XCTAssertNotNil(formatter.date(from: manifest.timestamp))
    }

    func testTimestampUTCTimezone() throws {
        // Given: Various timestamps
        let timestamps = [
            Date(timeIntervalSince1970: 0),            // 1970-01-01T00:00:00Z
            Date(timeIntervalSince1970: 1733751045),   // 2025-12-09T14:30:45Z
            Date(timeIntervalSince1970: 253402300799)  // 9999-12-31T23:59:59Z
        ]

        // When: Generate manifests
        for timestamp in timestamps {
            let manifest = generator.generate(
                builder: builder,
                version: "0.1.0",
                root: "/test",
                timestamp: timestamp
            )

            // Then: All should have Z suffix (UTC)
            XCTAssertTrue(manifest.timestamp.hasSuffix("Z"))
        }
    }

    func testTimestampDefaultToCurrentTime() throws {
        // Given: Generator without explicit timestamp
        // When: Generate manifest
        let beforeTime = Date()
        let manifest = generator.generate(
            builder: builder,
            version: "0.1.0",
            root: "/test"
            // No timestamp parameter - should use current time
        )
        let afterTime = Date()

        // Then: Timestamp should be between before and after times
        XCTAssertFalse(manifest.timestamp.isEmpty)
        XCTAssertTrue(manifest.timestamp.hasSuffix("Z"))

        // Parse timestamp and verify it's in the expected range
        let formatter = ISO8601DateFormatter()
        let manifestTime = formatter.date(from: manifest.timestamp)!
        XCTAssertGreaterThanOrEqual(manifestTime, beforeTime.addingTimeInterval(-1))  // Allow 1s margin
        XCTAssertLessThanOrEqual(manifestTime, afterTime.addingTimeInterval(1))
    }

    // MARK: - Edge Cases Tests

    func testLargeManifest() throws {
        // Given: Builder with many entries
        for i in 0..<1000 {
            builder.add(entry: ManifestEntry(
                path: "file_\(String(format: "%04d", i)).hc",
                sha256: String(repeating: "a", count: 64),
                size: i * 100,
                type: i % 2 == 0 ? .hypercode : .markdown
            ))
        }

        // When: Generate manifest and convert to JSON
        let startTime = Date()
        let manifest = generator.generate(
            builder: builder,
            version: "0.1.0",
            root: "/test",
            timestamp: Date(timeIntervalSince1970: 1733751045)
        )
        let json = try generator.toJSON(manifest: manifest)
        let duration = Date().timeIntervalSince(startTime)

        // Then: Should complete in reasonable time (< 500ms)
        XCTAssertLessThan(duration, 0.5)
        XCTAssertEqual(manifest.sources.count, 1000)

        // Verify sorting maintained
        for i in 0..<999 {
            XCTAssertLessThan(manifest.sources[i].path, manifest.sources[i + 1].path)
        }

        // Verify JSON is valid
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Manifest.self, from: data)
        XCTAssertEqual(decoded.sources.count, 1000)
    }

    func testManifestWithLongPaths() throws {
        // Given: Entry with very long path
        let longPath = String(repeating: "very_long_directory_name/", count: 10) + "file.hc"
        builder.add(entry: ManifestEntry(
            path: longPath,
            sha256: "abc123",
            size: 1024,
            type: .hypercode
        ))

        // When: Generate and serialize
        let manifest = generator.generate(
            builder: builder,
            version: "0.1.0",
            root: "/test",
            timestamp: Date(timeIntervalSince1970: 1733751045)
        )
        let json = try generator.toJSON(manifest: manifest)

        // Then: Should handle long paths correctly
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Manifest.self, from: data)
        XCTAssertEqual(decoded.sources[0].path, longPath)
    }
}

import XCTest
@testable import Core

/// Tests for ManifestBuilder functionality.
///
/// Covers:
/// - Entry accumulation
/// - Entry retrieval
/// - Insertion order preservation
/// - Clear functionality
final class ManifestBuilderTests: XCTestCase {

    var builder: ManifestBuilder!

    override func setUp() {
        super.setUp()
        builder = ManifestBuilder()
    }

    override func tearDown() {
        builder = nil
        super.tearDown()
    }

    // MARK: - Basic Functionality

    func testInitiallyEmpty() {
        // Given: New builder
        // (setUp creates builder)

        // Then: Count is 0
        XCTAssertEqual(builder.count, 0)

        // And: Entries array is empty
        XCTAssertTrue(builder.getEntries().isEmpty)
    }

    func testAddSingleEntry() {
        // Given: Single manifest entry
        let entry = ManifestEntry(
            path: "/test/file.md",
            sha256: "abc123",
            size: 1024,
            type: .markdown
        )

        // When: Add entry
        builder.add(entry: entry)

        // Then: Count is 1
        XCTAssertEqual(builder.count, 1)

        // And: Entry is retrievable
        let entries = builder.getEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].path, "/test/file.md")
    }

    func testAddMultipleEntries() {
        // Given: Multiple manifest entries
        let entry1 = ManifestEntry(path: "/test/file1.md", sha256: "hash1", size: 100, type: .markdown)
        let entry2 = ManifestEntry(path: "/test/file2.hc", sha256: "hash2", size: 200, type: .hypercode)
        let entry3 = ManifestEntry(path: "/test/file3.md", sha256: "hash3", size: 300, type: .markdown)

        // When: Add all entries
        builder.add(entry: entry1)
        builder.add(entry: entry2)
        builder.add(entry: entry3)

        // Then: Count is 3
        XCTAssertEqual(builder.count, 3)

        // And: All entries are retrievable
        let entries = builder.getEntries()
        XCTAssertEqual(entries.count, 3)
    }

    // MARK: - Insertion Order

    func testInsertionOrderPreserved() {
        // Given: Entries added in specific order
        let entry1 = ManifestEntry(path: "/a.md", sha256: "hash1", size: 1, type: .markdown)
        let entry2 = ManifestEntry(path: "/b.hc", sha256: "hash2", size: 2, type: .hypercode)
        let entry3 = ManifestEntry(path: "/c.md", sha256: "hash3", size: 3, type: .markdown)

        // When: Add in order
        builder.add(entry: entry1)
        builder.add(entry: entry2)
        builder.add(entry: entry3)

        // Then: Retrieval maintains order
        let entries = builder.getEntries()
        XCTAssertEqual(entries[0].path, "/a.md")
        XCTAssertEqual(entries[1].path, "/b.hc")
        XCTAssertEqual(entries[2].path, "/c.md")
    }

    // MARK: - Duplicate Paths

    func testDuplicatePathsAllowed() {
        // Given: Same path used twice (different content)
        let entry1 = ManifestEntry(path: "/test/file.md", sha256: "hash1", size: 100, type: .markdown)
        let entry2 = ManifestEntry(path: "/test/file.md", sha256: "hash2", size: 200, type: .markdown)

        // When: Add both entries
        builder.add(entry: entry1)
        builder.add(entry: entry2)

        // Then: Both entries are stored (duplicates allowed)
        XCTAssertEqual(builder.count, 2)

        let entries = builder.getEntries()
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].path, "/test/file.md")
        XCTAssertEqual(entries[1].path, "/test/file.md")
        XCTAssertEqual(entries[0].sha256, "hash1")
        XCTAssertEqual(entries[1].sha256, "hash2")
    }

    // MARK: - Clear Functionality

    func testClear() {
        // Given: Builder with entries
        let entry1 = ManifestEntry(path: "/a.md", sha256: "hash1", size: 1, type: .markdown)
        let entry2 = ManifestEntry(path: "/b.hc", sha256: "hash2", size: 2, type: .hypercode)
        builder.add(entry: entry1)
        builder.add(entry: entry2)
        XCTAssertEqual(builder.count, 2)

        // When: Clear
        builder.clear()

        // Then: Builder is empty
        XCTAssertEqual(builder.count, 0)
        XCTAssertTrue(builder.getEntries().isEmpty)
    }

    func testClearThenAddAgain() {
        // Given: Builder with entry, then cleared
        let entry1 = ManifestEntry(path: "/a.md", sha256: "hash1", size: 1, type: .markdown)
        builder.add(entry: entry1)
        builder.clear()

        // When: Add new entry after clear
        let entry2 = ManifestEntry(path: "/b.hc", sha256: "hash2", size: 2, type: .hypercode)
        builder.add(entry: entry2)

        // Then: Only new entry exists
        XCTAssertEqual(builder.count, 1)
        let entries = builder.getEntries()
        XCTAssertEqual(entries[0].path, "/b.hc")
    }

    // MARK: - Array Independence

    func testGetEntriesReturnsIndependentCopy() {
        // Given: Builder with entry
        let entry = ManifestEntry(path: "/test.md", sha256: "hash", size: 100, type: .markdown)
        builder.add(entry: entry)

        // When: Get entries array
        var entries = builder.getEntries()

        // And: Mutate the array (this should not affect builder)
        entries.removeAll()

        // Then: Builder still has original entry
        XCTAssertEqual(builder.count, 1)
        XCTAssertEqual(builder.getEntries().count, 1)
    }

    // MARK: - Large Collections

    func testLargeNumberOfEntries() {
        // Given: Many entries (stress test)
        let count = 1000

        // When: Add many entries
        for i in 0..<count {
            let entry = ManifestEntry(
                path: "/test/file\(i).md",
                sha256: "hash\(i)",
                size: i,
                type: .markdown
            )
            builder.add(entry: entry)
        }

        // Then: All entries stored
        XCTAssertEqual(builder.count, count)

        // And: All entries retrievable
        let entries = builder.getEntries()
        XCTAssertEqual(entries.count, count)

        // And: First and last entries are correct
        XCTAssertEqual(entries.first?.path, "/test/file0.md")
        XCTAssertEqual(entries.last?.path, "/test/file999.md")
    }
}

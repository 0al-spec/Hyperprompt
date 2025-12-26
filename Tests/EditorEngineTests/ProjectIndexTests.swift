#if Editor
/// Unit Tests for ProjectIndex Data Structures
///
/// Tests the core data model for project indexing including:
/// - FileType classification
/// - FileIndexEntry creation
/// - ProjectIndex construction and computed properties

import XCTest
@testable import EditorEngine

final class ProjectIndexTests: XCTestCase {
    // MARK: - FileType Tests

    func testFileType_HypercodeExtension() {
        XCTAssertEqual(FileType.from(path: "main.hc"), .hypercode)
        XCTAssertEqual(FileType.from(path: "/path/to/file.hc"), .hypercode)
        XCTAssertEqual(FileType.from(path: "nested/deep/source.hc"), .hypercode)
    }

    func testFileType_MarkdownExtension() {
        XCTAssertEqual(FileType.from(path: "README.md"), .markdown)
        XCTAssertEqual(FileType.from(path: "/path/to/doc.md"), .markdown)
        XCTAssertEqual(FileType.from(path: "nested/deep/guide.md"), .markdown)
    }

    func testFileType_UnsupportedExtension() {
        XCTAssertNil(FileType.from(path: "script.swift"))
        XCTAssertNil(FileType.from(path: "data.json"))
        XCTAssertNil(FileType.from(path: "image.png"))
        XCTAssertNil(FileType.from(path: "noextension"))
    }

    // MARK: - FileIndexEntry Tests

    func testFileIndexEntry_Creation() {
        let entry = FileIndexEntry(
            path: "src/main.hc",
            type: .hypercode,
            size: 1024
        )

        XCTAssertEqual(entry.path, "src/main.hc")
        XCTAssertEqual(entry.type, .hypercode)
        XCTAssertEqual(entry.size, 1024)
        XCTAssertNil(entry.lastModified)
    }

    func testFileIndexEntry_WithModificationDate() {
        let date = Date()
        let entry = FileIndexEntry(
            path: "docs/guide.md",
            type: .markdown,
            size: 2048,
            lastModified: date
        )

        XCTAssertEqual(entry.lastModified, date)
    }

    func testFileIndexEntry_Equality() {
        let entry1 = FileIndexEntry(path: "foo.hc", type: .hypercode, size: 100)
        let entry2 = FileIndexEntry(path: "foo.hc", type: .hypercode, size: 100)
        let entry3 = FileIndexEntry(path: "bar.hc", type: .hypercode, size: 100)

        XCTAssertEqual(entry1, entry2)
        XCTAssertNotEqual(entry1, entry3)
    }

    // MARK: - ProjectIndex Tests

    func testProjectIndex_EmptyIndex() {
        let index = ProjectIndex.empty(workspaceRoot: "/test")

        XCTAssertEqual(index.workspaceRoot, "/test")
        XCTAssertEqual(index.totalFiles, 0)
        XCTAssertEqual(index.hypercodeFileCount, 0)
        XCTAssertEqual(index.markdownFileCount, 0)
        XCTAssertEqual(index.totalSize, 0)
    }

    func testProjectIndex_SingleFile() {
        let entry = FileIndexEntry(path: "main.hc", type: .hypercode, size: 512)
        let index = ProjectIndex(workspaceRoot: "/workspace", files: [entry])

        XCTAssertEqual(index.totalFiles, 1)
        XCTAssertEqual(index.hypercodeFileCount, 1)
        XCTAssertEqual(index.markdownFileCount, 0)
        XCTAssertEqual(index.totalSize, 512)
    }

    func testProjectIndex_MultipleFiles() {
        let files = [
            FileIndexEntry(path: "main.hc", type: .hypercode, size: 512),
            FileIndexEntry(path: "README.md", type: .markdown, size: 256),
            FileIndexEntry(path: "lib/utils.hc", type: .hypercode, size: 1024),
            FileIndexEntry(path: "docs/guide.md", type: .markdown, size: 2048)
        ]
        let index = ProjectIndex(workspaceRoot: "/workspace", files: files)

        XCTAssertEqual(index.totalFiles, 4)
        XCTAssertEqual(index.hypercodeFileCount, 2)
        XCTAssertEqual(index.markdownFileCount, 2)
        XCTAssertEqual(index.totalSize, 3840) // 512 + 256 + 1024 + 2048
    }

    func testProjectIndex_FilesSortedLexicographically() {
        let files = [
            FileIndexEntry(path: "z_last.hc", type: .hypercode, size: 100),
            FileIndexEntry(path: "a_first.md", type: .markdown, size: 100),
            FileIndexEntry(path: "m_middle.hc", type: .hypercode, size: 100)
        ]
        let index = ProjectIndex(workspaceRoot: "/workspace", files: files)

        // Files should be sorted by path
        XCTAssertEqual(index.files[0].path, "a_first.md")
        XCTAssertEqual(index.files[1].path, "m_middle.hc")
        XCTAssertEqual(index.files[2].path, "z_last.hc")
    }

    func testProjectIndex_FindFileByPath() {
        let files = [
            FileIndexEntry(path: "main.hc", type: .hypercode, size: 512),
            FileIndexEntry(path: "README.md", type: .markdown, size: 256)
        ]
        let index = ProjectIndex(workspaceRoot: "/workspace", files: files)

        let found = index.file(at: "main.hc")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.path, "main.hc")

        let notFound = index.file(at: "nonexistent.hc")
        XCTAssertNil(notFound)
    }

    func testProjectIndex_Codable() throws {
        let files = [
            FileIndexEntry(path: "main.hc", type: .hypercode, size: 512)
        ]
        let original = ProjectIndex(workspaceRoot: "/workspace", files: files)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProjectIndex.self, from: data)

        XCTAssertEqual(decoded.workspaceRoot, original.workspaceRoot)
        XCTAssertEqual(decoded.files, original.files)
        XCTAssertEqual(decoded.totalFiles, original.totalFiles)
    }
}
#endif

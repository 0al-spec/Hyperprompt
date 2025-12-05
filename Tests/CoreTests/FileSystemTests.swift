import XCTest
@testable import Core

/// Unit tests for FileSystem protocol implementations (MockFileSystem and LocalFileSystem).
final class FileSystemTests: XCTestCase {
    var mockFS: MockFileSystem!

    override func setUp() {
        super.setUp()
        mockFS = MockFileSystem()
    }

    override func tearDown() {
        mockFS = nil
        super.tearDown()
    }

    // MARK: - MockFileSystem Tests

    /// Test adding and reading a file from MockFileSystem.
    func testMockFileSystemReadSuccess() throws {
        mockFS.addFile(at: "/test/file.hc", content: "\"Root\"\n")

        let content = try mockFS.readFile(at: "/test/file.hc")
        XCTAssertEqual(content, "\"Root\"\n")
    }

    /// Test reading non-existent file throws IO error.
    func testMockFileSystemReadFailure() {
        XCTAssertThrowsError(try mockFS.readFile(at: "/nonexistent.hc")) { error in
            guard let compilerError = error as? CompilerError else {
                XCTFail("Expected CompilerError")
                return
            }
            XCTAssertEqual(compilerError.category, .io)
            XCTAssertTrue(compilerError.message.contains("File not found"))
        }
    }

    /// Test fileExists returns true for added file.
    func testMockFileSystemFileExists() {
        mockFS.addFile(at: "/test/file.hc", content: "test")

        XCTAssertTrue(mockFS.fileExists(at: "/test/file.hc"))
    }

    /// Test fileExists returns false for non-existent file.
    func testMockFileSystemFileNotExists() {
        XCTAssertFalse(mockFS.fileExists(at: "/nonexistent.hc"))
    }

    /// Test canonicalizePath with absolute path.
    func testMockFileSystemCanonicalizeAbsolutePath() throws {
        let result = try mockFS.canonicalizePath("/absolute/path/file.hc")
        XCTAssertEqual(result, "/absolute/path/file.hc")
    }

    /// Test canonicalizePath with relative path.
    func testMockFileSystemCanonicalizeRelativePath() throws {
        mockFS.setCurrentDirectory("/base")

        let result = try mockFS.canonicalizePath("relative/file.hc")
        XCTAssertEqual(result, "/base/relative/file.hc")
    }

    /// Test currentDirectory returns default value.
    func testMockFileSystemCurrentDirectory() {
        XCTAssertEqual(mockFS.currentDirectory(), "/mock")
    }

    /// Test setting custom current directory.
    func testMockFileSystemSetCurrentDirectory() {
        mockFS.setCurrentDirectory("/custom")
        XCTAssertEqual(mockFS.currentDirectory(), "/custom")
    }

    /// Test clear removes all files.
    func testMockFileSystemClear() {
        mockFS.addFile(at: "/file1.hc", content: "content1")
        mockFS.addFile(at: "/file2.hc", content: "content2")

        XCTAssertTrue(mockFS.fileExists(at: "/file1.hc"))
        XCTAssertTrue(mockFS.fileExists(at: "/file2.hc"))

        mockFS.clear()

        XCTAssertFalse(mockFS.fileExists(at: "/file1.hc"))
        XCTAssertFalse(mockFS.fileExists(at: "/file2.hc"))
    }

    /// Test removeFile removes specific file.
    func testMockFileSystemRemoveFile() {
        mockFS.addFile(at: "/file1.hc", content: "content1")
        mockFS.addFile(at: "/file2.hc", content: "content2")

        mockFS.removeFile(at: "/file1.hc")

        XCTAssertFalse(mockFS.fileExists(at: "/file1.hc"))
        XCTAssertTrue(mockFS.fileExists(at: "/file2.hc"))
    }

    /// Test simulated error is thrown.
    func testMockFileSystemSimulatedError() {
        let simulatedError = TestCompilerError(
            category: .io,
            message: "Simulated permission denied",
            location: nil
        )

        mockFS.simulateError(for: "/test/file.hc", error: simulatedError)

        XCTAssertThrowsError(try mockFS.readFile(at: "/test/file.hc")) { error in
            guard let compilerError = error as? CompilerError else {
                XCTFail("Expected CompilerError")
                return
            }
            XCTAssertEqual(compilerError.category, .io)
            XCTAssertTrue(compilerError.message.contains("Simulated permission denied"))
        }
    }

    /// Test that simulatedError takes precedence over real file.
    func testMockFileSystemSimulatedErrorOverridesFile() {
        mockFS.addFile(at: "/test/file.hc", content: "real content")

        let simulatedError = TestCompilerError(
            category: .internal,
            message: "Simulated error",
            location: nil
        )
        mockFS.simulateError(for: "/test/file.hc", error: simulatedError)

        XCTAssertThrowsError(try mockFS.readFile(at: "/test/file.hc")) { error in
            guard let compilerError = error as? CompilerError else {
                XCTFail("Expected CompilerError")
                return
            }
            XCTAssertEqual(compilerError.category, .internal)
        }
    }

    /// Test multiple files can be stored independently.
    func testMockFileSystemMultipleFiles() throws {
        mockFS.addFile(at: "/file1.hc", content: "content1")
        mockFS.addFile(at: "/file2.hc", content: "content2")
        mockFS.addFile(at: "/dir/file3.hc", content: "content3")

        XCTAssertEqual(try mockFS.readFile(at: "/file1.hc"), "content1")
        XCTAssertEqual(try mockFS.readFile(at: "/file2.hc"), "content2")
        XCTAssertEqual(try mockFS.readFile(at: "/dir/file3.hc"), "content3")
    }

    // MARK: - LocalFileSystem Tests

    /// Test LocalFileSystem currentDirectory returns non-empty path.
    func testLocalFileSystemCurrentDirectory() {
        let localFS = LocalFileSystem()
        let currentDir = localFS.currentDirectory()

        XCTAssertFalse(currentDir.isEmpty)
        // Should be an absolute path
        XCTAssertTrue(currentDir.hasPrefix("/") || currentDir.contains(":")) // Unix or Windows path
    }

    /// Test LocalFileSystem fileExists for known file (Package.swift should exist).
    func testLocalFileSystemFileExistsForKnownFile() {
        let localFS = LocalFileSystem()

        // Package.swift should exist in project root
        XCTAssertTrue(localFS.fileExists(at: "Package.swift"))
    }

    /// Test LocalFileSystem fileExists returns false for non-existent file.
    func testLocalFileSystemFileNotExists() {
        let localFS = LocalFileSystem()

        XCTAssertFalse(localFS.fileExists(at: "/this/file/definitely/does/not/exist.hc"))
    }

    /// Test LocalFileSystem canonicalizePath with relative path.
    func testLocalFileSystemCanonicalizeRelativePath() throws {
        let localFS = LocalFileSystem()

        let result = try localFS.canonicalizePath("Package.swift")

        // Should return absolute path
        XCTAssertTrue(result.hasPrefix("/") || result.contains(":")) // Unix or Windows path
        XCTAssertTrue(result.hasSuffix("Package.swift"))
    }

    /// Test LocalFileSystem readFile for known file.
    func testLocalFileSystemReadKnownFile() throws {
        let localFS = LocalFileSystem()

        // Read Package.swift (should exist)
        let content = try localFS.readFile(at: "Package.swift")

        XCTAssertFalse(content.isEmpty)
        // Should contain Swift package declaration
        XCTAssertTrue(content.contains("swift-tools-version") || content.contains("Package"))
    }

    /// Test LocalFileSystem readFile throws for non-existent file.
    func testLocalFileSystemReadNonExistentFile() {
        let localFS = LocalFileSystem()

        XCTAssertThrowsError(try localFS.readFile(at: "/nonexistent/file.hc")) { error in
            guard let compilerError = error as? CompilerError else {
                XCTFail("Expected CompilerError")
                return
            }
            XCTAssertEqual(compilerError.category, .io)
            XCTAssertTrue(compilerError.message.contains("File not found") ||
                         compilerError.message.contains("Failed to read"))
        }
    }
}

// MARK: - Test Helper

private struct TestCompilerError: CompilerError {
    let category: ErrorCategory
    let message: String
    let location: SourceLocation?
}

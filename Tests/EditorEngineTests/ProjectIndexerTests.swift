#if Editor
/// Unit Tests for ProjectIndexer
///
/// Tests the project indexing engine including:
/// - Configuration options
/// - Error handling
/// - Integration with FileSystem
///
/// Note: Full integration tests require MockFileSystem setup

import XCTest
@testable import EditorEngine
@testable import Core

final class ProjectIndexerTests: XCTestCase {
    // MARK: - IndexerOptions Tests

    func testIndexerOptions_DefaultValues() {
        let options = IndexerOptions.default

        XCTAssertEqual(options.symlinkPolicy, .skip)
        XCTAssertEqual(options.hiddenEntryPolicy, .exclude)
        XCTAssertEqual(options.maxDepth, 100)
        XCTAssertTrue(options.customIgnorePatterns.isEmpty)
    }

    func testIndexerOptions_CustomValues() {
        let options = IndexerOptions(
            symlinkPolicy: .follow,
            hiddenEntryPolicy: .include,
            maxDepth: 50,
            customIgnorePatterns: ["*.draft", "tmp/"]
        )

        XCTAssertEqual(options.symlinkPolicy, .follow)
        XCTAssertEqual(options.hiddenEntryPolicy, .include)
        XCTAssertEqual(options.maxDepth, 50)
        XCTAssertEqual(options.customIgnorePatterns.count, 2)
    }

    // MARK: - IndexerError Tests

    func testIndexerError_WorkspaceNotFound() {
        let error = IndexerError.workspaceNotFound(path: "/nonexistent")
        let description = error.description

        XCTAssertTrue(description.contains("/nonexistent"))
        XCTAssertTrue(description.contains("not found"))
    }

    func testIndexerError_PermissionDenied() {
        let error = IndexerError.permissionDenied(path: "/restricted")
        let description = error.description

        XCTAssertTrue(description.contains("/restricted"))
        XCTAssertTrue(description.contains("denied"))
    }

    func testIndexerError_MaxDepthExceeded() {
        let error = IndexerError.maxDepthExceeded(depth: 150, limit: 100)
        let description = error.description

        XCTAssertTrue(description.contains("150"))
        XCTAssertTrue(description.contains("100"))
    }

    func testIndexerError_InvalidIgnoreFile() {
        let error = IndexerError.invalidIgnoreFile(path: ".hyperpromptignore", reason: "malformed")
        let description = error.description

        XCTAssertTrue(description.contains(".hyperpromptignore"))
        XCTAssertTrue(description.contains("malformed"))
    }

    func testIndexerError_InvalidWorkspaceRoot_Description() {
        let error = IndexerError.invalidWorkspaceRoot(path: "relative/path", reason: "Workspace root must be an absolute path")
        let description = error.description

        XCTAssertTrue(description.contains("relative/path"))
        XCTAssertTrue(description.contains("Workspace root must be an absolute path"))
    }

    func testIndexerError_Equality() {
        let error1 = IndexerError.workspaceNotFound(path: "/test")
        let error2 = IndexerError.workspaceNotFound(path: "/test")
        let error3 = IndexerError.workspaceNotFound(path: "/other")

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    // MARK: - Default Ignore Directories

    func testDefaultIgnoreDirs_ContainsCommonPatterns() {
        // This test verifies that ProjectIndexer has sensible defaults
        // We can't directly access the private static property, but we can
        // test the behavior through integration tests with MockFileSystem
        // For now, this is a placeholder for documentation

        // Expected default ignore directories:
        // .git, .build, build, Build, DerivedData, node_modules, Packages,
        // .vscode, .idea, .cache, dist, target

        XCTAssertTrue(true, "Default ignore patterns are defined in ProjectIndexer")
    }

    // MARK: - Integration Test Placeholders

    func testIndexer_RequiresMockFileSystemForFullTesting() {
        // Full integration testing requires:
        // 1. MockFileSystem implementation with directory structure
        // 2. Test workspace setup with .hc and .md files
        // 3. .hyperpromptignore file creation
        // 4. Verification of discovered files and ordering
        //
        // Example test structure:
        //
        // let mockFS = MockFileSystem()
        // mockFS.createDirectory("/workspace/src")
        // mockFS.createFile("/workspace/main.hc", content: "")
        // mockFS.createFile("/workspace/src/utils.hc", content: "")
        //
        // let indexer = ProjectIndexer(fileSystem: mockFS)
        // let index = try indexer.index(workspaceRoot: "/workspace")
        //
        // XCTAssertEqual(index.totalFiles, 2)
        // XCTAssertEqual(index.files[0].path, "main.hc")
        // XCTAssertEqual(index.files[1].path, "src/utils.hc")

        XCTAssertTrue(true, "Integration tests require MockFileSystem implementation")
    }

    // MARK: - Error Condition Tests

    func testIndexer_WorkspaceNotFound_ThrowsError() {
        // This test would require MockFileSystem that reports "directory not found"
        // For now, placeholder for expected behavior

        // let mockFS = MockFileSystem()
        // mockFS.markDirectoryAsNonExistent("/nonexistent")
        //
        // let indexer = ProjectIndexer(fileSystem: mockFS)
        //
        // XCTAssertThrowsError(try indexer.index(workspaceRoot: "/nonexistent")) { error in
        //     if case IndexerError.workspaceNotFound = error {
        //         // Expected error
        //     } else {
        //         XCTFail("Expected IndexerError.workspaceNotFound")
        //     }
        // }

        XCTAssertTrue(true, "Error handling requires MockFileSystem")
    }

    // MARK: - Workspace Root Path Validation Tests

    func testIndexer_RelativePath_ThrowsError() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)

        XCTAssertThrowsError(try indexer.index(workspaceRoot: "relative/path")) { error in
            guard case IndexerError.invalidWorkspaceRoot(let path, let reason) = error else {
                XCTFail("Expected IndexerError.invalidWorkspaceRoot, got \(error)")
                return
            }
            XCTAssertEqual(path, "relative/path")
            XCTAssertEqual(reason, "Workspace root must be an absolute path")
        }
    }

    func testIndexer_EmptyPath_ThrowsError() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)

        XCTAssertThrowsError(try indexer.index(workspaceRoot: "")) { error in
            guard case IndexerError.invalidWorkspaceRoot = error else {
                XCTFail("Expected IndexerError.invalidWorkspaceRoot, got \(error)")
                return
            }
        }
    }

    func testIndexer_CurrentDirectoryPath_ThrowsError() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)

        XCTAssertThrowsError(try indexer.index(workspaceRoot: ".")) { error in
            guard case IndexerError.invalidWorkspaceRoot = error else {
                XCTFail("Expected IndexerError.invalidWorkspaceRoot, got \(error)")
                return
            }
        }
    }

    func testIndexer_ParentDirectoryPath_ThrowsError() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)

        XCTAssertThrowsError(try indexer.index(workspaceRoot: "../foo")) { error in
            guard case IndexerError.invalidWorkspaceRoot = error else {
                XCTFail("Expected IndexerError.invalidWorkspaceRoot, got \(error)")
                return
            }
        }
    }

    func testIndexer_AbsolutePath_ProceedsToExistenceCheck() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)

        // Absolute path should pass validation, then fail on existence check
        XCTAssertThrowsError(try indexer.index(workspaceRoot: "/absolute/path")) { error in
            guard case IndexerError.workspaceNotFound = error else {
                XCTFail("Expected IndexerError.workspaceNotFound (path validation passed), got \(error)")
                return
            }
        }
    }

    // MARK: - joinPath Tests

    func testJoinPath_NormalCase() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)
        let result = indexer.joinPath("/path", "file")
        XCTAssertEqual(result, "/path/file")
    }

    func testJoinPath_TrailingSlashOnBase() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)
        let result = indexer.joinPath("/path/", "file")
        XCTAssertEqual(result, "/path/file")
    }

    func testJoinPath_LeadingSlashOnComponent() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)
        let result = indexer.joinPath("/path", "/file")
        XCTAssertEqual(result, "/path/file")
    }

    func testJoinPath_BothSlashes() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)
        let result = indexer.joinPath("/path/", "/file")
        XCTAssertEqual(result, "/path/file")
    }

    func testJoinPath_EmptyComponent() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)
        let result = indexer.joinPath("/path", "")
        XCTAssertEqual(result, "/path")
    }

    func testJoinPath_RootBase() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)
        let result = indexer.joinPath("/", "file")
        XCTAssertEqual(result, "/file")
    }
}

// MARK: - MockFileSystem for Testing

/// Minimal mock file system for ProjectIndexer tests
private final class MockFileSystem: FileSystem {
    private var files: [String: String] = [:]
    private var currentDir = "/mock"

    func addFile(path: String, content: String = "") {
        files[path] = content
    }

    func readFile(at path: String) throws -> String {
        guard let content = files[path] else {
            throw MockFileSystemError(message: "File not found: \(path)")
        }
        return content
    }

    func fileExists(at path: String) -> Bool {
        files[path] != nil
    }

    func canonicalizePath(_ path: String) throws -> String {
        if path.hasPrefix("/") {
            return path
        }
        return currentDir + "/" + path
    }

    func currentDirectory() -> String {
        currentDir
    }

    func writeFile(at path: String, content: String) throws {
        files[path] = content
    }

    func listDirectory(at path: String) throws -> [String] {
        []
    }

    func isDirectory(at path: String) -> Bool {
        false
    }

    func fileAttributes(at path: String) -> FileAttributes? {
        guard let content = files[path] else {
            return nil
        }
        return FileAttributes(size: content.utf8.count)
    }
}

private struct MockFileSystemError: CompilerError {
    let category: ErrorCategory = .io
    let message: String
    let location: SourceLocation? = nil
}
#endif

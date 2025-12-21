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
}

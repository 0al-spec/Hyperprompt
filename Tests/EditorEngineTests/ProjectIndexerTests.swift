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

    func testIndexer_InvalidIgnorePattern_ThrowsError() {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addFile(path: "/workspace/.hyperpromptignore", content: "\0")

        let indexer = ProjectIndexer(fileSystem: mockFS)

        XCTAssertThrowsError(try indexer.index(workspaceRoot: "/workspace")) { error in
            guard case IndexerError.invalidIgnoreFile(let path, let reason) = error else {
                XCTFail("Expected IndexerError.invalidIgnoreFile, got \(error)")
                return
            }
            XCTAssertEqual(path, "/workspace/.hyperpromptignore")
            XCTAssertTrue(reason.contains("line 1"))
        }
    }

    func testIndexer_InvalidCustomIgnorePattern_ThrowsError() {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")

        let options = IndexerOptions(
            symlinkPolicy: .skip,
            hiddenEntryPolicy: .exclude,
            maxDepth: 100,
            customIgnorePatterns: ["\0"]
        )

        let indexer = ProjectIndexer(fileSystem: mockFS, options: options)

        XCTAssertThrowsError(try indexer.index(workspaceRoot: "/workspace")) { error in
            guard case IndexerError.invalidIgnoreFile(_, let reason) = error else {
                XCTFail("Expected IndexerError.invalidIgnoreFile, got \(error)")
                return
            }
            XCTAssertTrue(reason.contains("custom ignore pattern"))
        }
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

    // MARK: - Integration Tests

    func testIndexer_MultiLevelDirectoryTraversal() throws {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addDirectory(path: "/workspace/src")
        mockFS.addDirectory(path: "/workspace/docs")
        mockFS.addFile(path: "/workspace/main.hc")
        mockFS.addFile(path: "/workspace/src/utils.hc")
        mockFS.addFile(path: "/workspace/docs/readme.md")

        let indexer = ProjectIndexer(fileSystem: mockFS)
        let index = try indexer.index(workspaceRoot: "/workspace")

        XCTAssertEqual(index.totalFiles, 3)
        XCTAssertEqual(index.files.map(\.path), ["docs/readme.md", "main.hc", "src/utils.hc"])
    }

    func testIndexer_HyperpromptignoreExcludesMatches() throws {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addFile(path: "/workspace/.hyperpromptignore", content: "*.draft\ntmp/\n")
        mockFS.addDirectory(path: "/workspace/tmp")
        mockFS.addFile(path: "/workspace/main.hc")
        mockFS.addFile(path: "/workspace/notes.draft")
        mockFS.addFile(path: "/workspace/tmp/temp.hc")

        let indexer = ProjectIndexer(fileSystem: mockFS)
        let index = try indexer.index(workspaceRoot: "/workspace")

        XCTAssertEqual(index.totalFiles, 1)
        XCTAssertEqual(index.files.first?.path, "main.hc")
    }

    func testIndexer_DefaultIgnoreDirectoriesExcluded() throws {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addDirectory(path: "/workspace/.git")
        mockFS.addDirectory(path: "/workspace/.build")
        mockFS.addDirectory(path: "/workspace/node_modules")
        mockFS.addFile(path: "/workspace/main.hc")
        mockFS.addFile(path: "/workspace/.git/config.hc")
        mockFS.addFile(path: "/workspace/.build/output.hc")
        mockFS.addFile(path: "/workspace/node_modules/package.hc")

        let indexer = ProjectIndexer(fileSystem: mockFS)
        let index = try indexer.index(workspaceRoot: "/workspace")

        XCTAssertEqual(index.totalFiles, 1)
        XCTAssertEqual(index.files.first?.path, "main.hc")
    }

    func testIndexer_SymlinkSkipPolicy() throws {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addDirectory(path: "/external")
        mockFS.addFile(path: "/workspace/main.hc")
        mockFS.addFile(path: "/external/linked.hc")
        mockFS.addSymlink(path: "/workspace/link", target: "/external")

        let options = IndexerOptions(symlinkPolicy: .skip, hiddenEntryPolicy: .exclude, maxDepth: 100)
        let indexer = ProjectIndexer(fileSystem: mockFS, options: options)
        let index = try indexer.index(workspaceRoot: "/workspace")

        XCTAssertEqual(index.totalFiles, 1)
        XCTAssertEqual(index.files.first?.path, "main.hc")
    }

    func testIndexer_SymlinkFollowPolicy() throws {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addDirectory(path: "/external")
        mockFS.addFile(path: "/workspace/main.hc")
        mockFS.addFile(path: "/external/linked.hc")
        mockFS.addSymlink(path: "/workspace/link", target: "/external")

        let options = IndexerOptions(symlinkPolicy: .follow, hiddenEntryPolicy: .exclude, maxDepth: 100)
        let indexer = ProjectIndexer(fileSystem: mockFS, options: options)
        let index = try indexer.index(workspaceRoot: "/workspace")

        XCTAssertEqual(index.totalFiles, 2)
        XCTAssertEqual(index.files.map(\.path), ["link/linked.hc", "main.hc"])
    }

    func testIndexer_HiddenFilesExcluded() throws {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addFile(path: "/workspace/main.hc")
        mockFS.addFile(path: "/workspace/.hidden.hc")

        let options = IndexerOptions(symlinkPolicy: .skip, hiddenEntryPolicy: .exclude, maxDepth: 100)
        let indexer = ProjectIndexer(fileSystem: mockFS, options: options)
        let index = try indexer.index(workspaceRoot: "/workspace")

        XCTAssertEqual(index.totalFiles, 1)
        XCTAssertEqual(index.files.first?.path, "main.hc")
    }

    func testIndexer_HiddenFilesIncluded() throws {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addFile(path: "/workspace/main.hc")
        mockFS.addFile(path: "/workspace/.hidden.hc")

        let options = IndexerOptions(symlinkPolicy: .skip, hiddenEntryPolicy: .include, maxDepth: 100)
        let indexer = ProjectIndexer(fileSystem: mockFS, options: options)
        let index = try indexer.index(workspaceRoot: "/workspace")

        XCTAssertEqual(index.totalFiles, 2)
        XCTAssertEqual(index.files.map(\.path), [".hidden.hc", "main.hc"])
    }

    func testIndexer_MaxDepthExceeded() {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addDirectory(path: "/workspace/level1")
        mockFS.addDirectory(path: "/workspace/level1/level2")
        mockFS.addDirectory(path: "/workspace/level1/level2/level3")
        mockFS.addFile(path: "/workspace/root.hc")
        mockFS.addFile(path: "/workspace/level1/l1.hc")
        mockFS.addFile(path: "/workspace/level1/level2/l2.hc")
        mockFS.addFile(path: "/workspace/level1/level2/level3/l3.hc")

        let options = IndexerOptions(symlinkPolicy: .skip, hiddenEntryPolicy: .exclude, maxDepth: 2)
        let indexer = ProjectIndexer(fileSystem: mockFS, options: options)

        XCTAssertThrowsError(try indexer.index(workspaceRoot: "/workspace")) { error in
            guard case IndexerError.maxDepthExceeded(let depth, let limit) = error else {
                XCTFail("Expected maxDepthExceeded, got \(error)")
                return
            }
            XCTAssertEqual(depth, 2)
            XCTAssertEqual(limit, 2)
        }
    }

    func testIndexer_DeterministicOrdering() throws {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addFile(path: "/workspace/zebra.hc")
        mockFS.addFile(path: "/workspace/alpha.hc")
        mockFS.addFile(path: "/workspace/beta.md")

        let indexer = ProjectIndexer(fileSystem: mockFS)
        let index = try indexer.index(workspaceRoot: "/workspace")

        XCTAssertEqual(index.totalFiles, 3)
        XCTAssertEqual(index.files.map(\.path), ["alpha.hc", "beta.md", "zebra.hc"])
    }

    func testIndexer_EmptyWorkspace() throws {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")

        let indexer = ProjectIndexer(fileSystem: mockFS)
        let index = try indexer.index(workspaceRoot: "/workspace")

        XCTAssertEqual(index.totalFiles, 0)
        XCTAssertTrue(index.files.isEmpty)
    }

    func testIndexer_WorkspaceWithOnlyIgnoredFiles() throws {
        let mockFS = MockFileSystem()
        mockFS.addDirectory(path: "/workspace")
        mockFS.addFile(path: "/workspace/.hyperpromptignore", content: "*.hc\n")
        mockFS.addFile(path: "/workspace/ignored.hc")

        let indexer = ProjectIndexer(fileSystem: mockFS)
        let index = try indexer.index(workspaceRoot: "/workspace")

        XCTAssertEqual(index.totalFiles, 0)
        XCTAssertTrue(index.files.isEmpty)
    }

    // MARK: - Error Condition Tests

    func testIndexer_WorkspaceNotFound_ThrowsError() {
        let mockFS = MockFileSystem()
        let indexer = ProjectIndexer(fileSystem: mockFS)

        XCTAssertThrowsError(try indexer.index(workspaceRoot: "/nonexistent")) { error in
            guard case IndexerError.workspaceNotFound(let path) = error else {
                XCTFail("Expected IndexerError.workspaceNotFound, got \(error)")
                return
            }
            XCTAssertEqual(path, "/nonexistent")
        }
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
    private var directories: Set<String> = ["/"]
    private var symlinks: [String: String] = [:]
    private var currentDir = "/mock"

    func addFile(path: String, content: String = "") {
        addDirectory(path: parentDirectory(of: path))
        files[path] = content
    }

    func addDirectory(path: String) {
        var path = path
        if !path.hasPrefix("/") {
            path = currentDir + "/" + path
        }

        var components = path.split(separator: "/").map(String.init)
        var current = ""
        while !components.isEmpty {
            current += "/" + components.removeFirst()
            directories.insert(current)
        }
    }

    func addSymlink(path: String, target: String) {
        addDirectory(path: parentDirectory(of: path))
        symlinks[path] = target
    }

    func readFile(at path: String) throws -> String {
        let resolvedPath = try canonicalizePath(path)
        guard let content = files[resolvedPath] else {
            throw MockFileSystemError(message: "File not found: \(path)")
        }
        return content
    }

    func fileExists(at path: String) -> Bool {
        let resolvedPath = resolvePath(path)
        return files[resolvedPath] != nil || directories.contains(resolvedPath) || symlinks[resolvedPath] != nil
    }

    func canonicalizePath(_ path: String) throws -> String {
        let absolutePath = path.hasPrefix("/") ? path : currentDir + "/" + path
        if let mapped = resolveSymlinkPath(absolutePath) {
            return mapped
        }
        return absolutePath
    }

    func currentDirectory() -> String {
        currentDir
    }

    func writeFile(at path: String, content: String) throws {
        addDirectory(path: parentDirectory(of: path))
        files[path] = content
    }

    func listDirectory(at path: String) throws -> [String] {
        let resolvedPath = try canonicalizePath(path)
        guard isDirectory(at: resolvedPath) else {
            throw MockFileSystemError(message: "Not a directory: \(path)")
        }

        let normalizedPath = resolvedPath.hasSuffix("/") ? resolvedPath : resolvedPath + "/"
        var results: Set<String> = []

        for filePath in files.keys {
            if filePath.hasPrefix(normalizedPath) {
                let relativePath = String(filePath.dropFirst(normalizedPath.count))
                if let firstComponent = relativePath.split(separator: "/").first {
                    results.insert(String(firstComponent))
                }
            }
        }

        for directoryPath in directories {
            if directoryPath == resolvedPath {
                continue
            }
            if directoryPath.hasPrefix(normalizedPath) {
                let relativePath = String(directoryPath.dropFirst(normalizedPath.count))
                if let firstComponent = relativePath.split(separator: "/").first {
                    results.insert(String(firstComponent))
                }
            }
        }

        for symlinkPath in symlinks.keys {
            if symlinkPath.hasPrefix(normalizedPath) {
                let relativePath = String(symlinkPath.dropFirst(normalizedPath.count))
                if let firstComponent = relativePath.split(separator: "/").first {
                    results.insert(String(firstComponent))
                }
            }
        }

        return Array(results)
    }

    func isDirectory(at path: String) -> Bool {
        let resolvedPath = resolvePath(path)
        return directories.contains(resolvedPath)
    }

    func fileAttributes(at path: String) -> FileAttributes? {
        let resolvedPath = resolvePath(path)
        guard let content = files[resolvedPath] else {
            return nil
        }
        return FileAttributes(size: content.utf8.count)
    }

    private func resolvePath(_ path: String) -> String {
        if let absolutePath = try? canonicalizePath(path) {
            return absolutePath
        }
        return path
    }

    private func resolveSymlinkPath(_ path: String) -> String? {
        let sortedSymlinks = symlinks.keys.sorted { $0.count > $1.count }
        for symlinkPath in sortedSymlinks {
            if path == symlinkPath {
                return symlinks[symlinkPath]
            }
            let prefix = symlinkPath.hasSuffix("/") ? symlinkPath : symlinkPath + "/"
            if path.hasPrefix(prefix), let target = symlinks[symlinkPath] {
                let remainder = String(path.dropFirst(prefix.count))
                return target.hasSuffix("/") ? target + remainder : target + "/" + remainder
            }
        }
        return nil
    }

    private func parentDirectory(of path: String) -> String {
        if let index = path.lastIndex(of: "/"), index != path.startIndex {
            return String(path[..<index])
        }
        return "/"
    }
}

private struct MockFileSystemError: CompilerError {
    let category: ErrorCategory = .io
    let message: String
    let location: SourceLocation? = nil
}
#endif

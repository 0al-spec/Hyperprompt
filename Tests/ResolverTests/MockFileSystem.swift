import Foundation
import Core

/// In-memory file system for testing ReferenceResolver.
///
/// Provides a simple, deterministic file system implementation
/// for unit tests without touching the real file system.
class MockFileSystem: FileSystem {
    /// In-memory file storage: path → content
    private var files: [String: String] = [:]

    /// Simulated current directory
    private var _currentDirectory: String = "/mock"

    // MARK: - Test Setup Methods

    /// Add a file to the mock file system.
    ///
    /// - Parameters:
    ///   - path: File path (use absolute paths)
    ///   - content: File content as string
    func addFile(at path: String, content: String) {
        files[path] = content
    }

    /// Remove a file from the mock file system.
    func removeFile(at path: String) {
        files.removeValue(forKey: path)
    }

    /// Clear all files from the mock file system.
    func clear() {
        files.removeAll()
    }

    /// Set the simulated current directory.
    func setCurrentDirectory(_ directory: String) {
        _currentDirectory = directory
    }

    // MARK: - FileSystem Protocol

    func readFile(at path: String) throws -> String {
        guard let content = files[path] else {
            throw MockIOError(message: "File not found: \(path)")
        }
        return content
    }

    func fileExists(at path: String) -> Bool {
        files.keys.contains(path)
    }

    func canonicalizePath(_ path: String) throws -> String {
        if path.hasPrefix("/") {
            return path
        }
        return "\(_currentDirectory)/\(path)"
    }

    func currentDirectory() -> String {
        _currentDirectory
    }

    func writeFile(at path: String, content: String) throws {
        files[path] = content
    }
}

/// Simple IO error for mock file system.
private struct MockIOError: CompilerError {
    let category: ErrorCategory = .io
    let message: String
    let location: SourceLocation? = nil
}

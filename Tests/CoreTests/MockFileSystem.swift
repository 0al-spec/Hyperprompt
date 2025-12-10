import Foundation
@testable import Core

/// In-memory file system for testing.
///
/// MockFileSystem provides a simple, deterministic file system implementation
/// that stores files in memory. This enables fast, isolated unit tests without
/// touching the real file system.
///
/// Features:
/// - Add/remove files programmatically
/// - Simulate file not found errors
/// - Simulate permission errors (via error simulation)
/// - No disk I/O
/// - Deterministic behavior
///
/// Example usage:
/// ```swift
/// let fs = MockFileSystem()
/// fs.addFile(at: "/test/file.hc", content: "\"Root\"\n")
/// let content = try fs.readFile(at: "/test/file.hc")
/// ```
class MockFileSystem: FileSystem {
    /// In-memory file storage: path → content
    private var files: [String: String] = [:]

    /// Simulated current directory
    private var _currentDirectory: String = "/mock"

    /// Simulated errors: path → error to throw
    private var simulatedErrors: [String: CompilerError] = [:]

    // MARK: - Test Setup Methods

    /// Add a file to the mock file system.
    ///
    /// - Parameters:
    ///   - path: File path (use absolute paths for clarity)
    ///   - content: File content as string
    func addFile(at path: String, content: String) {
        files[path] = content
    }

    /// Remove a file from the mock file system.
    ///
    /// - Parameter path: File path to remove
    func removeFile(at path: String) {
        files.removeValue(forKey: path)
    }

    /// Clear all files from the mock file system.
    func clear() {
        files.removeAll()
        simulatedErrors.removeAll()
    }

    /// Simulate an error for a specific file path.
    ///
    /// When `readFile(at:)` is called for this path, the error will be thrown
    /// instead of returning content.
    ///
    /// - Parameters:
    ///   - path: File path that should trigger the error
    ///   - error: CompilerError to throw
    func simulateError(for path: String, error: CompilerError) {
        simulatedErrors[path] = error
    }

    /// Set the simulated current directory.
    ///
    /// - Parameter directory: Absolute path to use as current directory
    func setCurrentDirectory(_ directory: String) {
        _currentDirectory = directory
    }

    // MARK: - FileSystem Protocol Implementation

    /// Read file content from in-memory storage.
    ///
    /// - Parameter path: File path
    /// - Returns: File content if file exists
    /// - Throws: CompilerError with category `.io` if file not found or error simulated
    func readFile(at path: String) throws -> String {
        // Check for simulated error first
        if let error = simulatedErrors[path] {
            throw error
        }

        // Check if file exists
        guard let content = files[path] else {
            throw MockFileSystemError(
                category: .io,
                message: "File not found: \(path)",
                location: nil
            )
        }

        return content
    }

    /// Check if file exists in in-memory storage.
    ///
    /// - Parameter path: File path
    /// - Returns: `true` if file exists, `false` otherwise
    func fileExists(at path: String) -> Bool {
        files.keys.contains(path)
    }

    /// Convert relative path to absolute canonical path.
    ///
    /// Simple mock implementation: prepends current directory if path is relative.
    ///
    /// - Parameter path: File path (may be relative)
    /// - Returns: Absolute path
    func canonicalizePath(_ path: String) throws -> String {
        // If already absolute, return as-is
        if path.hasPrefix("/") {
            return path
        }

        // Prepend current directory
        return "\(_currentDirectory)/\(path)"
    }

    /// Get simulated current working directory.
    ///
    /// - Returns: Simulated current directory (default: "/mock")
    func currentDirectory() -> String {
        _currentDirectory
    }

    /// Write file content to in-memory storage.
    ///
    /// - Parameters:
    ///   - path: File path
    ///   - content: Content to write
    func writeFile(at path: String, content: String) throws {
        files[path] = content
    }
}

/// Concrete CompilerError implementation for MockFileSystem errors.
private struct MockFileSystemError: CompilerError {
    let category: ErrorCategory
    let message: String
    let location: SourceLocation?
}

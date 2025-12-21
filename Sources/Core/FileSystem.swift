import Foundation

/// Abstract interface for file system operations.
///
/// This protocol abstracts file I/O to enable:
/// - **Testability**: Mock implementations for unit tests (no disk I/O)
/// - **Cross-platform support**: Platform-specific implementations
/// - **Dependency injection**: Easy to swap implementations
///
/// All file system errors thrown must conform to `CompilerError` with
/// category `.io` for consistency in error handling.
public protocol FileSystem {
    /// Read entire file content as UTF-8 string.
    ///
    /// - Parameter path: File path (absolute or relative to current directory)
    /// - Returns: File content as String with LF line endings
    /// - Throws: CompilerError with category `.io` if file cannot be read
    ///
    /// Error conditions:
    /// - File does not exist
    /// - Permission denied
    /// - File is not valid UTF-8
    /// - I/O error during reading
    func readFile(at path: String) throws -> String

    /// Check if file exists at given path.
    ///
    /// - Parameter path: File path (absolute or relative to current directory)
    /// - Returns: `true` if file exists and is readable, `false` otherwise
    ///
    /// Note: Does not throw errors. Returns `false` for permission errors.
    func fileExists(at path: String) -> Bool

    /// Convert relative path to absolute canonical path.
    ///
    /// Resolves:
    /// - Relative paths (e.g., `./file.hc` → `/absolute/path/file.hc`)
    /// - Symlinks (follows links to real file location)
    /// - `.` and `..` components
    ///
    /// - Parameter path: File path (may be relative, may contain symlinks)
    /// - Returns: Absolute canonical path with resolved symlinks
    /// - Throws: CompilerError with category `.io` if path is invalid
    ///
    /// Error conditions:
    /// - Path contains invalid characters
    /// - Symlink points outside allowed root (security)
    func canonicalizePath(_ path: String) throws -> String

    /// Get current working directory.
    ///
    /// - Returns: Absolute path to current directory (always ends without trailing slash)
    func currentDirectory() -> String

    /// Write string content to file.
    ///
    /// - Parameters:
    ///   - path: File path (absolute or relative to current directory)
    ///   - content: String content to write (will be encoded as UTF-8)
    /// - Throws: CompilerError with category `.io` if file cannot be written
    ///
    /// Error conditions:
    /// - Directory does not exist
    /// - Permission denied
    /// - Disk full
    /// - I/O error during writing
    func writeFile(at path: String, content: String) throws

    /// List contents of a directory.
    ///
    /// - Parameter path: Directory path (absolute or relative to current directory)
    /// - Returns: Array of file/directory names (not full paths, just basenames)
    /// - Throws: CompilerError with category `.io` if directory cannot be read
    ///
    /// Error conditions:
    /// - Directory does not exist
    /// - Permission denied
    /// - Path is not a directory
    func listDirectory(at path: String) throws -> [String]

    /// Check if path is a directory.
    ///
    /// - Parameter path: Path to check (absolute or relative to current directory)
    /// - Returns: `true` if path exists and is a directory, `false` otherwise
    ///
    /// Note: Returns `false` for permission errors or non-existent paths.
    func isDirectory(at path: String) -> Bool

    /// Get file attributes (size, modification date).
    ///
    /// - Parameter path: File path (absolute or relative to current directory)
    /// - Returns: File attributes if file exists and is readable, `nil` otherwise
    ///
    /// Note: Returns `nil` for permission errors or non-existent files.
    func fileAttributes(at path: String) -> FileAttributes?
}

/// File attributes for indexing and caching
public struct FileAttributes: Equatable {
    /// File size in bytes
    public let size: Int

    /// Last modification date
    public let modificationDate: Date?

    /// Creates file attributes
    /// - Parameters:
    ///   - size: File size in bytes
    ///   - modificationDate: Optional modification date
    public init(size: Int, modificationDate: Date? = nil) {
        self.size = size
        self.modificationDate = modificationDate
    }
}

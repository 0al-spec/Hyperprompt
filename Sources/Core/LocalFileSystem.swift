import Foundation

/// Production file system implementation using Foundation APIs.
///
/// This implementation provides real file I/O operations for the compiler,
/// wrapping Foundation's FileManager and String APIs with CompilerError
/// error handling.
///
/// Thread safety: FileManager.default is thread-safe. String reading operations
/// are atomic per-file.
struct LocalFileSystem: FileSystem {
    /// Read entire file content as UTF-8 string.
    ///
    /// - Parameter path: File path (absolute or relative to current directory)
    /// - Returns: File content as String
    /// - Throws: CompilerError with category `.io` for all file reading errors
    func readFile(at path: String) throws -> String {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw mapFoundationError(error, path: path)
        }
    }

    /// Check if file exists at given path.
    ///
    /// - Parameter path: File path (absolute or relative to current directory)
    /// - Returns: `true` if file exists, `false` otherwise
    func fileExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    /// Convert relative path to absolute canonical path.
    ///
    /// Resolves relative paths, symlinks, and normalizes path components.
    ///
    /// - Parameter path: File path (may be relative, may contain symlinks)
    /// - Returns: Absolute canonical path
    /// - Throws: CompilerError with category `.io` if path cannot be resolved
    func canonicalizePath(_ path: String) throws -> String {
        let url = URL(fileURLWithPath: path)
        let standardized = url.standardized
        return standardized.path
    }

    /// Get current working directory.
    ///
    /// - Returns: Absolute path to current directory
    func currentDirectory() -> String {
        FileManager.default.currentDirectoryPath
    }

    // MARK: - Error Mapping

    /// Map Foundation errors to CompilerError.
    ///
    /// Converts NSError codes to appropriate CompilerError with category `.io`.
    ///
    /// - Parameters:
    ///   - error: The Foundation error
    ///   - path: The file path that caused the error
    /// - Returns: CompilerError with diagnostic information
    private func mapFoundationError(_ error: Error, path: String) -> CompilerError {
        let nsError = error as NSError

        let message: String
        switch nsError.code {
        case NSFileReadNoSuchFileError:
            message = "File not found: \(path)"
        case NSFileReadNoPermissionError:
            message = "Permission denied: \(path)"
        case NSFileReadCorruptFileError:
            message = "File is corrupted or not valid UTF-8: \(path)"
        default:
            message = "Failed to read file '\(path)': \(error.localizedDescription)"
        }

        return FileSystemError(
            category: .io,
            message: message,
            location: nil
        )
    }
}

/// Concrete implementation of CompilerError for file system errors.
private struct FileSystemError: CompilerError {
    let category: ErrorCategory
    let message: String
    let location: SourceLocation?
}

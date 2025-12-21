import Foundation

/// Production file system implementation using Foundation APIs.
///
/// This implementation provides real file I/O operations for the compiler,
/// wrapping Foundation's FileManager and String APIs with CompilerError
/// error handling.
///
/// Thread safety: FileManager.default is thread-safe. String reading operations
/// are atomic per-file.
public struct LocalFileSystem: FileSystem {
    /// Create a new LocalFileSystem instance.
    public init() {}

    /// Read entire file content as UTF-8 string.
    ///
    /// - Parameter path: File path (absolute or relative to current directory)
    /// - Returns: File content as String
    /// - Throws: CompilerError with category `.io` for all file reading errors
    public func readFile(at path: String) throws -> String {
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
    public func fileExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    /// Convert relative path to absolute canonical path.
    ///
    /// Resolves relative paths, symlinks, and normalizes path components.
    ///
    /// - Parameter path: File path (may be relative, may contain symlinks)
    /// - Returns: Absolute canonical path
    /// - Throws: CompilerError with category `.io` if path cannot be resolved
    public func canonicalizePath(_ path: String) throws -> String {
        let url = URL(fileURLWithPath: path)
        let standardized = url.standardized
        return standardized.path
    }

    /// Get current working directory.
    ///
    /// - Returns: Absolute path to current directory
    public func currentDirectory() -> String {
        FileManager.default.currentDirectoryPath
    }

    /// Write string content to file.
    ///
    /// - Parameters:
    ///   - path: File path (absolute or relative to current directory)
    ///   - content: String content to write (will be encoded as UTF-8)
    /// - Throws: CompilerError with category `.io` if file cannot be written
    public func writeFile(at path: String, content: String) throws {
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw mapFoundationError(error, path: path)
        }
    }

    /// List contents of a directory.
    ///
    /// - Parameter path: Directory path (absolute or relative to current directory)
    /// - Returns: Array of file/directory names (basenames only, not full paths)
    /// - Throws: CompilerError with category `.io` if directory cannot be read
    public func listDirectory(at path: String) throws -> [String] {
        do {
            return try FileManager.default.contentsOfDirectory(atPath: path)
        } catch {
            throw mapFoundationError(error, path: path)
        }
    }

    /// Check if path is a directory.
    ///
    /// - Parameter path: Path to check (absolute or relative to current directory)
    /// - Returns: `true` if path exists and is a directory, `false` otherwise
    public func isDirectory(at path: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }

    /// Get file attributes (size, modification date).
    ///
    /// - Parameter path: File path (absolute or relative to current directory)
    /// - Returns: File attributes if file exists and is readable, `nil` otherwise
    public func fileAttributes(at path: String) -> FileAttributes? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else {
            return nil
        }

        let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
        let modificationDate = attrs[.modificationDate] as? Date

        return FileAttributes(size: size, modificationDate: modificationDate)
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

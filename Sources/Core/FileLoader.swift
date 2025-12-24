import Foundation
import Crypto

/// Production-grade file loader with caching and hash computation.
///
/// FileLoader handles all file I/O for the Hyperprompt compiler:
/// - Reads file content with UTF-8 encoding
/// - Normalizes line endings (CRLF/CR → LF)
/// - Caches loaded content to avoid redundant disk reads
/// - Computes SHA256 hashes for content verification
/// - Collects file metadata for manifest generation
///
/// Usage:
/// ```swift
/// let fileSystem = LocalFileSystem()
/// let loader = FileLoader(fileSystem: fileSystem)
///
/// // Load a file (caches result)
/// let result = try loader.load(path: "docs/intro.md")
///
/// print("Content: \(result.content)")
/// print("Hash: \(result.hash)")
/// print("Metadata: \(result.metadata)")
/// ```
///
/// **Caching:** Once a file is loaded, subsequent calls to `load(path:)`
/// return cached results without disk I/O.
///
/// **Thread Safety:** Not thread-safe. Use from single thread only.
public class FileLoader {
    /// File system abstraction for I/O operations.
    private let fileSystem: FileSystem

    /// In-memory cache: path → (content, hash, metadata)
    ///
    /// Cache key is the file path as provided (not canonicalized).
    /// Lifetime: duration of compilation session.
    private var cache: [String: LoadResult] = [:]

    /// Result of loading a file.
    ///
    /// Contains normalized content, hash, and metadata.
    public struct LoadResult {
        /// Normalized file content (LF line endings).
        public let content: String

        /// SHA256 hash of normalized content (64-char lowercase hex).
        public let hash: String

        /// Manifest entry with file metadata.
        public let metadata: ManifestEntry
    }

    /// Initialize a file loader.
    ///
    /// - Parameter fileSystem: File system implementation for I/O
    public init(fileSystem: FileSystem) {
        self.fileSystem = fileSystem
    }

    /// Load a file with caching and hash computation.
    ///
    /// - Parameter path: File path (absolute or relative to current directory)
    /// - Returns: LoadResult with content, hash, and metadata
    /// - Throws: CompilerError with category `.io` if file cannot be loaded
    ///
    /// **Caching:** If the file was previously loaded, returns cached result
    /// without disk I/O.
    ///
    /// **Normalization:** Line endings are normalized to LF before caching.
    ///
    /// **Hash:** SHA256 computed on normalized content.
    ///
    /// **Error handling:**
    /// - File not found → IO error
    /// - Permission denied → IO error
    /// - Invalid UTF-8 → IO error
    /// - Invalid extension → IO error
    public func load(path: String) throws -> LoadResult {
        // Check cache first
        if let cached = cache[path] {
            return cached
        }

        // Detect file type from extension
        let fileType = try detectFileType(path)

        // Read raw file content
        let rawContent = try fileSystem.readFile(at: path)

        // Get original size (before normalization)
        let originalSize = rawContent.utf8.count

        // Normalize line endings (CRLF/CR → LF)
        let normalizedContent = normalizeLineEndings(rawContent)

        // Compute SHA256 hash on normalized content
        let hash = computeHash(normalizedContent)

        // Create manifest entry
        let metadata = ManifestEntry(
            path: path,
            sha256: hash,
            size: originalSize,
            type: fileType
        )

        // Create result
        let result = LoadResult(
            content: normalizedContent,
            hash: hash,
            metadata: metadata
        )

        // Cache the result
        cache[path] = result

        return result
    }

    /// Normalize line endings to LF.
    ///
    /// Converts:
    /// - CRLF (\\r\\n) → LF (\\n)
    /// - CR (\\r) → LF (\\n)
    /// - LF (\\n) → unchanged
    ///
    /// - Parameter content: Raw file content
    /// - Returns: Normalized content with consistent LF line endings
    ///
    /// **Note:** FileSystem.readFile already performs this normalization,
    /// but we keep this method for explicitness and testability.
    public func normalizeLineEndings(_ content: String) -> String {
        // Replace CRLF with LF first (order matters!)
        let step1 = content.replacingOccurrences(of: "\r\n", with: "\n")
        // Replace any remaining standalone CR with LF
        let step2 = step1.replacingOccurrences(of: "\r", with: "\n")
        return step2
    }

    /// Compute SHA256 hash of content.
    ///
    /// - Parameter content: String content to hash
    /// - Returns: SHA256 hash as 64-character lowercase hexadecimal string
    ///
    /// Hash is computed on UTF-8 bytes of the content.
    /// Output matches `openssl sha256` (with normalized line endings).
    public func computeHash(_ content: String) -> String {
        ContentHasher.sha256Hex(content)
    }

    /// Detect file type from extension.
    ///
    /// - Parameter path: File path
    /// - Returns: FileType (.markdown or .hypercode)
    /// - Throws: CompilerError with category `.io` if extension is invalid
    ///
    /// Valid extensions:
    /// - `.md` → FileType.markdown
    /// - `.hc` → FileType.hypercode
    ///
    /// All other extensions are rejected with an error.
    public func detectFileType(_ path: String) throws -> FileType {
        let lowercasedPath = path.lowercased()

        if lowercasedPath.hasSuffix(".md") {
            return .markdown
        } else if lowercasedPath.hasSuffix(".hc") {
            return .hypercode
        } else {
            // Invalid extension
            throw FileLoaderError(
                message: "Invalid file extension. Only .md and .hc files are allowed: \(path)"
            )
        }
    }

    /// Clear the cache.
    ///
    /// Removes all cached file content. Useful for testing or when
    /// files may have changed during long-running compilation sessions.
    public func clearCache() {
        cache.removeAll()
    }

    /// Number of cached files.
    ///
    /// - Returns: Count of files in cache
    public var cacheCount: Int {
        return cache.count
    }
}

/// Error thrown by FileLoader for invalid operations.
struct FileLoaderError: CompilerError {
    let category: ErrorCategory = .io
    let message: String
    let location: SourceLocation? = nil
}

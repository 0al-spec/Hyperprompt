/// Metadata for a single source file in the compilation manifest.
///
/// The manifest tracks all files processed during compilation, including:
/// - Original source file paths (relative to root)
/// - Content hashes for change detection and verification
/// - File sizes for statistics
/// - File types for classification
///
/// This structure is JSON-serializable and used to generate the compilation
/// manifest (typically saved as `manifest.json`).
///
/// Example JSON output:
/// ```json
/// {
///   "path": "docs/introduction.md",
///   "sha256": "a1b2c3d4...",
///   "size": 1024,
///   "type": "markdown"
/// }
/// ```
public struct ManifestEntry: Codable {
    /// File path relative to compilation root.
    ///
    /// - Always uses forward slashes (/) as path separator
    /// - Normalized to relative path (no leading ./)
    /// - Example: `docs/introduction.md`
    public let path: String

    /// SHA256 hash of normalized file content.
    ///
    /// - Computed on normalized content (after CRLF/CR → LF conversion)
    /// - Lowercase hexadecimal string (64 characters)
    /// - Matches output of `openssl sha256` on normalized content
    /// - Example: `"a1b2c3d4e5f6789..."`
    public let sha256: String

    /// File size in bytes (original, pre-normalization).
    ///
    /// - Size of raw file content before line ending normalization
    /// - Used for statistics and capacity planning
    /// - Always >= 0 (empty files have size 0)
    public let size: Int

    /// File type classification.
    ///
    /// - `.markdown` for .md files (embedded content)
    /// - `.hypercode` for .hc files (compiled recursively)
    public let type: FileType

    /// Initialize a manifest entry.
    ///
    /// - Parameters:
    ///   - path: File path relative to root
    ///   - sha256: SHA256 hash (64-char lowercase hex)
    ///   - size: File size in bytes (>= 0)
    ///   - type: File type (markdown or hypercode)
    public init(path: String, sha256: String, size: Int, type: FileType) {
        self.path = path
        self.sha256 = sha256
        self.size = size
        self.type = type
    }
}

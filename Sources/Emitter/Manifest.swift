import Foundation
import Core

/// Top-level manifest structure for compilation provenance.
///
/// The Manifest represents the complete record of a compilation session,
/// including all source files processed, their metadata, and compilation
/// context. The manifest is serialized to JSON with deterministic key ordering.
///
/// Example JSON structure:
/// ```json
/// {
///   "root": "/path/to/root",
///   "sources": [
///     {
///       "path": "input.hc",
///       "sha256": "abc123...",
///       "size": 1024,
///       "type": "hypercode"
///     }
///   ],
///   "timestamp": "2025-12-09T14:30:45Z",
///   "version": "0.1.0"
/// }
/// ```
///
/// **Key Requirements:**
/// - All JSON keys alphabetically sorted (deterministic output)
/// - Timestamp in ISO 8601 format with UTC timezone
/// - Sources array sorted by path
/// - Valid JSON parseable by standard parsers
public struct Manifest: Codable {
    /// Compilation root directory path.
    ///
    /// - Absolute or relative path to the root directory
    /// - All source file paths are relative to this root
    /// - Example: `"/home/user/project"` or `"./docs"`
    public let root: String

    /// Array of source file metadata entries.
    ///
    /// - Sorted alphabetically by path for determinism
    /// - Contains all files processed during compilation
    /// - May be empty for zero-file compilations
    public let sources: [ManifestEntry]

    /// ISO 8601 timestamp of compilation.
    ///
    /// - Format: `YYYY-MM-DDTHH:MM:SSZ` (UTC timezone)
    /// - Example: `"2025-12-09T14:30:45Z"`
    /// - Precision: seconds (no fractional seconds)
    public let timestamp: String

    /// Compiler version string.
    ///
    /// - Semantic version format: `"MAJOR.MINOR.PATCH"`
    /// - Example: `"0.1.0"`
    /// - Matches package version from Package.swift
    public let version: String

    /// Initialize a manifest.
    ///
    /// - Parameters:
    ///   - root: Root directory path
    ///   - sources: Array of manifest entries (will be sorted by path)
    ///   - timestamp: ISO 8601 timestamp string
    ///   - version: Compiler version string
    public init(root: String, sources: [ManifestEntry], timestamp: String, version: String) {
        self.root = root
        self.sources = sources.sorted { $0.path < $1.path }  // Ensure deterministic order
        self.timestamp = timestamp
        self.version = version
    }
}

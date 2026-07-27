import Foundation
import Core

/// One direct include edge in a compilation.
///
/// Both paths are normalized relative to the compilation root. The edge is a
/// physical assembly dependency, not a semantic or normative dependency.
public struct ManifestDependency: Codable, Equatable, Hashable, Sendable {
    public let from: String
    public let to: String

    public init(from: String, to: String) {
        self.from = from
        self.to = to
    }
}

/// Top-level manifest structure for compilation provenance.
///
/// The Manifest represents the complete record of a compilation session,
/// including all source files processed, their metadata, and compilation
/// context. The manifest is serialized to JSON with deterministic key ordering.
///
/// Example JSON structure:
/// ```json
/// {
///   "dependencies": [
///     {
///       "from": "root.hc",
///       "to": "sections/introduction.md"
///     }
///   ],
///   "root": "root.hc",
///   "sources": [
///     {
///       "path": "root.hc",
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
    /// Sorted direct include edges discovered during this compilation.
    public let dependencies: [ManifestDependency]

    /// Root Hypercode source path.
    ///
    /// - Relative to the compilation `--root`
    /// - Uses forward slashes and has no leading `./`
    /// - Example: `"root.hc"` or `"drafts/specification.hc"`
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
    public init(
        root: String,
        sources: [ManifestEntry],
        dependencies: [ManifestDependency] = [],
        timestamp: String,
        version: String
    ) {
        self.dependencies = Array(Set(dependencies)).sorted {
            ($0.from, $0.to) < ($1.from, $1.to)
        }
        self.root = root
        self.sources = sources.sorted { $0.path < $1.path }  // Ensure deterministic order
        self.timestamp = timestamp
        self.version = version
    }

    private enum CodingKeys: String, CodingKey {
        case dependencies
        case root
        case sources
        case timestamp
        case version
    }

    /// Decode manifests created before dependency edges were introduced.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            root: try container.decode(String.self, forKey: .root),
            sources: try container.decode([ManifestEntry].self, forKey: .sources),
            dependencies: try container.decodeIfPresent(
                [ManifestDependency].self,
                forKey: .dependencies
            ) ?? [],
            timestamp: try container.decode(String.self, forKey: .timestamp),
            version: try container.decode(String.self, forKey: .version)
        )
    }
}

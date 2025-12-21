/// ProjectIndex — Data Model for Workspace Indexing
///
/// Represents the result of scanning a workspace for Hypercode and Markdown files.
/// Provides deterministic, lexicographically sorted file listings with metadata.
///
/// ## Usage
///
/// ```swift
/// let indexer = ProjectIndexer(fileSystem: LocalFileSystem())
/// let index = try indexer.index(workspaceRoot: "/path/to/workspace")
///
/// print("Discovered \(index.totalFiles) files:")
/// for file in index.files {
///     print("  - \(file.path) (\(file.type), \(file.size) bytes)")
/// }
/// ```

import Foundation

// MARK: - FileType

/// Represents the type of a source file in a Hyperprompt project
public enum FileType: String, Codable, Equatable {
    /// Hypercode source file (.hc)
    case hypercode = "hypercode"

    /// Markdown documentation file (.md)
    case markdown = "markdown"

    /// Determines file type from file extension
    /// - Parameter path: File path with extension
    /// - Returns: FileType if extension is .hc or .md, nil otherwise
    public static func from(path: String) -> FileType? {
        if path.hasSuffix(".hc") {
            return .hypercode
        } else if path.hasSuffix(".md") {
            return .markdown
        }
        return nil
    }
}

// MARK: - FileIndexEntry

/// Represents a single file in the project index with metadata
public struct FileIndexEntry: Codable, Equatable {
    /// Path relative to workspace root (e.g., "src/main.hc")
    public let path: String

    /// Type of file (hypercode or markdown)
    public let type: FileType

    /// File size in bytes
    public let size: Int

    /// Last modification date (optional, for future caching support)
    public let lastModified: Date?

    /// Creates a new file index entry
    /// - Parameters:
    ///   - path: Relative path from workspace root
    ///   - type: File type (hypercode or markdown)
    ///   - size: File size in bytes
    ///   - lastModified: Optional modification timestamp
    public init(path: String, type: FileType, size: Int, lastModified: Date? = nil) {
        self.path = path
        self.type = type
        self.size = size
        self.lastModified = lastModified
    }
}

// MARK: - ProjectIndex

/// Represents the complete index of a workspace with all discovered files
public struct ProjectIndex: Codable, Equatable {
    /// Absolute path to workspace root directory
    public let workspaceRoot: String

    /// All discovered files, sorted lexicographically by path
    public let files: [FileIndexEntry]

    /// Timestamp when index was created
    public let discoveredAt: Date

    /// Total number of files in index (computed property)
    public var totalFiles: Int {
        files.count
    }

    /// Number of Hypercode files (.hc)
    public var hypercodeFileCount: Int {
        files.filter { $0.type == .hypercode }.count
    }

    /// Number of Markdown files (.md)
    public var markdownFileCount: Int {
        files.filter { $0.type == .markdown }.count
    }

    /// Total size of all indexed files in bytes
    public var totalSize: Int {
        files.reduce(0) { $0 + $1.size }
    }

    /// Creates a new project index
    /// - Parameters:
    ///   - workspaceRoot: Absolute path to workspace root
    ///   - files: List of file entries (will be sorted by path)
    ///   - discoveredAt: Timestamp of index creation (defaults to current time)
    public init(workspaceRoot: String, files: [FileIndexEntry], discoveredAt: Date = Date()) {
        self.workspaceRoot = workspaceRoot
        // Ensure deterministic ordering: sort by path
        self.files = files.sorted { $0.path < $1.path }
        self.discoveredAt = discoveredAt
    }

    /// Creates an empty index for a workspace
    /// - Parameter workspaceRoot: Absolute path to workspace root
    /// - Returns: Empty project index
    public static func empty(workspaceRoot: String) -> ProjectIndex {
        ProjectIndex(workspaceRoot: workspaceRoot, files: [])
    }

    /// Finds a file entry by path
    /// - Parameter path: Relative path to search for
    /// - Returns: File entry if found, nil otherwise
    public func file(at path: String) -> FileIndexEntry? {
        files.first { $0.path == path }
    }
}

// MARK: - CustomStringConvertible

extension ProjectIndex: CustomStringConvertible {
    public var description: String {
        """
        ProjectIndex(workspaceRoot: "\(workspaceRoot)", \
        totalFiles: \(totalFiles), \
        hypercode: \(hypercodeFileCount), \
        markdown: \(markdownFileCount), \
        totalSize: \(totalSize) bytes)
        """
    }
}

extension FileIndexEntry: CustomStringConvertible {
    public var description: String {
        "\(path) (\(type.rawValue), \(size) bytes)"
    }
}

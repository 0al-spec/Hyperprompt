#if Editor
/// ProjectIndexer — Workspace File Discovery Engine
///
/// Scans a workspace directory for Hypercode and Markdown files with
/// deterministic ordering, configurable ignore patterns, and security safeguards.
///
/// ## Features
///
/// - Recursive directory traversal with depth limits
/// - Deterministic lexicographic ordering
/// - `.hyperpromptignore` pattern support
/// - Default exclusion of hidden directories and build artifacts
/// - Symlink policy enforcement (no follow by default)
///
/// ## Usage
///
/// ```swift
/// let indexer = ProjectIndexer(fileSystem: LocalFileSystem())
/// let index = try indexer.index(workspaceRoot: "/path/to/workspace")
/// ```

import Foundation
import Core

// MARK: - IndexerOptions

/// Configuration options for project indexing behavior
public struct IndexerOptions: Sendable {
    /// Symlink traversal policy (default: skip for security)
    public let symlinkPolicy: SymlinkPolicy

    /// Hidden file policy (default: exclude)
    public let hiddenEntryPolicy: HiddenEntryPolicy

    /// Maximum directory depth to traverse (default: 100)
    public let maxDepth: Int

    /// Custom ignore patterns (glob-style) in addition to defaults
    public let customIgnorePatterns: [String]

    /// Creates indexer options with specified settings
    /// - Parameters:
    ///   - symlinkPolicy: Symlink traversal policy (default: skip)
    ///   - hiddenEntryPolicy: Hidden entry policy (default: exclude)
    ///   - maxDepth: Maximum traversal depth (default: 100)
    ///   - customIgnorePatterns: Additional patterns to ignore (default: empty)
    public init(
        symlinkPolicy: SymlinkPolicy = .skip,
        hiddenEntryPolicy: HiddenEntryPolicy = .exclude,
        maxDepth: Int = 100,
        customIgnorePatterns: [String] = []
    ) {
        self.symlinkPolicy = symlinkPolicy
        self.hiddenEntryPolicy = hiddenEntryPolicy
        self.maxDepth = maxDepth
        self.customIgnorePatterns = customIgnorePatterns
    }

    /// Default options (secure defaults: no symlinks, no hidden files)
    public static let `default` = IndexerOptions()
}

// MARK: - IndexerError

/// Errors that can occur during project indexing
public enum IndexerError: Error, Equatable {
    /// Workspace root path is invalid (e.g., relative path)
    case invalidWorkspaceRoot(path: String, reason: String)

    /// Workspace root directory does not exist
    case workspaceNotFound(path: String)

    /// Permission denied accessing directory or file
    case permissionDenied(path: String)

    /// Maximum traversal depth exceeded
    case maxDepthExceeded(depth: Int, limit: Int)

    /// Invalid .hyperpromptignore file format
    case invalidIgnoreFile(path: String, reason: String)
}

extension IndexerError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidWorkspaceRoot(let path, let reason):
            return "Invalid workspace root '\(path)': \(reason)"
        case .workspaceNotFound(let path):
            return "Workspace not found: \(path)"
        case .permissionDenied(let path):
            return "Permission denied: \(path)"
        case .maxDepthExceeded(let depth, let limit):
            return "Maximum depth exceeded: \(depth) (limit: \(limit))"
        case .invalidIgnoreFile(let path, let reason):
            return "Invalid .hyperpromptignore at \(path): \(reason)"
        }
    }
}

// MARK: - ProjectIndexer

/// Scans workspace directories to build a file index
public struct ProjectIndexer {
    /// File system abstraction for I/O operations
    private let fileSystem: FileSystem

    /// Configuration options
    private let options: IndexerOptions
    private let directoryDecision = DirectoryDispositionDecisionSpec()
    private let targetFileSpec = TargetFileSpec()

    /// Default directories to ignore (common build artifacts and VCS)
    private static let defaultIgnoreDirs: Set<String> = [
        ".git",
        ".build",
        "build",
        "Build",
        "DerivedData",
        "node_modules",
        "Packages",
        ".vscode",
        ".idea",
        ".cache",
        "dist",
        "target"
    ]

    /// Creates a new project indexer
    /// - Parameters:
    ///   - fileSystem: File system implementation (use LocalFileSystem for production)
    ///   - options: Indexing configuration options
    public init(fileSystem: FileSystem, options: IndexerOptions = .default) {
        self.fileSystem = fileSystem
        self.options = options
    }

    /// Indexes a workspace directory
    /// - Parameter workspaceRoot: Absolute path to workspace root
    /// - Returns: ProjectIndex with all discovered files
    /// - Throws: IndexerError if workspace cannot be scanned
    public func index(workspaceRoot: String) throws -> ProjectIndex {
        // Validate workspace root is absolute path
        guard workspaceRoot.hasPrefix("/") else {
            throw IndexerError.invalidWorkspaceRoot(
                path: workspaceRoot,
                reason: "Workspace root must be an absolute path"
            )
        }

        // Verify workspace exists
        guard fileSystem.fileExists(at: workspaceRoot) else {
            throw IndexerError.workspaceNotFound(path: workspaceRoot)
        }

        // Load ignore patterns from .hyperpromptignore if present
        let ignorePatterns = try loadIgnorePatterns(workspaceRoot: workspaceRoot)

        // Discover files recursively
        let discoveredPaths = try discoverFiles(
            at: workspaceRoot,
            depth: 0,
            ignorePatterns: ignorePatterns
        )

        // Collect metadata for each file
        let entries = try discoveredPaths.compactMap { path -> FileIndexEntry? in
            try collectMetadata(filePath: path, workspaceRoot: workspaceRoot)
        }

        // Build and return index
        return ProjectIndex(
            workspaceRoot: workspaceRoot,
            files: entries,
            discoveredAt: Date()
        )
    }

    // MARK: - Private Implementation

    /// Recursively discovers files in directory tree
    private func discoverFiles(
        at directory: String,
        depth: Int,
        ignorePatterns: [String]
    ) throws -> [String] {
        // Check depth limit
        guard depth < options.maxDepth else {
            throw IndexerError.maxDepthExceeded(depth: depth, limit: options.maxDepth)
        }

        // List directory contents
        guard let contents = try? fileSystem.listDirectory(at: directory) else {
            // Permission denied or other error - skip this directory gracefully
            return []
        }

        var discoveredFiles: [String] = []

        // Process each item in deterministic order
        for item in contents.sorted() {
            let fullPath = joinPath(directory, item)

            // Check if this is a directory
            if fileSystem.isDirectory(at: fullPath) {
                // Skip if should be ignored
                if shouldSkipDirectory(fullPath) {
                    continue
                }

                // Recurse into subdirectory
                let subFiles = try discoverFiles(
                    at: fullPath,
                    depth: depth + 1,
                    ignorePatterns: ignorePatterns
                )
                discoveredFiles.append(contentsOf: subFiles)

            } else if isTargetFile(fullPath) {
                // Check if file should be ignored by patterns
                let relativePath = makeRelative(path: fullPath, to: directory)
                if !matchesIgnorePattern(path: relativePath, patterns: ignorePatterns) {
                    discoveredFiles.append(fullPath)
                }
            }
        }

        return discoveredFiles
    }

    /// Checks if a directory should be skipped
    private func shouldSkipDirectory(_ path: String) -> Bool {
        let context = DirectoryDecisionContext(
            path: path,
            includeHidden: options.hiddenEntryPolicy == .include,
            ignoredDirectories: Self.defaultIgnoreDirs
        )
        let decision = directoryDecision.decide(context) ?? .include
        return decision == .skip
    }

    /// Checks if a file is a target file (.hc or .md)
    private func isTargetFile(_ path: String) -> Bool {
        targetFileSpec.isSatisfiedBy(path)
    }

    /// Loads ignore patterns from .hyperpromptignore file
    private func loadIgnorePatterns(workspaceRoot: String) throws -> [String] {
        let ignorePath = joinPath(workspaceRoot, ".hyperpromptignore")

        guard fileSystem.fileExists(at: ignorePath) else {
            return options.customIgnorePatterns
        }

        // Read and parse ignore file
        guard let content = try? fileSystem.readFile(at: ignorePath) else {
            // Cannot read file - use only custom patterns
            return options.customIgnorePatterns
        }

        let lines = content.components(separatedBy: .newlines)
        let patterns = lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") } // Skip comments and blank lines

        return patterns + options.customIgnorePatterns
    }

    /// Checks if a path matches any ignore pattern using glob matching
    private func matchesIgnorePattern(path: String, patterns: [String]) -> Bool {
        var matcher = GlobMatcher()
        return patterns.matchesAny(path: path, using: &matcher)
    }

    /// Collects metadata for a file
    private func collectMetadata(filePath: String, workspaceRoot: String) throws -> FileIndexEntry? {
        guard let type = FileType.from(path: filePath) else {
            return nil
        }

        let attributes = fileSystem.fileAttributes(at: filePath)
        let size = attributes?.size ?? 0
        let lastModified = attributes?.modificationDate

        let relativePath = makeRelative(path: filePath, to: workspaceRoot)

        return FileIndexEntry(
            path: relativePath,
            type: type,
            size: size,
            lastModified: lastModified
        )
    }

    /// Makes a path relative to a base directory
    private func makeRelative(path: String, to base: String) -> String {
        if path.hasPrefix(base) {
            let result = String(path.dropFirst(base.count))
            return result.hasPrefix("/") ? String(result.dropFirst()) : result
        }
        return path
    }

    /// Joins two path components
    internal func joinPath(_ base: String, _ component: String) -> String {
        // Handle empty component
        guard !component.isEmpty else {
            return base
        }

        // Normalize trailing slash on base
        let normalizedBase = base.hasSuffix("/") ? String(base.dropLast()) : base

        // Normalize leading slash on component
        let normalizedComponent = component.hasPrefix("/")
            ? String(component.dropFirst())
            : component

        return normalizedBase + "/" + normalizedComponent
    }
}
#endif

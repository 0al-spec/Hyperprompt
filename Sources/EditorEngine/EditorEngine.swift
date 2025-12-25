#if Editor
/// EditorEngine Module Entry Point
///
/// This module provides IDE/editor-oriented capabilities on top of the
/// deterministic Hyperprompt compiler, enabling rich editor experiences
/// without compromising the compiler's CLI-first design.
///
/// ## Features
///
/// - **Project Indexing**: Scan and index .hc and .md files
/// - **Parsing with Link Spans**: Extract link ranges for editor navigation
/// - **Link Resolution**: Resolve file references identically to CLI
/// - **Editor Compilation**: Compile projects programmatically with diagnostics
///
/// ## Usage
///
/// ```swift
/// import EditorEngine
///
/// // Index a workspace
/// let index = try ProjectIndexer.index(workspaceRoot: workspaceURL)
///
/// // Parse a file
/// let parsed = EditorParser.parse(filePath: "main.hc")
///
/// // Compile with diagnostics
/// let result = EditorCompiler.compile(entryFile: "main.hc", options: options)
/// ```
///
/// ## Status
///
/// **Experimental** - API stability not guaranteed until Hyperprompt v1.0

import Foundation
import Core
import Parser
import Resolver
import Emitter
import Statistics

/// EditorEngine namespace for public API
public enum EditorEngine {
    /// Current version of EditorEngine API
    public static let version = "0.2.0-experimental"

    /// Indicates whether EditorEngine is available in this build
    public static let isAvailable = true

    // MARK: - Project Indexing

    /// Indexes a workspace directory to discover all Hypercode and Markdown files
    ///
    /// - Parameters:
    ///   - workspaceRoot: Absolute path to workspace root directory
    ///   - options: Optional indexing configuration (defaults to secure settings)
    /// - Returns: Project index with all discovered files
    /// - Throws: IndexerError if workspace cannot be scanned
    ///
    /// ## Example
    ///
    /// ```swift
    /// let index = try EditorEngine.indexProject(workspaceRoot: "/path/to/workspace")
    /// print("Found \(index.totalFiles) files:")
    /// for file in index.files {
    ///     print("  - \(file.path) (\(file.type))")
    /// }
    /// ```
    public static func indexProject(
        workspaceRoot: String,
        options: IndexerOptions = .default
    ) throws -> ProjectIndex {
        let fileSystem = LocalFileSystem()
        let indexer = ProjectIndexer(fileSystem: fileSystem, options: options)
        return try indexer.index(workspaceRoot: workspaceRoot)
    }

    /// Indexes a workspace with custom file system (for testing)
    ///
    /// - Parameters:
    ///   - workspaceRoot: Absolute path to workspace root directory
    ///   - fileSystem: File system implementation (use for testing with MockFileSystem)
    ///   - options: Optional indexing configuration
    /// - Returns: Project index with all discovered files
    /// - Throws: IndexerError if workspace cannot be scanned
    public static func indexProject(
        workspaceRoot: String,
        fileSystem: FileSystem,
        options: IndexerOptions = .default
    ) throws -> ProjectIndex {
        let indexer = ProjectIndexer(fileSystem: fileSystem, options: options)
        return try indexer.index(workspaceRoot: workspaceRoot)
    }
}
#endif

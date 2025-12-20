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
/// let parsed = try EditorParser.parse(filePath: "main.hc")
///
/// // Compile with diagnostics
/// let result = try EditorCompiler.compile(entryFile: "main.hc", options: options)
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
}

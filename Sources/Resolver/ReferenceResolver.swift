import Core
import Parser

/// Reference resolver for classifying node literals.
///
/// Determines the semantic classification of each node literal:
/// - **Inline text:** Raw content to be used as-is in output
/// - **Markdown file (.md):** File path resolving to a Markdown file
/// - **Hypercode file (.hc):** File path resolving to a Hypercode file (recursive compilation)
/// - **Forbidden extension:** Any other extension → hard error (exit code 3)
///
/// The resolver validates all references against the root directory, enforces
/// strict/lenient modes for missing files, and provides hooks for dependent modules.
///
/// Example usage:
/// ```swift
/// let resolver = ReferenceResolver(
///     fileSystem: LocalFileSystem(),
///     rootPath: "/project",
///     mode: .strict
/// )
/// let result = resolver.resolve(node: someNode)
/// ```
public struct ReferenceResolver {
    /// File system abstraction for file operations.
    private let fileSystem: FileSystem

    /// Root directory for resolving relative file paths.
    /// All file references are resolved relative to this path.
    public let rootPath: String

    /// Resolution mode (strict or lenient).
    public let mode: ResolutionMode

    /// Set of file paths visited during resolution (for circular dependency tracking).
    /// Integration hook for B2: DependencyTracker.
    public private(set) var visitedPaths: Set<String> = []

    /// Initialize a new reference resolver.
    ///
    /// - Parameters:
    ///   - fileSystem: File system abstraction for file operations
    ///   - rootPath: Root directory for resolving relative file paths
    ///   - mode: Resolution mode (strict or lenient)
    public init(fileSystem: FileSystem, rootPath: String, mode: ResolutionMode) {
        self.fileSystem = fileSystem
        self.rootPath = rootPath
        self.mode = mode
    }

    // MARK: - Main Resolution API

    /// Resolve a node's literal to determine its semantic classification.
    ///
    /// This is the main entry point for resolution. It analyzes the node's
    /// literal content and classifies it as inline text, file reference, or error.
    ///
    /// - Parameter node: The AST node to resolve
    /// - Returns: Result containing ResolutionKind or ResolutionError
    ///
    /// Algorithm:
    /// 1. Check if literal looks like a file path (contains `/` or `.`)
    /// 2. If not, return `.inlineText`
    /// 3. Check for path traversal (`..`) → error
    /// 4. Extract extension and route by type
    /// 5. Validate file existence per mode
    public func resolve(node: Node) -> Result<ResolutionKind, ResolutionError> {
        let literal = node.literal.trimmingCharacters(in: .whitespaces)

        // Check if looks like a file path
        guard looksLikeFilePath(literal) else {
            return .success(.inlineText)
        }

        // Check for path traversal
        if containsPathTraversal(literal) {
            return .failure(.pathTraversal(path: literal, location: node.location))
        }

        // Get extension
        guard let ext = fileExtension(literal) else {
            // No extension found, treat as inline text
            return .success(.inlineText)
        }

        // Route by extension
        switch ext.lowercased() {
        case "md":
            return resolveMarkdown(literal, node: node)
        case "hc":
            return resolveHypercode(literal, node: node)
        default:
            return .failure(.forbiddenExtension(path: literal, ext: ".\(ext)", location: node.location))
        }
    }

    /// Resolve multiple nodes in a tree (depth-first).
    ///
    /// Traverses the node tree and resolves each node's literal,
    /// setting the `resolution` property on each node.
    ///
    /// - Parameter root: The root node to resolve
    /// - Returns: Result indicating success or the first error encountered
    public mutating func resolveTree(root: Node) -> Result<Void, ResolutionError> {
        // Resolve root
        switch resolve(node: root) {
        case .success(let kind):
            root.resolution = kind
        case .failure(let error):
            return .failure(error)
        }

        // Resolve children recursively
        for child in root.children {
            switch resolveTree(root: child) {
            case .success:
                continue
            case .failure(let error):
                return .failure(error)
            }
        }

        return .success(())
    }

    // MARK: - Helper Methods

    /// Check if a literal looks like a file path (heuristic).
    ///
    /// A literal is heuristically identified as a potential file path if:
    /// - Contains path separator (`/`), OR
    /// - Contains extension marker (`.`)
    ///
    /// This heuristic is safe because:
    /// - Pure inline text typically doesn't contain slashes or dots
    /// - If a literal looks like a path but isn't, lenient mode treats it as inline
    /// - Strict mode explicitly fails on missing files (catch errors early)
    ///
    /// - Parameter literal: The literal string to check
    /// - Returns: `true` if the literal looks like a file path
    public func looksLikeFilePath(_ literal: String) -> Bool {
        literal.contains("/") || literal.contains(".")
    }

    /// Extract the file extension from a path.
    ///
    /// Returns the extension without the leading dot.
    /// Returns nil if no valid extension found.
    ///
    /// Examples:
    /// - `"README.md"` → `"md"`
    /// - `"docs/guide.hc"` → `"hc"`
    /// - `"README"` → `nil`
    /// - `"file."` → `nil` (empty extension)
    /// - `".hidden"` → `nil` (hidden file, no extension)
    ///
    /// - Parameter path: The path to extract extension from
    /// - Returns: Extension string without dot, or nil
    public func fileExtension(_ path: String) -> String? {
        // Find last dot
        guard let dotIndex = path.lastIndex(of: ".") else {
            return nil
        }

        // Check if dot is at start (hidden file like .gitignore)
        if dotIndex == path.startIndex {
            return nil
        }

        // Check if dot is at end (trailing dot)
        let afterDot = path.index(after: dotIndex)
        if afterDot == path.endIndex {
            return nil
        }

        // Check if there's a slash after the dot (not an extension)
        let ext = String(path[afterDot...])
        if ext.contains("/") {
            return nil
        }

        return ext
    }

    /// Check if a path contains path traversal components.
    ///
    /// Detects `..` components which could escape the root directory.
    /// Note: `./` is allowed (same directory reference).
    ///
    /// Detection patterns:
    /// - `..` at start: `../file.md`
    /// - `..` in middle: `subdir/../file.md`
    /// - `..` at end: `subdir/..`
    /// - Just `..`: standalone traversal
    ///
    /// - Parameter path: The path to check
    /// - Returns: `true` if path contains traversal components
    public func containsPathTraversal(_ path: String) -> Bool {
        // Split by path separator and check each component
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        return components.contains { $0 == ".." }
    }

    /// Check if a file exists at the given path relative to root.
    ///
    /// - Parameter path: Relative path from root
    /// - Returns: `true` if file exists
    public func fileExists(at path: String) -> Bool {
        let fullPath = constructFullPath(path)
        return fileSystem.fileExists(at: fullPath)
    }

    /// Construct full path by combining root and relative path.
    ///
    /// - Parameter relativePath: Path relative to root
    /// - Returns: Full absolute path
    private func constructFullPath(_ relativePath: String) -> String {
        if relativePath.hasPrefix("/") {
            // Already absolute, use as-is
            return relativePath
        }
        return rootPath + "/" + relativePath
    }

    // MARK: - Resolution Paths

    /// Resolve a Markdown file reference.
    ///
    /// - Parameters:
    ///   - path: The file path
    ///   - node: The source node for error location
    /// - Returns: Result with `.markdownFile` or error
    private func resolveMarkdown(_ path: String, node: Node) -> Result<ResolutionKind, ResolutionError> {
        let fullPath = constructFullPath(path)

        if fileSystem.fileExists(at: fullPath) {
            // File exists - load content
            // Note: Content loading is placeholder for B3: FileLoader integration
            do {
                let content = try fileSystem.readFile(at: fullPath)
                return .success(.markdownFile(path: path, content: content))
            } catch {
                // File exists but couldn't read - treat as IO error propagated up
                // For now, return as inline text in lenient mode, error in strict
                switch mode {
                case .strict:
                    return .failure(ResolutionError(
                        message: "Failed to read file: \(path)",
                        location: node.location
                    ))
                case .lenient:
                    return .success(.inlineText)
                }
            }
        } else {
            // File doesn't exist
            switch mode {
            case .strict:
                return .failure(.fileNotFound(path: path, location: node.location))
            case .lenient:
                return .success(.inlineText)
            }
        }
    }

    /// Resolve a Hypercode file reference.
    ///
    /// - Parameters:
    ///   - path: The file path
    ///   - node: The source node for error location
    /// - Returns: Result with `.hypercodeFile` or error
    private func resolveHypercode(_ path: String, node: Node) -> Result<ResolutionKind, ResolutionError> {
        let fullPath = constructFullPath(path)

        if fileSystem.fileExists(at: fullPath) {
            // File exists - placeholder AST for B4: Recursive Compilation integration
            // The actual recursive compilation will be done in B4
            // For now, return a placeholder indicating the file should be compiled
            return .success(.hypercodeFile(path: path, ast: node))
        } else {
            // File doesn't exist
            switch mode {
            case .strict:
                return .failure(.fileNotFound(path: path, location: node.location))
            case .lenient:
                return .success(.inlineText)
            }
        }
    }

    // MARK: - Integration Hooks for B2, B3, B4

    /// Mark a path as visited (for circular dependency tracking).
    ///
    /// Call this method before recursively processing a `.hc` file.
    /// Integration hook for B2: DependencyTracker.
    ///
    /// - Parameter path: The file path being visited
    /// - Returns: `true` if path was already visited (cycle detected)
    public mutating func markVisited(_ path: String) -> Bool {
        let normalized = constructFullPath(path)
        if visitedPaths.contains(normalized) {
            return true // Cycle detected
        }
        visitedPaths.insert(normalized)
        return false
    }

    /// Clear visited paths (for new resolution context).
    ///
    /// Call this method when starting resolution of a new root file.
    public mutating func clearVisited() {
        visitedPaths.removeAll()
    }
}

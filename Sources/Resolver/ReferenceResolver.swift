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

    /// Dependency tracker for circular dependency detection.
    public var dependencyTracker: DependencyTracker?

    /// Initialize a new reference resolver.
    ///
    /// - Parameters:
    ///   - fileSystem: File system abstraction for file operations
    ///   - rootPath: Root directory for resolving relative file paths
    ///   - mode: Resolution mode (strict or lenient)
    public init(
        fileSystem: FileSystem,
        rootPath: String,
        mode: ResolutionMode,
        dependencyTracker: DependencyTracker? = nil
    ) {
        self.fileSystem = fileSystem
        self.rootPath = rootPath
        self.mode = mode
        self.dependencyTracker = dependencyTracker
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
    public mutating func resolve(node: Node) -> Result<ResolutionKind, ResolutionError> {
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
            return .failure(
                .forbiddenExtension(path: literal, ext: ".\(ext)", location: node.location))
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
        let components = path.components(separatedBy: PathSegment.separators)
        return components.contains { $0 == PathSegment.traversal }
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

    /// Validate that a path is contained within the configured root directory.
    ///
    /// - Parameters:
    ///   - fullPath: Absolute path to validate
    ///   - location: Source location for error reporting
    /// - Returns: Success when the path is within root or a resolution error otherwise.
    private func validateWithinRoot(fullPath: String, location: SourceLocation) -> Result<
        Void, ResolutionError
    > {
        do {
            let canonicalRoot = try fileSystem.canonicalizePath(rootPath)
            let canonicalTarget = try fileSystem.canonicalizePath(fullPath)

            let isInsideRoot =
                canonicalTarget == canonicalRoot || canonicalTarget.hasPrefix(canonicalRoot + "/")

            if isInsideRoot {
                return .success(())
            }

            return .failure(
                .outsideRoot(path: canonicalTarget, root: canonicalRoot, location: location))
        } catch let compilerError as CompilerError {
            return .failure(
                ResolutionError(
                    message: compilerError.message, location: compilerError.location ?? location))
        } catch {
            return .failure(
                ResolutionError(
                    message: "Failed to canonicalize path: \(fullPath)", location: location))
        }
    }

    // MARK: - Resolution Paths

    /// Resolve a Markdown file reference.
    ///
    /// - Parameters:
    ///   - path: The file path
    ///   - node: The source node for error location
    /// - Returns: Result with `.markdownFile` or error
    private func resolveMarkdown(_ path: String, node: Node) -> Result<
        ResolutionKind, ResolutionError
    > {
        let fullPath = constructFullPath(path)

        switch validateWithinRoot(fullPath: fullPath, location: node.location) {
        case .success:
            break
        case .failure(let error):
            return .failure(error)
        }

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
                    return .failure(
                        ResolutionError(
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
    private mutating func resolveHypercode(_ path: String, node: Node) -> Result<
        ResolutionKind, ResolutionError
    > {
        let fullPath = constructFullPath(path)

        switch validateWithinRoot(fullPath: fullPath, location: node.location) {
        case .success:
            break
        case .failure(let error):
            return .failure(error)
        }

        guard fileSystem.fileExists(at: fullPath) else {
            switch mode {
            case .strict:
                return .failure(.fileNotFound(path: path, location: node.location))
            case .lenient:
                return .success(.inlineText)
            }
        }

        var pushedToTracker = false

        // Perform cycle detection before attempting recursive compilation.
        if var tracker = dependencyTracker {
            do {
                if let error = try tracker.checkAndPush(path: fullPath, location: node.location) {
                    dependencyTracker = tracker
                    return .failure(
                        ResolutionError(message: error.message, location: error.location))
                }
                dependencyTracker = tracker
                pushedToTracker = true
            } catch let compilerError as CompilerError {
                return .failure(
                    ResolutionError(
                        message: compilerError.message, location: compilerError.location))
            } catch {
                return .failure(
                    ResolutionError(
                        message: "Unknown error during cycle detection for \(path)",
                        location: node.location))
            }
        }

        let compilationResult = compileHypercode(at: fullPath)

        if var tracker = dependencyTracker, pushedToTracker {
            tracker.pop()
            dependencyTracker = tracker
        }

        switch compilationResult {
        case .success(let ast):
            let mergedAst = merge(childRoot: ast, into: node)
            node.children = [mergedAst]

            return .success(.hypercodeFile(path: path, ast: mergedAst))
        case .failure(let error):
            return .failure(contextualize(error: error, for: fullPath))
        }
    }

    // MARK: - Integration Hooks for B2, B3, B4

    /// Recursively compile a Hypercode file into a resolved AST.
    ///
    /// - Parameter fullPath: Absolute path to the `.hc` file.
    /// - Returns: Root node of the compiled AST or a resolution error.
    private mutating func compileHypercode(at fullPath: String) -> Result<Node, ResolutionError> {
        do {
            // Parse the Hypercode file into an AST.
            let lexer = Lexer(fileSystem: fileSystem)
            let tokens = try lexer.tokenize(fullPath)
            let parser = Parser()

            let program: Program
            switch parser.parse(tokens: tokens) {
            case .success(let parsedProgram):
                program = Program(root: parsedProgram.root, sourceFile: fullPath)
            case .failure(let error):
                return .failure(ResolutionError(message: error.message, location: error.location))
            }

            // Resolve references within the nested AST using the same resolver settings.
            var childResolver = ReferenceResolver(
                fileSystem: fileSystem,
                rootPath: rootPath,
                mode: mode,
                dependencyTracker: dependencyTracker
            )

            switch childResolver.resolveTree(root: program.root) {
            case .success:
                dependencyTracker = childResolver.dependencyTracker
                return .success(program.root)
            case .failure(let error):
                dependencyTracker = childResolver.dependencyTracker
                return .failure(error)
            }
        } catch let compilerError as CompilerError {
            return .failure(
                ResolutionError(message: compilerError.message, location: compilerError.location))
        } catch {
            return .failure(
                ResolutionError(
                    message: "Unknown error during Hypercode compilation at \(fullPath)",
                    location: nil))
        }
    }

    /// Attach resolution stack context to a nested error.
    ///
    /// - Parameters:
    ///   - error: The original resolution error.
    ///   - fullPath: The nested file path that failed to compile.
    /// - Returns: A new ResolutionError with path chain appended for diagnostics.
    private func contextualize(error: ResolutionError, for fullPath: String) -> ResolutionError {
        var contextLines: [String] = [error.message]

        var pathChain: [String] = []
        if let tracker = dependencyTracker {
            pathChain.append(contentsOf: tracker.stack)
        }
        pathChain.append(fullPath)

        if !pathChain.isEmpty {
            contextLines.append("Resolution path: " + pathChain.joined(separator: " → "))
        }

        return ResolutionError(
            message: contextLines.joined(separator: "\n"), location: error.location)
    }

    /// Merge a child AST into the parent tree with depth adjustments.
    ///
    /// - Parameters:
    ///   - childRoot: Root node of the child AST to merge.
    ///   - parent: The node that referenced the child AST.
    /// - Returns: A new root node whose subtree depths are offset relative to the parent.
    private func merge(childRoot: Node, into parent: Node) -> Node {
        clone(node: childRoot, depthOffset: parent.depth + 1)
    }

    /// Create a deep copy of a node applying a depth offset throughout the subtree.
    ///
    /// - Parameters:
    ///   - node: Node to clone.
    ///   - depthOffset: Depth adjustment applied to the node and all descendants.
    /// - Returns: Cloned node with adjusted depths and preserved source locations.
    private func clone(node: Node, depthOffset: Int) -> Node {
        let clonedChildren = node.children.map { clone(node: $0, depthOffset: depthOffset) }

        let clonedResolution: ResolutionKind?
        if let resolution = node.resolution {
            switch resolution {
            case .inlineText:
                clonedResolution = .inlineText
            case .markdownFile(let path, let content):
                clonedResolution = .markdownFile(path: path, content: content)
            case .hypercodeFile(let path, let ast):
                let adjustedAst = clone(node: ast, depthOffset: depthOffset)
                clonedResolution = .hypercodeFile(path: path, ast: adjustedAst)
            case .forbidden(let ext):
                clonedResolution = .forbidden(extension: ext)
            }
        } else {
            clonedResolution = nil
        }

        return Node(
            literal: node.literal,
            depth: node.depth + depthOffset,
            location: node.location,
            children: clonedChildren,
            resolution: clonedResolution
        )
    }

    // MARK: - Deprecated visitation helpers

    /// Clear visited paths (for new resolution context).
    ///
    /// Maintained for backward compatibility with earlier workflows.
    public mutating func clearVisited() {
        dependencyTracker = nil
    }
}

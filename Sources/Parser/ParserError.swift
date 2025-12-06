import Core

/// Errors that can occur during parsing (AST construction).
///
/// Parser errors represent violations of the syntactic rules for Hypercode,
/// such as multiple root nodes, invalid indentation depth, or structural issues.
/// All parser errors are syntax errors (exit code 2).
public enum ParserError: CompilerError, Equatable {
    /// Multiple nodes found at depth 0 (multiple root nodes).
    ///
    /// Hypercode documents must have exactly one root node.
    /// - Parameter locations: Locations of all root nodes found
    case multipleRoots(locations: [SourceLocation])

    /// No node found at depth 0 (missing root node).
    ///
    /// Hypercode documents must have at least one root node at depth 0.
    case noRoot

    /// Invalid depth jump detected (e.g., depth 0 → 3).
    ///
    /// Indentation can only increase by one level at a time.
    /// - Parameters:
    ///   - from: Previous depth
    ///   - to: Current depth
    ///   - location: Where the invalid jump occurred
    case invalidDepthJump(from: Int, to: Int, location: SourceLocation)

    /// Depth exceeds maximum allowed (depth > 10).
    ///
    /// Hypercode has a maximum depth limit of 10 levels.
    /// - Parameters:
    ///   - depth: The depth that was exceeded
    ///   - location: Where the depth limit was exceeded
    case depthExceeded(depth: Int, location: SourceLocation)

    /// Empty token stream provided to parser.
    ///
    /// At least one token must be provided.
    case emptyTokenStream

    // MARK: - CompilerError Protocol

    public var category: ErrorCategory {
        .syntax
    }

    public var message: String {
        switch self {
        case .multipleRoots(let locations):
            let locationList = locations
                .map { "line \($0.line)" }
                .joined(separator: ", ")
            return "Multiple root nodes (depth 0) found at \(locationList). Hypercode documents must have exactly one root."

        case .noRoot:
            return "No root node (depth 0) found. Hypercode documents must have at least one root node at depth 0."

        case .invalidDepthJump(let from, let to, _):
            return "Invalid depth jump from \(from) to \(to). Indentation can only increase by one level at a time."

        case .depthExceeded(let depth, _):
            return "Depth \(depth) exceeds maximum allowed (10). Reduce indentation nesting."

        case .emptyTokenStream:
            return "Empty token stream. Cannot parse with no tokens."
        }
    }

    public var location: SourceLocation? {
        switch self {
        case .multipleRoots:
            return nil  // Multiple locations, handled in message
        case .noRoot:
            return nil
        case .invalidDepthJump(_, _, let location):
            return location
        case .depthExceeded(_, let location):
            return location
        case .emptyTokenStream:
            return nil
        }
    }
}

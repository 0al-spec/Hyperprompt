import Core

/// Represents a node in the Abstract Syntax Tree (AST).
///
/// A Node is the fundamental element of a Hypercode document tree.
/// Each node corresponds to a quoted literal in the source file, positioned
/// at a specific indentation depth. Nodes form a hierarchical tree structure
/// based on indentation levels.
///
/// The parser constructs nodes during AST building, and later phases
/// (resolution, emission) enrich nodes with semantic information.
public final class Node: Equatable, Sendable {
    /// The raw content between quotes (without the quotes).
    /// This is either inline text or a file reference (resolved later).
    public let literal: String

    /// The indentation depth (0-10).
    /// Computed as: indentation_spaces / 4
    /// Depth 0 is the root node; depth > 0 are nested children.
    public let depth: Int

    /// Source location for error reporting.
    /// Points to the exact line in the source file where this node was defined.
    public let location: SourceLocation

    /// Mutable array of direct child nodes.
    /// Populated during AST construction by the parser.
    public var children: [Node]

    /// Semantic classification determined during the resolution phase.
    /// Initially nil; set later by the resolver to classify the literal
    /// as inline text, file reference, etc.
    public var resolution: ResolutionKind?

    /// Initialize a new AST node.
    ///
    /// - Parameters:
    ///   - literal: Content between quotes
    ///   - depth: Indentation depth (0-10)
    ///   - location: Source location for error reporting
    ///   - children: Array of child nodes (default: empty)
    ///   - resolution: Semantic classification (default: nil)
    public init(
        literal: String,
        depth: Int,
        location: SourceLocation,
        children: [Node] = [],
        resolution: ResolutionKind? = nil
    ) {
        self.literal = literal
        self.depth = depth
        self.location = location
        self.children = children
        self.resolution = resolution
    }

    /// Append a child node to this node's children array.
    ///
    /// - Parameter child: The node to append as a child
    public func addChild(_ child: Node) {
        children.append(child)
    }

    /// Recursively collect all descendant nodes (children, grandchildren, etc.).
    ///
    /// - Returns: Array containing this node and all its descendants in depth-first order
    public func allDescendants() -> [Node] {
        var result = [self]
        for child in children {
            result.append(contentsOf: child.allDescendants())
        }
        return result
    }

    /// The total number of nodes in this subtree (including self).
    ///
    /// - Returns: Count of nodes in the subtree rooted at this node
    public var subtreeSize: Int {
        1 + children.reduce(0) { $0 + $1.subtreeSize }
    }

    // MARK: - Equatable

    public static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.literal == rhs.literal
            && lhs.depth == rhs.depth
            && lhs.location == rhs.location
            && lhs.children == rhs.children
            && lhs.resolution == rhs.resolution
    }
}

/// Semantic classification of a node's literal content.
///
/// Determined during the resolution phase to classify whether
/// a literal represents inline text, a file reference, etc.
public enum ResolutionKind: Equatable, Sendable {
    /// The literal is inline text (not a file reference).
    case inlineText

    /// The literal is a path to a Markdown file.
    /// The file content will be embedded with heading level adjustment.
    case markdownFile(path: String, content: String)

    /// The literal is a path to a Hypercode file.
    /// The file will be recursively compiled and the resulting AST embedded.
    case hypercodeFile(path: String, ast: Node)

    /// The literal looks like a file reference but refers to a forbidden extension.
    /// Examples: .txt, .py, .json (only .md and .hc are allowed).
    case forbidden(extension: String)
}

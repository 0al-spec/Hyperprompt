import Core

/// Represents a complete Hypercode program (parsed AST).
///
/// A Program is the result of parsing a Hypercode source file.
/// It contains a single root node (depth 0) and all nested children,
/// forming a complete tree structure representing the document.
public struct Program: Equatable, Sendable {
    /// The root node of the program (depth 0).
    /// There is exactly one root node in a valid Program.
    public let root: Node

    /// Source file path (for reference and debugging).
    /// This is typically the path to the .hc file that was parsed.
    public let sourceFile: String

    /// Initialize a new Program with a root node.
    ///
    /// - Parameters:
    ///   - root: The root node at depth 0
    ///   - sourceFile: Path to the source file (optional, for reference)
    public init(root: Node, sourceFile: String = "") {
        self.root = root
        self.sourceFile = sourceFile
    }

    /// Get the total number of nodes in the program (including root).
    ///
    /// - Returns: Count of all nodes in the tree
    public var nodeCount: Int {
        root.subtreeSize
    }

    /// Get the maximum depth of any node in the program.
    ///
    /// - Returns: Maximum depth encountered, or 0 if only root exists
    public var maxDepth: Int {
        var max = root.depth
        for node in root.allDescendants().dropFirst() {  // Skip root itself
            max = Swift.max(max, node.depth)
        }
        return max
    }
}

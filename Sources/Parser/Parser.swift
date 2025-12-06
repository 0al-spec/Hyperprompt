import Core

/// The AST Parser.
///
/// The parser transforms a token stream (from the Lexer) into an Abstract Syntax Tree (AST).
/// The key algorithm uses a **depth stack** to maintain parent-child relationships based
/// on indentation levels.
///
/// Key responsibilities:
/// 1. Build tree structure from token stream
/// 2. Compute depth from indentation
/// 3. Establish parent-child relationships via depth stack
/// 4. Enforce single root node constraint
/// 5. Report comprehensive syntax errors
public struct Parser {
    /// Maximum allowed depth (Hypercode limit).
    private static let maxDepth = 10

    /// Initialize a new parser.
    public init() {}

    /// Parse a token stream into an AST.
    ///
    /// Algorithm:
    /// 1. Filter to semantic tokens only (skip blank and comment)
    /// 2. Maintain depth stack of (depth, node) pairs
    /// 3. For each semantic token:
    ///    - Pop stack until top.depth < token.depth
    ///    - Create new node
    ///    - Append to top of stack as child
    ///    - Push new node onto stack
    /// 4. Validate single root constraint
    /// 5. Return Program with root node
    ///
    /// - Parameter tokens: Token stream from the Lexer
    /// - Returns: Parsed Program, or ParserError if syntax error detected
    public func parse(tokens: [Token]) -> Result<Program, ParserError> {
        // Extract semantic tokens (nodes only; skip blank and comment)
        let semanticTokens = tokens.filter { $0.isSemantic }

        // Empty token stream is an error
        guard !semanticTokens.isEmpty else {
            return .failure(.emptyTokenStream)
        }

        // Initialize depth stack with (depth, node) pairs
        var stack: [(depth: Int, node: Node)] = []

        // Process each semantic token
        for token in semanticTokens {
            guard case .node(let indent, let literal, let location) = token else {
                // Should not happen (isSemantic filters to .node only), but be defensive
                continue
            }

            let depth = token.depth

            // Validate depth
            if depth > Parser.maxDepth {
                return .failure(.depthExceeded(depth: depth, location: location))
            }

            // Validate no depth gaps (pop stack until we find a parent at depth-1)
            if !stack.isEmpty {
                let previousDepth = stack.last!.depth
                if depth > previousDepth + 1 {
                    // Invalid jump: can only increase depth by 1
                    return .failure(
                        .invalidDepthJump(from: previousDepth, to: depth, location: location)
                    )
                }
            } else if depth != 0 {
                // First node must be at depth 0
                return .failure(
                    .invalidDepthJump(from: -1, to: depth, location: location)
                )
            }

            // Create new node
            let newNode = Node(literal: literal, depth: depth, location: location)

            // Pop stack until we find a parent at depth-1 (or empty for depth 0)
            while !stack.isEmpty && stack.last!.depth >= depth {
                stack.removeLast()
            }

            // Append new node to parent's children
            if !stack.isEmpty {
                stack.last!.node.addChild(newNode)
            }

            // Push new node onto stack
            stack.append((depth: depth, node: newNode))
        }

        // Validate single root constraint
        // At the end, stack contains all nodes from root to the last one
        // Find the node at depth 0 (should be exactly one)
        let rootNodes = stack.filter { $0.depth == 0 }

        guard rootNodes.count == 1 else {
            if rootNodes.isEmpty {
                return .failure(.noRoot)
            } else {
                let locations = rootNodes.map { $0.node.location }
                return .failure(.multipleRoots(locations: locations))
            }
        }

        let root = rootNodes[0].node
        return .success(Program(root: root))
    }
}

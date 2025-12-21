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

        // Track all root nodes (depth 0) for validation
        var rootNodes: [(location: SourceLocation, node: Node)] = []
        var seenRootNode = false

        // Process each semantic token
        for token in semanticTokens {
            guard case .node(_, let literal, let location) = token else {
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

            // Track root nodes for validation
            if depth == 0 {
                if seenRootNode {
                    // We already have a root node, this is a second one
                    rootNodes.append((location: location, node: newNode))
                } else {
                    // First root node
                    seenRootNode = true
                    rootNodes.append((location: location, node: newNode))
                }
            }

            // Append new node to parent's children
            if !stack.isEmpty {
                stack.last!.node.addChild(newNode)
            }

            // Push new node onto stack
            stack.append((depth: depth, node: newNode))
        }

        // Validate single root constraint
        guard rootNodes.count == 1 else {
            if rootNodes.isEmpty {
                return .failure(.noRoot)
            } else {
                let locations = rootNodes.map { $0.location }
                return .failure(.multipleRoots(locations: locations))
            }
        }

        let root = rootNodes[0].node
        return .success(Program(root: root))
    }

    /// Parse a token stream into an AST with best-effort recovery.
    ///
    /// This variant attempts to continue parsing after syntax errors,
    /// returning a partial AST (if possible) plus collected diagnostics.
    ///
    /// - Parameter tokens: Token stream from the Lexer
    /// - Returns: ParserRecoveryResult with partial program and diagnostics
    public func parseWithRecovery(tokens: [Token]) -> ParserRecoveryResult {
        // Extract semantic tokens (nodes only; skip blank and comment)
        let semanticTokens = tokens.filter { $0.isSemantic }

        // Empty token stream produces no AST
        guard !semanticTokens.isEmpty else {
            return ParserRecoveryResult(program: nil, diagnostics: [.emptyTokenStream])
        }

        var diagnostics: [ParserError] = []
        var stack: [(depth: Int, node: Node)] = []
        var rootNode: Node?
        var rootLocations: [SourceLocation] = []

        func resetStackToRoot() {
            if let rootNode {
                stack = [(depth: rootNode.depth, node: rootNode)]
            } else {
                stack.removeAll()
            }
        }

        for token in semanticTokens {
            guard case .node(_, let literal, let location) = token else {
                continue
            }

            let depth = token.depth

            if depth > Parser.maxDepth {
                diagnostics.append(.depthExceeded(depth: depth, location: location))
                continue
            }

            if stack.isEmpty {
                if depth != 0 {
                    diagnostics.append(
                        .invalidDepthJump(from: -1, to: depth, location: location)
                    )
                    continue
                }
            } else {
                let previousDepth = stack.last!.depth
                if depth > previousDepth + 1 {
                    diagnostics.append(
                        .invalidDepthJump(from: previousDepth, to: depth, location: location)
                    )
                    continue
                }
            }

            let newNode = Node(literal: literal, depth: depth, location: location)

            while !stack.isEmpty && stack.last!.depth >= depth {
                stack.removeLast()
            }

            if depth == 0 {
                rootLocations.append(location)
                if rootNode == nil {
                    rootNode = newNode
                } else {
                    resetStackToRoot()
                    continue
                }
            }

            if let parent = stack.last?.node {
                parent.addChild(newNode)
            }

            stack.append((depth: depth, node: newNode))
        }

        if rootLocations.count > 1 {
            diagnostics.append(.multipleRoots(locations: rootLocations))
        }

        guard let rootNode else {
            diagnostics.append(.noRoot)
            return ParserRecoveryResult(program: nil, diagnostics: diagnostics)
        }

        let program = Program(root: rootNode, sourceFile: rootNode.location.filePath)
        return ParserRecoveryResult(program: program, diagnostics: diagnostics)
    }
}

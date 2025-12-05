import Core

/// Represents a single token produced by the Lexer.
///
/// Tokens are the output of lexical analysis, representing classified lines
/// from a Hypercode (.hc) source file. Each token carries enough information
/// for the Parser to build an AST.
///
/// Token Types:
/// - `blank`: Empty line or line containing only spaces
/// - `comment`: Line starting with `#` (after optional indentation)
/// - `node`: Line containing a quoted literal (after optional indentation)
public enum Token: Equatable, Sendable {
    /// A blank line (empty or containing only spaces).
    ///
    /// Blank lines do not affect AST structure but are preserved
    /// for accurate source location tracking.
    case blank(location: SourceLocation)

    /// A comment line starting with `#` after optional indentation.
    ///
    /// - Parameters:
    ///   - indent: Number of leading spaces (must be multiple of 4)
    ///   - location: Source location for error reporting
    case comment(indent: Int, location: SourceLocation)

    /// A node line containing a quoted literal.
    ///
    /// Node lines form the actual structure of Hypercode documents.
    /// The literal content is either inline text or a file reference.
    ///
    /// - Parameters:
    ///   - indent: Number of leading spaces (must be multiple of 4)
    ///   - literal: Content between the quotes (without quotes)
    ///   - location: Source location for error reporting
    case node(indent: Int, literal: String, location: SourceLocation)

    /// The source location of this token.
    public var location: SourceLocation {
        switch self {
        case .blank(let location):
            return location
        case .comment(_, let location):
            return location
        case .node(_, _, let location):
            return location
        }
    }

    /// The indentation level in spaces (0 for blank lines).
    public var indent: Int {
        switch self {
        case .blank:
            return 0
        case .comment(let indent, _):
            return indent
        case .node(let indent, _, _):
            return indent
        }
    }

    /// The depth level (indent / 4).
    public var depth: Int {
        indent / 4
    }

    /// Whether this token represents a semantic line (node).
    ///
    /// Blank and comment lines are non-semantic and do not contribute
    /// to the AST structure.
    public var isSemantic: Bool {
        switch self {
        case .node:
            return true
        case .blank, .comment:
            return false
        }
    }
}

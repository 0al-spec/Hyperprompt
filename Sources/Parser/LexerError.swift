import Core

/// Errors that can occur during lexical analysis.
///
/// All lexer errors are syntax errors (exit code 2) because they represent
/// violations of the Hypercode language syntax rules.
public enum LexerError: CompilerError, Equatable {
    /// Tab character found in indentation.
    ///
    /// Hypercode requires spaces for indentation. Tabs are not allowed.
    /// - Parameter location: Where the tab was found
    case tabInIndentation(location: SourceLocation)

    /// Indentation is not a multiple of 4 spaces.
    ///
    /// Hypercode requires indentation in multiples of 4 spaces.
    /// - Parameters:
    ///   - location: Where the misalignment was found
    ///   - actual: The actual number of spaces found
    case misalignedIndentation(location: SourceLocation, actual: Int)

    /// Opening quote without matching closing quote.
    ///
    /// All literals must be enclosed in double quotes on a single line.
    /// - Parameter location: Where the unclosed quote was found
    case unclosedQuote(location: SourceLocation)

    /// Literal content spans multiple lines.
    ///
    /// Literals cannot contain newline characters (\n, \r, or \r\n).
    /// - Parameter location: Where the multi-line literal was found
    case multilineLiteral(location: SourceLocation)

    /// Line does not match any valid line type.
    ///
    /// Valid line types are: blank, comment (#), or node ("literal").
    /// - Parameter location: Where the invalid line was found
    case invalidLineFormat(location: SourceLocation)

    /// Indentation depth exceeds configured maximum.
    ///
    /// - Parameters:
    ///   - location: Where the depth overflow was found
    ///   - maxDepth: Maximum allowed depth (in indentation levels)
    case depthExceeded(location: SourceLocation, maxDepth: Int)

    /// Trailing content after closing quote.
    ///
    /// Node lines must end immediately after the closing quote.
    /// - Parameter location: Where the trailing content was found
    case trailingContent(location: SourceLocation)

    // MARK: - CompilerError Protocol

    public var category: ErrorCategory {
        .syntax
    }

    public var message: String {
        switch self {
        case .tabInIndentation:
            return "Tab characters are not allowed in indentation (failed NoTabsIndentSpec). Use 4 spaces per indent level."
        case .misalignedIndentation(_, let actual):
            return "Indentation must be a multiple of 4 spaces (failed IndentMultipleOf4Spec). Found \(actual) space\(actual == 1 ? "" : "s")."
        case .unclosedQuote:
            return "Unclosed quotation mark (failed ValidQuotesSpec). Literals must be enclosed in double quotes on a single line."
        case .multilineLiteral:
            return "Literal content cannot span multiple lines (failed SingleLineContentSpec). Each node must be on a single line."
        case .invalidLineFormat:
            return "Invalid line format (failed LineKindDecision/ValidNodeLineSpec). Expected blank line, comment (# ...), or quoted literal (\"...\")."
        case .trailingContent:
            return "Unexpected content after closing quote (failed ValidNodeLineSpec). Node lines must end after the closing quote."
        case .depthExceeded(_, let maxDepth):
            return "Indentation depth exceeds maximum of \(maxDepth) levels (failed DepthWithinLimitSpec). Reduce nesting before this line."
        }
    }

    public var location: SourceLocation? {
        switch self {
        case .tabInIndentation(let location),
             .misalignedIndentation(let location, _),
             .unclosedQuote(let location),
             .multilineLiteral(let location),
             .invalidLineFormat(let location),
             .depthExceeded(let location, _),
             .trailingContent(let location):
            return location
        }
    }
}

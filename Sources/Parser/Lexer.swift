import Core
import Foundation
import HypercodeGrammar

/// Lexer for Hypercode (.hc) source files.
///
/// The Lexer performs line-by-line tokenization of Hypercode source files,
/// classifying each line as blank, comment, or node, and validating syntax rules.
///
/// ## Usage
///
/// ```swift
/// let lexer = Lexer()
/// let tokens = try lexer.tokenize("/path/to/file.hc")
/// for token in tokens {
///     switch token {
///     case .blank: print("Blank line")
///     case .comment(let indent, _): print("Comment at indent \(indent)")
///     case .node(let indent, let literal, _): print("Node '\(literal)' at indent \(indent)")
///     }
/// }
/// ```
///
/// ## Validation Rules
///
/// - **Indentation:** Must use spaces only (no tabs), in multiples of 4
/// - **Literals:** Must be quoted, single-line, properly closed
/// - **Line endings:** Normalized to LF (\n) internally
public final class Lexer {
    /// File system abstraction for reading files.
    private let fileSystem: FileSystem
    private let indentAlignmentSpec: IndentGroupAlignmentSpec

    /// Create a new Lexer instance.
    ///
    /// - Parameter fileSystem: File system to use for reading files.
    ///   Defaults to `LocalFileSystem()` for production use.
    public init(
        fileSystem: FileSystem = LocalFileSystem(),
        indentAlignmentSpec: IndentGroupAlignmentSpec = IndentGroupAlignmentSpec()
    ) {
        self.fileSystem = fileSystem
        self.indentAlignmentSpec = indentAlignmentSpec
    }

    /// Tokenize a Hypercode source file.
    ///
    /// Reads the file, normalizes line endings, and classifies each line
    /// into a token (blank, comment, or node).
    ///
    /// - Parameter filePath: Path to the Hypercode (.hc) file
    /// - Returns: Array of tokens representing the file contents
    /// - Throws: `LexerError` for syntax errors, or IO errors from file system
    public func tokenize(_ filePath: String) throws -> [Token] {
        let content = try fileSystem.readFile(at: filePath)
        return try tokenize(content: content, filePath: filePath)
    }

    /// Tokenize Hypercode content from a string.
    ///
    /// Useful for testing or when content is already loaded.
    ///
    /// - Parameters:
    ///   - content: The Hypercode source content
    ///   - filePath: File path for error reporting
    /// - Returns: Array of tokens
    /// - Throws: `LexerError` for syntax errors
    public func tokenize(content: String, filePath: String) throws -> [Token] {
        let normalizedContent = normalizeLineEndings(content)
        let lines = splitIntoLines(normalizedContent)

        var tokens: [Token] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1  // 1-indexed
            let location = SourceLocation(filePath: filePath, line: lineNumber)
            let token = try classifyLine(line, location: location)
            tokens.append(token)
        }

        return tokens
    }

    // MARK: - Line Ending Normalization

    /// Normalize line endings to LF (\n).
    ///
    /// Converts CRLF (\r\n) and CR (\r) to LF (\n) for consistent processing.
    ///
    /// - Parameter content: Raw file content
    /// - Returns: Content with normalized line endings
    func normalizeLineEndings(_ content: String) -> String {
        // Replace CRLF first, then CR
        content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    /// Split content into lines.
    ///
    /// Handles trailing newline correctly: "a\nb\n" produces ["a", "b"],
    /// not ["a", "b", ""].
    ///
    /// - Parameter content: Normalized content
    /// - Returns: Array of line strings (without newline characters)
    func splitIntoLines(_ content: String) -> [String] {
        // Handle empty content
        guard !content.isEmpty else {
            return []
        }

        // Split by newline
        var lines = content.components(separatedBy: "\n")

        // Remove trailing empty line if content ended with newline
        if content.hasSuffix(LineBreak.lineFeedString) && lines.last == "" {
            lines.removeLast()
        }

        return lines
    }

    // MARK: - Line Classification

    /// Classify a single line into a token.
    ///
    /// Uses LineKindDecision from HypercodeGrammar specifications for classification
    /// with priority: blank → comment → node.
    ///
    /// - Parameters:
    ///   - line: The line content (without newline)
    ///   - location: Source location for error reporting
    /// - Returns: Classified token
    /// - Throws: `LexerError` if line is invalid
    func classifyLine(_ line: String, location: SourceLocation) throws -> Token {
        // Create RawLine for specification-based classification (blank check doesn't require valid indentation)
        let rawLine = RawLine(text: line, lineNumber: location.line, filePath: location.filePath)
        let blankSpec = IsBlankLineSpec()

        // Check if blank first (doesn't require indentation validation)
        if blankSpec.isSatisfiedBy(rawLine) {
            return .blank(location: location)
        }

        // For non-blank lines, validate indentation to provide detailed error messages
        let (indent, contentStart) = try extractIndentation(line, location: location)

        // Extract content after indentation
        let content = String(line[contentStart...])

        // For non-blank, non-comment lines, validate as node with detailed error messages
        if !content.isEmpty && content.first != "#" {
            // Extract and validate literal content for detailed error reporting
            let literal = try extractLiteral(content, location: location)
            return .node(indent: indent, literal: literal, location: location)
        }

        // Use LineKindDecision for comment classification
        let classifier = HypercodeGrammar.makeLineClassifier()
        guard let kind = classifier.decide(rawLine) else {
            throw LexerError.invalidLineFormat(location: location)
        }

        // Handle classification result
        switch kind {
        case .blank:
            return .blank(location: location)
        case .comment:
            return .comment(indent: indent, location: location)
        case .node:
            // Should not reach here, but handle for completeness
            let literal = try extractLiteral(content, location: location)
            return .node(indent: indent, literal: literal, location: location)
        }
    }

    // MARK: - Blank Line Detection

    /// Check if a line is blank (empty or only spaces).
    ///
    /// - Parameter line: The line to check
    /// - Returns: `true` if line is blank
    ///
    /// - Warning: This method is deprecated. Use `LineKindDecision` from HypercodeGrammar
    ///   for specification-based line classification instead.
    @available(*, deprecated, message: "Use LineKindDecision for specification-based classification")
    func isBlankLine(_ line: String) -> Bool {
        line.isEmpty || line.allSatisfy { $0 == Whitespace.space }
    }

    // MARK: - Indentation Handling

    /// Extract and validate indentation from a line.
    ///
    /// - Parameters:
    ///   - line: The line to process
    ///   - location: Source location for error reporting
    /// - Returns: Tuple of (indent count, index where content starts)
    /// - Throws: `LexerError.tabInIndentation` or `LexerError.misalignedIndentation`
    ///
    /// - Warning: This method is deprecated. Use `LineKindDecision` from HypercodeGrammar
    ///   for specification-based indentation validation instead.
    @available(*, deprecated, message: "Use LineKindDecision for specification-based indentation validation")
    func extractIndentation(_ line: String, location: SourceLocation) throws -> (Int, String.Index)
    {
        var indent = 0
        var index = line.startIndex

        while index < line.endIndex {
            let char = line[index]

            if char == Whitespace.space {
                indent += 1
                index = line.index(after: index)
            } else if char == Whitespace.tab {
                throw LexerError.tabInIndentation(location: location)
            } else {
                break
            }
        }

        // Validate indent is multiple of 4
        if !indentAlignmentSpec.isSatisfiedBy(indent) {
            throw LexerError.misalignedIndentation(location: location, actual: indent)
        }

        return (indent, index)
    }

    // MARK: - Literal Extraction

    /// Extract literal content from a quoted string.
    ///
    /// Expects content starting with `"` and ending with `"`.
    /// Validates that literal is single-line and properly closed.
    ///
    /// - Parameters:
    ///   - content: Content starting with opening quote
    ///   - location: Source location for error reporting
    /// - Returns: The literal content (without quotes)
    /// - Throws: `LexerError.unclosedQuote`, `LexerError.multilineLiteral`,
    ///           or `LexerError.trailingContent`
    ///
    /// - Warning: This method is deprecated. Use `LineKindDecision` from HypercodeGrammar
    ///   for specification-based literal validation instead.
    @available(*, deprecated, message: "Use LineKindDecision for specification-based literal validation")
    func extractLiteral(_ content: String, location: SourceLocation) throws -> String {
        // Content should start with quote
        guard content.hasPrefix(QuoteDelimiter.doubleQuoteString) else {
            throw LexerError.invalidLineFormat(location: location)
        }

        // Find closing quote (after opening quote)
        let afterOpeningQuote = content.index(after: content.startIndex)

        guard afterOpeningQuote < content.endIndex else {
            throw LexerError.unclosedQuote(location: location)
        }

        // Look for closing quote
        guard
            let closingQuoteIndex = content[afterOpeningQuote...]
                .firstIndex(of: QuoteDelimiter.doubleQuote)
        else {
            throw LexerError.unclosedQuote(location: location)
        }

        // Extract literal
        let literal = String(content[afterOpeningQuote..<closingQuoteIndex])

        // Check for multi-line content
        if literal.contains(LineBreak.lineFeed) || literal.contains(LineBreak.carriageReturn) {
            throw LexerError.multilineLiteral(location: location)
        }

        // Check for trailing content after closing quote
        let afterClosingQuote = content.index(after: closingQuoteIndex)
        if afterClosingQuote < content.endIndex {
            let trailing = content[afterClosingQuote...]
            // Allow only whitespace after closing quote
            if !trailing.allSatisfy({ $0 == Whitespace.space }) {
                throw LexerError.trailingContent(location: location)
            }
        }

        return literal
    }
}

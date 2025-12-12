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

    private let blankLineSpec = IsBlankLineSpec()
    private let noTabsSpec = NoTabsIndentSpec()
    private let indentMultipleOf4Spec: IndentMultipleOf4Spec
    private let depthWithinLimitSpec: DepthWithinLimitSpec
    private let nodeValidationSpec: ValidNodeLineSpec
    private let startsWithQuoteSpec = StartsWithDoubleQuoteSpec()
    private let singleLineContentSpec = SingleLineContentSpec()
    private let lineClassifier: LineKindDecision

    /// Create a new Lexer instance.
    ///
    /// - Parameter fileSystem: File system to use for reading files.
    ///   Defaults to `LocalFileSystem()` for production use.
    public init(
        fileSystem: FileSystem = LocalFileSystem(),
        spacesPerIndentLevel: Int = Indentation.spacesPerLevel,
        maxDepth: Int = 10
    ) {
        self.fileSystem = fileSystem
        self.indentMultipleOf4Spec = IndentMultipleOf4Spec(spacesPerLevel: spacesPerIndentLevel)
        self.depthWithinLimitSpec = DepthWithinLimitSpec(maxDepth: maxDepth)
        self.nodeValidationSpec = ValidNodeLineSpec(maxDepth: maxDepth)
        self.lineClassifier = HypercodeGrammar.makeLineClassifier()
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
    /// with priority: blank → comment → node. Delegates to private helpers for
    /// indentation and literal validation.
    ///
    /// - Parameters:
    ///   - line: The line content (without newline)
    ///   - location: Source location for error reporting
    /// - Returns: Classified token
    /// - Throws: `LexerError` if line is invalid
    func classifyLine(_ line: String, location: SourceLocation) throws -> Token {
        let rawLine = RawLine(text: line, lineNumber: location.line, filePath: location.filePath)
        let normalizedLine = trimTrailingSpaces(from: rawLine)

        if blankLineSpec.isSatisfiedBy(normalizedLine) {
            return .blank(location: location)
        }

        try validateIndentation(for: normalizedLine, location: location)

        if let kind = lineClassifier.decide(normalizedLine) {
            switch kind {
            case .blank:
                return .blank(location: location)
            case .comment:
                return .comment(indent: normalizedLine.leadingSpaces, location: location)
            case .node(let literal):
                let extractedLiteral = try validateNodeLine(normalizedLine, literal, location: location)
                return .node(indent: normalizedLine.leadingSpaces, literal: extractedLiteral, location: location)
            }
        }

        try diagnoseSpecificationFailure(for: normalizedLine, location: location)
        throw LexerError.invalidLineFormat(location: location)
    }

    // MARK: - Private Validation Helpers

    private func validateIndentation(for rawLine: RawLine, location: SourceLocation) throws {
        if !noTabsSpec.isSatisfiedBy(rawLine) {
            throw LexerError.tabInIndentation(location: location)
        }

        if !indentMultipleOf4Spec.isSatisfiedBy(rawLine) {
            throw LexerError.misalignedIndentation(location: location, actual: rawLine.leadingSpaces)
        }
    }

    private func validateNodeLine(
        _ rawLine: RawLine,
        _ literal: String,
        location: SourceLocation
    ) throws -> String {
        guard depthWithinLimitSpec.isSatisfiedBy(rawLine) else {
            throw LexerError.invalidLineFormat(location: location)
        }

        if !nodeValidationSpec.isSatisfiedBy(rawLine) {
            try diagnoseSpecificationFailure(for: rawLine, location: location)
            throw LexerError.invalidLineFormat(location: location)
        }

        let extractedLiteral = try extractLiteral(from: rawLine, location: location)

        return extractedLiteral
    }

    private func diagnoseSpecificationFailure(for rawLine: RawLine, location: SourceLocation) throws {
        let trimmed = rawLine.text.drop(while: { $0 == Whitespace.space })

        if trimmed.first == QuoteDelimiter.doubleQuote {
            try diagnoseQuoteFailure(in: rawLine, trimmed: trimmed, location: location)
        }
    }

    private func diagnoseQuoteFailure(
        in rawLine: RawLine,
        trimmed: Substring,
        location: SourceLocation
    ) throws {
        guard startsWithQuoteSpec.isSatisfiedBy(rawLine) else {
            throw LexerError.invalidLineFormat(location: location)
        }

        let afterOpening = trimmed.index(after: trimmed.startIndex)
        guard afterOpening < trimmed.endIndex else {
            throw LexerError.unclosedQuote(location: location)
        }

        guard let closingQuoteIndex = trimmed[afterOpening...].firstIndex(of: QuoteDelimiter.doubleQuote) else {
            throw LexerError.unclosedQuote(location: location)
        }

        let literal = String(trimmed[afterOpening..<closingQuoteIndex])

        if !singleLineContentSpec.isSatisfiedBy(literal) {
            throw LexerError.multilineLiteral(location: location)
        }

        let afterClosingQuote = trimmed.index(after: closingQuoteIndex)
        if afterClosingQuote < trimmed.endIndex {
            let trailing = trimmed[afterClosingQuote...]
            if !trailing.allSatisfy({ $0 == Whitespace.space }) {
                throw LexerError.trailingContent(location: location)
            }
        }
    }

    private func assertSingleLineLiteral(_ literal: String, location: SourceLocation) throws {
        if !singleLineContentSpec.isSatisfiedBy(literal) {
            throw LexerError.multilineLiteral(location: location)
        }
    }

    private func extractLiteral(from rawLine: RawLine, location: SourceLocation) throws -> String {
        let trimmed = rawLine.text.drop(while: { $0 == Whitespace.space })

        guard !trimmed.isEmpty, trimmed.first == QuoteDelimiter.doubleQuote else {
            throw LexerError.invalidLineFormat(location: location)
        }

        let afterOpeningQuote = trimmed.index(after: trimmed.startIndex)
        guard afterOpeningQuote < trimmed.endIndex else {
            throw LexerError.unclosedQuote(location: location)
        }

        guard let closingQuoteIndex = trimmed[afterOpeningQuote...].firstIndex(of: QuoteDelimiter.doubleQuote) else {
            throw LexerError.unclosedQuote(location: location)
        }

        let literal = String(trimmed[afterOpeningQuote..<closingQuoteIndex])
        try assertSingleLineLiteral(literal, location: location)

        let afterClosingQuote = trimmed.index(after: closingQuoteIndex)
        if afterClosingQuote < trimmed.endIndex {
            let trailing = trimmed[afterClosingQuote...]
            if !trailing.allSatisfy({ $0 == Whitespace.space }) {
                throw LexerError.trailingContent(location: location)
            }
        }

        return literal
    }

    private func trimTrailingSpaces(from rawLine: RawLine) -> RawLine {
        let trimmedText = String(rawLine.text.reversed().drop(while: { $0 == Whitespace.space }).reversed())
        return RawLine(text: trimmedText, lineNumber: rawLine.lineNumber, filePath: rawLine.filePath)
    }
}

#if Editor
import Core
import Foundation
import HypercodeGrammar
import Parser

/// EditorParser — Parses Hypercode and extracts link spans.
public struct EditorParser {
    private let fileSystem: FileSystem
    private let lexer: Lexer
    private let parser: Parser
    private let referenceHintDecision = LinkReferenceHintDecisionSpec()

    /// Creates a new editor parser.
    /// - Parameter fileSystem: File system implementation (use MockFileSystem in tests)
    public init(fileSystem: FileSystem = LocalFileSystem()) {
        self.fileSystem = fileSystem
        self.lexer = Lexer(fileSystem: fileSystem)
        self.parser = Parser()
    }

    /// Parses a file from disk, returning a ParsedFile with link spans.
    /// - Parameter filePath: Path to the Hypercode file
    /// - Returns: ParsedFile containing AST, link spans, and diagnostics
    public func parse(filePath: String) -> ParsedFile {
        do {
            let content = try fileSystem.readFile(at: filePath)
            return parse(content: content, filePath: filePath)
        } catch let error as CompilerError {
            return ParsedFile(
                ast: nil,
                linkSpans: [],
                diagnostics: [error],
                sourceFile: filePath
            )
        } catch {
            let internalError = ConcreteCompilerError.internalError(
                message: "Unexpected parser error: \(error)",
                location: nil
            )
            return ParsedFile(
                ast: nil,
                linkSpans: [],
                diagnostics: [internalError],
                sourceFile: filePath
            )
        }
    }

    /// Parses Hypercode content, returning a ParsedFile with link spans.
    /// - Parameters:
    ///   - content: Hypercode source content
    ///   - filePath: File path for diagnostics
    /// - Returns: ParsedFile containing AST, link spans, and diagnostics
    public func parse(content: String, filePath: String) -> ParsedFile {
        let normalizedContent = normalizeLineEndings(content)
        let lines = splitIntoLines(normalizedContent)
        let lineStartOffsets = computeLineStartOffsets(lines)

        var diagnostics: [CompilerError] = []
        let tokens: [Token]

        do {
            tokens = try lexer.tokenize(content: content, filePath: filePath)
        } catch let error as CompilerError {
            diagnostics.append(error)
            return ParsedFile(
                ast: nil,
                linkSpans: [],
                diagnostics: diagnostics,
                sourceFile: filePath
            )
        } catch {
            diagnostics.append(
                ConcreteCompilerError.internalError(
                    message: "Unknown parser error: \(error)",
                    location: nil
                )
            )
            return ParsedFile(
                ast: nil,
                linkSpans: [],
                diagnostics: diagnostics,
                sourceFile: filePath
            )
        }

        let parseResult = parser.parseWithRecovery(tokens: tokens)
        diagnostics.append(contentsOf: parseResult.diagnostics)

        let linkSpans = extractLinkSpans(
            tokens: tokens,
            lines: lines,
            lineStartOffsets: lineStartOffsets,
            sourceFile: filePath
        )

        return ParsedFile(
            ast: parseResult.program,
            linkSpans: linkSpans,
            diagnostics: diagnostics,
            sourceFile: filePath
        )
    }

    // MARK: - Link Span Extraction

    private func extractLinkSpans(
        tokens: [Token],
        lines: [String],
        lineStartOffsets: [Int],
        sourceFile: String
    ) -> [LinkSpan] {
        var spans: [LinkSpan] = []

        for token in tokens {
            guard case .node(_, let literal, let location) = token else {
                continue
            }

            let lineIndex = location.line - 1
            guard lineIndex >= 0, lineIndex < lines.count else {
                continue
            }

            let line = lines[lineIndex]
            guard let literalBounds = literalBounds(in: line) else {
                continue
            }

            let literalStartIndex = literalBounds.start
            let literalEndIndex = literalBounds.end

            let lineStartOffset = lineStartOffsets[lineIndex]
            let byteStart = lineStartOffset + line[..<literalStartIndex].utf8.count
            let byteEnd = byteStart + line[literalStartIndex..<literalEndIndex].utf8.count

            let startColumn = line.distance(from: line.startIndex, to: literalStartIndex) + 1
            let endColumn = startColumn + literal.count

            let lineRange = location.line..<(location.line + 1)
            let columnRange = startColumn..<endColumn

            let span = LinkSpan(
                literal: literal,
                byteRange: byteStart..<byteEnd,
                lineRange: lineRange,
                columnRange: columnRange,
                referenceHint: referenceHintDecision.decide(literal) ?? .inlineText,
                sourceFile: sourceFile
            )
            spans.append(span)
        }

        return spans
    }

    private func literalBounds(in line: String) -> (start: String.Index, end: String.Index)? {
        guard let openQuote = line.firstIndex(of: "\"") else {
            return nil
        }
        let start = line.index(after: openQuote)
        guard let closeQuote = line[start...].firstIndex(of: "\"") else {
            return nil
        }
        return (start: start, end: closeQuote)
    }

    // MARK: - Line Ending Normalization

    private func normalizeLineEndings(_ content: String) -> String {
        content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    private func splitIntoLines(_ content: String) -> [String] {
        guard !content.isEmpty else {
            return []
        }

        var lines = content.components(separatedBy: "\n")
        if content.hasSuffix("\n") && lines.last == "" {
            lines.removeLast()
        }
        return lines
    }

    private func computeLineStartOffsets(_ lines: [String]) -> [Int] {
        var offsets: [Int] = []
        offsets.reserveCapacity(lines.count)

        var currentOffset = 0
        for (index, line) in lines.enumerated() {
            offsets.append(currentOffset)
            currentOffset += line.utf8.count
            if index < lines.count - 1 {
                currentOffset += 1
            }
        }

        return offsets
    }
}

extension EditorParser {
    /// Finds the link span at the given line and column position.
    ///
    /// This method uses binary search for O(log n) performance when looking up links by position.
    /// It assumes that link spans are sorted by (line, column) order, which is guaranteed by
    /// the `extractLinkSpans` method.
    ///
    /// - Parameters:
    ///   - line: 1-based line number
    ///   - column: 1-based column number
    ///   - parsedFile: The parsed file containing link spans to search
    /// - Returns: The `LinkSpan` at the specified position, or `nil` if no link exists there
    ///
    /// - Complexity: O(log n + k) where n is the number of link spans and k is the number of links on the same line (typically 1-3)
    ///
    /// - Note: The position check uses inclusive start and exclusive end semantics.
    ///   For example, a link at columns 10..<20 contains column 10 but not column 20.
    ///
    /// - Precondition: `parsedFile.linkSpans` must be sorted by (line, column) order
    ///
    /// Example:
    /// ```swift
    /// let parser = EditorParser()
    /// let parsedFile = parser.parse(filePath: "example.hc")
    ///
    /// // User clicks at line 5, column 15
    /// if let link = parser.linkAt(line: 5, column: 15, in: parsedFile) {
    ///     print("Link found: \(link.literal)")
    ///     // Proceed to resolve link target
    /// } else {
    ///     print("No link at cursor position")
    /// }
    /// ```
    public func linkAt(line: Int, column: Int, in parsedFile: ParsedFile) -> LinkSpan? {
        // Guard against invalid input
        guard line > 0, column > 0 else {
            return nil
        }

        let linkSpans = parsedFile.linkSpans

        // Handle empty array
        guard !linkSpans.isEmpty else {
            return nil
        }

        #if DEBUG
        // Verify sortedness assumption in debug builds
        for i in 1..<linkSpans.count {
            let prev = linkSpans[i - 1]
            let curr = linkSpans[i]
            assert(
                (prev.lineRange.lowerBound, prev.columnRange.lowerBound) <=
                (curr.lineRange.lowerBound, curr.columnRange.lowerBound),
                "linkSpans must be sorted by (line, column) order. " +
                "Found \(prev.sourceLocation) followed by \(curr.sourceLocation)"
            )
        }
        #endif

        // Binary search for first link that could contain the target line
        var low = 0
        var high = linkSpans.count - 1
        var firstCandidateIndex: Int?

        while low <= high {
            let mid = low + (high - low) / 2
            let span = linkSpans[mid]

            if span.lineRange.contains(line) {
                // Found a span on target line, search backwards for first one
                firstCandidateIndex = mid
                high = mid - 1
            } else if span.lineRange.lowerBound > line {
                // This span is after target line, search earlier
                high = mid - 1
            } else {
                // This span is before target line, search later
                low = mid + 1
            }
        }

        // If we found a candidate, scan forward on the same line for column match
        if let startIndex = firstCandidateIndex {
            for i in startIndex..<linkSpans.count {
                let span = linkSpans[i]

                // Stop if we've moved past the target line
                guard span.lineRange.contains(line) else {
                    break
                }

                // Check if column is within this span (inclusive start, exclusive end)
                if span.columnRange.contains(column) {
                    return span
                }
            }
        }

        return nil
    }
}

extension EditorParser {
    /// Convenience static entry point using the default file system.
    public static func parse(filePath: String) -> ParsedFile {
        let parser = EditorParser()
        return parser.parse(filePath: filePath)
    }

    /// Convenience static entry point for parsing content directly.
    public static func parse(content: String, filePath: String) -> ParsedFile {
        let parser = EditorParser()
        return parser.parse(content: content, filePath: filePath)
    }
}
#endif

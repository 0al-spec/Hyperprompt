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

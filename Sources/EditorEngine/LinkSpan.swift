import Core

/// Represents a literal span in a source file with byte and line/column ranges.
///
/// Ranges use 0-based UTF-8 byte offsets for `byteRange`, and 1-based
/// line/column indices for `lineRange` and `columnRange`.
public struct LinkSpan: Equatable, Sendable {
    /// The literal content between quotes.
    public let literal: String

    /// UTF-8 byte range within the normalized file content (0-based, end-exclusive).
    public let byteRange: Range<Int>

    /// Line range (1-based, end-exclusive).
    public let lineRange: Range<Int>

    /// Column range (1-based, end-exclusive).
    public let columnRange: Range<Int>

    /// Reference hint derived from link heuristics.
    public let referenceHint: LinkReferenceHint

    /// Source file path for this span.
    public let sourceFile: String

    /// Convenience source location (start line).
    public var sourceLocation: SourceLocation {
        SourceLocation(filePath: sourceFile, line: lineRange.lowerBound)
    }

    /// Creates a new link span.
    public init(
        literal: String,
        byteRange: Range<Int>,
        lineRange: Range<Int>,
        columnRange: Range<Int>,
        referenceHint: LinkReferenceHint,
        sourceFile: String
    ) {
        self.literal = literal
        self.byteRange = byteRange
        self.lineRange = lineRange
        self.columnRange = columnRange
        self.referenceHint = referenceHint
        self.sourceFile = sourceFile
    }
}

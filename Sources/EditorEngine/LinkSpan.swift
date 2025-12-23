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

// MARK: - Codable Conformance
extension LinkSpan: Codable {
    private enum CodingKeys: String, CodingKey {
        case literal
        case byteRangeStart
        case byteRangeEnd
        case lineRangeStart
        case lineRangeEnd
        case columnRangeStart
        case columnRangeEnd
        case referenceHint
        case sourceFile
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        literal = try container.decode(String.self, forKey: .literal)
        let byteStart = try container.decode(Int.self, forKey: .byteRangeStart)
        let byteEnd = try container.decode(Int.self, forKey: .byteRangeEnd)
        byteRange = byteStart..<byteEnd
        let lineStart = try container.decode(Int.self, forKey: .lineRangeStart)
        let lineEnd = try container.decode(Int.self, forKey: .lineRangeEnd)
        lineRange = lineStart..<lineEnd
        let columnStart = try container.decode(Int.self, forKey: .columnRangeStart)
        let columnEnd = try container.decode(Int.self, forKey: .columnRangeEnd)
        columnRange = columnStart..<columnEnd
        referenceHint = try container.decode(LinkReferenceHint.self, forKey: .referenceHint)
        sourceFile = try container.decode(String.self, forKey: .sourceFile)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(literal, forKey: .literal)
        try container.encode(byteRange.lowerBound, forKey: .byteRangeStart)
        try container.encode(byteRange.upperBound, forKey: .byteRangeEnd)
        try container.encode(lineRange.lowerBound, forKey: .lineRangeStart)
        try container.encode(lineRange.upperBound, forKey: .lineRangeEnd)
        try container.encode(columnRange.lowerBound, forKey: .columnRangeStart)
        try container.encode(columnRange.upperBound, forKey: .columnRangeEnd)
        try container.encode(referenceHint, forKey: .referenceHint)
        try container.encode(sourceFile, forKey: .sourceFile)
    }
}

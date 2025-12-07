import Core
import Foundation

/// Raw line read from source file before classification.
public struct RawLine: Equatable, Codable, Sendable {
    public let text: String
    public let lineNumber: Int
    public let filePath: String

    public init(text: String, lineNumber: Int, filePath: String) {
        precondition(lineNumber >= 1, "Line number must be 1-indexed and positive")
        self.text = text
        self.lineNumber = lineNumber
        self.filePath = filePath
    }

    /// Convenience accessor for `SourceLocation` derived from the stored path and line number.
    public var location: SourceLocation {
        SourceLocation(filePath: filePath, line: lineNumber)
    }

    /// Number of leading space characters used for indentation.
    public var leadingSpaces: Int {
        text.prefix(while: { $0 == Whitespace.space }).count
    }
}

/// Classification for a line in Hypercode source.
public enum LineKind: Equatable, Codable, Sendable {
    case blank
    case comment(prefix: String?)
    case node(literal: String)
}

/// Parsed line enriched with indentation metadata and resolved literal content when present.
public struct ParsedLine: Equatable, Codable, Sendable {
    public let kind: LineKind
    public let indentSpaces: Int
    public let depth: Int
    public let literal: String?
    public let location: SourceLocation

    public init(kind: LineKind, indentSpaces: Int, literal: String?, location: SourceLocation) {
        precondition(indentSpaces >= 0, "Indentation cannot be negative")
        precondition(
            indentSpaces % Indentation.spacesPerLevel == 0,
            "Indentation must align to \(Indentation.spacesPerLevel)-space groups"
        )
        self.kind = kind
        self.indentSpaces = indentSpaces
        self.depth = indentSpaces / Indentation.spacesPerLevel
        self.literal = literal
        self.location = location
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case indentSpaces
        case depth
        case literal
        case filePath
        case line
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.kind = try container.decode(LineKind.self, forKey: .kind)
        self.indentSpaces = try container.decode(Int.self, forKey: .indentSpaces)
        let decodedDepth = try container.decode(Int.self, forKey: .depth)
        precondition(
            indentSpaces % Indentation.spacesPerLevel == 0,
            "Indentation must align to \(Indentation.spacesPerLevel)-space groups"
        )
        let computedDepth = indentSpaces / Indentation.spacesPerLevel
        precondition(decodedDepth == computedDepth, "Decoded depth must match indentation")
        self.depth = computedDepth
        self.literal = try container.decodeIfPresent(String.self, forKey: .literal)
        let filePath = try container.decode(String.self, forKey: .filePath)
        let line = try container.decode(Int.self, forKey: .line)
        self.location = SourceLocation(filePath: filePath, line: line)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encode(indentSpaces, forKey: .indentSpaces)
        try container.encode(depth, forKey: .depth)
        try container.encodeIfPresent(literal, forKey: .literal)
        try container.encode(location.filePath, forKey: .filePath)
        try container.encode(location.line, forKey: .line)
    }

    /// Indicates whether the line can be skipped during semantic processing (blank or comment).
    public var isSkippable: Bool {
        if case .blank = kind { return true }
        if case .comment = kind { return true }
        return false
    }
}

/// Classification for path validation outcomes used by the resolver.
public enum PathKind: Equatable, Codable, Sendable {
    case allowed(extension: String)
    case forbidden(extension: String)
    case invalid(reason: String)
}

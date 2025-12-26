#if Editor
import Core

/// Severity levels for editor diagnostics.
public enum DiagnosticSeverity: String, Equatable, Sendable, Codable {
    case error
    case warning
    case info
    case hint
}

/// 1-based position in a source file.
public struct SourcePosition: Equatable, Sendable, Codable {
    public let line: Int
    public let column: Int

    public init(line: Int, column: Int) {
        precondition(line >= 1, "Line must be 1-based")
        precondition(column >= 1, "Column must be 1-based")
        self.line = line
        self.column = column
    }
}

/// Range in a source file using 1-based line/column positions.
public struct SourceRange: Equatable, Sendable, Codable {
    public let start: SourcePosition
    public let end: SourcePosition

    public init(start: SourcePosition, end: SourcePosition) {
        self.start = start
        self.end = end
    }
}

/// Related diagnostic info for secondary locations.
public struct DiagnosticRelatedInfo: Equatable, Sendable, Codable {
    public let message: String
    public let range: SourceRange?

    public init(message: String, range: SourceRange?) {
        self.message = message
        self.range = range
    }
}

/// Editor-friendly diagnostic.
public struct Diagnostic: Equatable, Sendable, Codable {
    public let code: String
    public let severity: DiagnosticSeverity
    public let message: String
    public let range: SourceRange?
    public let related: [DiagnosticRelatedInfo]

    public init(
        code: String,
        severity: DiagnosticSeverity,
        message: String,
        range: SourceRange?,
        related: [DiagnosticRelatedInfo] = []
    ) {
        self.code = code
        self.severity = severity
        self.message = message
        self.range = range
        self.related = related
    }
}
#endif

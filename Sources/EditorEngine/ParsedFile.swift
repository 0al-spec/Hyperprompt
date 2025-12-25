#if Editor
import Core
import Parser

/// ParsedFile — Parsed AST plus link spans and diagnostics.
public struct ParsedFile {
    /// Parsed AST program (nil when no valid root was produced).
    public let ast: Program?

    /// Link spans extracted from literals.
    public let linkSpans: [LinkSpan]

    /// Diagnostics collected during lexing/parsing.
    public let diagnostics: [CompilerError]

    /// Source file path.
    public let sourceFile: String

    /// Whether any diagnostics were produced.
    public var hasDiagnostics: Bool {
        !diagnostics.isEmpty
    }

    /// Creates a new parsed file result.
    public init(
        ast: Program?,
        linkSpans: [LinkSpan],
        diagnostics: [CompilerError],
        sourceFile: String
    ) {
        self.ast = ast
        self.linkSpans = linkSpans
        self.diagnostics = diagnostics
        self.sourceFile = sourceFile
    }
}
#endif

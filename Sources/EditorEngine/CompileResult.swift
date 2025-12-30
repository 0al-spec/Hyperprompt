#if Editor
import Core
import Statistics

/// Result of editor compilation.
public struct CompileResult {
    /// Compiled Markdown output.
    public let output: String?

    /// Diagnostics captured during compilation.
    public let diagnostics: [CompilerError]

    /// Optional manifest JSON.
    public let manifest: String?

    /// Optional compilation statistics.
    public let statistics: CompilationStats?

    /// Optional source map for bidirectional navigation.
    public let sourceMap: SourceMap?

    /// Whether diagnostics contain errors.
    public var hasErrors: Bool {
        !diagnostics.isEmpty
    }

    public init(
        output: String?,
        diagnostics: [CompilerError],
        manifest: String?,
        statistics: CompilationStats?,
        sourceMap: SourceMap? = nil
    ) {
        self.output = output
        self.diagnostics = diagnostics
        self.manifest = manifest
        self.statistics = statistics
        self.sourceMap = sourceMap
    }
}
#endif

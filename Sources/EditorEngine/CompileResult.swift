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

    /// Whether diagnostics contain errors.
    public var hasErrors: Bool {
        !diagnostics.isEmpty
    }

    public init(
        output: String?,
        diagnostics: [CompilerError],
        manifest: String?,
        statistics: CompilationStats?
    ) {
        self.output = output
        self.diagnostics = diagnostics
        self.manifest = manifest
        self.statistics = statistics
    }
}

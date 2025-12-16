import Foundation

/// Immutable snapshot of compilation metrics.
///
/// Captures aggregate counts for a single compiler run. Values are 64-bit
/// integers (via `Int` on 64-bit platforms) to avoid overflow for large inputs.
public struct CompilationStats: Equatable, Sendable {
    /// Number of unique Hypercode files processed.
    public let numHypercodeFiles: Int

    /// Number of unique Markdown files embedded.
    public let numMarkdownFiles: Int

    /// Total bytes read from all input files (Hypercode + Markdown).
    public let totalInputBytes: Int

    /// Total bytes produced (compiled Markdown + manifest JSON).
    public let totalOutputBytes: Int

    /// Maximum depth encountered in the resolved AST.
    public let maxDepth: Int

    /// Elapsed wall-clock time in milliseconds for the compilation pipeline.
    public let durationMs: Int

    public init(
        numHypercodeFiles: Int,
        numMarkdownFiles: Int,
        totalInputBytes: Int,
        totalOutputBytes: Int,
        maxDepth: Int,
        durationMs: Int
    ) {
        self.numHypercodeFiles = numHypercodeFiles
        self.numMarkdownFiles = numMarkdownFiles
        self.totalInputBytes = totalInputBytes
        self.totalOutputBytes = totalOutputBytes
        self.maxDepth = maxDepth
        self.durationMs = durationMs
    }
}

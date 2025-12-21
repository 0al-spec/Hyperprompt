import Core

/// Compilation options for EditorEngine.
public struct CompileOptions {
    /// Compilation mode (strict or lenient).
    public let mode: CompilerArguments.CompilationMode

    /// Optional workspace root for resolution.
    public let workspaceRoot: String?

    /// Optional output path override.
    public let outputPath: String?

    /// Optional manifest path override.
    public let manifestPath: String?

    /// Whether to include manifest output in results.
    public let emitManifest: Bool

    /// Whether to collect and return compilation statistics.
    public let collectStats: Bool

    /// Whether to write output files to disk.
    public let writeOutput: Bool

    /// Create compile options with defaults matching CLI behavior.
    public init(
        mode: CompilerArguments.CompilationMode = .strict,
        workspaceRoot: String? = nil,
        outputPath: String? = nil,
        manifestPath: String? = nil,
        emitManifest: Bool = true,
        collectStats: Bool = false,
        writeOutput: Bool = false
    ) {
        self.mode = mode
        self.workspaceRoot = workspaceRoot
        self.outputPath = outputPath
        self.manifestPath = manifestPath
        self.emitManifest = emitManifest
        self.collectStats = collectStats
        self.writeOutput = writeOutput
    }

    /// Default options (strict, no disk writes, no stats).
    public static let `default` = CompileOptions()
}

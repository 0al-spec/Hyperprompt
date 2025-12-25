#if Editor
import Core

/// Compilation options for EditorEngine.
public struct CompileOptions: Sendable {
    /// Compilation mode (strict or lenient).
    public let mode: CompilerArguments.CompilationMode

    /// Optional workspace root for resolution.
    public let workspaceRoot: String?

    /// Optional output path override.
    public let outputPath: String?

    /// Optional manifest path override.
    public let manifestPath: String?

    /// Manifest output policy.
    public let manifestPolicy: ManifestPolicy

    /// Statistics output policy.
    public let statisticsPolicy: StatisticsPolicy

    /// Output write policy.
    public let outputWritePolicy: OutputWritePolicy

    /// Create compile options with defaults matching CLI behavior.
    public init(
        mode: CompilerArguments.CompilationMode = .strict,
        workspaceRoot: String? = nil,
        outputPath: String? = nil,
        manifestPath: String? = nil,
        manifestPolicy: ManifestPolicy = .include,
        statisticsPolicy: StatisticsPolicy = .omit,
        outputWritePolicy: OutputWritePolicy = .dryRun
    ) {
        self.mode = mode
        self.workspaceRoot = workspaceRoot
        self.outputPath = outputPath
        self.manifestPath = manifestPath
        self.manifestPolicy = manifestPolicy
        self.statisticsPolicy = statisticsPolicy
        self.outputWritePolicy = outputWritePolicy
    }

    /// Default options (strict, no disk writes, no stats).
    public static let `default` = CompileOptions()
}
#endif

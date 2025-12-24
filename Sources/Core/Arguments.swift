/// Parsed command-line arguments passed to the compiler driver.
/// This struct contains all arguments needed for compilation pipeline.
public struct CompilerArguments {
    /// Path to root .hc file to compile
    public let input: String

    /// Path to output Markdown file
    public let output: String

    /// Path to output manifest JSON file
    public let manifest: String

    /// Root directory for resolving file references
    public let root: String

    /// Compilation mode (strict or lenient for missing references)
    public let mode: CompilationMode

    /// Enable verbose logging
    public let verbose: Bool

    /// Collect and report compilation statistics
    public let stats: Bool

    /// Validate without writing output files
    public let dryRun: Bool

    /// Compilation mode determines how missing file references are handled
    public enum CompilationMode: Sendable {
        /// Strict mode: missing file references cause compilation failure (exit code 3)
        case strict
        /// Lenient mode: missing file references are treated as inline text
        case lenient
    }

    /// Initialize CompilerArguments with all required values.
    ///
    /// - Parameters:
    ///   - input: Path to root .hc file to compile
    ///   - output: Path to output Markdown file
    ///   - manifest: Path to output manifest JSON file
    ///   - root: Root directory for resolving file references
    ///   - mode: Compilation mode (strict or lenient)
    ///   - verbose: Enable verbose logging
    ///   - stats: Collect and report compilation statistics
    ///   - dryRun: Validate without writing output files
    public init(
        input: String,
        output: String,
        manifest: String,
        root: String,
        mode: CompilationMode,
        verbose: Bool,
        stats: Bool,
        dryRun: Bool
    ) {
        self.input = input
        self.output = output
        self.manifest = manifest
        self.root = root
        self.mode = mode
        self.verbose = verbose
        self.stats = stats
        self.dryRun = dryRun
    }
}

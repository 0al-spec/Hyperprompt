import ArgumentParser
import Core

/// Main command for the Hyperprompt compiler.
/// Compiles Hypercode (.hc) sources into unified Markdown documents.
@main
struct Hyperprompt: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hyperprompt",
        abstract: "Compile Hypercode to Markdown with manifest generation",
        version: "0.1.0"
    )

    // MARK: - Positional Arguments

    /// Path to root .hc file to compile (required)
    @Argument(help: "Path to root .hc file to compile")
    var input: String

    // MARK: - Optional Arguments

    /// Output Markdown file path (optional, default: out.md)
    @Option(name: .shortAndLong, help: "Output Markdown file (default: out.md)")
    var output: String?

    /// Output manifest JSON file path (optional, default: manifest.json)
    @Option(name: .shortAndLong, help: "Output manifest JSON file (default: manifest.json)")
    var manifest: String?

    /// Root directory for resolving file references (optional, default: current directory)
    @Option(name: .shortAndLong, help: "Root directory for file resolution (default: .)")
    var root: String?

    // MARK: - Mode Flags (Mutually Exclusive)

    /// Lenient mode: treat missing file references as inline text (mutually exclusive with strict)
    @Flag(help: "Treat missing file references as inline text")
    var lenient: Bool = false

    // MARK: - Action Flags

    /// Enable verbose logging output
    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false

    /// Collect and report compilation statistics
    @Flag(help: "Collect and report compilation statistics")
    var stats: Bool = false

    /// Validate compilation without writing output files
    @Flag(help: "Validate without writing output files")
    var dryRun: Bool = false

    // MARK: - Run Method

    mutating func run() throws {
        // Validation: strict and lenient are mutually exclusive
        // Note: strict mode is implicit (default) when lenient is false
        // Currently no explicit --strict flag needed; just ensure lenient flag exists

        // Set defaults for optional arguments
        let outputPath = output ?? "out.md"
        let manifestPath = manifest ?? "manifest.json"
        let rootPath = root ?? "."

        // Create CompilerArguments struct for passing to driver (D2)
        let args = CompilerArguments(
            input: input,
            output: outputPath,
            manifest: manifestPath,
            root: rootPath,
            mode: lenient ? .lenient : .strict,
            verbose: verbose,
            stats: stats,
            dryRun: dryRun
        )

        // TODO: In task D2 (Compiler Driver), invoke compiler with args
        // For now, just display parsed arguments if verbose
        if verbose {
            printParsedArguments(args)
        }
    }

    /// Helper function to display parsed arguments (for debugging/verbose mode)
    private func printParsedArguments(_ args: CompilerArguments) {
        let mode = args.mode == .strict ? "strict" : "lenient"
        print("Hyperprompt Compiler v0.1")
        print("─────────────────────────────────────────")
        print("Input file:      \(args.input)")
        print("Output file:     \(args.output)")
        print("Manifest file:   \(args.manifest)")
        print("Root directory:  \(args.root)")
        print("Mode:            \(mode)")
        print("Verbose:         \(args.verbose)")
        print("Statistics:      \(args.stats)")
        print("Dry run:         \(args.dryRun)")
        print("─────────────────────────────────────────")
    }
}

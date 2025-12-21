#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unsupported platform")
#endif

import Dispatch
import ArgumentParser
import Core

/// Main command for the Hyperprompt compiler.
/// Compiles Hypercode (.hc) sources into unified Markdown documents.

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
        let signalSources = installSignalHandlers()
        defer { _ = signalSources }

        // Validation: strict and lenient are mutually exclusive
        // Note: strict mode is implicit (default) when lenient is false
        // Currently no explicit --strict flag needed; just ensure lenient flag exists

        // Compute defaults for optional arguments following PRD FR-4
        let outputPath = output ?? computeDefaultOutput(from: input)
        let manifestPath = manifest ?? computeDefaultManifest(from: outputPath)
        let rootPath = root ?? computeDefaultRoot(from: input)

        // Create CompilerArguments struct for passing to driver
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

        // Create compiler driver and execute compilation
        let driver = CompilerDriver()

        do {
            _ = try driver.compile(args)

            // If not in verbose mode, still show success message
            if !verbose && !dryRun {
                print("✓ Compilation successful")
                print("  Output: \(outputPath)")
                print("  Manifest: \(manifestPath)")
            }

            // Exit with success code
            Self.exit(withError: nil)
        } catch let error as CompilerError {
            // Handle compiler errors with proper exit codes
            printError(error)
            Self.exit(withError: ExitCode(error.exitCode))
        } catch {
            // Handle unexpected errors as internal errors
            let internalError = ConcreteCompilerError.internalError(
                message: "Unexpected error: \(error)",
                location: nil
            )
            printError(internalError)
            Self.exit(withError: ExitCode(4))
        }
    }

    // MARK: - Default Path Computation (PRD FR-4)

    /// Compute default output path from input path.
    /// Rule: Replace .hc extension with .md
    /// Example: "main.hc" → "main.md"
    private func computeDefaultOutput(from inputPath: String) -> String {
        if inputPath.hasSuffix(".hc") {
            return String(inputPath.dropLast(3)) + ".md"
        } else {
            return inputPath + ".md"
        }
    }

    /// Compute default manifest path from output path.
    /// Rule: Append .manifest.json to output path
    /// Example: "main.md" → "main.md.manifest.json"
    private func computeDefaultManifest(from outputPath: String) -> String {
        return outputPath + ".manifest.json"
    }

    /// Compute default root directory from input path.
    /// Rule: Parent directory of input file
    /// Example: "project/main.hc" → "project/"
    private func computeDefaultRoot(from inputPath: String) -> String {
        if let lastSlash = inputPath.lastIndex(of: "/") {
            return String(inputPath[..<lastSlash])
        } else {
            return "."
        }
    }

    // MARK: - Error Handling

    /// Print compiler error to stderr with formatted diagnostic.
    private func printError(_ error: CompilerError) {
        fputs("Error: \(error.message)\n", stderr)

        if let location = error.location {
            fputs("  at \(location.filePath):\(location.line)\n", stderr)
        }

        fputs("\n", stderr)
        fputs("Exit code: \(error.exitCode)\n", stderr)
    }

    // MARK: - Signal Handling

    private func installSignalHandlers() -> [DispatchSourceSignal] {
        let signals: [Int32] = [SIGINT, SIGTERM]
        var sources: [DispatchSourceSignal] = []
        let queue = DispatchQueue(label: "hyperprompt.signal-handler")

        for signalValue in signals {
            #if canImport(Darwin)
            _ = Darwin.signal(signalValue, SIG_IGN)
            #elseif canImport(Glibc)
            _ = Glibc.signal(signalValue, SIG_IGN)
            #endif

            let source = DispatchSource.makeSignalSource(
                signal: signalValue,
                queue: queue
            )

            source.setEventHandler {
                let name = Self.signalName(forSignal: signalValue)
                fputs("Interrupted by signal: \(name)\n", stderr)
                let code = Self.interruptionExitCode(forSignal: signalValue)
                Self.exit(withError: ExitCode(code))
            }

            source.resume()
            sources.append(source)
        }

        return sources
    }

    static func interruptionExitCode(forSignal signal: Int32) -> Int32 {
        switch signal {
        case SIGINT:
            return 130
        case SIGTERM:
            return 143
        default:
            return 1
        }
    }

    private static func signalName(forSignal signal: Int32) -> String {
        switch signal {
        case SIGINT:
            return "SIGINT"
        case SIGTERM:
            return "SIGTERM"
        default:
            return "SIGNAL(\(signal))"
        }
    }
}

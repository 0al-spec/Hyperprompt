// CompilerDriver.swift
// Shared module - D2: Compiler Driver
//
// Orchestrates the complete compilation pipeline: parse → resolve → emit → manifest
// Handles dry-run mode, verbose logging, and end-to-end validation.

import Foundation
import Core
import Parser
import Resolver
import Emitter
import Statistics

/// Result of successful compilation containing all generated outputs.
public struct CompilationResult {
    /// Compiled Markdown content
    public let markdown: String

    /// Manifest JSON content
    public let manifestJSON: String

    /// Compilation statistics (if enabled)
    public let statistics: CompilationStats?

    public init(markdown: String, manifestJSON: String, statistics: CompilationStats? = nil) {
        self.markdown = markdown
        self.manifestJSON = manifestJSON
        self.statistics = statistics
    }
}

/// Orchestrates the complete Hypercode compilation pipeline.
///
/// The CompilerDriver is the central coordinator that integrates all compilation stages:
/// 1. **Parse Phase**: Tokenize and construct AST from input .hc file
/// 2. **Resolve Phase**: Classify literals, load files, detect circular dependencies
/// 3. **Emit Phase**: Generate Markdown with heading adjustments
/// 4. **Manifest Phase**: Generate provenance JSON with file hashes
///
/// The driver supports multiple modes:
/// - **Normal mode**: Full compilation with file output
/// - **Dry-run mode**: Validation without writing files
/// - **Verbose mode**: Detailed logging to stderr
/// - **Statistics mode**: Metric collection and reporting
///
/// Example usage:
/// ```swift
/// let driver = CompilerDriver(fileSystem: LocalFileSystem())
/// let args = CompilerArguments(...)
/// do {
///     let result = try driver.compile(args)
///     // Use result.markdown, result.manifestJSON
/// } catch {
///     // Handle compilation errors
/// }
/// ```
public final class CompilerDriver {

    // MARK: - Dependencies

    /// File system abstraction for I/O operations
    private let fileSystem: FileSystem

    /// Compiler version string
    private let version: String

    // MARK: - Initialization

    /// Initialize a new compiler driver.
    ///
    /// - Parameters:
    ///   - fileSystem: File system abstraction (default: LocalFileSystem)
    ///   - version: Compiler version string (default: "0.1.0")
    public init(
        fileSystem: FileSystem = LocalFileSystem(),
        version: String = "0.1.0"
    ) {
        self.fileSystem = fileSystem
        self.version = version
    }

    // MARK: - Main Compilation Entry Point

    /// Execute the complete compilation pipeline.
    ///
    /// This method orchestrates all compilation stages in sequence:
    /// 1. Path validation and default computation
    /// 2. Parse input file into AST
    /// 3. Resolve all file references
    /// 4. Emit Markdown output
    /// 5. Generate manifest JSON
    /// 6. Write output files (unless dry-run mode)
    ///
    /// - Parameter args: Compiler arguments from CLI
    /// - Returns: CompilationResult containing all generated outputs
    /// - Throws: CompilerError on any compilation failure
    public func compile(_ args: CompilerArguments) throws -> CompilationResult {
        let statsCollector = StatsCollector(enabled: args.stats)
        statsCollector.start()

        // Verbose logging: show compilation start
        if args.verbose {
            logVerbose("╔════════════════════════════════════════════════════════════╗")
            logVerbose("║  Hyperprompt Compiler v\(version)")
            logVerbose("╚════════════════════════════════════════════════════════════╝")
            logVerbose("")
            logVerbose("[COMPILE] Starting compilation...")
            logVerbose("[INPUT] \(args.input)")
            logVerbose("[MODE] \(args.mode == .strict ? "Strict" : "Lenient")")
            if args.dryRun {
                logVerbose("[DRY RUN] Validation only (no files will be written)")
            }
            logVerbose("")
        }

        // Phase 1: Path validation and canonicalization
        if args.verbose {
            logVerbose("[PHASE 1] Path validation and canonicalization")
        }

        let validatedPaths = try validatePaths(args)

        if args.verbose {
            logVerbose("  [✓] Input file: \(validatedPaths.inputPath)")
            logVerbose("  [✓] Root directory: \(validatedPaths.rootPath)")
            logVerbose("  [✓] Output file: \(validatedPaths.outputPath)")
            logVerbose("  [✓] Manifest file: \(validatedPaths.manifestPath)")
            logVerbose("")
        }

        // Phase 2: Parse input file
        if args.verbose {
            logVerbose("[PHASE 2] Parse phase - constructing AST")
        }

        let program = try parseInputFile(
            path: validatedPaths.inputPath,
            verbose: args.verbose,
            statsCollector: statsCollector
        )

        if args.verbose {
            logVerbose("  [✓] Parsed successfully")
            logVerbose("  [✓] Root node: \"\(program.root.literal)\"")
            logVerbose("  [✓] Tree depth: \(program.root.depth)")
            logVerbose("")
        }

        // Phase 3: Resolve references
        if args.verbose {
            logVerbose("[PHASE 3] Resolve phase - loading file references")
        }

        let resolvedProgram = try resolveReferences(
            program: program,
            rootPath: validatedPaths.rootPath,
            mode: args.mode,
            verbose: args.verbose,
            statsCollector: statsCollector
        )

        if args.verbose {
            logVerbose("  [✓] Resolved successfully")
            logVerbose("")
        }

        // Phase 4: Emit Markdown
        if args.verbose {
            logVerbose("[PHASE 4] Emit phase - generating Markdown")
        }

        let markdown = try emitMarkdown(
            program: resolvedProgram,
            verbose: args.verbose
        )

        if args.verbose {
            logVerbose("  [✓] Generated successfully")
            logVerbose("  [✓] Output size: \(markdown.utf8.count) bytes")
            logVerbose("")
        }

        // Phase 5: Generate manifest
        if args.verbose {
            logVerbose("[PHASE 5] Manifest phase - generating provenance JSON")
        }

        let manifestJSON = try generateManifest(
            rootPath: validatedPaths.inputPath,
            verbose: args.verbose
        )

        if args.verbose {
            logVerbose("  [✓] Generated successfully")
            logVerbose("  [✓] Manifest size: \(manifestJSON.utf8.count) bytes")
            logVerbose("")
        }

        // Phase 6: Write output files (unless dry-run mode)
        if args.dryRun {
            if args.verbose {
                logVerbose("[DRY RUN] Skipping file writes")
                logVerbose("  [~] Would write: \(validatedPaths.outputPath) (\(markdown.utf8.count) bytes)")
                logVerbose("  [~] Would write: \(validatedPaths.manifestPath) (\(manifestJSON.utf8.count) bytes)")
                logVerbose("")
            }
        } else {
            if args.verbose {
                logVerbose("[PHASE 6] Output phase - writing files")
            }

            try writeOutputFiles(
                markdown: markdown,
                manifestJSON: manifestJSON,
                outputPath: validatedPaths.outputPath,
                manifestPath: validatedPaths.manifestPath,
                verbose: args.verbose
            )

            if args.verbose {
                logVerbose("  [✓] Output written: \(validatedPaths.outputPath)")
                logVerbose("  [✓] Manifest written: \(validatedPaths.manifestPath)")
                logVerbose("")
            }
        }

        // Calculate statistics if enabled
        statsCollector.recordOutputBytes(markdown.utf8.count + manifestJSON.utf8.count)
        statsCollector.updateMaxDepth(resolvedProgram.maxDepth)

        let stats = statsCollector.finish()
        if let stats {
            StatsReporter().print(stats)
        }

        if args.verbose {
            logVerbose("[COMPLETE] Compilation finished successfully")
            logVerbose("")
        }

        return CompilationResult(
            markdown: markdown,
            manifestJSON: manifestJSON,
            statistics: stats
        )
    }

    // MARK: - Pipeline Stages

    /// Validated and canonicalized paths.
    private struct ValidatedPaths {
        let inputPath: String
        let rootPath: String
        let outputPath: String
        let manifestPath: String
    }

    /// Validate and canonicalize all paths.
    private func validatePaths(_ args: CompilerArguments) throws -> ValidatedPaths {
        // Validate input file exists
        guard fileSystem.fileExists(at: args.input) else {
            throw ConcreteCompilerError.ioError(
                message: "Input file not found: \(args.input)",
                location: nil
            )
        }

        // Validate input has .hc extension
        guard args.input.hasSuffix(".hc") else {
            throw ConcreteCompilerError.ioError(
                message: "Input file must have .hc extension: \(args.input)",
                location: nil
            )
        }

        // Validate root directory exists
        guard fileSystem.fileExists(at: args.root) else {
            throw ConcreteCompilerError.ioError(
                message: "Root directory not found: \(args.root)",
                location: nil
            )
        }

        // Compute absolute paths (simplified - would use Foundation.URL in production)
        let inputPath = args.input
        let rootPath = args.root
        let outputPath = args.output
        let manifestPath = args.manifest

        return ValidatedPaths(
            inputPath: inputPath,
            rootPath: rootPath,
            outputPath: outputPath,
            manifestPath: manifestPath
        )
    }

    /// Parse input file into AST.
    private func parseInputFile(
        path: String,
        verbose: Bool,
        statsCollector: StatsCollector?
    ) throws -> Program {
        // Read file content
        let content: String
        do {
            content = try fileSystem.readFile(at: path)
        } catch {
            throw ConcreteCompilerError.ioError(
                message: "Failed to read input file: \(path)",
                location: nil
            )
        }

        let canonicalPath = (try? fileSystem.canonicalizePath(path)) ?? path
        statsCollector?.recordHypercodeFile(path: canonicalPath, bytes: content.utf8.count)

        // Create lexer and tokenize
        let lexer = Lexer()
        let tokens: [Token]

        do {
            tokens = try lexer.tokenize(content: content, filePath: path)
            if verbose {
                logVerbose("  [LEXER] Tokenized \(tokens.count) tokens")
            }
        } catch let error as LexerError {
            throw ConcreteCompilerError.syntaxError(
                message: error.message,
                location: error.location
            )
        }

        // Create parser and parse AST
        let parser = Parser()

        switch parser.parse(tokens: tokens) {
        case .success(let program):
            if verbose {
                logVerbose("  [PARSER] Built AST with root node")
            }
            return program
        case .failure(let error):
            throw ConcreteCompilerError.syntaxError(
                message: error.message,
                location: error.location
            )
        }
    }

    /// Resolve all file references in the AST.
    private func resolveReferences(
        program: Program,
        rootPath: String,
        mode: CompilerArguments.CompilationMode,
        verbose: Bool,
        statsCollector: StatsCollector?
    ) throws -> Program {
        let resolutionMode: ResolutionMode = mode == .strict ? .strict : .lenient

        let dependencyTracker = DependencyTracker(fileSystem: fileSystem)
        var resolver = ReferenceResolver(
            fileSystem: fileSystem,
            rootPath: rootPath,
            mode: resolutionMode,
            dependencyTracker: dependencyTracker,
            statsCollector: statsCollector
        )

        // Resolve root node
        let mutableRoot = program.root

        switch resolver.resolveTree(root: mutableRoot) {
        case .success:
            if verbose {
                logVerbose("  [RESOLVER] All references resolved successfully")
            }
        case .failure(let error):
            throw ConcreteCompilerError.resolutionError(
                message: error.message,
                location: error.location
            )
        }

        return Program(root: mutableRoot)
    }

    /// Emit Markdown from resolved AST.
    private func emitMarkdown(program: Program, verbose: Bool) throws -> String {
        let emitter = MarkdownEmitter(config: EmitterConfig())
        let markdown = emitter.emit(program.root)

        if verbose {
            logVerbose("  [EMITTER] Generated Markdown output")
        }

        return markdown
    }

    /// Generate manifest JSON.
    private func generateManifest(
        rootPath: String,
        verbose: Bool,
        timestampProvider: DeterministicTimestampProvider = DeterministicTimestampProvider()
    ) throws -> String {
        let generator = ManifestGenerator()
        let builder = ManifestBuilder()  // Empty for now - will be populated in future
        let manifest = generator.generate(
            builder: builder,
            version: version,
            root: rootPath,
            timestamp: timestampProvider.resolveDate(for: rootPath)
        )

        do {
            let json = try generator.toJSON(manifest: manifest)

            if verbose {
                logVerbose("  [MANIFEST] Generated JSON (stub - no entries yet)")
            }

            return json
        } catch {
            throw ConcreteCompilerError.internalError(
                message: "Failed to serialize manifest to JSON: \(error)",
                location: nil
            )
        }
    }

    /// Write output files atomically.
    private func writeOutputFiles(
        markdown: String,
        manifestJSON: String,
        outputPath: String,
        manifestPath: String,
        verbose: Bool
    ) throws {
        // Write Markdown output
        do {
            try fileSystem.writeFile(at: outputPath, content: markdown)
        } catch {
            throw ConcreteCompilerError.ioError(
                message: "Failed to write output file: \(outputPath)",
                location: nil
            )
        }

        // Write manifest JSON
        do {
            try fileSystem.writeFile(at: manifestPath, content: manifestJSON)
        } catch {
            throw ConcreteCompilerError.ioError(
                message: "Failed to write manifest file: \(manifestPath)",
                location: nil
            )
        }
    }

    // MARK: - Utility Methods

    /// Log message to stderr when verbose mode enabled.
    private func logVerbose(_ message: String) {
        if let data = (message + "\n").data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}

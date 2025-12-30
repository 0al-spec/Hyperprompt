#if Editor
import CompilerDriver
import Core

/// EditorCompiler — Editor-facing wrapper around CompilerDriver.
public struct EditorCompiler {
    private let fileSystem: FileSystem
    private let version: String

    /// Create a new editor compiler.
    /// - Parameters:
    ///   - fileSystem: File system implementation (use MockFileSystem in tests)
    ///   - version: Compiler version string
    public init(fileSystem: FileSystem = LocalFileSystem(), version: String = "0.1.0") {
        self.fileSystem = fileSystem
        self.version = version
    }

    /// Compile an entry file with editor-friendly output and diagnostics.
    /// - Parameters:
    ///   - entryFile: Path to the root .hc file
    ///   - options: Compile options (defaults match CLI behavior)
    /// - Returns: CompileResult with output and diagnostics
    public func compile(entryFile: String, options: CompileOptions = .default) -> CompileResult {
        let outputPath = options.outputPath ?? computeDefaultOutput(from: entryFile)
        let manifestPath = options.manifestPath ?? computeDefaultManifest(from: outputPath)
        let rootPath = options.workspaceRoot ?? computeDefaultRoot(from: entryFile)
        let statsDecision = StatisticsPolicyDecisionSpec()
        let outputDecision = OutputWritePolicyDecisionSpec()

        let args = CompilerArguments(
            input: entryFile,
            output: outputPath,
            manifest: manifestPath,
            root: rootPath,
            mode: options.mode,
            verbose: false,
            stats: statsDecision.decide(options.statisticsPolicy) ?? false,
            dryRun: !(outputDecision.decide(options.outputWritePolicy) ?? false)
        )

        let driver = CompilerDriver(fileSystem: fileSystem, version: version)
        let manifestDecision = ManifestPolicyDecisionSpec()

        do {
            let result = try driver.compile(args)

            // Build stub source map (maps all output lines to entry file)
            // TODO: Enhance with full source tracking through Emitter
            let sourceMap = buildStubSourceMap(
                output: result.markdown,
                entryFile: entryFile
            )

            return CompileResult(
                output: result.markdown,
                diagnostics: [],
                manifest: (manifestDecision.decide(options.manifestPolicy) ?? false)
                    ? result.manifestJSON
                    : nil,
                statistics: (statsDecision.decide(options.statisticsPolicy) ?? false)
                    ? result.statistics
                    : nil,
                sourceMap: sourceMap
            )
        } catch let error as CompilerError {
            return CompileResult(
                output: nil,
                diagnostics: [error],
                manifest: nil,
                statistics: nil
            )
        } catch {
            let internalError = ConcreteCompilerError.internalError(
                message: "Unexpected error: \(error)",
                location: nil
            )
            return CompileResult(
                output: nil,
                diagnostics: [internalError],
                manifest: nil,
                statistics: nil
            )
        }
    }

    // MARK: - Default Path Computation (matches CLI)

    private func computeDefaultOutput(from inputPath: String) -> String {
        let decision = OutputPathStrategyDecisionSpec().decide(inputPath) ?? .appendMarkdownExtension
        switch decision {
        case .replaceHypercodeExtension:
            return String(inputPath.dropLast(3)) + ".md"
        case .appendMarkdownExtension:
            return inputPath + ".md"
        }
    }

    private func computeDefaultManifest(from outputPath: String) -> String {
        outputPath + ".manifest.json"
    }

    private func computeDefaultRoot(from inputPath: String) -> String {
        let decision = RootPathStrategyDecisionSpec().decide(inputPath) ?? .currentDirectory
        switch decision {
        case .parentDirectory:
            guard let lastSlash = inputPath.lastIndex(of: "/") else {
                return "."
            }
            return String(inputPath[..<lastSlash])
        case .currentDirectory:
            return "."
        }
    }

    // MARK: - Source Map Generation (Stub Implementation)

    /// Build stub source map that maps all output lines to entry file.
    ///
    /// This is a minimal implementation for VSC-10 (bidirectional navigation).
    /// TODO: Replace with full source tracking through Emitter to support multi-file navigation.
    ///
    /// - Parameters:
    ///   - output: Compiled markdown output
    ///   - entryFile: Path to entry .hc file
    /// - Returns: SourceMap with basic line mappings
    private func buildStubSourceMap(output: String?, entryFile: String) -> SourceMap? {
        guard let output = output, !output.isEmpty else {
            return nil
        }

        let builder = SourceMapBuilder()
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false)

        // Map each output line to corresponding line in entry file
        // This is approximate since we don't track actual source ranges yet
        // Note: outputLine is 0-indexed (array enumeration), but SourceLocation requires 1-indexed lines
        for (outputLine, _) in lines.enumerated() {
            let sourceLocation = SourceLocation(
                filePath: entryFile,
                line: outputLine + 1  // Convert 0-indexed to 1-indexed for source location
            )
            builder.addMapping(outputLine: outputLine, sourceLocation: sourceLocation)
        }

        return builder.build()
    }
}
#endif

import Core
import Foundation
import HypercodeGrammar
import Resolver
import SpecificationCore

/// Result of resolving a link span.
public struct ResolutionResult: Sendable {
    /// Resolved target classification.
    public let target: ResolvedTarget

    /// Diagnostics generated during resolution.
    public let diagnostics: [CompilerError]

    public init(target: ResolvedTarget, diagnostics: [CompilerError]) {
        self.target = target
        self.diagnostics = diagnostics
    }
}

/// EditorResolver — editor-facing wrapper around reference resolution rules.
public struct EditorResolver {
    private let fileSystem: FileSystem
    private let workspaceRoot: String?
    private let mode: ResolutionMode
    private let linkDecision = LinkLiteralDecisionSpec()
    private let rootDecision = RootEligibilityDecisionSpec()
    private let candidateDecision = CandidateResolutionDecisionSpec()
    private let outcomeDecision = ResolutionOutcomeDecisionSpec()

    /// Creates a new resolver instance.
    /// - Parameters:
    ///   - fileSystem: File system implementation (use MockFileSystem in tests)
    ///   - workspaceRoot: Optional explicit workspace root
    ///   - mode: Resolution mode (strict or lenient)
    public init(
        fileSystem: FileSystem = LocalFileSystem(),
        workspaceRoot: String? = nil,
        mode: ResolutionMode = .strict
    ) {
        self.fileSystem = fileSystem
        self.workspaceRoot = workspaceRoot
        self.mode = mode
    }

    /// Resolve a single link span.
    /// - Parameter link: LinkSpan to resolve
    /// - Returns: Resolution result including diagnostics
    public func resolve(link: LinkSpan) -> ResolutionResult {
        resolve(literal: link.literal, location: link.sourceLocation, sourceFile: link.sourceFile)
    }

    /// Resolve all link spans in a parsed file.
    /// - Parameter parsed: ParsedFile with link spans
    /// - Returns: Resolved targets and diagnostics
    public func resolveAll(parsed: ParsedFile) -> (targets: [ResolvedTarget], diagnostics: [CompilerError]) {
        var targets: [ResolvedTarget] = []
        var diagnostics: [CompilerError] = []

        for link in parsed.linkSpans {
            let result = resolve(link: link)
            targets.append(result.target)
            diagnostics.append(contentsOf: result.diagnostics)
        }

        return (targets: targets, diagnostics: diagnostics)
    }

    // MARK: - Internal Resolution

    private func resolve(literal: String, location: SourceLocation, sourceFile: String) -> ResolutionResult {
        let trimmed = literal.trimmingCharacters(in: .whitespaces)
        let ext = (trimmed as NSString).pathExtension.lowercased()
        let decision = linkDecision.decide(trimmed) ?? .inlineText
        switch decision {
        case .inlineText:
            return ResolutionResult(target: .inlineText, diagnostics: [])
        case .invalidTraversal:
            let error = ResolutionError.pathTraversal(path: trimmed, location: location)
            return ResolutionResult(target: .invalid(reason: error.message), diagnostics: [error])
        case .forbiddenExtension:
            let error = ResolutionError.forbiddenExtension(path: trimmed, ext: ".\(ext)", location: location)
            return ResolutionResult(target: .forbidden(extension: ext), diagnostics: [error])
        case .markdown, .hypercode:
            break
        }

        let roots = resolutionRoots(sourceFile: sourceFile)
        var candidatePaths: [String] = []
        var diagnostics: [CompilerError] = []

        for root in roots {
            let eligibility = rootDecision.decide(
                RootEligibilityContext(root: root, literal: trimmed, mode: mode)
            ) ?? .outOfRootLenient
            switch eligibility {
            case .eligible:
                break
            case .outOfRootStrict:
                let fullPath = joinPath(rootPath: root, relativePath: trimmed)
                let error = ResolutionError.outsideRoot(path: fullPath, root: root, location: location)
                diagnostics.append(error)
                continue
            case .outOfRootLenient:
                continue
            }

            let fullPath = joinPath(rootPath: root, relativePath: trimmed)
            let exists = fileSystem.fileExists(at: fullPath)
            let candidateContext = CandidateResolutionContext(exists: exists, mode: mode)
            let candidateDecision = candidateDecision.decide(candidateContext) ?? .missingLenient
            switch candidateDecision {
            case .found:
                candidatePaths.append(fullPath)
            case .missingStrict:
                diagnostics.append(ResolutionError.fileNotFound(path: trimmed, location: location))
            case .missingLenient:
                break
            }
        }

        let outcome = outcomeDecision.decide(
            ResolutionOutcomeContext(candidateCount: candidatePaths.count, mode: mode)
        ) ?? .unresolvedLenient

        switch outcome {
        case .ambiguous:
            let message = "Ambiguous reference: \(trimmed)\nCandidates:\n- " + candidatePaths.joined(separator: "\n- ")
            let error = ResolutionError(message: message, location: location)
            return ResolutionResult(
                target: .ambiguous(candidates: candidatePaths),
                diagnostics: [error]
            )
        case .resolved:
            guard let candidate = candidatePaths.first else {
                let reason = diagnostics.first?.message ?? "Unresolved reference"
                return ResolutionResult(target: .invalid(reason: reason), diagnostics: diagnostics)
            }
            let target: ResolvedTarget
            switch decision {
            case .markdown:
                target = .markdownFile(path: candidate)
            case .hypercode:
                target = .hypercodeFile(path: candidate)
            case .inlineText, .invalidTraversal, .forbiddenExtension:
                target = .inlineText
            }
            return ResolutionResult(target: target, diagnostics: [])
        case .unresolvedLenient:
            return ResolutionResult(target: .inlineText, diagnostics: [])
        case .unresolvedStrict:
            let reason = diagnostics.first?.message ?? "Unresolved reference"
            return ResolutionResult(target: .invalid(reason: reason), diagnostics: diagnostics)
        }
    }

    private func resolutionRoots(sourceFile: String) -> [String] {
        let rawRoots = [
            workspaceRoot ?? "",
            (sourceFile as NSString).deletingLastPathComponent,
            fileSystem.currentDirectory()
        ]
        let nonEmptySpec = PredicateSpec<String>(description: "Non-empty root") { root in
            !root.isEmpty
        }
        let roots = rawRoots
            .filter { nonEmptySpec.isSatisfiedBy($0) }
            .map(normalizePath)

        var seen = Set<String>()
        let uniquenessSpec = PredicateSpec<String>(description: "Unique root") { root in
            if seen.contains(root) {
                return false
            }
            seen.insert(root)
            return true
        }
        return roots.filter { uniquenessSpec.isSatisfiedBy($0) }
    }

    private func normalizePath(_ path: String) -> String {
        URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL.path
    }

    private func joinPath(rootPath: String, relativePath: String) -> String {
        if relativePath.hasPrefix("/") {
            return relativePath
        }
        if rootPath.hasSuffix("/") {
            return rootPath + relativePath
        }
        return rootPath + "/" + relativePath
    }
}

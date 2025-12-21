import Core
import Foundation
import HypercodeGrammar
import Resolver

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

    private let linkSpec = LooksLikeFileReferenceSpec()
    private let traversalSpec = NoTraversalSpec()

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

        guard linkSpec.isSatisfiedBy(trimmed) else {
            return ResolutionResult(target: .inlineText, diagnostics: [])
        }

        guard traversalSpec.isSatisfiedBy(trimmed) else {
            let error = ResolutionError.pathTraversal(path: trimmed, location: location)
            return ResolutionResult(target: .invalid(reason: error.message), diagnostics: [error])
        }

        let ext = (trimmed as NSString).pathExtension.lowercased()
        if !ext.isEmpty && ext != "md" && ext != "hc" {
            let error = ResolutionError.forbiddenExtension(path: trimmed, ext: ".\(ext)", location: location)
            return ResolutionResult(target: .forbidden(extension: ext), diagnostics: [error])
        }

        if ext.isEmpty {
            return ResolutionResult(target: .inlineText, diagnostics: [])
        }

        let roots = resolutionRoots(sourceFile: sourceFile)
        var candidatePaths: [String] = []
        var diagnostics: [CompilerError] = []

        for root in roots {
            let withinRoot = WithinRootSpec(rootPath: root).isSatisfiedBy(trimmed)
            if !withinRoot {
                if mode == .strict {
                    let fullPath = joinPath(rootPath: root, relativePath: trimmed)
                    let error = ResolutionError.outsideRoot(path: fullPath, root: root, location: location)
                    diagnostics.append(error)
                }
                continue
            }

            let fullPath = joinPath(rootPath: root, relativePath: trimmed)
            if fileSystem.fileExists(at: fullPath) {
                candidatePaths.append(fullPath)
            } else if mode == .strict {
                diagnostics.append(ResolutionError.fileNotFound(path: trimmed, location: location))
            }
        }

        if candidatePaths.count > 1 {
            let message = "Ambiguous reference: \(trimmed)\nCandidates:\n- " + candidatePaths.joined(separator: "\n- ")
            let error = ResolutionError(message: message, location: location)
            return ResolutionResult(
                target: .ambiguous(candidates: candidatePaths),
                diagnostics: [error]
            )
        }

        if let candidate = candidatePaths.first {
            let target: ResolvedTarget = (ext == "md")
                ? .markdownFile(path: candidate)
                : .hypercodeFile(path: candidate)
            return ResolutionResult(target: target, diagnostics: [])
        }

        switch mode {
        case .lenient:
            return ResolutionResult(target: .inlineText, diagnostics: [])
        case .strict:
            let reason = diagnostics.first?.message ?? "Unresolved reference"
            return ResolutionResult(target: .invalid(reason: reason), diagnostics: diagnostics)
        }
    }

    private func resolutionRoots(sourceFile: String) -> [String] {
        var roots: [String] = []

        if let workspaceRoot, !workspaceRoot.isEmpty {
            roots.append(normalizePath(workspaceRoot))
        }

        if !sourceFile.isEmpty {
            let directory = (sourceFile as NSString).deletingLastPathComponent
            if !directory.isEmpty {
                roots.append(normalizePath(directory))
            }
        }

        let cwd = fileSystem.currentDirectory()
        if !cwd.isEmpty {
            roots.append(normalizePath(cwd))
        }

        var seen = Set<String>()
        return roots.filter { root in
            if seen.contains(root) {
                return false
            }
            seen.insert(root)
            return true
        }
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

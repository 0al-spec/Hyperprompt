import Foundation
import Core
import Emitter
import Parser

/// Immutable provenance snapshot for one compiler invocation.
struct CompilationProvenance {
    let rootSource: String
    let sources: [ManifestEntry]
    let dependencies: [ManifestDependency]
}

/// Collects physical source and include provenance from a fully resolved AST.
///
/// Collection happens after resolution on every invocation, including parsed
/// program cache hits. This keeps the manifest scoped to the current build
/// rather than inheriting process-wide cache state.
struct CompilationProvenanceCollector {
    private let fileSystem: FileSystem
    private let fileLoader: FileLoader

    init(fileSystem: FileSystem) {
        self.fileSystem = fileSystem
        self.fileLoader = FileLoader(fileSystem: fileSystem)
    }

    func collect(program: Program, inputPath: String, rootPath: String) throws
        -> CompilationProvenance
    {
        let canonicalRoot = try fileSystem.canonicalizePath(rootPath)
        let canonicalInput = try fileSystem.canonicalizePath(inputPath)
        let rootSource = try relativePath(for: canonicalInput, under: canonicalRoot)

        var sourcesByPath: [String: ManifestEntry] = [:]
        var dependencies = Set<ManifestDependency>()

        func recordSource(_ canonicalPath: String) throws {
            let relative = try relativePath(for: canonicalPath, under: canonicalRoot)
            if sourcesByPath[relative] != nil {
                return
            }

            let loaded = try fileLoader.load(path: canonicalPath)
            sourcesByPath[relative] = ManifestEntry(
                path: relative,
                sha256: loaded.hash,
                size: loaded.content.utf8.count,
                type: loaded.metadata.type
            )
        }

        try recordSource(canonicalInput)

        for node in program.root.allDescendants() {
            let sourcePath = try canonicalSourcePath(
                node.location.filePath,
                canonicalRoot: canonicalRoot
            )
            if sourcePath.lowercased().hasSuffix(".hc") {
                try recordSource(sourcePath)
            }

            let targetReference: String?
            switch node.resolution {
            case .markdownFile(let path, _):
                targetReference = path
            case .hypercodeFile(let path, _):
                targetReference = path
            case .inlineText, .forbidden, nil:
                targetReference = nil
            }

            guard let targetReference else {
                continue
            }

            let targetPath = try canonicalTargetPath(
                targetReference,
                canonicalRoot: canonicalRoot
            )
            try recordSource(targetPath)

            let sourceRelative = try relativePath(for: sourcePath, under: canonicalRoot)
            let targetRelative = try relativePath(for: targetPath, under: canonicalRoot)
            dependencies.insert(
                ManifestDependency(from: sourceRelative, to: targetRelative)
            )
        }

        return CompilationProvenance(
            rootSource: rootSource,
            sources: sourcesByPath.values.sorted { $0.path < $1.path },
            dependencies: dependencies.sorted {
                ($0.from, $0.to) < ($1.from, $1.to)
            }
        )
    }

    private func canonicalSourcePath(_ path: String, canonicalRoot: String) throws -> String {
        guard !path.isEmpty else {
            throw provenanceError("Source location has an empty file path")
        }

        if isAbsolute(path) {
            return try fileSystem.canonicalizePath(path)
        }

        let rooted = join(canonicalRoot, path)
        if fileSystem.fileExists(at: rooted) {
            return try fileSystem.canonicalizePath(rooted)
        }
        return try fileSystem.canonicalizePath(path)
    }

    private func canonicalTargetPath(_ path: String, canonicalRoot: String) throws -> String {
        let candidate = isAbsolute(path) ? path : join(canonicalRoot, path)
        return try fileSystem.canonicalizePath(candidate)
    }

    private func relativePath(for path: String, under root: String) throws -> String {
        let canonicalPath = try fileSystem.canonicalizePath(path)
        let canonicalRoot = try fileSystem.canonicalizePath(root)
        let pathComponents = URL(fileURLWithPath: canonicalPath).standardized.pathComponents
        let rootComponents = URL(fileURLWithPath: canonicalRoot).standardized.pathComponents

        guard pathComponents.starts(with: rootComponents),
              pathComponents.count > rootComponents.count
        else {
            throw provenanceError(
                "Compilation source is outside --root: \(canonicalPath)"
            )
        }

        return pathComponents
            .dropFirst(rootComponents.count)
            .joined(separator: "/")
    }

    private func join(_ base: String, _ component: String) -> String {
        let trimmedBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        let trimmedComponent = component.hasPrefix("/") ? String(component.dropFirst()) : component
        return "\(trimmedBase)/\(trimmedComponent)"
    }

    private func isAbsolute(_ path: String) -> Bool {
        NSString(string: path).isAbsolutePath
    }

    private func provenanceError(_ message: String) -> ConcreteCompilerError {
        .resolutionError(message: message, location: nil)
    }
}

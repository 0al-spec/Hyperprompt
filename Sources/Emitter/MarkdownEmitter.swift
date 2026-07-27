// MarkdownEmitter.swift
// Emitter module - C2: Markdown Emitter

import Core
import Foundation
import Parser

/// Configuration for Markdown emission behavior.
public struct EmitterConfig {
    /// Whether to insert blank lines between sibling nodes.
    public let insertBlankLines: Bool

    /// Whether to use filename (without path) as heading for file references.
    ///
    /// Retained for source compatibility. File-reference headings currently use
    /// the node literal exactly as earlier emitter versions did.
    public let useFilenameAsHeading: Bool

    public init(
        insertBlankLines: Bool = true,
        useFilenameAsHeading: Bool = false
    ) {
        self.insertBlankLines = insertBlankLines
        self.useFilenameAsHeading = useFilenameAsHeading
    }
}

/// Markdown and exact line provenance produced in the same emitter traversal.
public struct EmissionResult: Equatable, Sendable {
    public let markdown: String
    public let sourceMap: CompilationSourceMap

    public init(markdown: String, sourceMap: CompilationSourceMap) {
        self.markdown = markdown
        self.sourceMap = sourceMap
    }
}

/// Transforms a fully resolved AST into a Markdown document.
public struct MarkdownEmitter {
    private static let maxHeadingLevel = 6

    private let config: EmitterConfig
    private let headingAdjuster: HeadingAdjuster

    #if Editor
    private let legacySourceMapBuilder: SourceMapBuilder?
    #endif

    #if Editor
    public init(
        config: EmitterConfig = EmitterConfig(),
        sourceMapBuilder: SourceMapBuilder? = nil
    ) {
        self.config = config
        self.headingAdjuster = HeadingAdjuster()
        self.legacySourceMapBuilder = sourceMapBuilder
    }
    #else
    public init(config: EmitterConfig = EmitterConfig()) {
        self.config = config
        self.headingAdjuster = HeadingAdjuster()
    }
    #endif

    /// Emit Markdown while preserving the historical string-only API.
    public func emit(_ root: Node) -> String {
        emitWithSourceMap(root).markdown
    }

    /// Emit Markdown and a complete one-based source map in one traversal.
    public func emitWithSourceMap(_ root: Node) -> EmissionResult {
        var builder = MappedLineBuilder()
        emitNode(root, parentDepth: -1, output: &builder)

        let markdown = builder.buildMarkdown()
        let lineCount = markdown.reduce(into: 0) { count, character in
            if character == "\n" {
                count += 1
            }
        }
        precondition(
            builder.mappings.count == lineCount,
            "Emitter mappings must cover every generated Markdown line"
        )
        let sourceMap = CompilationSourceMap(
            outputSha256: ContentHasher.sha256Hex(markdown),
            mappings: builder.mappings
        )

        #if Editor
        if let legacySourceMapBuilder {
            for mapping in sourceMap.mappings {
                guard let source = mapping.source else {
                    continue
                }
                legacySourceMapBuilder.addMapping(
                    outputLine: mapping.generatedLine - 1,
                    sourceLocation: SourceLocation(
                        filePath: source.path,
                        line: source.startLine
                    )
                )
            }
        }
        #endif

        return EmissionResult(markdown: markdown, sourceMap: sourceMap)
    }

    // MARK: - Tree traversal

    private func emitNode(
        _ node: Node,
        parentDepth: Int,
        output: inout MappedLineBuilder
    ) {
        let effectiveDepth = parentDepth + 1
        assert(
            effectiveDepth <= 10,
            "Depth exceeds maximum of 10 (resolver should prevent this)"
        )

        let headingLevel = effectiveDepth + 1
        let isMarkdownInclude: Bool
        if case .markdownFile = node.resolution {
            isMarkdownInclude = true
        } else {
            isMarkdownInclude = false
        }

        if !isMarkdownInclude {
            let heading = generateHeading(text: node.literal, level: headingLevel)
            if !heading.isEmpty {
                output.appendLine(
                    heading,
                    kind: .hypercodeHeading,
                    source: CompilationSourceSpan(
                        path: node.location.filePath,
                        startLine: node.location.line,
                        endLine: node.location.line
                    )
                )
            }
        }

        let headingOffset = isMarkdownInclude ? effectiveDepth : headingLevel
        embedContent(for: node, headingOffset: headingOffset, output: &output)

        for (index, child) in node.children.enumerated() {
            if index > 0 && config.insertBlankLines {
                output.appendLine(
                    "",
                    kind: .generatedSeparator,
                    source: nil
                )
            }
            emitNode(child, parentDepth: effectiveDepth, output: &output)
        }
    }

    private func generateHeading(text: String, level: Int) -> String {
        if level > Self.maxHeadingLevel {
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "" : "**\(trimmed)**"
        }

        let hashes = String(repeating: "#", count: level)
        return text.isEmpty ? hashes : "\(hashes) \(text)"
    }

    // MARK: - Content embedding

    private func embedContent(
        for node: Node,
        headingOffset: Int,
        output: inout MappedLineBuilder
    ) {
        guard let resolution = node.resolution else {
            return
        }

        switch resolution {
        case .inlineText:
            break

        case let .markdownFile(path, content):
            let adjustment = headingAdjuster.adjustHeadingsWithOrigins(
                in: content,
                offset: headingOffset
            )
            let lines = emittedLines(from: adjustment.markdown)
            precondition(
                lines.count == adjustment.lineOrigins.count,
                "Heading adjustment line origins must cover every emitted line"
            )

            for index in lines.indices {
                let line = lines[index]
                let origin = adjustment.lineOrigins[index]
                output.appendLine(
                    line,
                    kind: .markdown,
                    source: CompilationSourceSpan(
                        path: path,
                        startLine: origin.startLine,
                        endLine: origin.endLine
                    )
                )
            }

        case .hypercodeFile:
            // The nested AST is already present in node.children.
            break

        case let .forbidden(fileExtension):
            // Resolver failures normally prevent this state. Keep the existing
            // diagnostic output deterministic for manually constructed ASTs.
            output.appendLine(
                "<!-- Error: Forbidden extension .\(fileExtension) -->",
                kind: .hypercodeHeading,
                source: CompilationSourceSpan(
                    path: node.location.filePath,
                    startLine: node.location.line,
                    endLine: node.location.line
                )
            )
        }
    }

    private func emittedLines(from markdown: String) -> [String] {
        guard !markdown.isEmpty else {
            return []
        }

        var lines = markdown.components(separatedBy: "\n")
        if lines.last == "" {
            lines.removeLast()
        }
        return lines
    }
}

private struct MappedLineBuilder {
    private(set) var lines: [String] = []
    private(set) var mappings: [CompilationSourceMapping] = []

    mutating func appendLine(
        _ line: String,
        kind: CompilationSourceMappingKind,
        source: CompilationSourceSpan?
    ) {
        lines.append(line)
        mappings.append(
            CompilationSourceMapping(
                generatedLine: lines.count,
                kind: kind,
                source: source
            )
        )
    }

    mutating func buildMarkdown() -> String {
        while mappings.last?.kind == .generatedSeparator {
            mappings.removeLast()
            lines.removeLast()
        }

        guard !lines.isEmpty else {
            return ""
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

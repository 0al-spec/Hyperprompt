import Foundation

/// Inclusive source span that produced one generated Markdown line.
public struct CompilationSourceSpan: Codable, Equatable, Sendable {
    public let path: String
    public let startLine: Int
    public let endLine: Int

    public init(path: String, startLine: Int, endLine: Int) {
        self.path = path
        self.startLine = startLine
        self.endLine = endLine
    }
}

/// The kind of compiler input that produced a generated Markdown line.
public enum CompilationSourceMappingKind: String, Codable, Equatable, Sendable {
    case hypercodeHeading = "hypercode_heading"
    case markdown
    case generatedSeparator = "generated_separator"
}

/// A one-based generated-line mapping.
public struct CompilationSourceMapping: Codable, Equatable, Sendable {
    public let generatedLine: Int
    public let kind: CompilationSourceMappingKind
    public let source: CompilationSourceSpan?

    public init(
        generatedLine: Int,
        kind: CompilationSourceMappingKind,
        source: CompilationSourceSpan?
    ) {
        self.generatedLine = generatedLine
        self.kind = kind
        self.source = source
    }

    private enum CodingKeys: String, CodingKey {
        case generatedLine
        case kind
        case source
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedLine = try container.decode(Int.self, forKey: .generatedLine)
        kind = try container.decode(CompilationSourceMappingKind.self, forKey: .kind)
        source = try container.decodeIfPresent(CompilationSourceSpan.self, forKey: .source)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(generatedLine, forKey: .generatedLine)
        try container.encode(kind, forKey: .kind)
        if let source {
            try container.encode(source, forKey: .source)
        } else {
            try container.encodeNil(forKey: .source)
        }
    }
}

/// Validation failures for a compilation source-map artifact.
public enum CompilationSourceMapError: Error, Equatable, CustomStringConvertible {
    case unsupportedSchemaVersion(Int)
    case invalidLineBase(Int)
    case outputHashMismatch
    case incompleteCoverage(expected: [Int], actual: [Int])
    case invalidSourceSpan(generatedLine: Int)
    case invalidSourcePath(generatedLine: Int, path: String)
    case invalidGeneratedMapping(generatedLine: Int)

    public var description: String {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return "Unsupported source-map schema version: \(version)"
        case let .invalidLineBase(lineBase):
            return "Source-map line base must be 1, got \(lineBase)"
        case .outputHashMismatch:
            return "Source-map output hash does not match generated Markdown"
        case let .incompleteCoverage(expected, actual):
            return "Source-map coverage mismatch: expected \(expected), got \(actual)"
        case let .invalidSourceSpan(generatedLine):
            return "Invalid source span for generated line \(generatedLine)"
        case let .invalidSourcePath(generatedLine, path):
            return "Invalid root-relative source path at generated line \(generatedLine): \(path)"
        case let .invalidGeneratedMapping(generatedLine):
            return "Generated separator at line \(generatedLine) must have a null source"
        }
    }
}

/// Versioned, deterministic provenance for generated Markdown lines.
public struct CompilationSourceMap: Codable, Equatable, Sendable {
    public let lineBase: Int
    public let mappings: [CompilationSourceMapping]
    public let outputSha256: String
    public let schemaVersion: Int

    public init(
        outputSha256: String,
        mappings: [CompilationSourceMapping],
        schemaVersion: Int = 1,
        lineBase: Int = 1
    ) {
        self.lineBase = lineBase
        self.mappings = mappings.sorted { lhs, rhs in
            lhs.generatedLine < rhs.generatedLine
        }
        self.outputSha256 = outputSha256
        self.schemaVersion = schemaVersion
    }

    /// Serialize with stable key ordering and exactly one trailing LF.
    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(
                self,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Source-map JSON is not valid UTF-8"
                )
            )
        }
        return json.trimmingCharacters(in: .newlines) + "\n"
    }

    /// Validate artifact invariants against the exact generated Markdown bytes.
    public func validate(for markdown: String) throws {
        guard schemaVersion == 1 else {
            throw CompilationSourceMapError.unsupportedSchemaVersion(schemaVersion)
        }
        guard lineBase == 1 else {
            throw CompilationSourceMapError.invalidLineBase(lineBase)
        }
        guard outputSha256 == ContentHasher.sha256Hex(markdown) else {
            throw CompilationSourceMapError.outputHashMismatch
        }

        let newlineCount = markdown.reduce(into: 0) { count, character in
            if character == "\n" {
                count += 1
            }
        }
        let lineCount = markdown.isEmpty
            ? 0
            : newlineCount + (markdown.hasSuffix("\n") ? 0 : 1)
        let expectedLines = lineCount == 0 ? [] : Array(1...lineCount)
        let actualLines = mappings.map(\.generatedLine)
        guard actualLines == expectedLines else {
            throw CompilationSourceMapError.incompleteCoverage(
                expected: expectedLines,
                actual: actualLines
            )
        }

        for mapping in mappings {
            if mapping.kind == .generatedSeparator {
                guard mapping.source == nil else {
                    throw CompilationSourceMapError.invalidGeneratedMapping(
                        generatedLine: mapping.generatedLine
                    )
                }
                continue
            }

            guard let source = mapping.source,
                  !source.path.isEmpty,
                  source.startLine >= 1,
                  source.endLine >= source.startLine
            else {
                throw CompilationSourceMapError.invalidSourceSpan(
                    generatedLine: mapping.generatedLine
                )
            }
            guard isRootRelativePOSIXPath(source.path) else {
                throw CompilationSourceMapError.invalidSourcePath(
                    generatedLine: mapping.generatedLine,
                    path: source.path
                )
            }
        }
    }

    private func isRootRelativePOSIXPath(_ path: String) -> Bool {
        guard !NSString(string: path).isAbsolutePath,
              !path.contains("\\")
        else {
            return false
        }

        let components = path.split(
            separator: "/",
            omittingEmptySubsequences: false
        )
        return !components.isEmpty && components.allSatisfy {
            !$0.isEmpty && $0 != "." && $0 != ".."
        }
    }
}

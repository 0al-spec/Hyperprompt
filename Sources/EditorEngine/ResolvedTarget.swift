import Core

/// Represents the resolution result for a link span.
public enum ResolvedTarget: Equatable, Sendable, Codable {
    /// Literal is not a file reference.
    case inlineText

    /// Literal resolves to a Markdown file path.
    case markdownFile(path: String)

    /// Literal resolves to a Hypercode file path.
    case hypercodeFile(path: String)

    /// Literal refers to a forbidden extension.
    case forbidden(extension: String)

    /// Literal is invalid or cannot be resolved.
    case invalid(reason: String)

    /// Literal resolves to multiple possible targets.
    case ambiguous(candidates: [String])

    // MARK: - Codable
    private enum CodingKeys: CodingKey {
        case type, path, fileExtension, reason, candidates
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "inlineText":
            self = .inlineText
        case "markdownFile":
            let path = try container.decode(String.self, forKey: .path)
            self = .markdownFile(path: path)
        case "hypercodeFile":
            let path = try container.decode(String.self, forKey: .path)
            self = .hypercodeFile(path: path)
        case "forbidden":
            let ext = try container.decode(String.self, forKey: .fileExtension)
            self = .forbidden(extension: ext)
        case "invalid":
            let reason = try container.decode(String.self, forKey: .reason)
            self = .invalid(reason: reason)
        case "ambiguous":
            let candidates = try container.decode([String].self, forKey: .candidates)
            self = .ambiguous(candidates: candidates)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .inlineText:
            try container.encode("inlineText", forKey: .type)
        case .markdownFile(let path):
            try container.encode("markdownFile", forKey: .type)
            try container.encode(path, forKey: .path)
        case .hypercodeFile(let path):
            try container.encode("hypercodeFile", forKey: .type)
            try container.encode(path, forKey: .path)
        case .forbidden(let ext):
            try container.encode("forbidden", forKey: .type)
            try container.encode(ext, forKey: .fileExtension)
        case .invalid(let reason):
            try container.encode("invalid", forKey: .type)
            try container.encode(reason, forKey: .reason)
        case .ambiguous(let candidates):
            try container.encode("ambiguous", forKey: .type)
            try container.encode(candidates, forKey: .candidates)
        }
    }
}

import Core

/// Represents the resolution result for a link span.
public enum ResolvedTarget: Equatable, Sendable {
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
}

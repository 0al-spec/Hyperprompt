/// File type enumeration for Hyperprompt source files.
///
/// Hyperprompt supports two types of source files:
/// - **Markdown** (.md): Content files that are embedded verbatim
/// - **Hypercode** (.hc): Structured files that are compiled recursively
///
/// This type is used for:
/// - File classification during reference resolution
/// - Manifest generation (tracking source file types)
/// - Validation (only .md and .hc extensions are allowed)
public enum FileType: String, Codable {
    /// Markdown file (.md extension)
    ///
    /// Markdown files are:
    /// - Embedded as content (no recursion)
    /// - Processed for heading adjustment
    /// - Included in manifest as "markdown" type
    case markdown = "markdown"

    /// Hypercode file (.hc extension)
    ///
    /// Hypercode files are:
    /// - Compiled recursively (parsed and resolved)
    /// - Merged into parent AST at appropriate depth
    /// - Included in manifest as "hypercode" type
    case hypercode = "hypercode"
}

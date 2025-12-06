/// Resolution mode for handling missing files.
///
/// Determines how the resolver handles file references that point
/// to non-existent files on disk.
///
/// - Note: CLI enforces mutual exclusivity: `--strict` XOR `--lenient`
/// - Default: `.strict`
public enum ResolutionMode: Equatable, Sendable {
    /// Strict mode: missing file → resolution error (exit code 3)
    ///
    /// Use this mode during production compilation to catch all
    /// broken file references early. Any missing file reference
    /// will halt compilation with an error.
    case strict

    /// Lenient mode: missing file → treat as inline text
    ///
    /// Use this mode for templates or documents with placeholder
    /// references. Missing files are silently treated as inline text,
    /// allowing compilation to proceed.
    case lenient
}

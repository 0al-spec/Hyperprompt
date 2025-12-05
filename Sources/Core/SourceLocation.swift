/// Represents a specific location in a source file for error reporting and diagnostics.
///
/// SourceLocation tracks the exact position in a source file where an error or event occurred,
/// enabling precise error messages and debugging information.
///
/// - Note: Line numbers are 1-indexed, matching standard editor conventions.
public struct SourceLocation: Equatable, CustomStringConvertible, Sendable {
    /// Absolute or relative file path.
    /// Can be empty for synthetic locations (e.g., compiler-generated nodes).
    public let filePath: String

    /// Line number (1-indexed).
    /// Must be >= 1 as line numbers start at 1 in standard editors.
    public let line: Int

    /// Initialize a source location with file path and line number.
    ///
    /// - Parameters:
    ///   - filePath: The file path (absolute or relative). Can be empty for synthetic locations.
    ///   - line: The line number (1-indexed). Must be >= 1.
    ///
    /// - Precondition: `line` must be >= 1
    public init(filePath: String, line: Int) {
        precondition(line >= 1, "Line number must be >= 1 (1-indexed)")
        self.filePath = filePath
        self.line = line
    }

    /// Formatted description in the form `<file>:<line>`.
    ///
    /// Examples:
    /// - `/path/to/file.hc:42`
    /// - `test.hc:1`
    /// - `:15` (empty file path)
    public var description: String {
        "\(filePath):\(line)"
    }
}

/// Protocol for all compiler errors with diagnostic information.
///
/// All error types in the compiler must conform to this protocol to ensure
/// consistent error handling, reporting, and exit code mapping.
///
/// Example implementation:
/// ```swift
/// struct SyntaxError: CompilerError {
///     let category: ErrorCategory = .syntax
///     let message: String
///     let location: SourceLocation?
/// }
/// ```
///
/// Example diagnostic output:
/// ```
/// Error [Syntax]: /path/to/file.hc:15
/// Tab characters are not allowed in indentation. Use 4 spaces per level.
/// ```
protocol CompilerError: Error {
    /// Error category (IO, Syntax, Resolution, Internal)
    var category: ErrorCategory { get }

    /// Human-readable error message explaining what went wrong
    var message: String { get }

    /// Source location where error occurred (nil for non-source errors)
    var location: SourceLocation? { get }

    /// Detailed diagnostic information formatted for display
    var diagnosticInfo: String { get }
}

extension CompilerError {
    /// Default implementation of diagnostic information.
    ///
    /// Formats the error with category, location (if available), and message.
    ///
    /// Format with location:
    /// ```
    /// Error [<Category>]: <location>
    /// <message>
    /// ```
    ///
    /// Format without location:
    /// ```
    /// Error [<Category>]: <message>
    /// ```
    var diagnosticInfo: String {
        if let location = location {
            return "Error [\(category.rawValue)]: \(location)\n\(message)"
        } else {
            return "Error [\(category.rawValue)]: \(message)"
        }
    }

    /// Exit code corresponding to this error's category.
    ///
    /// Convenience property that delegates to the category's exit code.
    var exitCode: Int32 {
        category.exitCode
    }
}

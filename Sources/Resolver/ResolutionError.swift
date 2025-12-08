import Core

/// Error type for resolution failures.
///
/// All resolution errors have category `.resolution` (exit code 3).
/// Errors include source location for precise error reporting.
public struct ResolutionError: CompilerError, Equatable {
    public let category: ErrorCategory = .resolution
    public let message: String
    public let location: SourceLocation?

    /// Create a resolution error with location.
    ///
    /// - Parameters:
    ///   - message: Human-readable error description
    ///   - location: Source location where the error occurred
    public init(message: String, location: SourceLocation?) {
        self.message = message
        self.location = location
    }

    // MARK: - Factory Methods

    /// Create error for file not found in strict mode.
    ///
    /// - Parameters:
    ///   - path: The file path that was not found
    ///   - location: Source location of the reference
    /// - Returns: ResolutionError for missing file
    public static func fileNotFound(path: String, location: SourceLocation) -> ResolutionError {
        ResolutionError(
            message: "File not found in strict mode: \(path)\n" +
                     "Suggestion: Create the file or use --lenient mode to treat as inline text.",
            location: location
        )
    }

    /// Create error for forbidden file extension.
    ///
    /// - Parameters:
    ///   - path: The file path with forbidden extension
    ///   - ext: The forbidden extension (e.g., ".json")
    ///   - location: Source location of the reference
    /// - Returns: ResolutionError for forbidden extension
    public static func forbiddenExtension(path: String, ext: String, location: SourceLocation) -> ResolutionError {
        ResolutionError(
            message: "Unsupported file extension '\(ext)' in: \(path)\n" +
                     "Only .md (Markdown) and .hc (Hypercode) files are allowed.",
            location: location
        )
    }

    /// Create error for path traversal attempt.
    ///
    /// - Parameters:
    ///   - path: The path containing traversal components
    ///   - location: Source location of the reference
    /// - Returns: ResolutionError for path traversal
    public static func pathTraversal(path: String, location: SourceLocation) -> ResolutionError {
        ResolutionError(
            message: "Path traversal detected: \(path)\n" +
                     "File references must not contain '..' components for security reasons.",
            location: location
        )
    }

    /// Create error for circular dependency.
    ///
    /// - Parameters:
    ///   - cyclePath: Array of file paths forming the cycle
    ///   - location: Source location of the reference that caused the cycle
    /// - Returns: ResolutionError for circular dependency
    ///
    /// ## Error Message Format
    ///
    /// ```
    /// Circular dependency detected
    ///   Cycle path: /root/a.hc → /root/b.hc → /root/c.hc → /root/a.hc
    /// ```
    ///
    /// The cycle path shows the complete chain of file references that form
    /// the circular dependency, making it easy to identify and fix the issue.
    public static func circularDependency(cyclePath: [String], location: SourceLocation) -> ResolutionError {
        let cycleDescription = cyclePath.joined(separator: " → ")
        return ResolutionError(
            message: "Circular dependency detected\n" +
                     "  Cycle path: \(cycleDescription)",
            location: location
        )
    }
}

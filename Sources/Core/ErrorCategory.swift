/// Categories of compiler errors mapped to exit codes.
///
/// Each error category corresponds to a specific exit code that the compiler
/// returns when encountering that type of error. This enables automation tools
/// and scripts to distinguish between different failure modes.
///
/// Exit Code Mapping:
/// - IO → Exit code 1 (file not found, permission denied, disk full)
/// - Syntax → Exit code 2 (invalid Hypercode syntax)
/// - Resolution → Exit code 3 (circular dependency, missing reference)
/// - Internal → Exit code 4 (unexpected condition, compiler bug)
enum ErrorCategory: String, CaseIterable {
    /// File system I/O errors (file not found, permission denied, disk full)
    case io = "IO"

    /// Invalid Hypercode syntax errors (unclosed quotes, misaligned indentation)
    case syntax = "Syntax"

    /// Reference resolution errors (circular dependency, missing reference in strict mode)
    case resolution = "Resolution"

    /// Internal compiler errors indicating bugs (unexpected conditions, assertion failures)
    case `internal` = "Internal"

    /// Exit code corresponding to this error category.
    ///
    /// Returns:
    /// - 1 for IO errors
    /// - 2 for Syntax errors
    /// - 3 for Resolution errors
    /// - 4 for Internal errors
    var exitCode: Int32 {
        switch self {
        case .io:
            return 1
        case .syntax:
            return 2
        case .resolution:
            return 3
        case .internal:
            return 4
        }
    }
}

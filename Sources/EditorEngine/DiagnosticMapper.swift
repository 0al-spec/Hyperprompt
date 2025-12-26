#if Editor
import Core

/// Maps compiler errors into editor diagnostics.
public enum DiagnosticMapper {
    /// Convert a compiler error into an editor diagnostic.
    public static func map(_ error: CompilerError) -> Diagnostic {
        let code = codeForCategory(error.category)
        let severity: DiagnosticSeverity = .error
        let range = rangeFromLocation(error.location)

        return Diagnostic(
            code: code,
            severity: severity,
            message: error.message,
            range: range
        )
    }

    /// Convert multiple compiler errors into diagnostics.
    public static func mapAll(_ errors: [CompilerError]) -> [Diagnostic] {
        errors.map { map($0) }
    }

    private static func codeForCategory(_ category: ErrorCategory) -> String {
        let base: Int
        switch category {
        case .syntax:
            base = 1
        case .resolution:
            base = 100
        case .io:
            base = 200
        case .internal:
            base = 900
        }
        return String(format: "E%03d", base)
    }

    private static func rangeFromLocation(_ location: SourceLocation?) -> SourceRange? {
        guard let location else {
            return nil
        }
        let start = SourcePosition(line: location.line, column: 1)
        let end = SourcePosition(line: location.line, column: 2)
        return SourceRange(start: start, end: end)
    }
}
#endif

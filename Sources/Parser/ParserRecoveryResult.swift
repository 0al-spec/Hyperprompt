/// Result of parsing with recovery (best-effort AST + diagnostics).
public struct ParserRecoveryResult {
    /// Best-effort program output. Nil when no valid root node exists.
    public let program: Program?

    /// Parser diagnostics collected during recovery.
    public let diagnostics: [ParserError]

    /// Creates a new recovery result.
    public init(program: Program?, diagnostics: [ParserError]) {
        self.program = program
        self.diagnostics = diagnostics
    }
}

# Spec-3 — Path Validation Specifications

**Version:** 1.0.0

## Status

✅ **COMPLETE** — All specifications implemented and tested (2025-12-11)

## Summary

Spec-3 implements file path validation specifications for identifying file references and enforcing security constraints. All 9 specifications (5 atomic + 4 composite/semantic) are implemented in the HypercodeGrammar module with comprehensive test coverage.

### Implemented Specifications

**Atomic Specs:**
1. `HasMarkdownExtensionSpec` — Detects `.md` suffix
2. `HasHypercodeExtensionSpec` — Detects `.hc` suffix
3. `ContainsPathSeparatorSpec` — Detects `/` or `\` separators
4. `ContainsExtensionDotSpec` — Detects `.` in filename (extension indicator)
5. `NoTraversalSpec` — Validates no `..` path traversal components

**Composite & Semantic Specs:**
1. `IsAllowedExtensionSpec` — Composite: `HasMarkdownExtensionSpec OR HasHypercodeExtensionSpec`
2. `LooksLikeFileReferenceSpec` — Heuristic: `ContainsExtensionDotSpec OR ContainsPathSeparatorSpec`
3. `WithinRootSpec` — Security: Validates path stays within configured root directory
4. `ValidReferencePathSpec` — Combined: `(NoTraversal AND WithinRoot) AND LooksLikeFileReference`

### Test Coverage

- **Location:** `Tests/HypercodeGrammarTests/HypercodeGrammarTests.swift`
- **Test Cases:** `testExtensionSpecifications()` (line 103), `testPathSafetySpecifications()` (line 114), `testPathTypeDecisionClassifiesPaths()` (line 127)
- **Edge Cases:** Various extensions, path traversal attempts, root boundary checks
- **Pass Rate:** 14/14 (100%)

### Files

**Implementation:**
- `Sources/HypercodeGrammar/Syntactic/References/ReferenceSpecs.swift` — Extension and heuristic specs
- `Sources/HypercodeGrammar/Semantic/Security/SecuritySpecs.swift` — NoTraversalSpec, WithinRootSpec
- `Sources/HypercodeGrammar/Semantic/Paths/PathSpecs.swift` — ValidReferencePathSpec

**Tests:**
- `Tests/HypercodeGrammarTests/HypercodeGrammarTests.swift:102-135` — PathSpecsTests

### Acceptance Criteria

✅ **All 9/9 met:**
- Extension specs correctly identify `.md` and `.hc` files
- Composite extension spec works (`IsAllowedExtensionSpec`)
- Path heuristic correctly identifies file-like references
- Security specs prevent traversal attacks (`..` detection)
- Root boundary enforcement prevents path escape
- All tests passing (100% pass rate)

### Architecture Notes

- Path safety as layered specifications: structure → security → combined validation
- `WithinRootSpec(rootPath: String)` uses URL standardization for cross-platform path handling
- `LooksLikeFileReferenceSpec` as heuristic: assumes file references have `.` (extension) or `/` (path separator)
- `ValidReferencePathSpec` demonstrates integration of security + structural rules
- Candidate type: `String` (paths as literals, not RawLine)

### Integration Points

**Used by:**
- `PathTypeDecision` in Phase 4 (Reference Resolution) for path classification
- B1 (Reference Resolver) for pre-validation before file operations
- Phase 7 (Lexer Integration) indirectly via Decision specs

### Next Steps

- Archive to TASKS_ARCHIVE/ as part of Phase 3 completion
- Integration in Phase 4 (B1 Reference Resolver) uses PathTypeDecision
- All Spec-3 tasks unblock Integration-2 (resolver integration)

---

**Archived:** 2025-12-11

# Integration-2 — Resolver with Specifications

**Version:** 1.0.0
**Date:** 2025-12-12
**Status:** Planning (PLAN output)
**Priority:** P1 (High)
**Effort:** 6 hours
**Phase:** Phase 7 — Integration (requires Phase 4 Resolver ✅ and Phase 3 Specs ✅)

---

## 1. Objective & Scope

- **Goal:** Refactor the ReferenceResolver to replace imperative path validation logic with SpecificationCore-based specifications and decision specs while preserving public API, resolution kinds, and observable behavior.
- **Primary Deliverables:**
  1. ReferenceResolver (`Sources/Resolver/ReferenceResolver.swift`) rewritten to classify and validate paths via specification objects (`NoTraversalSpec`, `IsAllowedExtensionSpec`, `ValidReferencePathSpec`, `PathTypeDecision`, `WithinRootSpec`, `LooksLikeFileReferenceSpec`).
  2. Updated error messaging that cites failed specifications where applicable.
  3. Automated tests proving parity with previous behavior plus specification-driven integration coverage.
  4. Performance check demonstrating <10% overhead versus imperative implementation.
- **Constraints & Assumptions:**
  - Must keep `ResolutionKind` cases, `ResolutionError` cases, and resolver-facing API stable.
  - Must respect dependency ordering: specification classes from Phase 3 are available and should not be modified.
  - Strict/lenient modes remain unchanged in API surface.
  - No new CLI flags are introduced; benchmarks may be ad-hoc scripts.

---

## 2. Context & Dependencies

- **Dependencies:** Completion of Phase 4 Resolver and Phase 3 Specifications (Workplan Phase 7 entry). Blocking tasks are resolved; work can proceed directly in Integration-2.
- **Motivation:** Current resolver embeds imperative checks in `containsPathTraversal()`, `fileExtension()`, `validateWithinRoot()`, and classification branching. This duplicates logic already formalized in specification classes and hinders reuse and testing.
- **Source Materials:**
  - `DOCS/Workplan.md` Phase 7: Integration-2 checklist and acceptance criteria.
  - Specification definitions from Spec-3/Spec-4 (Phase 3 outputs), including decision factory `HypercodeGrammar.makePathClassifier()`.
  - Existing resolver tests (20+ cases) and integration tests in `Tests/IntegrationTests/CompilerDriverTests.swift`.
  - ReferenceResolver implementation in `Sources/Resolver/ReferenceResolver.swift` (already using `LooksLikeFileReferenceSpec` partially).

---

## 3. Functional Requirements

1. **Path Reference Heuristic via Specification**
   - `looksLikeFilePath()` must rely on `LooksLikeFileReferenceSpec` (already integrated, verify continuation).
   - Invalid or undecidable paths must throw appropriate errors without altering ResolutionKind construction semantics.

2. **Path Traversal Validation**
   - Replace manual `..` detection with `NoTraversalSpec`.
   - Path traversal violations must map to existing `ResolutionError.pathTraversal`.

3. **Extension Validation**
   - Replace imperative extension checking with `IsAllowedExtensionSpec` (composite: `.md` OR `.hc`).
   - Use `HasMarkdownExtensionSpec` and `HasHypercodeExtensionSpec` for explicit type checking if needed.
   - Forbidden extensions must map to existing `ResolutionError.forbiddenExtension`.

4. **Root Directory Boundary**
   - Enforce `WithinRootSpec` when validating canonical paths.
   - Violations must map to existing `ResolutionError.outsideRoot`.

5. **Path Classification via Decision Spec**
   - Use `PathTypeDecision` (via `HypercodeGrammar.makePathClassifier()`) to classify paths as allowed, forbidden, or invalid where beneficial.
   - Maintain backward compatibility with imperative classification branches.

6. **Composite Validation**
   - Use `ValidReferencePathSpec` (composite: NoTraversal AND AllowedExtension) to ensure reference paths satisfy all rules before resolution.

7. **Error Messaging**
   - Error descriptions should reference the failed specification (e.g., "Failed `NoTraversalSpec`: path contains ..") while keeping error types unchanged.

8. **Testing & Backward Compatibility**
   - All existing resolver unit tests (20+) must pass unchanged.
   - Add integration tests demonstrating specification-driven validation and path classification parity with prior behavior.

---

## 4. Non-Functional Requirements

- **Performance:** Resolver refactor introduces <10% runtime overhead versus the imperative version when processing large file trees (≥100 files). Benchmark with `swift build --configuration release` or equivalent timing harness.
- **Code Quality:** No new compiler warnings; maintain or improve resolver-related coverage (>80%). Keep code readable with concise comments where specification usage is non-obvious.
- **Compatibility:** Public resolver API and `ResolutionKind` shapes remain stable; downstream emitter/compiler should observe identical outputs for valid/invalid inputs.

---

## 5. Structured TODO Plan

| Step | Description | Priority | Effort | Inputs | Process | Output/Acceptance |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Confirm current resolver behavior and tests | High | 0.5h | Existing resolver tests; `Sources/Resolver/ReferenceResolver.swift` | Run resolver unit tests to capture baseline; verify ~20 test cases | Baseline results documented; ensures parity target |
| 2 | Replace containsPathTraversal with spec | High | 0.75h | `NoTraversalSpec` | Swap imperative `..` check with spec evaluation; map failures to existing `pathTraversal` error | Path traversal validation delegated to spec; errors cite spec failure |
| 3 | Replace fileExtension with spec checks | High | 0.75h | `HasMarkdownExtensionSpec`, `HasHypercodeExtensionSpec`, `IsAllowedExtensionSpec` | Use spec(s) to validate extensions instead of manual string parsing; ensure forbidden extensions caught | Extension validation purely spec-driven; errors reference spec names |
| 4 | Enforce root boundary via spec | High | 0.5h | `WithinRootSpec` | Apply spec during `validateWithinRoot()` canonicalization; ensure violations raise existing `outsideRoot` error | Root boundary validation delegated to spec; tests updated if messaging changes |
| 5 | Integrate ValidReferencePathSpec | High | 0.75h | `ValidReferencePathSpec` (composite) | Use spec(s) to validate complete reference path (NoTraversal AND AllowedExtension) as composite gate | Reference path validation purely spec-driven; errors reference composite spec |
| 6 | Verify looksLikeFilePath continuation | Medium | 0.25h | `LooksLikeFileReferenceSpec` | Confirm existing heuristic usage is optimal; consider if PathTypeDecision improves classification | Heuristic usage verified/improved; no regressions |
| 7 | Update error messaging | Medium | 0.5h | Resolver error definitions | Adjust error descriptions to mention failed spec while keeping error types; ensure localized strings consistent | Error messages identify spec failures without API change |
| 8 | Add integration tests | High | 0.75h | Tests suite; Phase 3 specs | Add tests that assert specification classes drive outcomes (validation, classification, failures). Update/enable any skipped Integration-2 tests | New/updated tests passing and proving parity |
| 9 | Benchmark & regression sweep | Medium | 0.25h | Benchmark harness (adhoc) | Time resolver on large file tree before/after; ensure <10% overhead; rerun full test suite | Performance recorded; tests all green |

---

## 6. Acceptance Criteria & Verification

- **Specification Adoption:** All resolver validation paths use specification objects instead of imperative code; verified by code review and targeted tests.
- **Functional Parity:** All existing resolver tests (20+) pass without modification; previously skipped Integration-2 test cases are enabled or updated to match new error wording.
- **Error Clarity:** Error messages reference failed specs while preserving error types; confirmed through unit tests covering failure scenarios (traversal, extension, root boundary).
- **Performance:** Benchmark shows <10% runtime increase versus baseline on large file tree; document results in PR notes or comments.
- **Coverage:** Test additions maintain or increase coverage relative to pre-refactor baseline.

---

## 7. Risks & Mitigations

- **Risk:** Specification decisions alter path classification precedence.
  **Mitigation:** Write regression tests mirroring previous precedence; validate decision factory ordering.

- **Risk:** Error messages change in ways that break downstream expectations.
  **Mitigation:** Keep `ResolutionError` cases intact; gate message tweaks behind assertions in tests.

- **Risk:** Performance regression due to additional spec allocations.
  **Mitigation:** Reuse spec instances; profile and inline simple checks if overhead exceeds 10% threshold.

- **Risk:** Integration with PathTypeDecision adds complexity without clear benefit.
  **Mitigation:** Use decision spec selectively for complex branches; keep simple imperative code where it clarifies intent.

---

## 8. Execution Notes

- Prefer constructing spec instances once per resolver or per file to minimize allocations.
- Align naming with SpecCore classes; avoid duplicating validation logic already encoded in specs.
- Keep TODO checklist synchronized with Workplan Phase 7 entries when marking completion.
- Consider deprecating helper methods (e.g., `containsPathTraversal()`, `fileExtension()`) once internal callers migrate to specs.

---

## 9. Key Specifications to Integrate

### From HypercodeGrammar Module

1. **NoTraversalSpec** — Detects `..` path components
   - Method: `isSatisfiedBy(_ path: String) -> Bool`
   - Error case: Path contains `..`

2. **HasMarkdownExtensionSpec** — Checks for `.md` suffix
   - Method: `isSatisfiedBy(_ path: String) -> Bool`
   - True if ends with `.md`

3. **HasHypercodeExtensionSpec** — Checks for `.hc` suffix
   - Method: `isSatisfiedBy(_ path: String) -> Bool`
   - True if ends with `.hc`

4. **IsAllowedExtensionSpec** — Composite: `.md` OR `.hc`
   - Method: `isSatisfiedBy(_ path: String) -> Bool`
   - True if ends with allowed extension

5. **ValidReferencePathSpec** — Composite: NoTraversal AND AllowedExtension
   - Method: `isSatisfiedBy(_ path: String) -> Bool`
   - True if path passes both checks

6. **LooksLikeFileReferenceSpec** — Heuristic detection
   - Method: `isSatisfiedBy(_ text: String) -> Bool`
   - Already integrated in `looksLikeFilePath()`

7. **WithinRootSpec** — Path containment check
   - Method: `isSatisfiedBy(_ path: String, root: String) -> Bool`
   - True if path is within root directory

8. **PathTypeDecision** — Factory-based classification
   - Method: `HypercodeGrammar.makePathClassifier(rootPath: String)` → PathTypeDecision
   - Returns: `.allowed`, `.forbidden`, or `.invalid` classifications

---

## 10. Files to Modify

### Phase 1: Specification Integration (Core Refactoring)
1. `Sources/Resolver/ReferenceResolver.swift` — Main refactoring:
   - Replace `containsPathTraversal()` with `NoTraversalSpec`
   - Replace `fileExtension()` logic with `IsAllowedExtensionSpec` checks
   - Integrate `WithinRootSpec` into `validateWithinRoot()`
   - Consider `PathTypeDecision` usage in extension routing

2. `Tests/ResolverTests/ReferenceResolverTests.swift` — Add specification integration tests

### Phase 2: Deprecation & Cleanup (Optional follow-up)
1. `Sources/Resolver/ReferenceResolver.swift` — Deprecate/remove imperative helpers
   - Mark `containsPathTraversal()` as deprecated (or remove if internal-only)
   - Mark `fileExtension()` as deprecated (or remove if internal-only)

---

## 11. Testing Strategy

### Unit Tests
- Verify each spec is correctly applied:
  - `testNoTraversalSpecDetectsPathTraversal()` — Verify `..` detection via spec
  - `testIsAllowedExtensionSpecValidatesExtensions()` — Verify `.md` and `.hc` acceptance
  - `testValidReferencePathSpecComposite()` — Verify composite (NoTraversal AND AllowedExtension)
  - `testWithinRootSpecEnforcesBoundary()` — Verify root boundary enforcement

### Integration Tests
- End-to-end resolver behavior:
  - `testResolverUsesNoTraversalSpec()` — Traversal rejection via spec
  - `testResolverUsesExtensionSpecs()` — Extension validation via spec
  - `testResolverUsesValidReferencePathSpec()` — Composite path validation
  - `testResolverEnforcesBoundaryViaSpec()` — Root boundary enforcement

### Regression Tests
- All existing resolver tests must pass:
  - File existence checks
  - Strict/lenient mode behavior
  - Error case handling

### Performance Tests
- Benchmark resolver on 100+ file tree before/after refactoring
- Verify <10% overhead

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-12 | Claude (PLAN Generator) | Initial PRD creation from next.md |

---

## 13. References

- **Workplan v2.0.0:** `DOCS/Workplan.md` — Phase 7, Integration-2
- **Spec-3:** Path Validation Specifications — `DOCS/TASKS_ARCHIVE/Spec-3_Path_Validation_Specifications.md`
- **Spec-4:** Composite & Decision Specifications — `DOCS/TASKS_ARCHIVE/Spec-4_Composite_And_Decision_Specifications.md`
- **ReferenceResolver Implementation:** `Sources/Resolver/ReferenceResolver.swift`
- **Integration-1 Reference:** `DOCS/TASKS_ARCHIVE/Integration-1_Lexer_with_Specifications.md`

---

**Status:** ✅ Planning Complete — Ready to begin implementation with Step 1

---

**Archived:** 2025-12-12

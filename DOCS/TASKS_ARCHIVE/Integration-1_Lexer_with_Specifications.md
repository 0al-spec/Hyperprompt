# Integration-1 — Lexer with Specifications

**Version:** 1.1.0  
**Date:** 2025-12-12  
**Status:** Planning (PLAN output)  
**Priority:** P1 (High)  
**Effort:** 5 hours  
**Phase:** Phase 7 — Integration (requires Phase 2 Lexer ✅ and Phase 3 Specs ✅)

---

## 1. Objective & Scope
- **Goal:** Refactor the lexer to replace imperative validation with SpecificationCore-based rules and decision specs while preserving public API, tokens, and observable behavior.
- **Primary Deliverables:**
  1. Lexer (`Sources/Parser/Lexer.swift`) rewritten to classify and validate lines via specification objects (`LineKindDecision`, `ValidNodeLineSpec`, `NoTabsIndentSpec`, `IndentMultipleOf4Spec`, `DepthWithinLimitSpec`, `ValidQuotesSpec`, `SingleLineContentSpec`).
  2. Updated error messaging that cites failed specifications where applicable.
  3. Automated tests proving parity with previous behavior plus specification-driven integration coverage.
  4. Performance check demonstrating <10% overhead versus imperative implementation.
- **Constraints & Assumptions:**
  - Must keep token shapes, `LexerError` cases, and parser-facing API stable.
  - Must respect dependency ordering: specification classes from Phase 3 are available and should not be modified.
  - Target depth limit remains 10 (from Workplan Phase 7 tasks). 
  - No new CLI flags are introduced; benchmarks may be ad-hoc scripts.

---

## 2. Context & Dependencies
- **Dependencies:** Completion of Phase 2 Lexer and Phase 3 Specifications (Workplan Phase 7 entry). Blocking tasks are resolved; work can proceed directly in Integration-1.
- **Motivation:** Current lexer embeds imperative checks in `isBlankLine`, `extractIndentation`, `extractLiteral`, and manual classification branches. This duplicates logic already formalized in specification classes and hinders reuse and testing.
- **Source Materials:**
  - `DOCS/Workplan.md` Phase 7: Integration-1 checklist and acceptance criteria.
  - Specification definitions from Spec-1/Spec-2/Spec-4 (Phase 3 outputs), including decision factory `HypercodeGrammar.makeLineClassifier()`.
  - Existing lexer tests (14 cases) and integration tests in `Tests/IntegrationTests/CompilerDriverTests.swift` referencing Integration-1 for skipped wording fixes.

---

## 3. Functional Requirements
1. **Line Classification via Decision Spec**
   - `classifyLine` must rely on `LineKindDecision` (via `HypercodeGrammar.makeLineClassifier()` or equivalent) to distinguish blank, comment, and node lines with the same priority ordering as before.
   - Invalid or undecidable lines must throw `LexerError.invalidLineFormat` without altering Token construction semantics.
2. **Indentation & Tab Validation**
   - Replace manual tab detection with `NoTabsIndentSpec`.
   - Replace manual alignment logic with `IndentMultipleOf4Spec`; indent count may be derived from `RawLine.leadingSpaces` or equivalent computation.
3. **Depth Validation**
   - Enforce `DepthWithinLimitSpec(maxDepth: 10)` when deriving node depth; violations must map to existing depth-related lexer errors.
4. **Quote & Literal Validation**
   - Replace imperative literal parsing checks with `ValidQuotesSpec` and `SingleLineContentSpec`, or through `ValidNodeLineSpec` if using composite validation.
5. **Composite Validation**
   - Use `ValidNodeLineSpec` (or equivalent composition) to ensure node lines satisfy all lexical rules before token emission.
6. **Error Messaging**
   - Error descriptions should reference the failed specification (e.g., "Failed `ValidNodeLineSpec`: missing closing quote") while keeping error types unchanged.
7. **Testing & Backward Compatibility**
   - All existing lexer unit tests (14/14) must pass unchanged.
   - Add integration tests demonstrating specification-driven classification and validation parity with prior behavior.

---

## 4. Non-Functional Requirements
- **Performance:** Lexer refactor introduces <10% runtime overhead versus the imperative version when tokenizing large inputs (≥10,000 lines). Benchmark with `swift build --configuration release` or equivalent timing harness.
- **Code Quality:** No new compiler warnings; maintain or improve lexer-related coverage (>80%). Keep code readable with concise comments where specification usage is non-obvious.
- **Compatibility:** Public lexer API and `Token` shapes remain stable; downstream parser should observe identical outputs for valid/invalid inputs.

---

## 5. Structured TODO Plan
| Step | Description | Priority | Effort | Inputs | Process | Output/Acceptance |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Confirm current lexer behavior and tests | High | 0.5h | Existing lexer tests; `Sources/Parser/Lexer.swift` | Run lexer unit tests to capture baseline; note any skipped tests referencing Integration-1 | Baseline results documented; ensures parity target |
| 2 | Introduce decision spec classification | High | 1h | `LineKindDecision`, `RawLine`, `classifyLine` | Replace manual branching with `LineKindDecision.decide(rawLine)` while preserving token construction order | `classifyLine` delegates to decision spec; tokens unchanged |
| 3 | Replace indentation & tab checks | High | 0.75h | `NoTabsIndentSpec`, `IndentMultipleOf4Spec` | Swap imperative tab/alignment checks with spec evaluation; map failures to existing errors | Indentation validation handled by specs; errors cite spec failures |
| 4 | Enforce depth limit via spec | High | 0.5h | `DepthWithinLimitSpec(maxDepth:10)` | Apply spec during depth derivation; ensure violations raise existing depth error | Depth validation delegated to spec; tests updated if messaging changes |
| 5 | Replace literal/quote validation | High | 0.75h | `ValidQuotesSpec`, `SingleLineContentSpec`, `ValidNodeLineSpec` | Use spec(s) to validate literals instead of manual scans; ensure composite validation covers multiline rejection | Literal validation purely spec-driven; errors reference spec names |
| 6 | Update error messaging | Medium | 0.5h | Lexer error definitions | Adjust error descriptions to mention failed spec while keeping error types; ensure localized strings consistent | Error messages identify spec failures without API change |
| 7 | Add integration tests | High | 0.75h | Tests suite; Phase 3 specs | Add tests that assert specification classes drive outcomes (classification, failures). Restore/adjust skipped Integration-1 tests in compiler driver suite | New/updated tests passing and proving parity |
| 8 | Benchmark & regression sweep | Medium | 0.25h | Benchmark harness (adhoc) | Time lexer on large corpus before/after; ensure <10% overhead; rerun full test suite | Performance recorded; tests all green |

---

## 6. Acceptance Criteria & Verification
- **Specification Adoption:** All lexer validation paths use specification objects instead of imperative code; verified by code review and targeted tests.
- **Functional Parity:** All existing lexer tests (14/14) pass without modification; previously skipped Integration-1 test cases are enabled or updated to match new error wording.
- **Error Clarity:** Error messages reference failed specs while preserving error types; confirmed through unit tests covering failure scenarios (tabs, misalignment, depth, quotes).
- **Performance:** Benchmark shows <10% runtime increase versus baseline on large input corpus; document results in PR notes or comments.
- **Coverage:** Test additions maintain or increase coverage relative to pre-refactor baseline.

---

## 7. Risks & Mitigations
- **Risk:** Specification decisions alter classification precedence.  
  **Mitigation:** Write regression tests mirroring previous precedence; validate decision factory ordering.
- **Risk:** Error messages change in ways that break downstream expectations.  
  **Mitigation:** Keep `LexerError` cases intact; gate message tweaks behind assertions in tests.
- **Risk:** Performance regression due to additional spec allocations.  
  **Mitigation:** Reuse spec instances; profile and inline simple checks if overhead exceeds 10% threshold.

---

## 8. Execution Notes
- Prefer constructing decision/spec instances once per lexer or per file to minimize allocations.
- Align naming with SpecCore classes; avoid duplicating validation logic already encoded in specs.
- Keep TODO checklist synchronized with Workplan Phase 7 entries when marking completion.

---

**Archived:** 2025-12-12

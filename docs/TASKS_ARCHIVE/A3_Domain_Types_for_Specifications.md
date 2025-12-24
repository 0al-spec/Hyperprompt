# PRD — A3: Domain Types for Specifications

**Priority:** P1 (High)  \
**Phase:** Phase 1 — Foundation & Core Types  \
**Track:** B — Specifications  \
**Status:** ✅ Completed on 2025-12-07  \
**Estimated Effort:** 3 hours  \
**Dependencies:** A1 (Project Init), A2 (Core Types)  \
**Blocking:** Phase 3 (Specifications) and all specification tasks listed in Workplan

---

## 1. Objective and Scope
- Implement the **HypercodeGrammar** Swift module backed by SpecificationCore to model executable grammar rules for lexer/resolver inputs and outputs.
- Define domain types that precisely capture lexical line data, parsed classification, and path semantics required by downstream specifications.
- Deliver a complete, testable PRD-level plan that lets LLM agents produce the grammar module and domain models without ambiguity.

**In Scope**
- Package scaffold for `HypercodeGrammar` with SpecificationCore dependency.
- Domain models: `RawLine`, `LineKind`, `ParsedLine`, `PathKind`.
- Specification naming/placement consistent with the Specification Pattern mapping from `02_DESIGN_SPEC_SPECIFICATION_CORE.md`.
- Unit tests for domain type behavior and conversions.

**Out of Scope**
- Parser, resolver, and emitter changes beyond verifying compatibility with the new types.
- Integration wiring inside existing compiler modules (Phase 7 will handle full integration).

---

## 2. Context and Rationale
- Track B (Specifications) proceeds in parallel; A3 is the foundation for all Phase 3 grammar specs and is **blocking** for specification tasks in Workplan §Phase 3.
- `A1` and `A2` provide module boundaries, core error types, and filesystem abstractions that domain types must reuse for consistency.
- SpecificationCore integration is mandated by the design spec (`02_DESIGN_SPEC_SPECIFICATION_CORE.md`) to centralize grammar rules and enable independent testing/versioning.

---

## 3. Deliverables
1. **HypercodeGrammar Module**
   - Swift package target `HypercodeGrammar` with dependency on `SpecificationCore` as shown in the design spec package template.
   - Public API exposing domain types and specification entry points for lexer/resolver classification.
2. **Domain Type Definitions**
   - `RawLine`: captures source text, 1-based line number, and file path (use `SourceLocation` where applicable).
   - `LineKind`: enum for lexical categories (`blank`, `comment(prefix: String?)`, `node(literal: String)`), designed for SpecificationCore decision specs.
   - `ParsedLine`: struct with `kind: LineKind`, `indentSpaces: Int`, `depth: Int` (indent/4), `literal: String?`, `location: SourceLocation`.
   - `PathKind`: enum for resolver semantics (`allowed(path: String)`, `forbidden(extension: String)`, `invalid(reason: String)`).
3. **Executable Specifications Stubs**
   - Placement of atomic/composite specifications per mapping in `02_DESIGN_SPEC_SPECIFICATION_CORE.md` (Whitespace, LineBreaks, Quotes, Lines, Nodes, References, Decisions).
   - Decision spec entry points (e.g., `LineKindDecision`) that produce `LineKind` from `RawLine`.
4. **Tests**
   - Unit coverage for domain conversions and sample specification behaviors (at least 15 cases per spec as indicated in Workplan for Phase 3 tasks) with fixtures representing blank, comment, node, and path scenarios.

---

## 4. Constraints and Assumptions
- **Language/Platform:** Swift 5.9+, cross-platform macOS/Linux.
- **Indentation:** 4-space groups; tabs are rejected by specification rules.
- **Encoding:** UTF-8; CRLF normalized to LF by lexer but specifications must tolerate LF and CRLF detection inputs.
- **Depth Limit:** Maximum depth 10 (aligned with PRD and design spec); exceeding depth classified as invalid.
- **File Types:** Only `.md` and `.hc` paths are considered allowed; others marked forbidden.
- **No network or filesystem side effects** in specs; operate on provided inputs only.

---

## 5. Execution Plan (Atomic, Dependency-Aware TODOs)
| # | Task | Priority | Effort | Dependencies | Acceptance Criteria |
|---|------|----------|--------|--------------|---------------------|
| 1 | Scaffold `HypercodeGrammar` package target referencing SpecificationCore (Package.swift update, target + test target) | High | 0.5h | A1, A2 | Package resolves; `swift test` discovers target and dependency. |
| 2 | Define `RawLine` struct (text, lineNumber, filePath) leveraging `SourceLocation` for location fidelity | High | 0.25h | A2 | Struct is Codable/Equatable; initializes with non-negative line; unit tests cover creation and equality. |
| 3 | Define `LineKind` enum (blank/comment/node) with payloads for comment prefix and node literal | High | 0.25h | A2 | Enum supports pattern matching; unit tests classify sample inputs correctly. |
| 4 | Define `ParsedLine` struct with indentSpaces, depth (indent/4), literal (optional), location, and computed helpers (e.g., `isSkippable`) | High | 0.5h | Tasks 2-3 | Validates indent multiple-of-4; depth derived; tests cover depth calculation and literal extraction. |
| 5 | Define `PathKind` enum (allowed/forbidden/invalid) to express resolver outcomes and diagnostics | High | 0.25h | A2 | Cases cover `.md`/`.hc` allowlist and rejection reasons; tests assert correct classification. |
| 6 | Implement atomic lexical specs: whitespace, quotes, linebreak detection (`IsBlankLineSpec`, `StartsWithDoubleQuoteSpec`, `EndsWithDoubleQuoteSpec`, `ContainsLFSpec`, `ContainsCRSpec`, `SingleLineContentSpec`) | High | 0.5h | 1 | Specs compile and evaluate true/false correctly for representative strings; 15+ unit cases each. |
| 7 | Implement syntactic specs: `IsCommentLineSpec`, `IsNodeLineSpec`, `ValidNodeLineSpec`, line decision (`LineKindDecision` using `FirstMatchSpec`) | High | 0.5h | 6 | Decision spec returns expected `LineKind` for blank/comment/node samples; composite spec enforces quotes + single-line content. |
| 8 | Implement semantic/path specs: `HasMarkdownExtensionSpec`, `HasHypercodeExtensionSpec`, `IsAllowedExtensionSpec`, `NoTabsIndentSpec`, `IndentMultipleOf4Spec`, `DepthWithinLimitSpec`, `ContainsPathSeparatorSpec`, `ContainsExtensionDotSpec`, `LooksLikeFileReferenceSpec`, `NoTraversalSpec`, `WithinRootSpec` | High | 0.75h | 6 | Specs classify paths per Workplan expectations; tests include positive/negative cases with root parameterization. |
| 9 | Write focused unit tests (HypercodeGrammarTests) covering domain types and all specs (≥15 cases per spec group) | High | 0.75h | 2-8 | `swift test` passes; coverage includes edge cases (tabs, CR-only, depth>10, forbidden extension). |

---

## 6. Functional Requirements
- **FR1 — Domain Models:** `RawLine`, `LineKind`, `ParsedLine`, and `PathKind` must be public, Equatable, and serializable where appropriate to allow reuse by parser/resolver and tests.
- **FR2 — Specification Entry Points:** Provide factory/namespace functions (e.g., `HypercodeGrammar.makeLineClassifier()`) that return composed specs ready for lexer/resolver usage.
- **FR3 — Depth Calculation:** `ParsedLine` computes `depth = indentSpaces / 4` with validation; invalid indentation triggers specification failure.
- **FR4 — Path Classification:** Path specs must distinguish allowed extensions (`.md`, `.hc`), forbidden extensions (others), and invalid paths (traversal, outside root) using `PathKind`.
- **FR5 — Decision Composition:** `LineKindDecision` must evaluate `blank | comment | node` in order, returning the first matching specification result.
- **FR6 — Testability:** All specs and domain types expose deterministic behavior suitable for unit tests without filesystem side effects.

---

## 7. Non-Functional Requirements
- **Performance:** Specification evaluations should be O(n) on line length/path length with no heap-heavy allocations; suitable for batch lexer runs.
- **Maintainability:** Naming matches grammar intent (e.g., `ValidQuotesSpec`), and folder structure mirrors categories in the mapping table from `02_DESIGN_SPEC_SPECIFICATION_CORE.md`.
- **Reusability:** Grammar module must compile standalone for reuse by other tools; avoid compiler-module-specific dependencies beyond shared core types (`SourceLocation`).
- **Determinism:** Identical inputs produce identical classification results; no randomization or time-based behavior.

---

## 8. Edge Cases and Failure Scenarios
- Lines containing only spaces → `LineKind.blank`.
- Tabs in indentation → fail `NoTabsIndentSpec`; classification should mark as invalid rather than misclassify as comment/node.
- CR-only or CRLF endings → correctly detected by line break specs and normalized depth handling.
- Empty quotes `""` → valid node literal with empty string (if line structure passes other specs).
- Depth > 10 → `DepthWithinLimitSpec` failure; produces `PathKind.invalid` equivalent for nodes referencing deep structures.
- Paths with traversal (`..`), leading slash outside root, or missing extension → `PathKind.invalid`.

---

## 9. Verification and Acceptance
- **Unit Tests:** Minimum 15 cases per spec group (lexical, syntactic, semantic/path) plus domain type initialization/conversion tests; run via `swift test` in workspace root.
- **Static Checks:** Ensure package graph resolves and exposes symbols without unused public APIs.
- **Acceptance Criteria:**
  - Domain models compiled and publicly accessible from `HypercodeGrammar`.
  - Specification suite matches mapping in `02_DESIGN_SPEC_SPECIFICATION_CORE.md` and passes tests.
  - Path and depth rules align with PRD constraints (extensions allowlist, depth ≤ 10, no traversal).

---

## 10. Risks and Mitigations
- **Specification Drift:** Grammar rules might diverge from PRD/design spec. *Mitigation:* keep folder structure and naming identical to mapping; add docstrings referencing EBNF productions.
- **Insufficient Test Coverage:** Missing edge cases (e.g., CR-only, mixed whitespace). *Mitigation:* enforce 15+ cases per spec group and include malformed inputs.
- **Dependency Locking:** SpecificationCore version mismatch. *Mitigation:* pin minimal compatible version (>=1.0.0) and run package resolution in CI.

---

## 11. Deliverable Checklist (Ready for Implementation)
- [x] Package scaffold with SpecificationCore dependency checked in.
- [x] Domain types (`RawLine`, `LineKind`, `ParsedLine`, `PathKind`) implemented with docs.
- [x] Lexical, syntactic, semantic/path specs implemented per mapping table.
- [x] Factory methods exporting composed specs for lexer/resolver consumption.
- [x] Unit tests (≥45 total cases across spec groups) passing via `swift test`.
- [x] Documentation within module mirrors terminology in Workplan and PRD.

---
**Archived:** 2025-12-09

# PRD: B4 — Recursive Compilation

## 1. Objective and Scope
- **Goal:** Implement recursive compilation for `.hc` files by invoking the parser recursively, merging child ASTs, and propagating source locations and errors so nested Hypercode trees compile into a single resolved AST.
- **In-Scope:**
  - Parser/resolver recursion for `.hc` references discovered in node content.
  - AST merging at correct depth with preserved parent-child relationships.
  - Source location tracking across files (line/column, file path, depth).
  - Error propagation from nested compilations with contextualized paths.
  - Visitation stack maintenance to prevent incorrect traversal state.
  - Tests covering multi-level nesting (≥3 levels) and error cases.
- **Out-of-Scope:**
  - Markdown emission changes beyond ensuring resolved AST structure is ready for emitter (handled in later tasks).
  - Manifest generation extensions (covered by other tasks).

## 2. Context and Constraints
- **Task ID / Name:** B4 — Recursive Compilation (Workplan status: INPROGRESS; Priority: P0; Effort: 8h; Phase: Phase 4 — Reference Resolution).
- **Dependencies:** A4, B1, B2, B3 must provide parser, resolver, and prerequisite resolution behaviors; B2 supplies visitation stack updates.
- **Blocks:** C2 depends on fully resolved AST produced here.
- **Assumptions:**
  - `.hc` extension triggers recursive compilation; `.md` embedding handled elsewhere.
  - File system rules from design spec apply: canonicalized paths, root containment, no disallowed extensions.
  - Existing parser/resolver interfaces can be invoked reentrantly without global mutable state leaks.
- **Constraints:**
  - Deterministic traversal order; consistent error formatting per design spec.
  - Maintain performance suitable for nested trees (avoid redundant parses, respect caching if available).
  - No network or external I/O beyond sanctioned file loading.

## 3. Functional Requirements
- **FR1 Recursive Invocation:** When resolver encounters `.hc` content reference, invoke parser/resolver recursively from that path using the same root context and configuration flags.
- **FR2 AST Integration:** Insert the child AST into the parent tree at the referencing node’s position, preserving depth offsets and semantic ordering.
- **FR3 Source Location Propagation:** Track and adjust source spans for embedded nodes so diagnostics reference the originating file and accurate line/column.
- **FR4 Error Propagation:** Any parsing/resolution error in a nested `.hc` must surface to the root compilation with hierarchical path context; exit code semantics unchanged.
- **FR5 Visitation Stack Integrity:** Update visitation/recursion stack to reflect entry/exit from each `.hc` to avoid cycles or misplaced state; stack visible to diagnostics when relevant.
- **FR6 Dependency Alignment:** Ensure behavior aligns with Workplan acceptance: nested `.hc` files compile and embed correctly; errors propagate with correct locations; depth accounting supports later emitter offsets.

## 4. Non-Functional Requirements
- **Performance:** Recursive compilation should avoid exponential blow-up; reuse caches where available; acceptable overhead scales linearly with number of nested `.hc` files.
- **Reliability:** Deterministic output and error ordering; robust against deeply nested trees (target ≥3 levels tested).
- **Maintainability:** Clear separation between recursion orchestration and AST construction; minimal duplication of parser/resolver setup code.
- **Security:** Enforce root containment and extension validation for all nested references; reject unsupported extensions.

## 5. Execution Plan (Structured TODO)
| Step | Description | Priority | Effort | Inputs | Outputs | Dependencies | Verification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Identify resolver/ parser entry points for handling file reference nodes and add hook for `.hc` recursion. | High | 1h | Resolver module, parser API | Design for recursion hook | A4, B1 | Code review notes referencing hook location |
| 2 | Implement recursive parse/resolve call for `.hc` references with shared config (root paths, flags) and guard against reentrant global state. | High | 2h | File system rules, parser/resolver interfaces | Child AST for referenced file | A4, B1 | Unit tests invoking recursion with simple 2-level nesting |
| 3 | Merge child AST into parent at referencing node, adjusting depth/indentation metadata to maintain hierarchy. | High | 2h | Parent/child AST structures | Combined AST with nested nodes | A4, B1 | Structural assertions in tests (depth, ordering) |
| 4 | Propagate source locations for merged nodes, ensuring spans retain original file path and remap depth offsets. | High | 1h | Source location structs | Nodes with accurate spans | A4, B1 | Tests validating file/line/column on diagnostics |
| 5 | Propagate errors from nested compilations with contextual path (root → child). | High | 1h | Error handling utilities | Bubble-up error list | A4, B1 | Tests asserting hierarchical error messages/exit code |
| 6 | Maintain visitation/recursion stack updates across entry/exit to each `.hc`; prevent cycles or stale state. | Medium | 0.5h | Visitation stack from B2 | Updated stack operations | B2 | Tests ensuring stack push/pop order and no leakage |
| 7 | Add tests for ≥3-level nested `.hc` files covering success and failure paths (invalid extension, missing file, parse error). | High | 1.5h | Test harness, sample fixtures | Test suite for recursion | A4, B1, B3 | Automated tests pass; assertions on AST depth and errors |

## 6. Acceptance Criteria
- Nested `.hc` references compile recursively into a single resolved AST with correct parent-child relationships.
- Source locations for merged nodes reference the originating file and line/column; diagnostics surface hierarchical context.
- Error conditions in nested compilations bubble to root with consistent formatting; unsupported extensions rejected.
- Visitation stack accurately reflects recursion depth; no residual state after compilation.
- Automated tests demonstrate ≥3-level nesting success and representative failure cases.

## 7. Risks and Mitigations
- **Risk:** Recursion could re-parse the same file leading to cycles or redundant work. **Mitigation:** Track visitation stack with cycle checks; leverage caching if available.
- **Risk:** Depth or location offsets misapplied, causing incorrect diagnostics. **Mitigation:** Centralize depth/location adjustment logic with unit tests on spans.
- **Risk:** Error propagation loses context. **Mitigation:** Ensure errors include file path chain and maintain ordering; add tests for nested error surfaces.

## 8. Verification Methods
- Unit/integration tests covering multi-level recursion (happy path and failure scenarios).
- Code review checklist ensuring recursion hook, depth adjustments, error propagation, and stack management align with design rules.
- Optional dry-run logging (if available) to inspect traversal order during tests.

## 9. Deliverables
- Updated resolver/parser code enabling recursive compilation of `.hc` files with AST merging and diagnostics propagation.
- Test suite fixtures demonstrating ≥3-level nesting and error paths.
- Documentation update (if needed) describing recursion behavior and limitations.

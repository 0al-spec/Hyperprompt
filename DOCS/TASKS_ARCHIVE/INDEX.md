# Archived Tasks

This directory contains completed task PRDs and summaries, organized by phase.

---

## Phase 4: Reference Resolution

### B2 — Dependency Tracker **[P1]** ✓ 2025-12-21
- **PRD:** [B2_Dependency_Tracker.md](./B2_Dependency_Tracker.md)
- **Summary:** [B2-summary.md](./B2-summary.md)
- **Effort:** 4 hours
- **Dependencies:** A4 (Parser & AST Construction)
- **Description:** Optimize dependency cycle detection for deep trees with memoized stack indexes.

---

## Phase 6: CLI & Integration

### D4 — Statistics Reporter **[P2]** ✓ 2025-12-16
- **PRD:** [D4_Statistics_Reporter.md](./D4_Statistics_Reporter.md)
- **Summary:** [D4-summary.md](./D4-summary.md)
- **Effort:** 3 hours
- **Dependencies:** D1 (Compiler Driver)
- **Description:** Implement statistics collection and reporting capability for `--stats` flag

### D2 — Compiler Driver (Signal Handling) **[P2]** ✓ 2025-12-21
- **PRD:** [D2_Compiler_Driver.md](./D2_Compiler_Driver.md)
- **Summary:** [D2-summary.md](./D2-summary.md)
- **Effort:** 6 hours
- **Dependencies:** C2, C3, D1
- **Description:** Add graceful SIGINT/SIGTERM handling with deterministic exit codes.

### BUG-D2-001 — Signal Handling Regression **[P1]** ✓ 2025-12-21
- **PRD:** [BUG-D2-001_Signal_Handling_Regression.md](./BUG-D2-001_Signal_Handling_Regression.md)
- **Summary:** [BUG-D2-001-summary.md](./BUG-D2-001-summary.md)
- **Effort:** 1 hour
- **Dependencies:** D2 (Compiler Driver)
- **Description:** Ensure SIGINT/SIGTERM handling works during synchronous compile on the main thread.

---

## Phase 8: Testing & Quality Assurance

### E4 — Build Warnings Cleanup **[P2]** ✓ 2025-12-21
- **PRD:** [E4_Build_Warnings_Cleanup.md](./E4_Build_Warnings_Cleanup.md)
- **Summary:** [E4-summary.md](./E4-summary.md)
- **Effort:** 2 hours
- **Dependencies:** D2, E1
- **Description:** Remove integration-test warnings and refresh build issues log.

---

## Phase 9: Optimization & Finalization

### P9 — Optimization Tasks **[P2]** ✓ 2025-12-21
- **PRD:** [P9_Optimization_Tasks.md](./P9_Optimization_Tasks.md)
- **Summary:** [P9-summary.md](./P9-summary.md)
- **Effort:** 3 hours
- **Dependencies:** E1, E2
- **Description:** Profile compilation, validate memory usage, and check for leaks.

---

## Phase 10: Editor Engine Module

### EE0 — EditorEngine Module Foundation **[P1]** ✓ 2025-12-20
- **Summary:** [EE0-summary.md](./EE0-summary.md)
- **Effort:** 1 hour
- **Dependencies:** D2 (Compiler Driver)
- **Description:** Create foundational structure for EditorEngine module with SPM configuration

### EE1 — Project Indexing **[P1]** ✓ 2025-12-20
- **PRD:** [EE1_Project_Indexing.md](./EE1_Project_Indexing.md)
- **Legacy PRD:** [EE1_Editor_Engine_Implementation.md](./EE1_Editor_Engine_Implementation.md)
- **Summary:** [EE1-summary.md](./EE1-summary.md)
- **Effort:** 3 hours
- **Dependencies:** EE0 (EditorEngine Module Foundation)
- **Description:** Implement deterministic workspace indexing for `.hc` and `.md` files with `.hyperpromptignore` rules, metadata, and EditorEngine API access.

### EE2 — Parsing with Link Spans **[P1]** ✓ 2025-12-21
- **PRD:** [EE2_Parsing_with_Link_Spans.md](./EE2_Parsing_with_Link_Spans.md)
- **Summary:** [EE2-summary.md](./EE2-summary.md)
- **Effort:** 3 hours
- **Dependencies:** EE1 (Project Indexing)
- **Description:** Extend parsing to capture link spans with UTF-8 ranges, heuristic link detection, and graceful diagnostics.

### EE3 — Link Resolution **[P1]** ✓ 2025-12-21
- **PRD:** [EE3_Link_Resolution.md](./EE3_Link_Resolution.md)
- **Summary:** [EE3-summary.md](./EE3-summary.md)
- **Effort:** 2 hours
- **Dependencies:** EE2 (Parsing with Link Spans)
- **Description:** Resolve editor link spans using CLI-equivalent path rules with diagnostics and ambiguity handling.

### EE4 — Editor Compilation **[P1]** ✓ 2025-12-21
- **PRD:** [EE4_Editor_Compilation.md](./EE4_Editor_Compilation.md)
- **Summary:** [EE4-summary.md](./EE4-summary.md)
- **Effort:** 3 hours
- **Dependencies:** EE3 (Link Resolution)
- **Description:** Provide editor compilation with deterministic output and diagnostics via CompilerDriver wrapper.

### EE5 — Diagnostics Mapping **[P1]** ✓ 2025-12-21
- **PRD:** [EE5_Diagnostics_Mapping.md](./EE5_Diagnostics_Mapping.md)
- **Summary:** [EE5-summary.md](./EE5-summary.md)
- **Effort:** 2 hours
- **Dependencies:** EE4 (Editor Compilation)
- **Description:** Map compiler errors into editor diagnostics with stable codes and ranges.

### EE6 — Documentation & Testing **[P1]** ✓ 2025-12-21
- **PRD:** [EE6_Documentation_and_Testing.md](./EE6_Documentation_and_Testing.md)
- **Summary:** [EE6-summary.md](./EE6-summary.md)
- **Effort:** 7 hours
- **Dependencies:** EE5 (Diagnostics Mapping)
- **Description:** Document EditorEngine API, expand tests, and verify editor vs CLI parity.

### EE7 — SpecificationCore Decision Refactor **[P1]** ✓ 2025-12-22
- **PRD:** [EE7_SpecificationCore_Decision_Refactor.md](./EE7_SpecificationCore_Decision_Refactor.md)
- **Summary:** [EE7-summary.md](./EE7-summary.md)
- **Effort:** 4 hours
- **Dependencies:** EE6 (Documentation & Testing)
- **Description:** Refactor EditorEngine decision points to use SpecificationCore specs and decision models.

### EE8 — EditorEngine Validation Follow-ups **[P1]** ✓ 2025-12-23
- **PRD:** [EE8_EditorEngine_Validation_Follow-ups.md](./EE8_EditorEngine_Validation_Follow-ups.md)
- **Summary:** [EE8-summary.md](./EE8-summary.md)
- **Effort:** 6 hours
- **Dependencies:** EE7 (SpecificationCore Decision Refactor)
- **Description:** Trait-gate EditorEngine, extract shared compiler orchestration, archive EE7 summary, and map parser I/O errors into diagnostics.

### BUG-EE1-001 — GlobMatcher Pattern Matching Issues ✓ 2025-12-21
- **PRD:** [BUG-EE1-001_GlobMatcher_Pattern_Matching_Issues.md](./BUG-EE1-001_GlobMatcher_Pattern_Matching_Issues.md)
- **Related Task:** EE1 — Project Indexing
- **Description:** Fix `.gitignore`-compatible wildcard semantics (`*` root-only, `**/` zero-or-more dirs)

---

## Phase 11: VS Code Extension Integration Architecture

### VSC-1 — Integration Architecture Decision **[P0]** ✓ 2025-12-23
- **PRD:** [VSC-1_Integration_Architecture_Decision.md](./VSC-1_Integration_Architecture_Decision.md)
- **Effort:** 4 hours
- **Dependencies:** EE8 (Phase 10 — EditorEngine complete)
- **Description:** Evaluate integration options between Swift EditorEngine and TypeScript VS Code extension. Chose CLI + JSON-RPC for MVP, LSP for long-term.

### VSC-2B — CLI JSON-RPC Interface **[P0]** ✓ 2025-12-23
- **PRD:** [VSC-2B_CLI_JSON-RPC_Interface.md](./VSC-2B_CLI_JSON-RPC_Interface.md)
- **Effort:** 8 hours
- **Dependencies:** VSC-1 (Integration Architecture Decision)
- **Description:** Implement JSON-RPC 2.0 interface for editor integration. Includes Swift 6 compilation validation, editor.indexProject method, Sendable fixes, and RPC protocol documentation. Builds successfully, all 521 tests pass.

---

## Phase 12: EditorEngine API Enhancements

### EE-EXT-1 — Position-to-Link Query API **[P0]** ✓ 2025-12-24
- **PRD:** [EE-EXT-1_Position-to-Link_Query_API.md](./EE-EXT-1_Position-to-Link_Query_API.md)
- **Effort:** 3 hours
- **Dependencies:** EE8 (Phase 10 — EditorEngine complete)
- **Description:** Add position-based query API to EditorParser with binary search for O(log n) lookup. Enables go-to-definition and hover features in VS Code extension.

---

## Phase 13: Performance & Incremental Compilation

### PERF-1 — Performance Baseline & Benchmarks **[P0]** ✓ 2025-12-24
- **PRD:** [PERF-1_Performance_Baseline_And_Benchmarks.md](./PERF-1_Performance_Baseline_And_Benchmarks.md)
- **Summary:** [PERF-1-summary.md](./PERF-1-summary.md)
- **Effort:** 3 hours
- **Dependencies:** EE8 (Phase 10 — EditorEngine complete)
- **Description:** Establish baseline performance measurements with a synthetic benchmark corpus, XCTest suite, documentation, and CI tracking.

### PERF-2 — Incremental Compilation — File Caching **[P0]** ✓ 2025-12-24
- **PRD:** [PERF-2_Incremental_Compilation_File_Caching.md](./PERF-2_Incremental_Compilation_File_Caching.md)
- **Summary:** [PERF-2-summary.md](./PERF-2-summary.md)
- **Effort:** 6 hours
- **Dependencies:** PERF-1
- **Description:** Implement parsed file cache with checksum invalidation, cascading invalidation, and LRU eviction for incremental compilation.

### PERF-3 — Incremental Compilation — Dependency Graph **[P0]** ✓ 2025-12-25
- **PRD:** [PERF-3_Incremental_Compilation_Dependency_Graph.md](./PERF-3_Incremental_Compilation_Dependency_Graph.md)
- **Summary:** [PERF-3-summary.md](./PERF-3-summary.md)
- **Effort:** 4 hours
- **Dependencies:** PERF-2
- **Description:** Add dependency graph accessors, dirty propagation, and topological ordering to support incremental compilation.

---

## Phase 14: VS Code Extension Development

### VSC-3 — Extension Scaffold **[P0]** ✓ 2025-12-24
- **PRD:** [VSC-3_Extension_Scaffold.md](./VSC-3_Extension_Scaffold.md)
- **Summary:** [VSC-3-summary.md](./VSC-3-summary.md)
- **Effort:** 3 hours
- **Dependencies:** VSC-2B (CLI JSON-RPC Interface)
- **Description:** Create the VS Code extension scaffold with language registration, activation events, and base assets for `.hc` support.

---

## Other Archives

### Build Issues Log ✓ 2025-12-21
- **Log:** [build-issues.md](./build-issues.md)
- **Description:** Archived build warnings log after warnings were resolved.

---

## Statistics

- **Total Archived:** 23 items
- **Total Effort:** 81 hours (tracked tasks only)
- **Phases Represented:** 9 (Phase 4, Phase 6, Phase 8, Phase 9, Phase 10, Phase 11, Phase 12, Phase 13, Phase 14)

---

## Archive Policy

Tasks are archived when:
1. Marked `[x]` as complete in `DOCS/Workplan.md`
2. PRD or summary exists in `DOCS/INPROGRESS/`
3. Task is no longer active in `next.md`

To restore a task:
```bash
mv DOCS/TASKS_ARCHIVE/{TASK_ID}_*.md DOCS/INPROGRESS/
git commit -m "Restore task {TASK_ID}"
```

---

**Last Updated:** 2025-12-25 (PERF-3 archived)

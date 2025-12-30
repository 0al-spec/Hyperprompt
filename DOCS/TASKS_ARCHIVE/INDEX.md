# Archived Tasks

This directory contains completed task PRDs and summaries, organized by phase.

---

## Hotfixes & Bug Reports

### BUG-CE1-001 — Lenient Compile Includes Markdown Filename Heading **[P0]** ✓ 2025-12-27
- **PRD:** [BUG-CE1-001_Lenient_Compile_Includes_Markdown_Filename_Heading.md](./BUG-CE1-001_Lenient_Compile_Includes_Markdown_Filename_Heading.md)
- **Summary:** [BUG-CE1-001-summary.md](./BUG-CE1-001-summary.md)
- **Report:** [BUG-CE1-001_Bug_Report.md](./BUG-CE1-001_Bug_Report.md)
- **Effort:** 1 hour
- **Dependencies:** None
- **Description:** Document lenient compile output bug for markdown include headings and capture repro details.

### DOC-REORG-001 — Move User Docs to Documentation.docc **[P0]** ✓ 2025-12-27
- **PRD:** [DOC-REORG-001_Move_User_Docs_to_Documentation_docc.md](./DOC-REORG-001_Move_User_Docs_to_Documentation_docc.md)
- **Summary:** [DOC-REORG-001-summary.md](./DOC-REORG-001-summary.md)
- **Effort:** 2 hours
- **Dependencies:** None
- **Description:** Relocate user-facing docs to Documentation.docc, keep process docs in DOCS, and update references.

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

### EE-EXT-1B — Fix EditorParser linkAt Regression **[P0]** ✓ 2025-12-27
- **PRD:** [EE-EXT-1B_Fix_EditorParser_linkAt_Regression.md](./EE-EXT-1B_Fix_EditorParser_linkAt_Regression.md)
- **Summary:** [EE-EXT-1B-summary.md](./EE-EXT-1B-summary.md)
- **Effort:** 2 hours
- **Dependencies:** EE-EXT-1
- **Description:** Restore link span extraction for linkAt queries and preserve ranges on lexer errors.

### EE-EXT-3 — Source Map Generation **[P2]** ⚠️ PARTIAL (Stub Only) 2025-12-26
- **Review:** [EE-EXT-3-review.md](./EE-EXT-3-review.md)
- **Summary:** [EE-EXT-3-summary.md](./EE-EXT-3-summary.md)
- **Effort:** 5 hours (stub only), 12-18 hours needed for full implementation
- **Dependencies:** EE8
- **Status:** Only 50% complete (3/6 requirements)
- **Description:** Minimal stub implementation for source map generation. Maps all output lines to entry file only. Missing: Emitter integration, multi-file support, unit tests.
- **Note:** ⚠️ Marked complete but not fully implemented. See review for details.

---

## EditorEngine Code Review Fixes

### EE-FIX-1 — Missing Workspace Root Path Validation **[P0] BLOCKER** ✓ 2025-12-28
- **PRD:** [EE-FIX-1_Workspace_Root_Validation.md](./EE-FIX-1_Workspace_Root_Validation.md)
- **Effort:** 1 hour
- **Dependencies:** None
- **Description:** Add validation that `workspaceRoot` is an absolute path in `ProjectIndexer.index()` to prevent relative paths from causing undefined behavior.

### EE-FIX-2 — Byte Offset Calculation Off-by-One Error **[P0] BLOCKER** ✓ 2025-12-28
- **PRD:** [EE-FIX-2_Byte_Offset_Calculation.md](./EE-FIX-2_Byte_Offset_Calculation.md)
- **Effort:** 2 hours
- **Dependencies:** None
- **Description:** Review and validate `computeLineStartOffsets` logic for trailing newlines. Result: **No bug found** - added comprehensive test coverage to confirm correct implementation.

### EE-FIX-3 — Path Manipulation Double-Slash Bug **[P1] HIGH** ✓ 2025-12-28
- **PRD:** [EE-FIX-3_Path_Manipulation.md](./EE-FIX-3_Path_Manipulation.md)
- **Effort:** 1 hour
- **Dependencies:** None
- **Description:** Fix `joinPath` to handle edge cases (trailing slash on base, leading slash on component, empty component) that can produce invalid paths with double slashes.

### EE-FIX-4 — GlobMatcher Regex Caching **[P1] HIGH** ✓ 2025-12-28
- **PRD:** [EE-FIX-4_GlobMatcher_Caching.md](./EE-FIX-4_GlobMatcher_Caching.md)
- **Effort:** 2 hours
- **Dependencies:** None
- **Description:** Cache compiled glob regexes in GlobMatcher to reduce repeated compilation overhead during indexing.

### EE-FIX-5 — Silent Regex Failure Fallback **[P1] HIGH** ✓ 2025-12-28
- **PRD:** [EE-FIX-5_Regex_Failure_Handling.md](./EE-FIX-5_Regex_Failure_Handling.md)
- **Summary:** [EE-FIX-5-summary.md](./EE-FIX-5-summary.md)
- **Effort:** 2 hours
- **Dependencies:** EE-FIX-4
- **Description:** Handle invalid glob regex patterns safely by surfacing errors during ignore file loading and avoiding silent fallback behavior.

### EE-FIX-6 — ProjectIndexer Integration Tests **[P1] HIGH** ✓ 2025-12-29
- **PRD:** [EE-FIX-6_ProjectIndexer_Tests.md](./EE-FIX-6_ProjectIndexer_Tests.md)
- **Summary:** [EE-FIX-6-summary.md](./EE-FIX-6-summary.md)
- **Effort:** 4 hours
- **Dependencies:** None
- **Description:** Replace placeholder ProjectIndexer tests with integration coverage for directory traversal, ignore patterns, hidden entries, depth limits, and deterministic ordering.

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

### PERF-4 — Performance Validation **[P0]** ✓ 2025-12-25
- **PRD:** [PERF-4_Performance_Validation.md](./PERF-4_Performance_Validation.md)
- **Summary:** [PERF-4-summary.md](./PERF-4-summary.md)
- **Effort:** 2 hours
- **Dependencies:** PERF-3
- **Description:** Validate incremental compilation performance targets and document results with CI regression checks.

---

## Phase 14: VS Code Extension Development

### VSC-4B — CLI RPC Client Integration **[P0]** ✓ 2025-12-25
- **PRD:** [VSC-4B_CLI_RPC_Client_Integration.md](./VSC-4B_CLI_RPC_Client_Integration.md)
- **Summary:** [VSC-4B-summary.md](./VSC-4B-summary.md)
- **Effort:** 3 hours
- **Dependencies:** VSC-2B, VSC-3
- **Description:** Implement a JSON-RPC client in the extension to spawn and communicate with the Hyperprompt editor process.

### VSC-4C — Engine Discovery & Platform Guard **[P0]** ✓ 2025-12-26
- **PRD:** [VSC-4C_Engine_Discovery_And_Platform_Guard.md](./VSC-4C_Engine_Discovery_And_Platform_Guard.md)
- **Effort:** 3 hours
- **Dependencies:** VSC-3, VSC-8
- **Description:** Add engine discovery, platform gating, and Editor trait validation with remediation guidance.

### VSC-3 — Extension Scaffold **[P0]** ✓ 2025-12-26
- **PRD:** [VSC-3_Extension_Scaffold.md](./VSC-3_Extension_Scaffold.md)
- **PRD (Dev Host Validation):** [VSC-3_Extension_Scaffold_Dev_Host_Validation.md](./VSC-3_Extension_Scaffold_Dev_Host_Validation.md)
- **Summary (2025-12-24):** [VSC-3-summary.md](./VSC-3-summary.md)
- **Summary (2025-12-26):** [VSC-3-summary-2025-12-26.md](./VSC-3-summary-2025-12-26.md)
- **Effort:** 3 hours
- **Dependencies:** VSC-2B (CLI JSON-RPC Interface)
- **Description:** Create the VS Code extension scaffold with language registration, activation events, and base assets for `.hc` support.

### VSC-7B — Compile Lenient Command **[P1]** ✓ 2025-12-26
- **PRD:** [VSC-7B_Compile_Lenient_Command.md](./VSC-7B_Compile_Lenient_Command.md)
- **Effort:** 1 hour
- **Dependencies:** VSC-2B, VSC-4*
- **Description:** Add a lenient compile command in the VS Code extension for missing-reference-tolerant builds.

### VSC-7A — Compile on Demand Command **[P0]** ✓ 2025-12-26
- **PRD:** [VSC-7A_Compile_on_Demand_Command.md](./VSC-7A_Compile_on_Demand_Command.md)
- **Effort:** 3 hours
- **Dependencies:** VSC-2B, VSC-4*
- **Description:** Surface compile output in the VS Code extension via output channel with tests.
### VSC-8 — Extension Settings **[P1]** ✓ 2025-12-26
- **PRD:** [VSC-8_Extension_Settings.md](./VSC-8_Extension_Settings.md)
- **Effort:** 2 hours
- **Dependencies:** VSC-4*
- **Description:** Add extension settings schema and runtime handling for resolution mode, preview auto-update, diagnostics, and engine configuration.

### VSC-5 — Navigation Features **[P0]** ✓ 2025-12-27
- **PRD:** [VSC-5_Navigation_Features.md](./VSC-5_Navigation_Features.md)
- **Summary:** [VSC-5-summary.md](./VSC-5-summary.md)
- **Effort:** 5 hours
- **Dependencies:** VSC-4*, EE-EXT-1
- **Description:** Add go-to-definition and hover support for Hypercode references.

### VSC-6 — Diagnostics Integration **[P0]** ✓ 2025-12-27
- **PRD:** [VSC-6_Diagnostics_Integration.md](./VSC-6_Diagnostics_Integration.md)
- **Summary:** [VSC-6-summary.md](./VSC-6-summary.md)
- **Effort:** 4 hours
- **Dependencies:** VSC-4*, EE-EXT-2
- **Description:** Surface diagnostics in the Problems panel with proper ranges and tests.

### VSC-7 — Live Preview Panel **[P0]** ✓ 2025-12-27
- **PRD:** [VSC-7_Live_Preview_Panel.md](./VSC-7_Live_Preview_Panel.md)
- **Summary:** [VSC-7-summary.md](./VSC-7-summary.md)
- **Effort:** 6 hours
- **Dependencies:** VSC-4*, PERF-4
- **Description:** Provide live preview panel with compile-on-save updates and scroll sync.

### VSC-11 — Extension Testing & QA **[P0]** ✓ 2025-12-27
- **PRD:** [VSC-11_Extension_Testing_QA.md](./VSC-11_Extension_Testing_QA.md)
- **Summary:** [VSC-11-summary.md](./VSC-11-summary.md)
- **Effort:** 4 hours
- **Dependencies:** VSC-5, VSC-6, VSC-7
- **Description:** Add integration coverage, fixtures, and CI validation for extension features.

### VSC-12 — Extension Documentation & Release **[P0]** ✓ 2025-12-27
- **PRD:** [VSC-12_Extension_Documentation_Release.md](./VSC-12_Extension_Documentation_Release.md)
- **Summary:** [VSC-12-summary.md](./VSC-12-summary.md)
- **Effort:** 3 hours
- **Dependencies:** VSC-11
- **Description:** Document extension features, requirements, and packaging steps with release notes.

### VSC-DOCS — TypeScript Project Documentation **[P1]** ✓ 2025-12-27
- **PRD:** [VSC-DOCS_TypeScript_Project_Documentation.md](./VSC-DOCS_TypeScript_Project_Documentation.md)
- **Summary:** [VSC-DOCS-summary.md](./VSC-DOCS-summary.md)
- **Effort:** 2 hours
- **Dependencies:** VSC-3
- **Description:** Document TypeScript project structure, workflows, and RPC behaviors.

### VSC-9 — Multi-Column Workflow (Optional) **[P2]** ✓ 2025-12-30
- **PRD:** [VSC-9_Multi-Column_Workflow.md](./VSC-9_Multi-Column_Workflow.md)
- **Summary:** [VSC-9-summary.md](./VSC-9-summary.md)
- **Review:** [REVIEW_VSC-9_Multi-Column_Workflow.md](./REVIEW_VSC-9_Multi-Column_Workflow.md)
- **Effort:** 3 hours
- **Dependencies:** VSC-5, EE-EXT-4
- **Description:** Implement multi-column workflow feature with `hyperprompt.openBeside` command for side-by-side editing.

### VSC-10 — Bidirectional Navigation (Optional) **[P2]** ✓ 2025-12-30
- **PRD:** [VSC-10_Bidirectional_Navigation.md](./VSC-10_Bidirectional_Navigation.md)
- **Summary:** [VSC-10-summary.md](./VSC-10-summary.md)
- **Validation:** [VSC-10-validation-report.md](./VSC-10-validation-report.md)
- **Effort:** 5 hours (actual vs 4h estimated)
- **Dependencies:** VSC-7, EE-EXT-3
- **Description:** Implement click-to-navigate from preview to source files using minimal source maps. Maps to entry file only (multi-file requires Emitter integration).
- **Note:** Uses stub SourceMap implementation; full multi-file tracking deferred to EE-EXT-3-FULL.

### VSC-13 — CI/CD Improvements for Extension **[P1]** ✓ 2025-12-30
- **PRD:** [VSC-13_CI_CD_Improvements_for_Extension.md](./VSC-13_CI_CD_Improvements_for_Extension.md)
- **Summary:** [VSC-13-summary.md](./VSC-13-summary.md)
- **Effort:** 2 hours
- **Dependencies:** VSC-11, VSC-12
- **Description:** Enhance CI/CD pipeline with dependency caching, separate lint/compile/test steps, reproducible builds, and VSIX packaging verification.

---

## Phase 15: PRD Validation & Gap Closure

### PRD-VAL-1 — PRD Requirements Checklist **[P0]** ✓ 2025-12-27
- **PRD:** [PRD-VAL-1_PRD_Requirements_Checklist.md](./PRD-VAL-1_PRD_Requirements_Checklist.md)
- **Summary:** [PRD-VAL-1-summary.md](./PRD-VAL-1-summary.md)
- **Effort:** 2 hours
- **Dependencies:** VSC-12
- **Description:** Validate PRD requirements against implementation and document evidence.

### PRD-VAL-2 — Validation Report Update **[P1]** ✓ 2025-12-27
- **PRD:** [PRD-VAL-2_Validation_Report_Update.md](./PRD-VAL-2_Validation_Report_Update.md)
- **Summary:** [PRD-VAL-2-summary.md](./PRD-VAL-2-summary.md)
- **Effort:** 2 hours
- **Dependencies:** PRD-VAL-1
- **Description:** Update validation report with resolved issues, architecture choice, and benchmarks.

### PRD-VAL-3 — Extension Parity Validation **[P1]** ✓ 2025-12-27
- **PRD:** [PRD-VAL-3_Extension_Parity_Validation.md](./PRD-VAL-3_Extension_Parity_Validation.md)
- **Summary:** [PRD-VAL-3-summary.md](./PRD-VAL-3-summary.md)
- **Effort:** 2 hours
- **Dependencies:** PRD-VAL-2
- **Description:** Add deterministic parity test comparing CLI output with extension RPC output.

---

## Other Archives

### Build Issues Log ✓ 2025-12-21
- **Log:** [build-issues.md](./build-issues.md)
- **Description:** Archived build warnings log after warnings were resolved.

---

## Statistics

- **Total Archived:** 51 items (50 complete, 1 partial)
- **Total Effort:** 150 hours completed + 5 hours partial + 12-18 hours pending (EE-EXT-3 full implementation)
- **Phases Represented:** 10 (Phase 4, Phase 6, Phase 8, Phase 9, Phase 10, Phase 11, Phase 12, Phase 13, Phase 14, Phase 15)

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

**Last Updated:** 2025-12-30 (VSC-13 archived)

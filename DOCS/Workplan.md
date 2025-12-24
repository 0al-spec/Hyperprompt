# Hyperprompt VS Code Extension — Work Plan

**Document Version:** 4.0.0
**Date:** December 23, 2025
**Status:** Active Development (Phases 11-15 In Progress)
**Based on:** PRD v0.0.1, PRD_EditorEngine.md, PRD_VSCode_Extension.md

---

## Overview

**Current Focus:** VS Code Extension Development (Phases 11-15)

This work plan focuses on the VS Code Extension implementation:
- **Phase 11:** VS Code Extension Integration Architecture — ⏸️ Partial (VSC-1 ✅ Complete)
- **Phase 12:** EditorEngine API Enhancements — ⏸️ Pending
- **Phase 13:** Performance & Incremental Compilation — ⏸️ Pending
- **Phase 14:** VS Code Extension Development — ⏸️ Pending
- **Phase 15:** PRD Validation & Gap Closure — ⏸️ Pending

**Total Estimated Effort (Phases 11-15):** ~82 hours remaining (VSC-1 complete: 4h)

### 📁 Completed Work Archive

**Phases 1-10 (Complete):** See archived work plan at:
- [`DOCS/TASKS_ARCHIVE/Workplan_Phases_1-10_Archive.md`](TASKS_ARCHIVE/Workplan_Phases_1-10_Archive.md)

Completed phases include:
- ✅ Phase 1-9: Core Compiler Implementation (100 hours)
- ✅ Phase 10: EditorEngine Module (31 hours)
- ✅ **Total completed:** 131 hours

---

## Priority Levels

- **[P0] Critical:** Blocks entire project, must complete before moving forward
- **[P1] High:** Important for core functionality, required for v0.1
- **[P2] Medium:** Nice-to-have, can be deferred to v0.1.1 if needed

---

## Phase 11: VS Code Extension Integration Architecture

**Goal:** Establish interoperability layer between Swift EditorEngine and TypeScript VS Code extension
**Estimated Duration:** 18 hours (2-3 weeks)
**Track:** D (VS Code Extension — FFI Layer)
**Status:** 🟢 **IN PROGRESS** — VSC-1 complete, VSC-2B ready to start

**Context:** PRD_VSCode_Extension.md validation identified critical gaps preventing implementation. This phase resolves 🔴 BLOCKER issues by establishing a bridge between Swift and Node.js.

### VSC-1: Integration Architecture Decision **[P0]**
**Dependencies:** EE8 (Phase 10 — EditorEngine complete)
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-23

- [x] **[P0, depends: EE8]** Evaluate integration options:
  - [x] Option A: Language Server Protocol (LSP) — standard, multi-editor support
  - [x] Option B: CLI + JSON-RPC — simple, process-based communication
  - [x] Option C: Node.js Native Addon (FFI) — fast, in-process calls
- [x] **[P0, depends: EE8]** Analyzed performance characteristics (startup time, latency, throughput)
- [x] **[P0, depends: EE8]** Document trade-offs (complexity, maintainability, cross-platform support)
- [x] **[P1, depends: EE8]** Choose architecture: **CLI for MVP, LSP for long-term**
- [x] **[P1, depends: EE8]** Document decision in DOCS/ARCHITECTURE_DECISIONS.md (ADR-001)

**Acceptance Criteria:** ✅ Architecture chosen, trade-offs documented, ADR created

**Blocks:** VSC-2B (CLI implementation chosen for Phase 11-12)

**Resolution Status:** ✅ RESOLVED — CLI + JSON-RPC chosen for MVP, LSP migration path defined

---

### VSC-2A: Language Server Implementation (if LSP chosen) **[P1]**
**Dependencies:** VSC-1
**Estimated:** 12 hours
**Status:** ⏸️ DEFERRED to Phase 14+ (Long-term migration from CLI to LSP)

- [ ] **[P0, depends: VSC-1]** Create `Sources/LanguageServer/` module in Swift
- [ ] **[P0, depends: VSC-1]** Implement LSP server skeleton (initialize, shutdown, exit)
- [ ] **[P0, depends: VSC-1]** Add JSON-RPC message handling (stdio transport)
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/didOpen` notification
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/didChange` notification
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/didSave` notification
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/definition` request (go-to-definition)
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/hover` request
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/publishDiagnostics` notification
- [ ] **[P1, depends: VSC-1]** Add LSP server build target (executable)
- [ ] **[P1, depends: VSC-1]** Write integration tests (mock LSP client)
- [ ] **[P1, depends: VSC-1]** Document LSP capabilities in DOCS/LSP.md

**Acceptance Criteria:** LSP server binary runs, handles basic requests, integrates with EditorEngine

**Blocks:** VSC-4 (extension needs LSP server)

**Resolution Status:** Deferred — CLI chosen for MVP

---

### VSC-2B: CLI JSON-RPC Interface **[P0]** ⭐ CHOSEN FOR MVP
**Dependencies:** VSC-1
**Estimated:** 8 hours
**Status:** ✅ **Completed (MVP)** on 2025-12-23

- [x] **[P0, depends: VSC-1]** Add `hyperprompt editor-rpc` CLI subcommand
- [x] **[P0, depends: VSC-1]** Implement JSON-RPC message handling (stdin/stdout)
- [x] **[P0, depends: VSC-1]** Add `editor.indexProject` RPC method
- [ ] **[P0, depends: VSC-1]** Add `editor.parse` RPC method (deferred to Phase 2)
- [ ] **[P0, depends: VSC-1]** Add `editor.resolve` RPC method (deferred to Phase 2)
- [ ] **[P0, depends: VSC-1]** Add `editor.compile` RPC method (deferred to Phase 2)
- [ ] **[P0, depends: VSC-1]** Add `editor.linkAt` RPC method (deferred to Phase 2)
- [x] **[P1, depends: VSC-1]** Handle errors gracefully (JSON error responses)
- [ ] **[P1, depends: VSC-1]** Write CLI RPC integration tests (deferred)
- [x] **[P1, depends: VSC-1]** Document RPC protocol in DOCS/RPC_PROTOCOL.md

**Acceptance Criteria (MVP):** CLI accepts JSON-RPC requests, returns JSON responses, indexProject method working

**Blocks:** VSC-4 (extension needs RPC interface) — MVP sufficient for initial integration

**Resolution Status:** ✅ MVP Complete — 4 methods deferred to VSC-2B-EXT (Phase 2)

---

### VSC-2C: Node.js Native Addon (if FFI chosen) **[P2]**
**Dependencies:** VSC-1
**Estimated:** 14 hours
**Status:** ❌ REJECTED (Too complex, no performance need per ADR-001)

- [ ] **[P0, depends: VSC-1]** Create C API wrapper for EditorEngine
- [ ] **[P0, depends: VSC-1]** Define C-compatible structs (CProjectIndex, CLinkSpan, etc.)
- [ ] **[P0, depends: VSC-1]** Implement memory management (alloc/free functions)
- [ ] **[P0, depends: VSC-1]** Generate Node.js addon scaffold (node-gyp + binding.gyp)
- [ ] **[P0, depends: VSC-1]** Wrap C API with N-API bindings
- [ ] **[P0, depends: VSC-1]** Handle async calls (libuv thread pool)
- [ ] **[P1, depends: VSC-1]** Cross-compile for macOS (x64, arm64) and Linux (x64)
- [ ] **[P1, depends: VSC-1]** Package pre-built binaries for extension distribution
- [ ] **[P1, depends: VSC-1]** Write native addon tests (Node.js test suite)
- [ ] **[P1, depends: VSC-1]** Document FFI layer in DOCS/FFI_API.md

**Acceptance Criteria:** Node.js addon compiles, calls EditorEngine, handles memory correctly, works on all platforms

**Blocks:** VSC-4 (extension needs native addon)

**Resolution Status:** ❌ Rejected

---

## Phase 12: EditorEngine API Enhancements

**Goal:** Add missing APIs required by VS Code extension PRD
**Estimated Duration:** 14 hours (2 weeks)
**Track:** C (Editor Engine — API Extensions)
**Status:** ⏸️ **PENDING** — Requires VSC-2B completion

**Context:** VS Code extension requires position-based queries, workspace diagnostics, and async APIs not present in current EditorEngine.

### EE-EXT-1: Position-to-Link Query API **[P0]** ✅
**Dependencies:** EE8 (Phase 10 — EditorEngine complete)
**Estimated:** 3 hours
**Status:** ✅ **COMPLETED** on 2025-12-24

- [x] **[P0, depends: EE8]** Add `EditorParser.linkAt(line:column:) -> LinkSpan?` method
- [x] **[P0, depends: EE8]** Implement binary search over sorted link spans (O(log n) lookup)
- [x] **[P0, depends: EE8]** Handle edge cases:
  - [x] Position before first link → return nil
  - [x] Position after last link → return nil
  - [x] Position between links → return nil
  - [x] Position at link boundary → return link
  - [x] Overlapping ranges → return first match
- [ ] **[P1, depends: EE8]** Add `ParsedFile.linksAt(range:) -> [LinkSpan]` for range queries (deferred to Phase 2)
- [x] **[P1, depends: EE8]** Write unit tests (21 comprehensive test cases)

**Acceptance Criteria:** ✅ Position queries return correct link or nil, O(log n) performance verified

**Code Location:** `Sources/EditorEngine/EditorParser.swift:1`

**Blocks:** VSC-5 (go-to-definition and hover need this API)

**Resolution Status:** 🔴 BLOCKER (Issue 1.2 from validation report)

---

### EE-EXT-2: Workspace-Level Diagnostics **[P1]**
**Dependencies:** EE8
**Estimated:** 4 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: EE8]** Add `EditorEngine.validateWorkspace(root:options:) -> [String: [Diagnostic]]` method
- [ ] **[P1, depends: EE8]** Return diagnostics grouped by file path (dictionary)
- [ ] **[P1, depends: EE8]** Implement incremental validation (only changed files)
- [ ] **[P1, depends: EE8]** Handle multi-file errors (e.g., circular dependencies spanning files)
- [ ] **[P1, depends: EE8]** Add performance optimization (parallel file validation)
- [ ] **[P1, depends: EE8]** Write unit tests (workspace with 50+ files)

**Acceptance Criteria:** Workspace validation returns diagnostics for all files, <5s for 100-file workspace

**Blocks:** VSC-6 (Problems panel needs workspace diagnostics)

**Resolution Status:** 🟠 CRITICAL (Issue 2.1 from validation report)

---

### EE-EXT-3: Source Map Generation **[P2]**
**Dependencies:** EE8
**Estimated:** 5 hours
**Status:** ⏸️ Pending

- [ ] **[P2, depends: EE8]** Define `SourceMap` struct (output line → source location mapping)
- [ ] **[P2, depends: EE8]** Extend `Emitter` to track source ranges during compilation
- [ ] **[P2, depends: EE8]** Add `CompileResult.sourceMap` field (optional)
- [ ] **[P2, depends: EE8]** Implement JSON source map format (compatible with browser devtools)
- [ ] **[P2, depends: EE8]** Add `SourceMap.lookup(outputLine:) -> SourceLocation?` method
- [ ] **[P2, depends: EE8]** Write unit tests (verify source map accuracy for nested files)

**Acceptance Criteria:** Source maps correctly map output lines to source locations

**Blocks:** VSC-7 (bidirectional navigation feature — Phase 4 of PRD)

**Resolution Status:** 🟠 CRITICAL (Issue 2.2 from validation report — optional feature)

---

### EE-EXT-4: Multi-Root Workspace Support **[P1]**
**Dependencies:** EE8
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: EE8]** Update `EditorResolver.init` to accept `workspaceRoots: [String]`
- [ ] **[P1, depends: EE8]** Update resolution algorithm to search all roots in order
- [ ] **[P1, depends: EE8]** Document priority rules (first match wins)
- [ ] **[P1, depends: EE8]** Handle ambiguous references across roots (error or first match?)
- [ ] **[P1, depends: EE8]** Write unit tests (multi-root workspace scenarios)

**Acceptance Criteria:** Resolver handles multiple workspace roots, priority documented

**Code Location:** `Sources/EditorEngine/EditorResolver.swift:157`

**Resolution Status:** 🟠 CRITICAL (Issue 2.3 from validation report)

---

### EE-EXT-5: Async API Variants **[P1]**
**Dependencies:** EE8
**Estimated:** 3 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: EE8]** Add `async` variants of blocking methods:
  - [ ] `EditorParser.parse(filePath:) async -> ParsedFile`
  - [ ] `EditorCompiler.compile(entryFile:options:) async -> CompileResult`
  - [ ] `EditorEngine.indexProject(workspaceRoot:) async -> ProjectIndex`
  - [ ] `EditorEngine.validateWorkspace(root:) async -> [String: [Diagnostic]]`
- [ ] **[P1, depends: EE8]** Use Swift concurrency (async/await, Task)
- [ ] **[P1, depends: EE8]** Ensure thread-safety (all types already Sendable)
- [ ] **[P1, depends: EE8]** Write async tests using XCTest async support

**Acceptance Criteria:** Async methods don't block caller, thread-safe, tests pass

**Resolution Status:** 🟠 CRITICAL (Issue 2.4 from validation report)

---

### EE-EXT-6: Documentation & Semantic Clarifications **[P1]**
**Dependencies:** EE-EXT-1, EE-EXT-2, EE-EXT-3, EE-EXT-4, EE-EXT-5
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: EE-EXT-1..5]** Update DOCS/EDITOR_ENGINE.md with new APIs
- [ ] **[P1, depends: EE8]** Document `LinkSpan.referenceHint` semantics (when to trust it)
- [ ] **[P1, depends: EE8]** Document `CompileResult.manifest` JSON schema
- [ ] **[P1, depends: EE8]** Document error recovery behavior (partial AST semantics)
- [ ] **[P1, depends: EE8]** Document resolution mode trade-offs (strict vs lenient)
- [ ] **[P1, depends: EE8]** Add code examples for all new APIs

**Acceptance Criteria:** All new APIs documented, semantic ambiguities resolved

**Resolution Status:** 🟡 MAJOR (Issues 3.1, 3.3, 3.4, 3.5 from validation report)

---

## Phase 13: Performance & Incremental Compilation

**Goal:** Achieve <200ms compile time for medium projects (50 files, 5000 lines)
**Estimated Duration:** 15 hours (2 weeks)
**Track:** C (Editor Engine — Performance)
**Status:** ⏸️ **PENDING** — Requires Phase 12 completion

**Context:** PRD requires live preview with <200ms compile time, but EditorCompiler always performs full recompilation.

### PERF-1: Performance Baseline & Benchmarks **[P0]**
**Dependencies:** EE8 (Phase 10 — EditorEngine complete)
**Estimated:** 3 hours
**Status:** 🟢 **IN PROGRESS**

- [ ] **[P0, depends: EE8]** Define "medium project" benchmark (50 files, 5000 lines total)
- [ ] **[P0, depends: EE8]** Create synthetic benchmark corpus (auto-generated .hc files)
- [ ] **[P0, depends: EE8]** Implement performance test suite (XCTest with XCTMeasure)
- [ ] **[P0, depends: EE8]** Baseline current performance:
  - [ ] Full compilation time (entry file → output)
  - [ ] Parse time per file
  - [ ] Resolution time per link
  - [ ] Emission time
- [ ] **[P1, depends: EE8]** Add CI job to track performance over commits
- [ ] **[P1, depends: EE8]** Document baseline in DOCS/PERFORMANCE.md

**Acceptance Criteria:** Benchmark suite runs, baseline documented, CI monitors regressions

**Blocks:** PERF-2 (optimization needs baseline)

**Resolution Status:** 🟡 MAJOR (Issue 3.2 from validation report)

---

### PERF-2: Incremental Compilation — File Caching **[P0]**
**Dependencies:** PERF-1
**Estimated:** 6 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: PERF-1]** Implement `ParsedFileCache` (file path → (checksum, ParsedFile))
- [ ] **[P0, depends: PERF-1]** Compute file checksums (SHA256 or faster hash)
- [ ] **[P0, depends: PERF-1]** Skip parsing if file unchanged (checksum match)
- [ ] **[P0, depends: PERF-1]** Invalidate cache on file change (checksum mismatch)
- [ ] **[P0, depends: PERF-1]** Handle cascading invalidation (referenced files changed)
- [ ] **[P1, depends: PERF-1]** Add cache eviction policy (LRU, max 1000 entries)
- [ ] **[P1, depends: PERF-1]** Write unit tests (cache hit/miss scenarios)

**Acceptance Criteria:** Cache reduces parse time by >80% on second compile, invalidation works correctly

**Blocks:** PERF-3 (dependency graph needs cached ASTs)

**Resolution Status:** 🔴 BLOCKER (Issue 1.3 from validation report)

---

### PERF-3: Incremental Compilation — Dependency Graph **[P0]**
**Dependencies:** PERF-2
**Estimated:** 4 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: PERF-2]** Build dependency graph (file → [referenced files])
- [ ] **[P0, depends: PERF-2]** Implement topological sort for compilation order
- [ ] **[P0, depends: PERF-2]** Track "dirty" files (changed since last compile)
- [ ] **[P0, depends: PERF-2]** Recompile only dirty files and their dependents
- [ ] **[P0, depends: PERF-2]** Merge incremental results into existing AST
- [ ] **[P1, depends: PERF-2]** Handle deletion of referenced files (invalidate cache)
- [ ] **[P1, depends: PERF-2]** Write unit tests (incremental vs full compile equivalence)

**Acceptance Criteria:** Incremental compile produces identical output to full compile, but faster

**Resolution Status:** 🔴 BLOCKER (Issue 1.3 from validation report)

---

### PERF-4: Performance Validation **[P0]**
**Dependencies:** PERF-3
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: PERF-3]** Re-run benchmark suite with incremental compilation
- [ ] **[P0, depends: PERF-3]** Verify <200ms for medium project (second compile)
- [ ] **[P0, depends: PERF-3]** Verify <1s for large project (120 files, 12000 lines)
- [ ] **[P0, depends: PERF-3]** Profile hot paths (Instruments or perf)
- [ ] **[P1, depends: PERF-3]** Document performance characteristics in DOCS/PERFORMANCE.md
- [ ] **[P1, depends: PERF-3]** Add performance regression tests to CI

**Acceptance Criteria:** <200ms compile time met, performance documented

**Resolution Status:** 🔴 BLOCKER (Issue 1.3 from validation report)

---

## Phase 14: VS Code Extension Development

**Goal:** Implement VS Code extension per PRD_VSCode_Extension.md
**Estimated Duration:** 35 hours (4-5 weeks)
**Track:** D (VS Code Extension — Client Implementation)
**Status:** ⏸️ **PENDING** — Requires Phase 11, 12, 13 completion

**Context:** With FFI layer, enhanced APIs, and performance optimizations in place, implement the TypeScript extension.

### VSC-3: Extension Scaffold **[P0]**
**Dependencies:** VSC-2A or VSC-2B or VSC-2C (integration layer chosen)
**Estimated:** 3 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-2*]** Initialize extension with `yo code` (TypeScript)
- [ ] **[P1, depends: VSC-2*]** Configure package.json metadata:
  - [ ] Extension ID: `anthropic.hyperprompt`
  - [ ] Publisher: `anthropic`
  - [ ] Repository URL
  - [ ] License (match Hyperprompt project)
- [ ] **[P0, depends: VSC-2*]** Register `.hc` file association
- [ ] **[P0, depends: VSC-2*]** Configure activation events (`onLanguage:hypercode`)
- [ ] **[P1, depends: VSC-2*]** Add TextMate grammar for syntax highlighting (`.tmLanguage.json`)
- [ ] **[P1, depends: VSC-2*]** Configure extension icon and colors
- [ ] **[P1, depends: VSC-2*]** Verify extension loads in VS Code dev mode

**Acceptance Criteria:** Extension scaffold builds, activates on .hc files, syntax highlighting works

**Blocks:** VSC-4 (client integration needs scaffold)

**Resolution Status:** ✅ Addresses PRD Phase 0 (Project Setup)

---

### VSC-4B: CLI RPC Client Integration (if CLI) **[P0]**
**Dependencies:** VSC-2B, VSC-3
**Estimated:** 3 hours
**Status:** ⏸️ Pending (conditional)

- [ ] **[P0, depends: VSC-2B, VSC-3]** Implement JSON-RPC client (stdio transport)
- [ ] **[P0, depends: VSC-2B, VSC-3]** Spawn `hyperprompt-editor` process on activation
- [ ] **[P0, depends: VSC-2B, VSC-3]** Handle process lifecycle (restart on crash)
- [ ] **[P1, depends: VSC-2B, VSC-3]** Implement request/response handling
- [ ] **[P1, depends: VSC-2B, VSC-3]** Add request timeout (5s default)
- [ ] **[P1, depends: VSC-2B, VSC-3]** Test RPC client (mock CLI)

**Acceptance Criteria:** RPC client sends requests, receives responses, handles errors

**Resolution Status:** ✅ Addresses FFI blocker (CLI option)

---

### VSC-5: Navigation Features **[P0]**
**Dependencies:** VSC-4*, EE-EXT-1
**Estimated:** 5 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-4*, EE-EXT-1]** Implement `DefinitionProvider` for go-to-definition
- [ ] **[P0, depends: VSC-4*, EE-EXT-1]** Call `EditorParser.linkAt(line:column:)` on definition request
- [ ] **[P0, depends: VSC-4*, EE-EXT-1]** Resolve link with `EditorResolver`
- [ ] **[P0, depends: VSC-4*, EE-EXT-1]** Navigate to resolved file path
- [ ] **[P1, depends: VSC-4*, EE-EXT-1]** Implement `HoverProvider` for hover tooltips
- [ ] **[P1, depends: VSC-4*, EE-EXT-1]** Show resolved path and status in hover
- [ ] **[P1, depends: VSC-4*, EE-EXT-1]** Handle unresolved links (show inline text message)
- [ ] **[P1, depends: VSC-4*, EE-EXT-1]** Write extension tests (integration)

**Acceptance Criteria:** Go-to-definition works on all file references, hover shows resolved path

**Blocks:** None (core feature)

**Resolution Status:** ✅ Addresses PRD Phase 1 (Editor Navigation)

---

### VSC-6: Diagnostics Integration **[P0]**
**Dependencies:** VSC-4*, EE-EXT-2
**Estimated:** 4 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-4*, EE-EXT-2]** Implement `DiagnosticCollection` for Problems panel
- [ ] **[P0, depends: VSC-4*, EE-EXT-2]** Call `EditorEngine.validateWorkspace()` on file save
- [ ] **[P0, depends: VSC-4*, EE-EXT-2]** Map `Diagnostic[]` to VS Code diagnostics
- [ ] **[P0, depends: VSC-4*, EE-EXT-2]** Set severity (error, warning, info, hint)
- [ ] **[P0, depends: VSC-4*, EE-EXT-2]** Set source ("Hyperprompt")
- [ ] **[P1, depends: VSC-4*, EE-EXT-2]** Implement incremental diagnostic updates (only changed files)
- [ ] **[P1, depends: VSC-4*, EE-EXT-2]** Clear diagnostics when file is fixed
- [ ] **[P1, depends: VSC-4*, EE-EXT-2]** Write extension tests

**Acceptance Criteria:** Errors appear in Problems panel, jump to correct location, clear when fixed

**Blocks:** None (core feature)

**Resolution Status:** ✅ Addresses PRD Phase 3 (Diagnostics)

---

### VSC-7: Live Preview Panel **[P0]**
**Dependencies:** VSC-4*, PERF-4
**Estimated:** 6 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-4*, PERF-4]** Create Webview panel for Markdown preview
- [ ] **[P0, depends: VSC-4*, PERF-4]** Register `hyperprompt.preview` command
- [ ] **[P0, depends: VSC-4*, PERF-4]** Call `EditorCompiler.compile()` on file save
- [ ] **[P0, depends: VSC-4*, PERF-4]** Render Markdown output in Webview
- [ ] **[P1, depends: VSC-4*, PERF-4]** Use incremental compilation for <200ms update
- [ ] **[P1, depends: VSC-4*, PERF-4]** Sync scroll position (preview follows editor)
- [ ] **[P1, depends: VSC-4*, PERF-4]** Add preview refresh command (manual override)
- [ ] **[P2, depends: VSC-4*, PERF-4]** Style Markdown with VS Code theme CSS
- [ ] **[P1, depends: VSC-4*, PERF-4]** Write extension tests

**Acceptance Criteria:** Preview updates on save, <200ms latency, Markdown rendered correctly

**Blocks:** None (core feature)

**Resolution Status:** ✅ Addresses PRD Phase 2 (Compilation & Preview)

---

### VSC-8: Extension Settings **[P1]**
**Dependencies:** VSC-4*
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: VSC-4*]** Add configuration schema to package.json
- [ ] **[P1, depends: VSC-4*]** Add `hyperprompt.resolutionMode` setting (strict/lenient)
- [ ] **[P1, depends: VSC-4*]** Add `hyperprompt.previewAutoUpdate` setting (boolean)
- [ ] **[P1, depends: VSC-4*]** Add `hyperprompt.diagnosticsEnabled` setting (boolean)
- [ ] **[P2, depends: VSC-4*]** Add `hyperprompt.server.path` setting (LSP/CLI executable path)
- [ ] **[P2, depends: VSC-4*]** Add `hyperprompt.server.logLevel` setting (error/warn/info/debug)
- [ ] **[P1, depends: VSC-4*]** Implement settings change handler (restart server if needed)
- [ ] **[P1, depends: VSC-4*]** Document settings in README

**Acceptance Criteria:** Settings work, changes apply correctly, documented

**Resolution Status:** ✅ Addresses resolution mode ambiguity (Issue 3.1)

---

### VSC-9: Multi-Column Workflow (Optional) **[P2]**
**Dependencies:** VSC-5, EE-EXT-4
**Estimated:** 3 hours
**Status:** ⏸️ Pending

- [ ] **[P2, depends: VSC-5, EE-EXT-4]** Open referenced files in editor group beside source
- [ ] **[P2, depends: VSC-5, EE-EXT-4]** Configure 3-column layout (source | reference | preview)
- [ ] **[P2, depends: VSC-5, EE-EXT-4]** Add `hyperprompt.openBeside` command
- [ ] **[P2, depends: VSC-5, EE-EXT-4]** Test multi-root workspace support
- [ ] **[P2, depends: VSC-5, EE-EXT-4]** Write extension tests

**Acceptance Criteria:** Multi-column layout works, navigation preserves layout

**Resolution Status:** ✅ Addresses PRD Phase 4 (UX Enhancements)

---

### VSC-10: Bidirectional Navigation (Optional) **[P2]**
**Dependencies:** VSC-7, EE-EXT-3
**Estimated:** 4 hours
**Status:** ⏸️ Pending

- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Implement click handler in preview Webview
- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Send message to extension (line number clicked)
- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Lookup source location from `SourceMap`
- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Navigate to source file and highlight range
- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Test source map accuracy
- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Write extension tests

**Acceptance Criteria:** Click in preview jumps to source, correct line highlighted

**Resolution Status:** ✅ Addresses PRD Phase 4.4.2 (Output → Source Navigation)

---

### VSC-11: Extension Testing & QA **[P0]**
**Dependencies:** VSC-5, VSC-6, VSC-7
**Estimated:** 4 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-5, VSC-6, VSC-7]** Write extension integration tests (VS Code Test API)
- [ ] **[P0, depends: VSC-5, VSC-6, VSC-7]** Test all features with corpus files (V01-V14, I01-I10)
- [ ] **[P0, depends: VSC-5, VSC-6, VSC-7]** Verify error handling (server crash, timeout, invalid response)
- [ ] **[P1, depends: VSC-5, VSC-6, VSC-7]** Test multi-root workspace scenarios
- [ ] **[P1, depends: VSC-5, VSC-6, VSC-7]** Test performance (large files, many diagnostics)
- [ ] **[P1, depends: VSC-5, VSC-6, VSC-7]** Add CI job for extension tests
- [ ] **[P1, depends: VSC-5, VSC-6, VSC-7]** Achieve >70% code coverage

**Acceptance Criteria:** All features tested, edge cases covered, CI passes

**Resolution Status:** ✅ Addresses PRD quality requirements

---

### VSC-12: Extension Documentation & Release **[P0]**
**Dependencies:** VSC-11
**Estimated:** 3 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-11]** Write extension README (features, installation, usage)
- [ ] **[P0, depends: VSC-11]** Add screenshots/GIFs demonstrating features
- [ ] **[P0, depends: VSC-11]** Document system requirements (macOS/Linux only)
- [ ] **[P0, depends: VSC-11]** Write CHANGELOG
- [ ] **[P1, depends: VSC-11]** Package extension (.vsix)
- [ ] **[P1, depends: VSC-11]** Test installation from VSIX
- [ ] **[P2, depends: VSC-11]** Publish to VS Code Marketplace (manual step)
- [ ] **[P1, depends: VSC-11]** Tag release (v0.1.0)

**Acceptance Criteria:** Extension packaged, README complete, ready for distribution

**Resolution Status:** ✅ Addresses PRD deliverables

---

## Phase 15: PRD Validation & Gap Closure

**Goal:** Verify all PRD_VSCode_Extension.md requirements met
**Estimated Duration:** 4 hours
**Track:** D (VS Code Extension — Validation)
**Status:** ⏸️ **PENDING** — Final validation phase

### PRD-VAL-1: PRD Requirements Checklist **[P0]**
**Dependencies:** VSC-12 (extension complete)
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-12]** Verify all Section 1.2 deliverables:
  - [ ] VS Code Extension published
  - [ ] Language support (syntax, file associations)
  - [ ] Navigation features (go-to-def, peek)
  - [ ] Live preview panel
  - [ ] Diagnostics integration
  - [ ] Build integration (trait-enabled)
- [ ] **[P0, depends: VSC-12]** Verify all Section 1.3 success criteria:
  - [ ] Opening .hc activates extension
  - [ ] File references navigable
  - [ ] Compilation results visible real-time
  - [ ] Errors in VS Code diagnostics
  - [ ] Works without modifying CLI
- [ ] **[P0, depends: VSC-12]** Verify all functional requirements (Section 4.2):
  - [ ] FR-1: Recognize .hc files
  - [ ] FR-2: Navigate file references
  - [ ] FR-3: Compile via EditorEngine
  - [ ] FR-4: Show Markdown preview
  - [ ] FR-5: Surface diagnostics
- [ ] **[P0, depends: VSC-12]** Verify non-functional requirements (Section 4.3):
  - [ ] Performance: <200ms compile
  - [ ] Reliability: No crashes on invalid input
  - [ ] Isolation: No compiler logic in JS
  - [ ] Portability: macOS + Linux
  - [ ] Determinism: Matches CLI output

**Acceptance Criteria:** All PRD requirements verified, checklist documented

**Resolution Status:** ✅ Final validation

---

### PRD-VAL-2: Validation Report Update **[P1]**
**Dependencies:** PRD-VAL-1
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: PRD-VAL-1]** Update DOCS/PRD_VALIDATION_VSCode_Extension.md
- [ ] **[P1, depends: PRD-VAL-1]** Mark all blockers as resolved (🔴 → ✅)
- [ ] **[P1, depends: PRD-VAL-1]** Mark all critical issues as resolved (🟠 → ✅)
- [ ] **[P1, depends: PRD-VAL-1]** Mark all major issues as resolved (🟡 → ✅)
- [ ] **[P1, depends: PRD-VAL-1]** Document final architecture chosen (LSP/CLI/FFI)
- [ ] **[P1, depends: PRD-VAL-1]** Document performance benchmarks achieved
- [ ] **[P1, depends: PRD-VAL-1]** Add "Resolution Summary" section
- [ ] **[P1, depends: PRD-VAL-1]** Update PRD quality assessment (5/10 → 9/10 feasibility)

**Acceptance Criteria:** Validation report reflects completed work, all gaps closed

**Resolution Status:** ✅ Documentation closure

---

## Progress Tracking

**Overall Progress:** 160 / 245 tasks completed (65%)
- **Phases 1-10 (Complete):** 159 tasks ✅
- **Phases 11-15 (In Progress):** 1 / 86 tasks (VSC-1 complete)

### By Phase
- [x] **Phases 1-10:** Complete (see archive) — **131h** ✅
- [~] **Phase 11:** VS Code Integration Architecture (1/3 major tasks) — **14h remaining**
- [ ] **Phase 12:** EditorEngine API Enhancements (0/6 major tasks) — **14h**
- [ ] **Phase 13:** Performance & Incremental Compilation (0/4 major tasks) — **15h**
- [ ] **Phase 14:** VS Code Extension Development (0/10 major tasks) — **35h**
- [ ] **Phase 15:** PRD Validation & Gap Closure (0/2 major tasks) — **4h**

### By Priority (Phases 11-15 only)
- **[P0] Critical:** 1 / 22 tasks complete (VSC-1)
- **[P1] High:** 0 / 57 tasks
- **[P2] Medium:** 0 / 8 tasks

### By Track
- **Track C (Editor Engine):** Phase 12, 13 — 29 hours ⏸️ Pending
- **Track D (VS Code Extension):** Phase 11, 14, 15 — 53 hours (4h complete, 49h pending)

---

## Summary: Active Phases Overview

| Phase | Title | Duration | Status | Addresses |
|-------|-------|----------|--------|-----------|
| **Phase 11** | VS Code Extension Integration Architecture | 14h remaining | 🟢 In Progress (VSC-1 ✅) | 🔴 FFI Blocker |
| **Phase 12** | EditorEngine API Enhancements | 14h | ⏸️ Pending | 🟠 Critical APIs |
| **Phase 13** | Performance & Incremental Compilation | 15h | ⏸️ Pending | 🔴 Performance Blocker |
| **Phase 14** | VS Code Extension Development | 35h | ⏸️ Pending | ✅ PRD Implementation |
| **Phase 15** | PRD Validation & Gap Closure | 4h | ⏸️ Pending | ✅ Final Validation |

**Next Task:** VSC-2B (CLI JSON-RPC Interface) — 8 hours

---

## Revision History

| Version | Date       | Author          | Changes                                              |
|---------|------------|-----------------|------------------------------------------------------|
| 4.0.0   | 2025-12-23 | Claude (AI)     | Archive Phases 1-10, focus on Phases 11-15 only. VSC-1 completed (ADR-001). |
| 3.0.0   | 2025-12-23 | Claude (AI)     | Add Phase 11-15 for VS Code Extension (86h total) |
| 2.0.0   | 2025-12-02 | Egor Merkushev  | Add priorities, dependencies, tracks, critical path |
| 1.0.0   | 2025-12-02 | Egor Merkushev  | Initial work plan creation                           |

# Critical Validation Report: PRD_VSCode_Extension.md vs EditorEngine Implementation

**Date:** 2025-12-23
**Branch:** SoundBlaster-patch-1
**Reviewer:** EditorEngine Module Analysis
**Status:** ⚠️ **MAJOR GAPS IDENTIFIED**

---

## Executive Summary

The PRD for the VS Code extension (`PRD_VSCode_Extension.md`) describes a JavaScript/TypeScript-based VS Code extension that integrates with EditorEngine. However, **critical architectural gaps** exist between the PRD's requirements and the current Swift-based EditorEngine implementation.

### Severity Levels
- 🔴 **BLOCKER**: Cannot implement PRD without this
- 🟠 **CRITICAL**: Major feature gap or architectural mismatch
- 🟡 **MAJOR**: Significant implementation work required
- 🔵 **MINOR**: Enhancement or clarification needed

---

## 1. BLOCKERS 🔴

### 1.1 No Foreign Function Interface (FFI) for Node.js/TypeScript

**Issue:** The PRD assumes a VS Code extension (Node.js/TypeScript) can call EditorEngine APIs, but EditorEngine is written in Swift with no interoperability layer.

**Current State:**
- EditorEngine is a Swift library
- No C API/FFI layer exposed
- No Node.js bindings or WASM compilation
- No CLI/IPC interface for external tools

**Impact:** VS Code extension cannot invoke any EditorEngine functionality.

**Required Work:**
1. Create a C-compatible API layer wrapping EditorEngine
2. Generate Node.js native bindings (using node-addon-api or napi-rs)
3. OR: Create a separate CLI/daemon for EditorEngine that communicates via JSON-RPC/LSP
4. OR: Compile EditorEngine to WebAssembly (requires Swift → WASM toolchain)

**PRD References:**
- Section 1.5: "Swift Toolchain | Native engine execution" (assumes some integration path)
- Section 2.2.1: "Call EditorEngine.compile()" (from TypeScript - impossible without FFI)

**Estimated Effort:** 2-3 weeks for C API + Node.js bindings

---

### 1.2 No Position-to-Link Lookup API

**Issue:** PRD requires "go-to-definition" and "hover" features based on cursor position (line, column), but EditorEngine has no API to query "which link is at this position?"

**Current State:**
- `EditorParser` returns `linkSpans: [LinkSpan]`
- `LinkSpan` contains `byteRange`, `lineRange`, `columnRange`
- NO method: `func linkAt(line: Int, column: Int) -> LinkSpan?`
- Extension would need to implement linear search over all link spans

**Impact:**
- Go-to-definition (PRD 2.1.1) requires custom position matching logic
- Hover information (PRD 2.1.2) has same problem
- Performance degrades with large files (O(n) search per hover)

**Required Work:**
1. Add `EditorParser.linkAt(position:)` method
2. Consider spatial index (interval tree) for efficient lookups
3. Handle edge cases (overlapping ranges, zero-width ranges)

**Code Location:** `Sources/EditorEngine/EditorParser.swift:1`

**Estimated Effort:** 2-3 days

---

### 1.3 No Incremental Compilation / Watch Mode

**Issue:** PRD Phase 2.2.2 requires "Preview updates on file save" with <200ms compile time, but EditorCompiler always performs full compilation.

**Current State:**
- `EditorCompiler.compile(entryFile:options:)` compiles entire project
- No file watching
- No incremental compilation
- No caching of parsed ASTs or resolved references

**Impact:**
- Every file save triggers full recompilation
- Large projects will exceed 200ms performance budget
- Inefficient resource usage

**Required Work:**
1. Implement incremental compilation (cache parsed files, only recompile changed subtree)
2. Add file change detection (checksum/mtime tracking)
3. Implement invalidation strategy for dependency graphs
4. OR: Accept performance hit and document limitation

**PRD References:**
- Section 4.3: "Performance | <200ms compile for medium projects"
- Section 2.2.2: "Preview updates on file save"

**Estimated Effort:** 1-2 weeks for incremental compilation

---

## 2. CRITICAL ISSUES 🟠

### 2.1 Diagnostics API Mismatch

**Issue:** VS Code Diagnostics API expects file-level diagnostic collections, but EditorEngine returns diagnostics only for the compiled entry file.

**Current State:**
- `CompileResult` has `diagnostics: [CompilerError]`
- Diagnostics include `.location` with file path
- BUT: Compilation is entry-file-centric, not workspace-centric
- No API to get diagnostics for all files in workspace

**Impact:**
- Extension cannot populate Problems panel for all workspace files
- Only active file shows errors
- Referenced files with errors are hidden

**Required Work:**
1. Add `EditorEngine.validateWorkspace(root:)` method
2. Return diagnostics grouped by file path
3. Consider performance implications (validating entire workspace on every change)

**PRD References:**
- Section 2.3.1: "Error Reporting | Problems panel entries"
- Section 1.3: "Errors appear as VS Code diagnostics"

**Estimated Effort:** 3-5 days

---

### 2.2 No Source Map for Output → Source Navigation

**Issue:** PRD Phase 4.4.2 (optional) requires "Click in preview → Jump to source" using SourceMap, but EditorEngine does not generate source maps.

**Current State:**
- `CompileResult` has `output: String?` (compiled Markdown)
- `CompileResult` has `manifest: String?` (JSON metadata)
- NO source map tracking which Markdown lines correspond to which .hc lines
- Manifest does not include source mapping info

**Impact:**
- Cannot implement bidirectional navigation (preview ↔ source)
- User experience degraded for long documents

**Required Work:**
1. Extend `Emitter` to track source ranges during compilation
2. Add source map to `CompileResult` (JSON format like `{line: 10, sourceFile: "foo.hc", sourceLine: 5}`)
3. Expose source map to extension via FFI

**PRD References:**
- Section 2.4.2: "Output → Source Navigation (Optional)"
- Tools: "Webview messaging"

**Estimated Effort:** 1 week

---

### 2.3 Multi-Root Workspace Ambiguity

**Issue:** VS Code supports multi-root workspaces, but `EditorResolver` assumes a single `workspaceRoot`.

**Current State:**
- `EditorResolver(workspaceRoot:mode:)` takes single root
- Resolution searches in `[workspaceRoot, sourceFileDir, currentDir]`
- Multi-root workspaces have multiple independent roots

**Impact:**
- Files in workspace B cannot reference files in workspace A
- Ambiguous references may not resolve correctly across workspace boundaries
- Extension needs to instantiate multiple resolvers (one per root)

**Required Work:**
1. Update `EditorResolver` to accept `[String]` (multiple roots)
2. Update resolution algorithm to search all roots
3. Document priority/precedence rules for multi-root scenarios

**Code Location:** `Sources/EditorEngine/EditorResolver.swift:157`

**Estimated Effort:** 2-3 days

---

### 2.4 No Streaming/Async API

**Issue:** EditorEngine APIs are synchronous, but Node.js ecosystem is async-first. Blocking the Node.js event loop during compilation will freeze the editor.

**Current State:**
- `EditorCompiler.compile(...)` is synchronous
- `EditorParser.parse(...)` is synchronous
- No async/await or callback-based variants

**Impact:**
- VS Code extension blocks during compilation (bad UX)
- Need to use worker threads or child processes to avoid blocking
- Complicates FFI layer (need to marshal data across thread boundary)

**Required Work:**
1. Provide async variants of key APIs (using Swift concurrency)
2. OR: Design FFI to use callbacks/promises
3. OR: Run EditorEngine in separate process and communicate via IPC

**PRD References:**
- Section 1.5: "Node.js | Extension runtime" (implies async patterns expected)

**Estimated Effort:** 3-5 days

---

## 3. MAJOR ISSUES 🟡

### 3.1 Resolution Mode Ambiguity

**Issue:** `EditorResolver` supports `strict` and `lenient` modes, but PRD does not specify which mode the extension should use or when to switch between them.

**Current State:**
- `ResolutionMode.strict`: errors on missing files, out-of-root references
- `ResolutionMode.lenient`: treats unresolved as inline text
- Default is `.strict` in `EditorResolver.init`

**Impact:**
- Strict mode may produce too many false-positive errors during authoring
- Lenient mode may hide real issues until compile time
- User frustration if mode doesn't match expectations

**Required Work:**
1. PRD should specify which mode to use
2. Consider exposing mode as user setting in extension
3. Document trade-offs in `EDITOR_ENGINE.md`

**Code Location:** `Sources/EditorEngine/EditorResolver.swift:35`

**PRD Gap:** Section 4.2 (Functional Requirements) does not mention resolution mode

---

### 3.2 Performance Benchmarks Missing

**Issue:** PRD requires "<200ms compile for medium projects" but no benchmarks or performance tests exist to validate this.

**Current State:**
- No performance tests in `EditorEngineTests`
- `CompileResult` has optional `statistics` but not exposed by default
- No definition of "medium project" (how many files? lines?)

**Impact:**
- Cannot validate if PRD requirement is met
- Risk of performance regressions
- Unclear if optimization work is needed

**Required Work:**
1. Define "medium project" benchmark (e.g., 50 files, 5000 lines total)
2. Create performance test suite
3. Add CI job to track compile time over commits
4. Document baseline performance in `EDITOR_ENGINE.md`

**PRD References:**
- Section 4.3: "Performance | <200ms compile for medium projects"

**Estimated Effort:** 2-3 days

---

### 3.3 LinkSpan.referenceHint Semantics Unclear

**Issue:** `LinkSpan` has a `referenceHint` field (enum `ReferenceHint`) but its purpose and reliability are not documented.

**Current State:**
- `LinkSpan.referenceHint` can be `.inlineText`, `.possibleFile`, etc. (assumed)
- Computed by `LinkReferenceHintDecisionSpec`
- No documentation on when to trust this hint vs. always resolving

**Impact:**
- Extension doesn't know if it should show "go-to-definition" affordance
- May attempt to resolve inline text (waste of resources)
- False positives/negatives in navigation UX

**Required Work:**
1. Document `referenceHint` semantics in `LinkSpan` type
2. Add tests for edge cases (e.g., "file.md" as inline text vs. reference)
3. Consider renaming to `isFileReference` (boolean) for clarity

**Code Location:** `Sources/EditorEngine/LinkSpan.swift:1`

---

### 3.4 Manifest JSON Format Not Specified

**Issue:** `CompileResult.manifest` returns JSON string, but PRD does not specify what this manifest contains or if extension needs it.

**Current State:**
- `EditorCompiler` can emit manifest JSON
- Format defined in `Emitter` module (not documented in EditorEngine)
- PRD does not mention manifest usage

**Impact:**
- Unclear if manifest is needed for extension features
- Wasted computation if extension doesn't use it
- Potential schema breakage if format changes

**Required Work:**
1. Clarify in PRD whether extension uses manifest
2. Document manifest JSON schema in `EDITOR_ENGINE.md`
3. Version the schema if it will be consumed externally

**PRD Gap:** No mention of manifest in Section 2 (TODO Plan) or Section 4 (Features)

---

### 3.5 Error Recovery Quality Unknown

**Issue:** `EditorParser` uses `parseWithRecovery`, but recovery quality and partial AST behavior are not documented.

**Current State:**
- `Parser.parseWithRecovery(tokens:)` returns partial AST + diagnostics
- No specification of what "partial AST" means
- Unclear how navigation features behave with partial ASTs

**Impact:**
- Go-to-definition may not work in files with syntax errors
- Unpredictable behavior during authoring (common case!)
- User confusion if features stop working on syntax errors

**Required Work:**
1. Document error recovery guarantees in `Parser` module
2. Test navigation features with files containing syntax errors
3. Add PRD section on error handling for extension features

**Code Location:** `Sources/EditorEngine/EditorParser.swift:87`

**PRD Gap:** Section 4.5 (Edge Cases) mentions "Invalid syntax" but not impact on navigation

---

## 4. MINOR ISSUES 🔵

### 4.1 Syntax Highlighting Not in Scope

**Issue:** PRD mentions "Syntax highlighting, file associations" (Section 1.2) but EditorEngine does not provide syntax highlighting.

**Current State:**
- EditorEngine has no syntax highlighting API
- VS Code syntax highlighting uses TextMate grammars (JSON/YAML)
- Typically a separate file (`.tmLanguage.json`)

**Impact:** None - syntax highlighting is orthogonal to EditorEngine.

**Clarification:** PRD should note that syntax highlighting is handled by VS Code grammar files, not EditorEngine APIs.

---

### 4.2 "Trait Editor" Terminology Confusion

**Issue:** PRD mentions "trait `Editor` must be enabled" but there's confusion between:
1. SwiftPM trait named `Editor` (build configuration)
2. A Swift protocol named `Editor` (does not exist)

**Current State:**
- `Package.swift` defines trait `Editor` (SwiftPM feature)
- No protocol/trait called `Editor` in code
- `EditorEngine` is an enum, not a protocol/trait

**Impact:** Readers may expect a protocol-oriented API.

**Clarification:** Update PRD to say "SwiftPM trait `Editor`" consistently to avoid confusion with Swift protocols.

**PRD Locations:**
- Section 1.4: "Extension relies on `EditorEngine` (trait `Editor` must be enabled)"
- Section 4.5: "Trait disabled | Prompt user to rebuild"

---

### 4.3 macOS and Linux Only

**Issue:** PRD specifies "macOS + Linux" support (Section 1.4) but VS Code also runs on Windows.

**Current State:**
- Swift toolchain supports Windows (experimental)
- PRD explicitly excludes Windows

**Impact:** Extension cannot be used by Windows developers.

**Clarification:** Intentional scope limitation or oversight? Update PRD rationale if intentional.

**PRD Reference:** Section 1.4 (Constraints & Assumptions)

---

### 4.4 No LLM Integration (Noted but Unclear)

**Issue:** PRD states "No LLM integration" (Section 1.4) but unclear what this means.

**Current State:**
- EditorEngine has no AI/ML features
- Hyperprompt is for AI prompts - connection unclear

**Impact:** None, but could clarify scope.

**Clarification:** Does this mean:
- No AI-powered autocomplete in v1?
- No semantic analysis of prompt content?
- Simply deferring LLM features to future versions?

---

### 4.5 Extension Metadata Missing

**Issue:** PRD does not specify:
- Extension ID (e.g., `0al.hyperprompt`)
- Publisher name
- Repository URL
- License

**Impact:** Cannot publish extension without this metadata.

**Required Work:** Add Section 1.6 "Extension Metadata" to PRD.

---

## 5. Architecture Recommendations

### 5.1 Recommended Integration Path

Given the FFI blocker, recommend one of these architectures:

**Option A: Language Server Protocol (LSP)**
- Implement Hyperprompt Language Server in Swift
- Use EditorEngine as library
- VS Code extension uses `vscode-languageclient`
- Pros: Standard protocol, works for other editors too
- Cons: More complex than simple FFI

**Option B: CLI + JSON-RPC**
- Create `hyperprompt-editor` CLI binary
- Extension spawns CLI, communicates via stdin/stdout JSON
- Pros: Simple, no FFI complexity
- Cons: Startup overhead, process management

**Option C: Node.js Native Addon**
- Create C API layer in EditorEngine
- Generate Node.js addon with node-addon-api
- Pros: Fast, in-process
- Cons: Complex build, platform-specific binaries

**Recommendation:** Option A (LSP) for best long-term ROI, Option B (CLI) for fastest MVP.

---

### 5.2 Update PRD Section 1.5 (External Dependencies)

Add:
- **Interop Layer:** LSP / JSON-RPC / FFI (choose one)
- **Build Tooling:** node-gyp (if native addon) or bundled CLI (if Option B)

---

### 5.3 Add PRD Section: "Build & Distribution"

Specify:
- How extension obtains EditorEngine binary (bundled vs. downloaded vs. user-compiled)
- Cross-compilation strategy for macOS + Linux
- Versioning and compatibility guarantees

---

## 6. EditorEngine Module Validation

### 6.1 Current EditorEngine Capabilities ✅

| Capability | Status | Notes |
|-----------|--------|-------|
| Project indexing | ✅ | `EditorEngine.indexProject` |
| Parse with link spans | ✅ | `EditorParser.parse` |
| Link resolution | ✅ | `EditorResolver.resolve` |
| Compilation | ✅ | `EditorCompiler.compile` |
| Diagnostics mapping | ✅ | `DiagnosticMapper.map` |
| Trait-gated build | ✅ | SwiftPM `Editor` trait |
| Sendable/thread-safe | ✅ | All types marked Sendable |

---

### 6.2 Missing EditorEngine Features for PRD ❌

| PRD Feature | EditorEngine API | Status |
|------------|-----------------|--------|
| Go-to-definition | `linkAt(position:)` | ❌ Missing |
| Hover info | Same as above | ❌ Missing |
| Live preview | Incremental compile | ❌ Missing |
| Workspace diagnostics | `validateWorkspace()` | ❌ Missing |
| Source maps | `SourceMap` in `CompileResult` | ❌ Missing |
| FFI/Node bindings | C API layer | ❌ Missing |
| Multi-root support | Multiple workspace roots | ⚠️ Partial |
| Async APIs | Async variants | ❌ Missing |

---

## 7. Action Items

### For PRD Author:
1. ✅ Add Section 0: "Integration Architecture" (LSP vs CLI vs FFI)
2. ✅ Clarify resolution mode (strict vs lenient) for extension
3. ✅ Define "medium project" for performance benchmarks
4. ✅ Specify whether manifest JSON is used by extension
5. ✅ Add Section 1.6: "Extension Metadata"
6. ✅ Update Section 1.5 to include interop layer dependency

### For EditorEngine Module:
1. 🔴 BLOCKER: Design and implement FFI/IPC layer
2. 🔴 BLOCKER: Add `linkAt(position:)` API for position queries
3. 🟠 CRITICAL: Implement workspace-level diagnostics API
4. 🟠 CRITICAL: Add async variants of key methods
5. 🟡 MAJOR: Implement incremental compilation or document performance limits
6. 🟡 MAJOR: Add performance benchmarks and tests
7. 🔵 MINOR: Document `referenceHint` semantics
8. 🔵 MINOR: Document manifest JSON schema

### For VS Code Extension (Not Started):
1. Choose integration architecture (LSP recommended)
2. Implement language client
3. Design extension settings (resolution mode, performance options)
4. Implement webview for live preview
5. Map EditorEngine diagnostics to VS Code Problems panel

---

## 8. PRD Quality Assessment

| Criterion | Rating | Notes |
|----------|--------|-------|
| **Clarity** | 7/10 | Clear structure, but missing integration architecture |
| **Completeness** | 5/10 | Major gaps: FFI layer, API details, build/distribution |
| **Feasibility** | 4/10 | Multiple blockers prevent implementation as written |
| **Traceability** | 8/10 | Good section references, acceptance criteria |
| **Testability** | 6/10 | Acceptance criteria present, but perf metrics vague |

**Overall:** PRD is a good starting point but requires significant revision to be implementable.

---

## 9. Estimated Effort to Close Gaps

| Category | Effort | Dependencies |
|---------|--------|-------------|
| FFI/IPC Layer | 2-3 weeks | Choose architecture |
| Position Query API | 2-3 days | None |
| Incremental Compilation | 1-2 weeks | File watching, caching |
| Workspace Diagnostics | 3-5 days | Compilation API |
| Source Maps | 1 week | Emitter changes |
| Async APIs | 3-5 days | Swift concurrency |
| Performance Tests | 2-3 days | Benchmark fixtures |
| Multi-root Workspaces | 2-3 days | Resolver refactor |

**Total Estimated Effort:** 6-8 weeks for all blockers + critical issues.

---

## 10. Conclusion

The PRD for the VS Code extension is **not currently implementable** due to:
1. **No FFI/IPC layer** to call Swift EditorEngine from Node.js
2. **Missing position-based APIs** for go-to-definition and hover
3. **No incremental compilation** for live preview performance

**Recommendation:** Update PRD to include integration architecture section, then implement FFI layer + position query APIs as Phase 0 prerequisites before starting extension work.

---

**End of Report**

# Architecture Decision Records

This document contains all architecture decisions for the Hyperprompt project.

---

## ADR-001: VS Code Extension Integration Architecture

**Date:** 2025-12-23
**Status:** ✅ Accepted
**Decision Makers:** EditorEngine Module Team
**Context:** VSC-1 — Integration Architecture Decision

### Context & Problem Statement

The Hyperprompt EditorEngine is implemented in Swift and provides APIs for parsing, resolving, and compiling Hypercode files. A VS Code extension needs to be developed to provide IDE features (syntax highlighting, go-to-definition, hover, preview, diagnostics), but VS Code extensions run in Node.js/TypeScript.

**Problem:** How can a TypeScript-based VS Code extension call Swift EditorEngine APIs?

**Critical Requirements:**
- Must support macOS (x64, arm64) and Linux (x64)
- Must enable calling `EditorEngine.indexProject()` and other APIs from TypeScript
- Must meet <200ms performance budget for medium-sized projects (per validation report)
- Must be implementable within Phase 11-15 timeline (86 hours total)

### Options Considered

#### Option A: Language Server Protocol (LSP)

**Architecture:**
- Swift LSP server implements JSON-RPC over stdio
- VS Code extension uses `vscode-languageclient` library
- Custom LSP methods: `hyperprompt/indexProject`, `hyperprompt/parse`, etc.
- Server process spawned by extension, communicates via JSON messages

**Implementation Estimate:** 12-14 hours

**Pros:**
- ✅ **Standard protocol** - LSP 3.17 compliance, well-documented
- ✅ **Multi-editor support** - Works with Vim, Emacs, Sublime, not just VS Code
- ✅ **Ecosystem tooling** - Debuggers, analyzers, client libraries available
- ✅ **Process isolation** - Server crashes don't crash editor
- ✅ **Long-lived sessions** - Amortize startup cost across many requests
- ✅ **Incremental sync** - LSP has built-in document sync protocol (`textDocument/didChange`)

**Cons:**
- ⚠️ **Higher complexity** - Need to implement JSON-RPC correctly, handle LSP lifecycle
- ⚠️ **Startup latency** - ~50-100ms to spawn server process (first request only)
- ⚠️ **IPC overhead** - Serialization/deserialization for every request (~1-5ms per call)
- ⚠️ **No Swift LSP library** - Must implement JSON-RPC manually or use minimal dependencies

**Performance Characteristics:**
- **Startup time:** 80-120ms (process spawn + initialize handshake)
- **Call latency (warm):** 5-15ms (JSON serialization + IPC + deserialization)
- **Throughput:** 50-200 calls/sec
- **Memory:** Server process ~20-50MB, separate from editor

**Cross-Platform:**
- ✅ macOS x64/arm64 - Full support
- ✅ Linux x64 - Full support
- ✅ Windows x64 - Possible with Swift for Windows (not prioritized for Phase 11)

**Maintainability:**
- Medium - Standard protocol reduces ad-hoc decisions
- LSP spec is stable (3.17), minimal breaking changes
- Large community, many reference implementations

---

#### Option B: CLI + JSON-RPC

**Architecture:**
- Add `hyperprompt editor-rpc` CLI subcommand
- Accepts JSON-RPC 2.0 requests on stdin, returns responses on stdout
- Extension spawns subprocess for each session or per-request
- Methods: `{"method":"indexProject","params":{"workspaceRoot":"/path"}}`

**Implementation Estimate:** 6-8 hours

**Pros:**
- ✅ **Simplest implementation** - Reuse existing CLI infrastructure, minimal new code
- ✅ **No platform-specific builds** - Just ship CLI binary (already exists)
- ✅ **Easy debugging** - Can test with `echo '{}' | hyperprompt editor-rpc`
- ✅ **No FFI complexity** - Pure IPC, no memory management risks
- ✅ **JSON-RPC 2.0 compliance** - Simple, well-defined protocol

**Cons:**
- ⚠️ **Process overhead** - Spawn subprocess for each request (or manage long-lived process manually)
- ⚠️ **No standard editor protocol** - Custom, requires manual VS Code client code
- ⚠️ **Single-editor focus** - Not easily reusable by other editors
- ⚠️ **Startup latency per call** - If spawning per-request: 50-80ms overhead per call
- ⚠️ **No incremental sync** - No built-in document change protocol (must design custom)

**Performance Characteristics:**
- **Startup time (long-lived process):** 50-80ms (process spawn only)
- **Call latency (warm):** 3-10ms (JSON serialization + IPC)
- **Call latency (per-request spawn):** 50-80ms (process overhead dominates)
- **Throughput:** 100-300 calls/sec (if long-lived), 10-20 calls/sec (if per-request)
- **Memory:** Process ~15-40MB (separate from editor)

**Cross-Platform:**
- ✅ macOS x64/arm64 - Full support
- ✅ Linux x64 - Full support
- ✅ Windows x64 - Possible with Swift for Windows

**Maintainability:**
- Easy - Minimal code, no protocol complexity
- Custom protocol means all design decisions are project-specific
- No ecosystem tooling, debugging is ad-hoc

---

#### Option C: Node.js Native Addon (FFI)

**Architecture:**
- Create C-compatible API wrapper for EditorEngine (`@_cdecl` Swift functions)
- Build Node.js native addon using `node-addon-api` (N-API)
- Extension calls `require('hyperprompt-native').indexProject()` directly (in-process)
- No IPC, no subprocess, direct function calls

**Implementation Estimate:** 14-18 hours

**Pros:**
- ✅ **Lowest latency** - No IPC, no serialization, direct Swift → Node.js calls (<1ms)
- ✅ **Highest throughput** - 1000+ calls/sec
- ✅ **No process overhead** - Single process, shared memory
- ✅ **Ideal for tight loops** - Excellent for frequent API calls (hover, completion)

**Cons:**
- ⚠️ **Highest complexity** - C API, memory management, cross-language ownership
- ⚠️ **Platform-specific binaries** - Must compile addon for macOS x64, macOS arm64, Linux x64 separately
- ⚠️ **Difficult debugging** - Native crashes, memory leaks, ABI compatibility issues
- ⚠️ **Maintenance burden** - Swift ABI changes, Node.js N-API changes, build toolchain updates
- ⚠️ **Non-standard** - No protocol, custom integration unique to Node.js
- ⚠️ **Single-editor only** - Cannot reuse for Vim, Emacs, etc.
- ⚠️ **Memory management risks** - Swift ownership, Node.js GC, manual deallocation

**Performance Characteristics:**
- **Startup time:** 10-20ms (addon load, no process spawn)
- **Call latency:** <1ms (in-process function call)
- **Throughput:** 1000+ calls/sec
- **Memory:** Shared with Node.js process (~100-200MB total)

**Cross-Platform:**
- ⚠️ macOS x64 - Requires compilation
- ⚠️ macOS arm64 - Requires separate compilation
- ⚠️ Linux x64 - Requires separate compilation
- ❌ Windows x64 - Complex Swift → C → Node.js toolchain on Windows

**Maintainability:**
- Difficult - C API layer, platform builds, memory correctness
- Requires expertise in Swift internals, N-API, build systems
- Significant ongoing maintenance cost for ABI stability

---

### Performance Comparison Table

| Criterion | LSP | CLI + JSON-RPC | FFI (Native Addon) |
|-----------|-----|----------------|---------------------|
| **Startup Time** | 80-120ms | 50-80ms (long-lived) | 10-20ms |
| **Call Latency (warm)** | 5-15ms | 3-10ms (long-lived), 50-80ms (per-request) | <1ms |
| **Throughput** | 50-200 calls/sec | 100-300 calls/sec (long-lived) | 1000+ calls/sec |
| **Implementation LoC** | ~800-1200 | ~400-600 | ~1200-1800 |
| **External Dependencies** | JSON encoder/decoder | JSON encoder/decoder | node-gyp, N-API, C headers |
| **Cross-Platform** | ✅ Easy (same binary) | ✅ Easy (same binary) | ⚠️ Hard (per-platform builds) |
| **Standard Compliance** | ✅ LSP 3.17 | ✅ JSON-RPC 2.0 | ❌ Custom |
| **Multi-Editor Support** | ✅ Yes (LSP standard) | ⚠️ Manual adaptation | ❌ Node.js only |
| **Maintainability** | Medium | Easy | Difficult |
| **Memory Safety** | ✅ Process isolation | ✅ Process isolation | ⚠️ Manual management |
| **Debugging Experience** | Good (LSP tools) | Easy (stdio logs) | Difficult (native crashes) |

---

### Decision

**Chosen Architecture: CLI + JSON-RPC for Phase 11-12 (MVP), migrate to LSP for Phase 14+ (Long-Term)**

**Rationale:**

#### Short-Term (Phase 11-12 MVP):
We choose **CLI + JSON-RPC** because:

1. **Simplest implementation** - Only 6-8 hours vs 12-14 (LSP) or 14-18 (FFI)
   - Fits within VSC-1 architecture decision task (4 hours) + VSC-2B implementation (8 hours)
   - Total Phase 11 budget: 18 hours; CLI path uses 14 hours, leaving 4 hours buffer

2. **Adequate performance** - 3-10ms latency meets <200ms budget with room to spare
   - Long-lived subprocess amortizes startup cost
   - Most editor operations (hover, go-to-def) happen <10 times/sec, well within 100-300 calls/sec limit

3. **Lowest risk** - No platform-specific builds, no memory management, no C API
   - Can test with simple `echo` commands
   - Easy rollback if issues arise

4. **Immediate delivery** - Can ship working extension in Phase 11-12 (18 + 20 = 38 hours)

#### Long-Term (Phase 14+ Production):
Migrate to **LSP** because:

1. **Multi-editor support** - Users request Vim, Emacs, Neovim support
   - LSP is industry standard for language tooling
   - One LSP server works with all editors (via their LSP clients)

2. **Better UX** - Incremental document sync (`textDocument/didChange`) reduces redundant parsing
   - CLI approach requires full-file resend on every change
   - LSP has built-in workspace/configuration management

3. **Ecosystem maturity** - LSP debuggers, analyzers, testing tools exist
   - Easier onboarding for contributors
   - Standard protocol = less documentation burden

4. **Performance optimization** - Long-lived LSP server can cache parsed ASTs, indexes
   - CLI subprocess might restart, losing warm state
   - LSP has standard initialization/shutdown lifecycle

5. **Future-proof** - LSP 3.17 is stable, backed by Microsoft, JetBrains, community
   - Less risk of breaking changes than custom CLI protocol

**Migration Path:**
- Phase 11-12: Ship CLI + JSON-RPC extension (working MVP)
- Phase 13: (Optional) Add performance profiling to measure actual bottlenecks
- Phase 14: Implement LSP server (reuse CLI RPC method handlers)
- Phase 15: Deprecate CLI RPC, default to LSP, keep CLI as fallback

---

### Consequences

**Accepted Trade-offs:**

✅ **Wins:**
- Fast MVP delivery (Phase 11-12)
- Low implementation risk
- Easy debugging and testing
- Adequate performance for initial release
- Clear upgrade path to LSP

⚠️ **Costs:**
- Must implement CLI RPC now, LSP later (duplicate effort)
- CLI approach not reusable for other editors (temporary limitation)
- Slightly higher latency than FFI (acceptable for MVP)

❌ **Rejected Alternatives:**

**LSP (now):** Too complex for MVP, delays initial release by 6-8 hours
- **When to reconsider:** Phase 14, when multi-editor support becomes priority

**FFI:** Highest risk, platform-specific builds, difficult maintenance
- **When to reconsider:** Only if profiling shows <10ms latency is insufficient (unlikely)

---

### Validation & Next Steps

**Acceptance Criteria Met:**
- [x] Evaluated all three options (LSP, CLI, FFI)
- [x] Documented trade-offs in comparison table
- [x] Chosen architecture (CLI for MVP, LSP for long-term)
- [x] Justified decision with rationale
- [x] Documented consequences and migration path

**Next Steps:**
1. ✅ Mark VSC-1 complete
2. ➡️ Proceed to **VSC-2B** (CLI JSON-RPC Implementation) — 8 hours
3. ⏸️ Skip VSC-2A (LSP) and VSC-2C (FFI) for now (defer to Phase 14)
4. Update Workplan.md:
   - Mark VSC-2B as "INPROGRESS"
   - Mark VSC-2A as "DEFERRED (use LSP for Phase 14+)"
   - Mark VSC-2C as "REJECTED (too complex, no clear need)"

---

### References

- **PRD Validation Report:** `DOCS/PRD_VALIDATION_VSCode_Extension.md`
  - Section 1.1: FFI layer blocker identified
  - Section 4.3: <200ms performance budget

- **EditorEngine API Documentation:** `DOCS/PRD/PRD_EditorEngine.md`
  - Public API: `indexProject()`, `parse()`, `compile()`, `resolve()`

- **VS Code Extension Development:**
  - Language Server Protocol 3.17: https://microsoft.github.io/language-server-protocol/
  - JSON-RPC 2.0: https://www.jsonrpc.org/specification
  - Node.js N-API: https://nodejs.org/api/n-api.html

---

### Review & Approval

**Reviewed by:** EditorEngine Module Team
**Approved by:** VSC-1 Task Owner
**Date:** 2025-12-23
**ADR Status:** ✅ Active

This decision may be revisited in Phase 13 if performance profiling reveals CLI latency as a bottleneck.

---

**END OF ADR-001**

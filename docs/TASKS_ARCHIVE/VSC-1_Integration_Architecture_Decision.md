# PRD — VSC-1: Integration Architecture Decision

**Document Version:** 1.0.0
**Task ID:** VSC-1
**Priority:** P0 (Critical)
**Phase:** 11 — VS Code Extension Integration Architecture
**Estimated Effort:** 4 hours
**Dependencies:** EE8 (EditorEngine complete)
**Status:** Ready for Implementation
**Date:** 2025-12-23

---

## 1. Scope & Intent

### 1.1 Objective

Establish the interoperability architecture between Swift-based **EditorEngine** and TypeScript-based **VS Code Extension**. This task resolves the critical blocker identified in PRD validation: there is currently no way for a Node.js/TypeScript extension to invoke EditorEngine APIs.

**Restatement:** Choose and validate a technical bridge that enables VS Code Extension (running in Node.js) to call EditorEngine methods (written in Swift), ensuring the chosen solution meets performance, maintainability, and cross-platform requirements.

### 1.2 Primary Deliverables

| Deliverable | Description |
|-------------|-------------|
| **Architecture Evaluation** | Comparative analysis of 3 integration options: LSP, CLI+JSON-RPC, FFI |
| **Prototypes** | Minimal working prototypes for each option demonstrating `EditorEngine.indexProject()` call |
| **Performance Benchmarks** | Measured startup time, latency, and throughput for each option |
| **Trade-off Documentation** | Analysis of complexity, maintainability, cross-platform support |
| **Architecture Decision** | Documented choice with justification |
| **Decision Record** | Entry in `DOCS/ARCHITECTURE_DECISIONS.md` |

### 1.3 Success Criteria

The task is complete when:

1. ✅ All three integration options (LSP, CLI+JSON-RPC, FFI) have been evaluated with working prototypes
2. ✅ Performance benchmarks demonstrate each option can call `EditorEngine.indexProject()` from TypeScript
3. ✅ Trade-offs are documented in a comparison table (complexity, performance, cross-platform support, maintainability)
4. ✅ One architecture is selected based on objective criteria
5. ✅ Decision is documented in `DOCS/ARCHITECTURE_DECISIONS.md` with:
   - Chosen architecture
   - Rationale (why this option)
   - Rejected alternatives (why not others)
   - Performance data
   - Implementation roadmap

### 1.4 Constraints & Assumptions

**Constraints:**
- Must support macOS (x64, arm64) and Linux (x64) — primary developer platforms
- Must enable synchronous *and* asynchronous calls from TypeScript
- Must not require Swift code changes in EditorEngine core (wrapper/adapter layer only)
- Must be feasible within Phases 11-15 timeline (86 hours total for VS Code Extension)

**Assumptions:**
- EditorEngine Phase 10 (EE8) is complete and stable
- Developer has Swift 6.1+ and Node.js 18+ installed
- VS Code Extension will be distributed via .vsix package
- Performance budget: <200ms for medium-sized projects (from PRD validation)

### 1.5 External Dependencies

| Dependency | Purpose |
|-----------|---------|
| Swift 6.1+ | EditorEngine runtime |
| Node.js 18+ | VS Code Extension runtime |
| VS Code Extension API | Host environment |
| EditorEngine module | Target API to be invoked |

---

## 2. Structured TODO Plan

### Phase 0: Preparation (15 minutes)

#### 2.0.1 Review EditorEngine API Surface
- **Input:** `Sources/EditorEngine/` module
- **Process:** Identify public API methods that must be exposed (indexProject, parse, resolve, compile)
- **Output:** List of methods with signatures
- **Priority:** High
- **Effort:** 15 minutes
- **Acceptance:** Complete list of EditorEngine public methods documented

---

### Phase 1: Option A — Language Server Protocol (LSP) (90 minutes)

#### 2.1.1 Research LSP Standard
- **Input:** LSP specification (https://microsoft.github.io/language-server-protocol/)
- **Process:** Identify required LSP capabilities for EditorEngine use case
- **Output:** Minimal LSP server requirements (initialize, textDocument/didOpen, custom requests)
- **Priority:** High
- **Effort:** 20 minutes
- **Tools:** Web browser, LSP spec
- **Acceptance:** List of LSP methods to implement

#### 2.1.2 Create LSP Server Skeleton
- **Input:** EditorEngine API
- **Process:** Create minimal Swift LSP server with JSON-RPC over stdio
- **Output:** Working LSP server that responds to `initialize` and `shutdown`
- **Priority:** High
- **Effort:** 30 minutes
- **Tools:** Swift, LSP libraries (if available) or manual JSON-RPC
- **Acceptance:** LSP server process starts, handles JSON-RPC messages, exits cleanly

#### 2.1.3 Add Custom LSP Method for indexProject
- **Input:** EditorEngine.indexProject() method
- **Process:** Define custom LSP method `hyperprompt/indexProject`, wire to EditorEngine
- **Output:** LSP server responds to custom request with project index JSON
- **Priority:** High
- **Effort:** 25 minutes
- **Acceptance:** TypeScript client sends request, receives valid ProjectIndex JSON

#### 2.1.4 Create TypeScript LSP Client Prototype
- **Input:** vscode-languageclient library
- **Process:** Create minimal VS Code extension that starts LSP server, sends `hyperprompt/indexProject`
- **Output:** Extension logs successful response from LSP server
- **Priority:** High
- **Effort:** 15 minutes
- **Tools:** TypeScript, vscode-languageclient
- **Acceptance:** Extension calls EditorEngine via LSP, receives data

---

### Phase 2: Option B — CLI + JSON-RPC (60 minutes)

#### 2.2.1 Add CLI Subcommand for Editor RPC
- **Input:** Existing CLI tool structure
- **Process:** Add `hyperprompt editor-rpc` subcommand with stdin/stdout JSON-RPC
- **Output:** CLI accepts JSON requests, returns JSON responses
- **Priority:** High
- **Effort:** 25 minutes
- **Tools:** Swift ArgumentParser
- **Acceptance:** `echo '{"method":"indexProject","params":{...}}' | hyperprompt editor-rpc` returns valid JSON

#### 2.2.2 Implement indexProject RPC Method
- **Input:** EditorEngine.indexProject()
- **Process:** Wire RPC method to EditorEngine call, serialize result to JSON
- **Output:** RPC responds with ProjectIndex JSON
- **Priority:** High
- **Effort:** 20 minutes
- **Acceptance:** CLI RPC returns same data structure as LSP option

#### 2.2.3 Create TypeScript CLI Client Prototype
- **Input:** Node.js child_process module
- **Process:** Spawn `hyperprompt editor-rpc`, send JSON request, parse response
- **Output:** TypeScript code successfully calls EditorEngine via CLI
- **Priority:** High
- **Effort:** 15 minutes
- **Tools:** Node.js, child_process
- **Acceptance:** Extension calls EditorEngine via subprocess, receives data

---

### Phase 3: Option C — Node.js Native Addon (FFI) (90 minutes)

#### 2.3.1 Create C-Compatible API Wrapper
- **Input:** EditorEngine Swift API
- **Process:** Define C functions wrapping EditorEngine methods (e.g., `hc_editor_index_project`)
- **Output:** C header file + Swift implementation using @_cdecl
- **Priority:** High
- **Effort:** 30 minutes
- **Tools:** Swift @_cdecl, C header
- **Acceptance:** C API compiles, exports symbols

#### 2.3.2 Create Node.js Addon with N-API
- **Input:** C API wrapper
- **Process:** Generate Node.js addon using node-addon-api, bind to C API
- **Output:** Node.js module that can be `require()`'d
- **Priority:** High
- **Effort:** 35 minutes
- **Tools:** node-gyp, node-addon-api
- **Acceptance:** `require('hyperprompt-native')` loads successfully

#### 2.3.3 Implement indexProject Binding
- **Input:** C API wrapper
- **Process:** Create N-API function wrapping `hc_editor_index_project`, handle memory
- **Output:** JavaScript function `indexProject()` callable from Node.js
- **Priority:** High
- **Effort:** 25 minutes
- **Acceptance:** TypeScript extension calls `indexProject()`, receives data without spawning process

---

### Phase 4: Benchmarking (30 minutes)

#### 2.4.1 Create Benchmark Test Project
- **Input:** Existing Hyperprompt test projects
- **Process:** Select medium-sized project (~50 files) for benchmarking
- **Output:** Standardized test project for all options
- **Priority:** High
- **Effort:** 10 minutes
- **Acceptance:** Same test data used across all three options

#### 2.4.2 Measure Startup Time
- **Input:** All three prototypes
- **Process:** Measure time from "extension activates" to "first successful indexProject call"
- **Output:** Startup latency for LSP, CLI, FFI
- **Priority:** High
- **Effort:** 10 minutes
- **Tools:** console.time() in TypeScript
- **Acceptance:** Data recorded in comparison table

#### 2.4.3 Measure Call Latency
- **Input:** All three prototypes
- **Process:** Measure time for 10 consecutive `indexProject` calls (warm state)
- **Output:** Average latency for LSP, CLI, FFI
- **Priority:** High
- **Effort:** 10 minutes
- **Acceptance:** Data recorded in comparison table

---

### Phase 5: Documentation & Decision (45 minutes)

#### 2.5.1 Document Trade-offs
- **Input:** Prototype experiences, benchmark data
- **Process:** Create comparison table with:
  - Complexity (LoC, external deps)
  - Performance (startup, latency)
  - Cross-platform support
  - Maintainability
  - Standard compliance
- **Output:** Markdown table in decision document
- **Priority:** High
- **Effort:** 20 minutes
- **Acceptance:** All criteria documented objectively

#### 2.5.2 Choose Architecture
- **Input:** Trade-off analysis
- **Process:** Select option based on priorities (recommend LSP for long-term, CLI for MVP)
- **Output:** Decision statement with justification
- **Priority:** High
- **Effort:** 10 minutes
- **Acceptance:** Clear choice with reasoning

#### 2.5.3 Create Architecture Decision Record
- **Input:** All analysis artifacts
- **Process:** Write ADR in `DOCS/ARCHITECTURE_DECISIONS.md` following ADR template
- **Output:** Permanent record of decision
- **Priority:** High
- **Effort:** 15 minutes
- **Tools:** Markdown
- **Acceptance:** ADR includes:
  - Context (problem statement)
  - Decision (chosen option)
  - Consequences (trade-offs accepted)
  - Alternatives considered

---

## 3. Functional Requirements

### 3.1 Prototype Requirements

Each prototype must:
- Demonstrate calling `EditorEngine.indexProject(workspaceRoot:options:)` from TypeScript
- Return valid `ProjectIndex` data structure
- Run without errors on macOS (primary development platform)
- Be measurable for performance benchmarking

### 3.2 Performance Requirements

From PRD validation report:
- **Startup time:** Time from extension activation to first successful EditorEngine call
- **Call latency:** Time from TypeScript invocation to result available
- **Target:** <200ms for medium-sized projects (as per validation report Section 1.3)

### 3.3 Cross-Platform Requirements

- **Must support:** macOS (x64, arm64), Linux (x64)
- **Nice to have:** Windows (x64) — optional for Phase 11, may defer to Phase 14

### 3.4 Maintainability Requirements

- Chosen solution must be maintainable by a single developer
- External dependencies should be minimal and stable
- Build process should integrate with existing Swift Package Manager setup

---

## 4. Non-Functional Requirements

### 4.1 Performance

- Prototypes must complete benchmark tests within 4-hour task window
- Chosen architecture must support <200ms compile time budget (from validation report)

### 4.2 Reliability

- All three prototypes must handle errors gracefully (missing files, invalid input)
- No memory leaks in FFI option (if chosen)

### 4.3 Security

- No network access during EditorEngine calls
- No arbitrary code execution vulnerabilities in RPC/FFI layer

### 4.4 Compliance

- LSP option must follow LSP 3.17 specification minimum
- CLI option must follow JSON-RPC 2.0 specification

---

## 5. Edge Cases & Failure Scenarios

| Scenario | Expected Behavior |
|----------|-------------------|
| EditorEngine throws error | Error propagated to TypeScript as structured diagnostic |
| Workspace root does not exist | Graceful error, do not crash extension |
| LSP server crashes | Extension detects failure, attempts restart |
| CLI subprocess hangs | Timeout mechanism (5s), kill process, report error |
| FFI addon fails to load | Extension falls back to error message, suggests manual installation |
| Multi-root workspace | Handled by EditorEngine resolver (per validation report §2.3) |

---

## 6. Acceptance Criteria (Detailed)

### 6.1 Prototypes

- [ ] LSP prototype: Server responds to custom `hyperprompt/indexProject` request
- [ ] CLI prototype: Subprocess handles JSON-RPC `indexProject` method
- [ ] FFI prototype: Native addon exposes `indexProject()` JavaScript function
- [ ] All prototypes return equivalent `ProjectIndex` data

### 6.2 Benchmarks

- [ ] Startup time measured for all three options
- [ ] Call latency measured for all three options (10 calls, average)
- [ ] Data recorded in comparison table

### 6.3 Documentation

- [ ] Trade-offs documented in comparison table
- [ ] Architecture chosen with clear justification
- [ ] ADR created in `DOCS/ARCHITECTURE_DECISIONS.md`
- [ ] ADR includes: context, decision, consequences, alternatives

### 6.4 Validation

- [ ] At least one prototype meets <200ms performance budget
- [ ] Chosen architecture is feasible within Phase 11-15 timeline
- [ ] Decision documented and ready for implementation in VSC-2A/B/C

---

## 7. Verification Methods

| Requirement | Verification Method |
|-------------|---------------------|
| Prototypes work | Manual testing: call `indexProject()` from TypeScript, log result |
| Performance benchmarks | Automated timing: `console.time()` wrappers |
| Cross-platform support | Build test on macOS x64, macOS arm64, Linux x64 |
| ADR completeness | Checklist review against ADR template |

---

## 8. Dependencies & Blockers

### 8.1 Dependencies

- ✅ **EE8 Complete:** EditorEngine Phase 10 must be finished (already marked complete in Workplan)
- ✅ **Development Environment:** Swift 6.1+ and Node.js 18+ installed
- ✅ **VS Code:** Installed for extension testing

### 8.2 Potential Blockers

- **SwiftPM limitations:** If Swift cannot easily export C symbols, FFI option may be infeasible → Document limitation, recommend LSP/CLI
- **LSP library availability:** If no Swift LSP library exists, manual JSON-RPC adds complexity → Still feasible, just longer implementation
- **Node.js addon build failures:** Platform-specific tooling issues → Document limitations, may affect FFI option viability

---

## 9. Out of Scope

The following are **NOT** part of this task:
- Full implementation of chosen architecture (deferred to VSC-2A/B/C)
- Production-ready error handling (prototypes only)
- Multi-root workspace support (handled separately in Phase 12)
- Incremental compilation (Phase 13)
- Full VS Code extension UI (Phase 14)

---

## 10. Implementation Checklist

### Pre-Implementation
- [ ] Review EditorEngine API (Phase 0)
- [ ] Set up benchmark test project

### LSP Option
- [ ] Research LSP spec (§2.1.1)
- [ ] Create LSP server skeleton (§2.1.2)
- [ ] Add indexProject custom method (§2.1.3)
- [ ] Create TypeScript client prototype (§2.1.4)

### CLI Option
- [ ] Add CLI subcommand (§2.2.1)
- [ ] Implement indexProject RPC (§2.2.2)
- [ ] Create TypeScript client prototype (§2.2.3)

### FFI Option
- [ ] Create C API wrapper (§2.3.1)
- [ ] Create Node.js addon (§2.3.2)
- [ ] Implement indexProject binding (§2.3.3)

### Benchmarking
- [ ] Measure startup time (§2.4.2)
- [ ] Measure call latency (§2.4.3)

### Decision
- [ ] Document trade-offs (§2.5.1)
- [ ] Choose architecture (§2.5.2)
- [ ] Create ADR (§2.5.3)

---

## 11. Recommended Approach

Based on PRD validation report recommendations:

**For MVP (Phase 11):** CLI + JSON-RPC
- ✅ Simplest to implement
- ✅ No platform-specific build issues
- ✅ Adequate performance for small-to-medium projects
- ⚠️ Process overhead, but acceptable for initial release

**For Long-Term (Phase 14+):** Language Server Protocol
- ✅ Standard protocol, multi-editor support
- ✅ Better performance for long-lived sessions
- ✅ Ecosystem tooling (LSP clients, debuggers)
- ⚠️ More complex, but future-proof

**FFI Option:** Only if performance benchmarks show CLI/LSP cannot meet <200ms budget
- ✅ Fastest (in-process calls)
- ⚠️ Complex build, platform-specific binaries
- ⚠️ Memory management risks

---

## 12. Next Steps

After this task (VSC-1) completes:
1. Proceed to **VSC-2A** (LSP implementation) **OR** **VSC-2B** (CLI implementation) **OR** **VSC-2C** (FFI implementation) based on decision
2. Update Workplan.md to mark VSC-2A/B/C as "in progress" (only the chosen path)
3. Mark VSC-1 as complete, move this PRD to `DOCS/TASKS_ARCHIVE/`

---

## Appendix A: Comparison Table Template

| Criterion | LSP | CLI + JSON-RPC | FFI (Native Addon) |
|-----------|-----|----------------|---------------------|
| **Startup Time** | TBD | TBD | TBD |
| **Call Latency (avg)** | TBD | TBD | TBD |
| **Complexity (LoC)** | TBD | TBD | TBD |
| **External Deps** | TBD | TBD | TBD |
| **Cross-Platform** | ✅ | ✅ | ⚠️ (build-dependent) |
| **Standard Compliance** | ✅ LSP 3.17 | ✅ JSON-RPC 2.0 | ❌ Custom |
| **Multi-Editor Support** | ✅ | ⚠️ (manual work) | ❌ VS Code only |
| **Maintainability** | TBD | TBD | TBD |

---

## Appendix B: EditorEngine API Summary

From Phase 10 (EE8), the following EditorEngine methods are public and must be callable from TypeScript:

| Method | Purpose | Returns |
|--------|---------|---------|
| `indexProject(workspaceRoot:options:)` | Discover all .hc/.md files in workspace | `ProjectIndex` |
| `parse(fileContents:filePath:)` | Parse Hypercode, extract link spans | `ParsedFile` |
| `resolve(link:sourceFile:workspaceRoot:mode:)` | Resolve file reference to target | `ResolvedTarget` |
| `compile(entryFile:options:)` | Compile project with diagnostics | `CompileResult` |
| `linkAt(fileContents:line:column:)` | Find link at cursor position (if implemented in Phase 12) | `LinkSpan?` |

This task (VSC-1) focuses on validating that **at least one** of these methods (`indexProject`) can be successfully called from TypeScript via any of the three architecture options.

---

**END OF PRD**

---
**Archived:** 2025-12-23

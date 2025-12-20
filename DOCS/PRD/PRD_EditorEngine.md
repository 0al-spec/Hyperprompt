# PRD — EditorEngine (Hyperprompt)

## 1. Scope & Intent

### 1.1 Objective

Create **EditorEngine** — an internal, optional (trait-gated) engine within the Hyperprompt project that provides
IDE/editor-oriented capabilities on top of the deterministic Hyperprompt compiler.

EditorEngine exposes a stable, minimal API for:
- parsing Hypercode files with link awareness,
- resolving file references,
- compiling projects with diagnostics and metadata suitable for editors,
- enabling editor UX such as *peek definition*, *multi-column navigation*, *live preview*, and *error reporting*.

EditorEngine **does not** introduce new language semantics and **does not** depend on any LLM or UI framework.

---

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| `EditorEngine` target | Swift module inside Hyperprompt, gated by SPM Trait `Editor` |
| Public Editor API | Narrow set of types & functions for editor integrations |
| Diagnostic Model | Structured diagnostics aligned with compiler error codes |
| Link & Resolution Model | Precise mapping of links → targets |
| Compile Result Model | Output + diagnostics + optional manifest/stats |
| Documentation | `DOCS/EDITOR_ENGINE.md` |

---

### 1.3 Success Criteria

- Hyperprompt builds **without EditorEngine** by default.
- With `--traits Editor`, EditorEngine builds and is usable by editor clients.
- EditorEngine exposes **no UI code**.
- All outputs are deterministic and reproducible.
- EditorEngine can power a 3-column editor UX without CLI invocation.

---

### 1.4 Constraints & Assumptions

- EditorEngine is **experimental** until Hyperprompt v1.0.
- API stability is not guaranteed before v1.0.
- EditorEngine must reuse existing compiler modules:
  `Core`, `Parser`, `Resolver`, `Emitter`, `Statistics`.
- No HTML, WebView, SwiftUI, or AppKit dependencies.

---

### 1.5 External Dependencies

| Dependency | Purpose |
|-----------|---------|
| Swift 6.1+ | Language & concurrency model |
| SwiftPM Traits | Optional compilation (`Editor` trait) |
| Hyperprompt Core Modules | Parsing, resolution, emission |

---

## 2. Structured TODO Plan

### Phase 0 — Package & Build Integration

#### 2.0.1 Define SPM Trait

- **Input:** Package.swift
- **Process:** Add trait `Editor`, disabled by default
- **Output:** Trait-gated compilation path

Metadata:
- Priority: High
- Effort: Low
- Tools: SwiftPM
- Acceptance: `swift build` works without Editor; `swift build --traits Editor` includes EditorEngine

---

#### 2.0.2 Create EditorEngine Target

- **Input:** Package.swift
- **Process:** Add new target `EditorEngine`
- **Output:** Isolated module with no CLI dependency

Metadata:
- Priority: High
- Effort: Low
- Tools: SwiftPM
- Acceptance: CLI target does not import EditorEngine

---

### Phase 1 — Core Editor API

#### 2.1.1 Project Indexing

- **Input:** Workspace root URL
- **Process:** Scan supported files (`.hc`, `.md`)
- **Output:** `ProjectIndex`

Metadata:
- Priority: High
- Effort: Medium
- Tools: FileManager
- Acceptance: Index lists all reachable files deterministically

---

#### 2.1.2 Parsing with Link Spans

- **Input:** File contents
- **Process:** Parse Hypercode, extract link ranges
- **Output:** `ParsedFile { ast, linkSpans[] }`

Metadata:
- Priority: High
- Effort: Medium
- Tools: Existing Parser
- Acceptance: All file references are captured with byte/line ranges

---

#### 2.1.3 Link Resolution

- **Input:** LinkSpan + source file
- **Process:** Resolve path using Resolver rules
- **Output:** `ResolvedTarget`

Metadata:
- Priority: High
- Effort: Low
- Tools: Resolver
- Acceptance: Matches CLI resolution behavior exactly

---

### Phase 2 — Compilation for Editors

#### 2.2.1 Editor Compilation Entry Point

- **Input:** Entry file, options
- **Process:** Invoke compiler pipeline
- **Output:** `CompileResult`

Metadata:
- Priority: High
- Effort: Medium
- Tools: Core/Emitter/Statistics
- Acceptance: Output matches CLI byte-for-byte

---

#### 2.2.2 Diagnostics Mapping

- **Input:** Compiler errors/warnings
- **Process:** Map to structured diagnostics
- **Output:** `[Diagnostic]`

Metadata:
- Priority: High
- Effort: Medium
- Tools: Error codes
- Acceptance: All CLI errors appear as editor diagnostics

---

### Phase 3 — Optional Enhancements (Post-MVP)

#### 2.3.1 Source Map (Optional)

- **Input:** Compilation traversal
- **Process:** Track output → input mapping
- **Output:** `SourceMap`

Metadata:
- Priority: Medium
- Effort: High
- Tools: Emitter hooks
- Acceptance: Output lines map back to source ranges

---

## 3. Execution Metadata Summary

| Phase | Parallelizable |
|------|----------------|
| Phase 0 | Yes |
| Phase 1 | Partial |
| Phase 2 | No (depends on Phase 1) |
| Phase 3 | Yes |

---

## 4. PRD Section

### 4.1 Feature Description & Rationale

EditorEngine enables **rich editor experiences** for Hyperprompt without compromising
the compiler’s deterministic, CLI-first design.

It bridges the gap between:
- *language semantics* (compiler),
- and *developer experience* (editors, IDEs).

---

### 4.2 Functional Requirements

| ID | Requirement |
|----|-------------|
| FR-1 | Parse Hypercode files and expose link spans |
| FR-2 | Resolve file references identically to CLI |
| FR-3 | Compile projects programmatically |
| FR-4 | Emit structured diagnostics |
| FR-5 | Be disabled unless `Editor` trait is enabled |

---

### 4.3 Non-Functional Requirements

| Category | Requirement |
|--------|-------------|
| Determinism | Same input → same output |
| Performance | <100ms for medium projects |
| Stability | Invalid files never crash engine |
| Portability | macOS + Linux |
| Isolation | No UI or LLM dependencies |

---

### 4.4 User Interaction Flows (Conceptual)

```
Editor → EditorEngine.parse()
Editor → EditorEngine.resolve()
Editor → EditorEngine.compile()
← Diagnostics / Output / Metadata
```

---

### 4.5 Edge Cases & Failure Scenarios

| Case | Handling |
|-----|---------|
| Missing file | Diagnostic (severity based on strict/lenient) |
| Circular reference | Deterministic resolution error |
| Invalid syntax | Precise range diagnostic |
| Trait disabled | EditorEngine not compiled |

---

## 5. Quality Enforcement Rules

- No implicit behavior
- No hidden side effects
- All APIs pure or explicitly state IO
- All outputs serializable
- All errors surfaced as diagnostics

---

## 6. Output Format

- Primary: Markdown (this document)
- Alternative: JSON PRD schema (on request)

---

**Status:** Draft  
**Target Version:** Hyperprompt 0.2  
**Last Updated:** 2025-12-20

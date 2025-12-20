# Hyperprompt Roadmap

This document describes the planned evolution of the **Hyperprompt** language, compiler, and tooling,
from the current state toward a stable 1.0 release.

The roadmap is intentionally **engineering-driven**, focusing on determinism, tooling quality,
and long-term maintainability rather than feature velocity.

---

## v0.1 — Compiler Core (Completed)

**Status:** ✅ Released  
**Milestone:** `v0.1 — Compiler Core`

### Scope
The foundational release that establishes Hyperprompt as a deterministic, standalone compiler.

### Delivered
- CLI-based compiler
- Hypercode parser (indentation-based grammar)
- File reference resolution (`.hc`, `.md`)
- Recursive compilation with cycle detection
- Strict and lenient modes
- Deterministic Markdown output
- Diagnostics and exit codes
- Optional manifest and statistics generation

### Outcome
> Hyperprompt exists as a reproducible, deterministic language and compiler.

---

## v0.2 — Editor MVP

**Status:** Planned  
**Milestone:** `v0.2 — Editor MVP`

### Goals
- Make Hyperprompt practical for daily authoring.
- Introduce editor-oriented APIs without compromising the compiler core.
- Deliver a functional VS Code extension.

---

### EditorEngine (Core Tooling Layer)

- Add SwiftPM trait `Editor` (disabled by default)
- Introduce `EditorEngine` target
- Workspace indexing
- Parsing with link span extraction
- Deterministic link resolution API
- Programmatic compilation entry point
- Structured diagnostics suitable for editors

---

### VS Code Extension (Primary Editor)

- `.hc` language registration
- Syntax highlighting (minimal)
- Go-to-definition / Peek reference
- Compile-on-demand command
- Live Markdown preview panel
- Diagnostics integration with Problems panel

### Outcome
> Hyperprompt becomes comfortable to use for medium and large projects.

---

## v0.3 — Advanced Editor UX

**Status:** Planned  
**Milestone:** `v0.3 — Advanced Editor UX`

### Goals
- Improve navigation and composition workflows.
- Reduce cognitive load when working with deeply nested documents.

### Planned Features
- Multi-column navigation (side-by-side reference editing)
- Dependency graph visualization (read-only)
- Inline hover previews for references
- Incremental recompilation on file changes
- Editor performance optimizations

### Acceptance Criteria
- Navigation UX supports side-by-side editing of referenced files without losing cursor/selection state.
- Dependency graph renders the current workspace graph deterministically (stable node ordering and layout inputs).
- Hover previews and go-to-definition remain correct under file edits and renames.
- Incremental recompilation triggers on save and updates diagnostics/preview without requiring a full workspace rebuild.
- Large workspaces remain usable (indexing, navigation, and incremental compile do not degrade into multi-second stalls during typical editing).

### Outcome
> Hyperprompt feels like an IDE for structured documents.

---

## v0.4 — Source Awareness & Traceability

**Status:** Planned  
**Milestone:** `v0.4 — Source Awareness`

### Goals
- Make compilation transparent and explainable.
- Improve debuggability of large compositions.

### Planned Features
- SourceMap support (output → input mapping)
- Jump from preview to originating source
- Error provenance across file boundaries
- Optional compilation tracing for debugging

### Acceptance Criteria
- A versioned SourceMap format exists and is emitted deterministically for the same inputs.
- Preview-to-source navigation lands on the correct originating file/region for composed output.
- Diagnostics include provenance across file boundaries (origin file + include/reference chain).
- Tracing output is machine-readable and stable enough to diff across runs (no timestamps/random IDs unless explicitly requested).

### Outcome
> Users can clearly understand *why* a given output looks the way it does.

---

## v0.5 — Stabilization & API Freeze

**Status:** Planned  
**Milestone:** `v0.5 — Stabilization`

### Goals
- Prepare the project for long-term stability.
- Lock down public APIs.

### Planned Work
- EditorEngine API cleanup
- Removal of experimental interfaces
- Documentation and specification review
- Tooling polish and consistency checks
- Publish a formal Hypercode spec (grammar + key semantic rules) aligned with the compiler behavior.
- Add a conformance corpus (golden inputs/outputs) that locks parser, resolver, and compiler determinism.

### Outcome
> Hyperprompt APIs are stable and predictable.

---

## v1.0 — Stable Language & Tooling

**Status:** Planned  
**Milestone:** `v1.0 — Stable Release`

### Guarantees
- Stable Hypercode grammar
- Stable CLI semantics
- Stable EditorEngine API
- Deterministic builds across platforms

### Post–1.0 Possibilities
- Extract EditorEngine as a standalone SDK
- Additional editors (Zed, Neovim)
- Alternative frontends (desktop / web)
- Ecosystem tooling built on Hyperprompt

### Outcome
> Hyperprompt is a production-ready language and tooling platform.

---

## Guiding Principles

- Determinism over convenience
- Tooling follows language, not the opposite
- Editor features are optional, never required
- Clear separation between compiler, engine, and UI
- No implicit or hidden behavior

---

**Last Updated:** 2025-12-20

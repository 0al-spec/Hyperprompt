# PRD — Hyperprompt VS Code Extension

## 1. Scope & Intent

### 1.1 Objective

Create an official **VS Code extension for Hyperprompt** that provides a first-class editor experience
for the Hypercode language by leveraging the internal `EditorEngine`.

The extension must enable developers to **author, navigate, validate, and preview Hyperprompt projects**
inside VS Code without invoking the CLI manually.

The extension is a **thin UI + integration layer** and must not reimplement compiler logic.

---

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| VS Code Extension | Published extension package |
| Language Support | Syntax highlighting, file associations |
| Navigation Features | Go-to-definition, peek reference |
| Live Preview Panel | Compiled Markdown output |
| Diagnostics Integration | Errors & warnings in Problems panel |
| Build Integration | Trait-enabled EditorEngine usage |

---

### 1.3 Success Criteria

- Opening a `.hc` file activates the extension.
- File references are navigable via click or command.
- Compilation results are visible in real time.
- Errors appear as VS Code diagnostics.
- Extension works without modifying Hyperprompt CLI behavior.

---

### 1.4 Constraints & Assumptions

- VS Code is the **only supported IDE** for this PRD.
- Extension relies on `EditorEngine` (trait `Editor` must be enabled).
- No language server protocol (LSP) in v1.
- No LLM integration.
- Extension must work on macOS and Linux.
- Windows is **not supported**; the extension must show a clear unsupported-platform message.

---

### 1.5 External Dependencies

| Dependency | Purpose |
|-----------|---------|
| VS Code Extension API | Editor integration |
| Node.js | Extension runtime |
| Hyperprompt EditorEngine | Compilation & analysis |
| Swift Toolchain | Native engine execution |

---

## 2. Structured TODO Plan

### Phase 0 — Project Setup

#### 2.0.1 Initialize Extension Skeleton

- **Input:** Empty repo
- **Process:** Generate VS Code extension scaffold
- **Output:** Buildable extension project

Metadata:
- Priority: High
- Effort: Low
- Tools: `yo code`
- Acceptance: Extension loads in VS Code dev mode

---

#### 2.0.2 File Associations

- **Input:** Extension manifest
- **Process:** Register `.hc` as Hypercode
- **Output:** Language activation

Metadata:
- Priority: High
- Effort: Low
- Tools: VS Code manifest
- Acceptance: `.hc` files trigger extension

---

### Phase 1 — Editor Navigation

#### 2.1.1 Go-To-Definition / Peek

- **Input:** Cursor position
- **Process:** Query EditorEngine for link resolution
- **Output:** Open target file at definition

Metadata:
- Priority: High
- Effort: Medium
- Tools: VS Code DefinitionProvider
- Acceptance: All file references navigable via definition/peek

---

#### 2.1.2 Hover Information

- **Input:** Cursor hover
- **Process:** Resolve link and show metadata
- **Output:** Hover tooltip

Metadata:
- Priority: Medium
- Effort: Low
- Tools: VS Code HoverProvider
- Acceptance: Hover shows resolved path and status

---

### Phase 2 — Compilation & Preview

#### 2.2.1 Compile on Demand

- **Input:** Command invocation
- **Process:** Call EditorEngine.compile()
- **Output:** Markdown output

Metadata:
- Priority: High
- Effort: Medium
- Tools: EditorEngine bridge
- Acceptance: Output matches CLI exactly

---

#### 2.2.2 Live Preview Panel

- **Input:** Compile result
- **Process:** Render Markdown in Webview
- **Output:** Preview panel

Metadata:
- Priority: High
- Effort: Medium
- Tools: VS Code Webview
- Acceptance: Preview updates on file save and manual refresh

---

### Phase 3 — Diagnostics

#### 2.3.1 Error Reporting

- **Input:** Compile diagnostics
- **Process:** Map to VS Code Diagnostic API
- **Output:** Problems panel entries

Metadata:
- Priority: High
- Effort: Medium
- Tools: VS Code Diagnostics
- Acceptance: Errors jump to correct file/line

---

#### 2.3.2 Severity Mapping

- **Input:** Diagnostic severity
- **Process:** Map to VS Code levels
- **Output:** Warning/Error/Info

Metadata:
- Priority: Medium
- Effort: Low
- Tools: DiagnosticSeverity
- Acceptance: Correct severity shown

---

### Phase 4 — UX Enhancements (Post-MVP)

#### 2.4.1 Multi-Column Workflow

- **Input:** User navigation
- **Process:** Open referenced files in side editor
- **Output:** 3-column layout

Metadata:
- Priority: Medium
- Effort: Medium
- Tools: VS Code editor groups
- Acceptance: Reference opens beside source

---

#### 2.4.2 Output → Source Navigation (Optional)

- **Input:** Click in preview
- **Process:** Use SourceMap
- **Output:** Jump to source

Metadata:
- Priority: Low
- Effort: High
- Tools: Webview messaging
- Acceptance: Correct source range highlighted

---

## 3. Execution Metadata Summary

| Phase | Parallelizable |
|------|----------------|
| Phase 0 | Yes |
| Phase 1 | Partial |
| Phase 2 | No |
| Phase 3 | Yes |
| Phase 4 | Yes |

---

## 4. PRD Section

### 4.1 Feature Description & Rationale

The VS Code extension provides **the primary authoring experience**
for Hyperprompt, turning the compiler into a usable daily tool.

It focuses on:
- fast navigation,
- immediate feedback,
- deterministic preview.

---

### 4.2 Functional Requirements

| ID | Requirement |
|----|-------------|
| FR-1 | Recognize `.hc` files |
| FR-2 | Navigate file references (definition + peek) |
| FR-3 | Provide hover metadata for references |
| FR-4 | Compile via EditorEngine |
| FR-5 | Show Markdown preview |
| FR-6 | Surface diagnostics |
| FR-7 | Provide activation on `.hc` open and explicit command |
| FR-8 | Resolve EditorEngine binary via configurable path or bundled binary |
| FR-9 | Show unsupported-platform messaging on Windows |

---

### 4.3 Non-Functional Requirements

| Category | Requirement |
|--------|-------------|
| Performance | <200ms compile for a medium project fixture (see §4.6) |
| Reliability | No crashes on invalid input |
| Isolation | No compiler logic in JS |
| Portability | macOS + Linux |
| Determinism | Matches CLI output |

---

### 4.4 User Interaction Flow

```
Edit .hc file
   ↓
Save / Command
   ↓
EditorEngine.compile()
   ↓
Diagnostics + Preview
```

---

### 4.5 Edge Cases & Failure Scenarios

| Case | Handling |
|-----|---------|
| Engine missing | Show setup error |
| Trait disabled | Prompt user to rebuild |
| Invalid syntax | Inline diagnostics |
| Circular refs | Clear error message |
| Unsupported OS | Show unsupported-platform error and disable features |

---

### 4.6 Operational Definitions & Acceptance Tests

#### 4.6.1 Medium Project Fixture

Define a canonical fixture for performance checks:
- **Files:** 20 `.hc` files, 5 referenced `.md` files.
- **Nodes:** ~200 total hypercode nodes.
- **Depth:** max depth 6.

Acceptance: compile time for this fixture must be **<200ms** on a modern laptop (baseline: 2023 MacBook Pro M2, release build).

#### 4.6.2 Activation & Engine Discovery

- Activation events: `onLanguage:hypercode`, `onCommand:hyperprompt.compile`, and `onCommand:hyperprompt.showPreview`.
- Engine discovery order:
  1. User-configured setting `hyperprompt.enginePath`
  2. Bundled engine binary (extension package)
  3. PATH lookup fallback

Acceptance: when the engine is not found, show a user-facing error with remediation steps.

#### 4.6.3 Diagnostics Mapping

- Diagnostic ranges use **0-based** line/column offsets mapped from EditorEngine outputs.
- Severity mapping:
  - `error` → `DiagnosticSeverity.Error`
  - `warning` → `DiagnosticSeverity.Warning`
  - `info` → `DiagnosticSeverity.Information`

Acceptance: diagnostics are reported per file and jump to the correct location.

#### 4.6.4 Navigation & Preview Test Matrix (Minimum)

| Scenario | Expected Result |
|----------|-----------------|
| Valid reference to `.hc` file | Go-to-definition opens target file at definition |
| Missing file reference | Hover shows missing status; diagnostic emitted |
| Circular reference | Diagnostic emitted with cycle path |
| Save current file | Preview updates within 1 second |

---

## 5. Quality Enforcement Rules

- No duplicated compiler logic
- All state derived from EditorEngine
- No silent failures
- Explicit user-facing errors

---

## 6. Output Format

- Primary: Markdown (this document)
- Alternative: JSON PRD schema (on request)

---

**Status:** Draft  
**Target Version:** Hyperprompt 0.2  
**Last Updated:** 2025-02-14

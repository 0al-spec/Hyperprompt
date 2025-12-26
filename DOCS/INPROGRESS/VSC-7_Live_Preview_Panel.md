# PRD — VSC-7: Live Preview Panel

**Task ID:** VSC-7
**Task Name:** Live Preview Panel
**Priority:** P0 (Critical)
**Phase:** Phase 14 — VS Code Extension Development
**Estimated Effort:** 6 hours
**Dependencies:** VSC-4*, PERF-4 ✅
**Status:** In Progress
**Date:** 2025-12-27
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Implement a live Markdown preview webview panel driven by EditorEngine compilation with refresh on save and manual refresh command.

**Restatement in Precise Terms:**
1. Create a webview panel for Markdown preview.
2. Compile on save and update preview content within performance targets.
3. Provide command to open/refresh preview and preserve state.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Preview panel | Webview panel rendering Markdown output |
| Compile-on-save | Update preview on save events |
| Tests | Coverage for preview behavior |

### 1.3 Success Criteria

1. ✅ Preview panel opens from command
2. ✅ Preview updates on save with latest Markdown
3. ✅ Manual refresh works and performance remains acceptable

### 1.4 Constraints

- Use existing compile RPC output (no new compiler logic in JS)
- No new dependencies
- Respect existing settings (previewAutoUpdate)

### 1.5 Assumptions

- compile output is deterministic and can be rendered directly in webview

---

## 2. Structured TODO Plan

### Phase 1: Webview Panel

#### Task 2.1.1: Implement preview webview + showPreview command
**Priority:** High
**Effort:** 2.5 hours
**Dependencies:** None

**Process:**
1. Create webview panel scaffolding with basic HTML
2. Register `hyperprompt.showPreview` command to open panel
3. Render compile output as Markdown (preformatted for now)

**Expected Output:**
- Webview panel created and visible

**Acceptance Criteria:**
- ✅ showPreview opens panel with initial content

---

### Phase 2: Live Updates

#### Task 2.2.1: Compile on save and update preview
**Priority:** High
**Effort:** 2 hours
**Dependencies:** 2.1.1

**Process:**
1. Listen for save events on Hypercode files
2. Call compile RPC with includeOutput true
3. Update webview content when previewAutoUpdate is enabled

**Expected Output:**
- Live preview refreshes on save

**Acceptance Criteria:**
- ✅ Preview updates on save for active entry file

---

### Phase 3: Tests & Validation

#### Task 2.3.1: Add preview tests
**Priority:** Medium
**Effort:** 1 hour
**Dependencies:** 2.2.1

**Process:**
1. Add tests for preview rendering helpers
2. Validate update logic under previewAutoUpdate

**Expected Output:**
- Preview tests added

**Acceptance Criteria:**
- ✅ Tests cover render/update helpers

---

#### Task 2.3.2: Validate and finalize docs
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** 2.3.1

**Process:**
1. Restore build cache if available
2. Run `swift test` and extension test suite if configured
3. Update `next.md` checklist and Workplan status
4. Write task summary in `DOCS/INPROGRESS/`

**Expected Output:**
- Passing validation commands noted in summary
- `DOCS/INPROGRESS/VSC-7-summary.md`

**Acceptance Criteria:**
- ✅ Summary saved with validation notes

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Preview panel renders Markdown output from compile
2. Updates are gated by previewAutoUpdate setting
3. Command can open or focus existing preview

### 3.2 Non-Functional Requirements

1. Preview update latency <200ms for medium fixture
2. No crashes on missing RPC engine

### 3.3 Acceptance Criteria per Task

- **2.1.1:** Preview panel opens and renders content
- **2.2.1:** Preview refreshes on save when enabled
- **2.3.1:** Tests cover preview helpers
- **2.3.2:** Validation commands recorded in summary

---

## 4. Verification Plan

```bash
./.github/scripts/restore-build-cache.sh
swift test 2>&1
```

---

## 5. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Large output in webview | Performance degradation | Use minimal HTML and reuse panel |
| Compile errors | Preview stale | Surface compile diagnostics and keep last output |

---

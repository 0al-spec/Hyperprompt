# PRD — VSC-12: Extension Documentation & Release

**Task ID:** VSC-12
**Task Name:** Extension Documentation & Release
**Priority:** P0 (Critical)
**Phase:** Phase 14 — VS Code Extension Development
**Estimated Effort:** 3 hours
**Dependencies:** VSC-11 ✅
**Status:** In Progress
**Date:** 2025-12-27
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Complete extension documentation for features, installation, requirements, and release packaging steps.

**Restatement in Precise Terms:**
1. Update extension README with feature list and usage instructions.
2. Add release packaging steps (VSIX build/install) and system requirements.
3. Add release notes / changelog entries for the extension.
4. Execute VSIX packaging and installation steps from the README and capture results.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| README updates | Feature overview, commands, settings, workflows |
| Release instructions | VSIX packaging/install steps |
| System requirements | OS/platform support and dependencies |

### 1.3 Success Criteria

1. ✅ README documents all commands and settings
2. ✅ Release steps documented for VSIX packaging
3. ✅ System requirements clearly stated
4. ✅ VSIX packaging and installation executed successfully or noted as blocked

### 1.4 Constraints

- Follow existing documentation tone and structure
- Keep documentation aligned with TypeScript implementation

### 1.5 Assumptions

- Extension distribution via VSIX is the primary pre-release path

---

## 2. Structured TODO Plan

### Phase 1: README Updates

#### Task 2.1.1: Update extension README
**Priority:** High
**Effort:** 1.5 hours
**Dependencies:** None

**Process:**
1. Document compile/preview/diagnostics/navigation features
2. Add command list and settings table
3. Add development workflow section

**Expected Output:**
- Updated `Tools/VSCodeExtension/README.md`

**Acceptance Criteria:**
- ✅ README reflects all implemented features

---

### Phase 2: Release Docs

#### Task 2.2.1: Add release packaging steps
**Priority:** Medium
**Effort:** 45 minutes
**Dependencies:** 2.1.1

**Process:**
1. Document `vsce package` workflow
2. Add install steps for `.vsix`

**Expected Output:**
- Release section in README or DOCS

**Acceptance Criteria:**
- ✅ Packaging steps documented

---

### Phase 3: Requirements & Validation

#### Task 2.3.1: Document system requirements
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** 2.2.1

**Process:**
1. List supported OS and required engine build
2. Note Editor trait requirement

**Expected Output:**
- Requirements section in README

**Acceptance Criteria:**
- ✅ Requirements documented

---

#### Task 2.3.2: Validate and finalize docs
**Priority:** Medium
**Effort:** 15 minutes
**Dependencies:** 2.3.1

**Process:**
1. Restore build cache if available
2. Run `swift test`
3. Update `next.md` checklist and Workplan status
4. Write task summary in `DOCS/INPROGRESS/`

**Expected Output:**
- Passing validation commands noted in summary
- `DOCS/INPROGRESS/VSC-12-summary.md`

**Acceptance Criteria:**
- ✅ Summary saved with validation notes

---

### Phase 4: Packaging Validation

#### Task 2.4.1: Run VSIX packaging steps
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** 2.3.2

**Process:**
1. Install vsce if needed.
2. Run `vsce package` in `Tools/VSCodeExtension`.
3. Install the VSIX locally and smoke test activation.

**Expected Output:**
- VSIX package artifact and installation notes.

**Acceptance Criteria:**
- ✅ Packaging and installation steps executed or blockers recorded

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. README documents commands, settings, and workflows
2. Release steps cover VSIX packaging and installation
3. Requirements include OS support and engine configuration

### 3.2 Non-Functional Requirements

1. Documentation matches current extension behavior
2. Instructions are copy-paste ready

### 3.3 Acceptance Criteria per Task

- **2.1.1:** README updated with features and settings
- **2.2.1:** Release packaging documented
- **2.3.1:** System requirements documented
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
| Docs drift from implementation | User confusion | Cross-check commands/settings with code |

---

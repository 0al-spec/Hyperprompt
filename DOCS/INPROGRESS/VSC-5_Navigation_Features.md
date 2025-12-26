# PRD — VSC-5: Navigation Features

**Task ID:** VSC-5
**Task Name:** Navigation Features
**Priority:** P0 (Critical)
**Phase:** Phase 14 — VS Code Extension Development
**Estimated Effort:** 5 hours
**Dependencies:** VSC-4*, EE-EXT-1 ✅
**Status:** In Progress
**Date:** 2025-12-27
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Implement go-to-definition and hover navigation features in the VS Code extension using `EditorParser.linkAt` and `EditorResolver` via the RPC client.

**Restatement in Precise Terms:**
1. Provide a DefinitionProvider that resolves links at the cursor.
2. Provide a HoverProvider that returns resolved file info or failure status.
3. Add navigation tests to validate the integration path.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| DefinitionProvider | Go-to-definition and peek using EditorEngine resolution |
| HoverProvider | Hover showing resolved path or error information |
| Tests | Integration coverage for navigation paths |

### 1.3 Success Criteria

1. ✅ DefinitionProvider resolves `@"..."` links to workspace files
2. ✅ HoverProvider returns informative output for resolved/unresolved links
3. ✅ Navigation tests pass

### 1.4 Constraints

- Must use existing RPC client and EditorEngine APIs
- No new external dependencies
- Keep behavior consistent with documented commands/settings

### 1.5 Assumptions

- Editor RPC supports linkAt/resolve operations needed for navigation

---

## 2. Structured TODO Plan

### Phase 1: Definition Provider

#### Task 2.1.1: Implement DefinitionProvider
**Priority:** High
**Effort:** 2 hours
**Dependencies:** None

**Process:**
1. Register DefinitionProvider for `hypercode` language
2. On request, call linkAt with cursor position
3. Resolve the link via RPC and return a VS Code Location
4. Handle unresolved links with a null result

**Expected Output:**
- Updated extension activation wiring and provider implementation

**Acceptance Criteria:**
- ✅ Go-to-definition navigates to resolved target

---

### Phase 2: Hover Provider

#### Task 2.2.1: Implement HoverProvider
**Priority:** High
**Effort:** 1.5 hours
**Dependencies:** 2.1.1

**Process:**
1. Register HoverProvider for `hypercode` language
2. Reuse linkAt + resolver path to determine target
3. Return hover markdown with resolved path or error status

**Expected Output:**
- Hover text for links

**Acceptance Criteria:**
- ✅ Hover shows path for resolved links and message for unresolved links

---

### Phase 3: Tests & Validation

#### Task 2.3.1: Add navigation tests
**Priority:** Medium
**Effort:** 1 hour
**Dependencies:** 2.2.1

**Process:**
1. Add integration tests for DefinitionProvider and HoverProvider
2. Use fixtures with known link targets
3. Validate unresolved link behavior

**Expected Output:**
- Extension test coverage for navigation

**Acceptance Criteria:**
- ✅ Navigation tests pass

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
- `DOCS/INPROGRESS/VSC-5-summary.md`

**Acceptance Criteria:**
- ✅ Summary saved with validation notes

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. DefinitionProvider uses linkAt + resolver to navigate to references
2. HoverProvider surfaces resolved path or failure details
3. Unresolved references return nil definition but still show hover

### 3.2 Non-Functional Requirements

1. Navigation requests complete within 200ms for typical files
2. No crashes when parser diagnostics exist

### 3.3 Acceptance Criteria per Task

- **2.1.1:** DefinitionProvider registered and returns Location for links
- **2.2.1:** HoverProvider returns markdown content for resolved/unresolved
- **2.3.1:** Navigation tests pass
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
| Missing RPC methods | Provider cannot resolve links | Gate behavior with error messaging and update plan |
| Incorrect range mapping | Navigation points to wrong location | Use existing link span byte/column offsets |

---

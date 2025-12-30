# PRD — VSC-9: Multi-Column Workflow (Optional)

**Task ID:** VSC-9
**Task Name:** Multi-Column Workflow (Optional)
**Priority:** P2 (Optional Enhancement)
**Phase:** Phase 14 — VS Code Extension Development
**Estimated Effort:** 3 hours
**Dependencies:** VSC-5 (Navigation Features) ✅, EE-EXT-4 (Multi-Root Workspace Support) ✅
**Status:** In Progress
**Date:** 2025-12-30
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Enhance the VS Code extension with multi-column workflow capabilities that allow users to open referenced files beside the source file, creating an ergonomic 3-column layout for Hypercode development: source | reference | preview.

**Restatement in Precise Terms:**
1. Add `hyperprompt.openBeside` command to open referenced files in adjacent editor group
2. Implement logic to preserve multi-column layout during navigation
3. Configure 3-column layout automatically when appropriate
4. Ensure compatibility with multi-root workspace scenarios

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| `hyperprompt.openBeside` command | Opens resolved link target in editor group beside source |
| Multi-column layout configuration | Automatically configures 3-column layout (source \| reference \| preview) |
| Multi-root workspace tests | Validates behavior across workspace boundaries |
| Extension tests | Integration coverage for multi-column workflow |

### 1.3 Success Criteria

1. ✅ `hyperprompt.openBeside` command opens files in adjacent editor group
2. ✅ 3-column layout preserves source, reference, and preview positions
3. ✅ Navigation between files maintains layout structure
4. ✅ Multi-root workspace support works correctly
5. ✅ Tests validate all multi-column scenarios

### 1.4 Constraints

- Must work with existing navigation infrastructure (DefinitionProvider, linkAt, resolve)
- Must respect VS Code's editor group API and user preferences
- No new RPC methods required (uses existing navigation APIs)
- Must handle edge cases gracefully (missing files, invalid links, etc.)

### 1.5 Assumptions

- Users want to view source and referenced files side-by-side
- 3-column layout (source | reference | preview) is the desired default
- VS Code's editor group API provides sufficient control over layout
- Existing navigation features (VSC-5) provide foundation for multi-column workflow

### 1.6 External Dependencies

- VS Code Editor Group API (`vscode.window.tabGroups`, `vscode.ViewColumn`)
- Existing RPC methods: `editor.linkAt`, `editor.resolve`
- Navigation infrastructure from VSC-5

---

## 2. Structured TODO Plan

### Phase 1: `hyperprompt.openBeside` Command Implementation

#### Task 2.1.1: Implement `openBeside` Command
**Priority:** High
**Effort:** 1.5 hours
**Dependencies:** None

**Process:**
1. Register `hyperprompt.openBeside` command in `package.json` contributions
2. Implement command handler in `extension.ts`:
   - Get cursor position in active editor
   - Call `editor.linkAt` RPC to find link at cursor
   - Call `editor.resolve` RPC to resolve link target
   - Determine target editor group (beside current)
   - Open resolved file using `vscode.window.showTextDocument` with `ViewColumn.Beside` option
3. Handle edge cases:
   - No link at cursor position → show info message
   - Link resolution fails → show error message with reason
   - File doesn't exist → show error message
   - Already in multi-column layout → preserve layout

**Expected Output:**
- `hyperprompt.openBeside` command registered
- Command handler in `extension.ts`
- Error handling for all failure modes

**Acceptance Criteria:**
- Command appears in VS Code command palette
- Clicking on a link and invoking command opens file beside source
- Error messages are clear and actionable

**Tools:**
- VS Code Extension API
- TypeScript
- Existing navigation infrastructure

**Verification:**
- Manual testing: open `.hc` file, place cursor on `@"..."` link, invoke command
- File opens in adjacent editor group
- Layout preserves source and target positions

---

#### Task 2.1.2: Configure 3-Column Layout Logic
**Priority:** High
**Effort:** 1 hour
**Dependencies:** 2.1.1

**Process:**
1. Implement layout detection logic:
   - Check current editor group configuration
   - Determine if preview panel is visible
   - Calculate optimal column assignment for source, reference, preview
2. Implement layout preservation:
   - When opening beside, maintain existing preview panel position
   - If no preview panel, suggest 2-column layout (source | reference)
   - If preview panel exists, arrange as source | reference | preview
3. Handle dynamic layout changes:
   - User manually moves editor groups → respect user choice
   - User closes reference → maintain source and preview
   - User closes preview → maintain source and reference

**Expected Output:**
- Layout detection and configuration logic
- Layout preservation during navigation
- Dynamic layout adaptation

**Acceptance Criteria:**
- Opening referenced file creates appropriate multi-column layout
- Existing preview panel position is preserved
- Layout adapts to user changes gracefully

**Tools:**
- VS Code Tab Groups API
- VS Code View Column API
- TypeScript

**Verification:**
- Test with preview panel open: verify 3-column layout (source | reference | preview)
- Test without preview: verify 2-column layout (source | reference)
- Test after user rearranges: verify user layout is respected

---

### Phase 2: Multi-Root Workspace Support

#### Task 2.2.1: Test Multi-Root Workspace Scenarios
**Priority:** Medium
**Effort:** 0.5 hours
**Dependencies:** 2.1.2

**Process:**
1. Create test workspace with multiple root folders
2. Test cross-root navigation:
   - Source file in root A references file in root B
   - Invoke `openBeside` command
   - Verify file opens correctly in adjacent group
3. Test workspace root resolution:
   - Verify `editor.resolve` uses correct workspace root for each file
   - Test ambiguous references across roots
4. Document multi-root behavior in README

**Expected Output:**
- Multi-root workspace test scenarios
- Documentation of cross-root navigation behavior

**Acceptance Criteria:**
- Cross-root navigation works correctly
- Workspace root resolution is accurate
- Multi-root behavior is documented

**Tools:**
- VS Code Workspace API
- Test fixtures with multiple roots

**Verification:**
- Create multi-root test workspace
- Navigate between files in different roots
- Verify resolution and layout behavior

---

### Phase 3: Testing & Validation

#### Task 2.3.1: Write Extension Tests
**Priority:** Medium
**Effort:** 1 hour
**Dependencies:** 2.2.1

**Process:**
1. Add integration tests for `openBeside` command:
   - Test basic navigation (single root workspace)
   - Test multi-column layout configuration
   - Test error handling (no link, invalid link, missing file)
   - Test multi-root workspace scenarios
2. Add test fixtures:
   - Sample `.hc` files with various link patterns
   - Multi-root workspace configuration
   - Expected layout configurations
3. Verify test coverage:
   - All command code paths covered
   - Error handling tested
   - Multi-column layout logic tested

**Expected Output:**
- Extension test suite for `openBeside` command
- Test fixtures covering all scenarios
- CI integration (tests run on commit)

**Acceptance Criteria:**
- All tests pass
- Test coverage ≥70% for new code
- CI validates multi-column workflow

**Tools:**
- VS Code Extension Test API
- @vscode/test-electron
- Mocha/Chai

**Verification:**
- Run `npm test` in `Tools/VSCodeExtension/`
- Verify all tests pass
- Check CI pipeline for test results

---

## 3. Subtask Metadata

| ID | Task | Priority | Effort | Dependencies | Tools | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| 2.1.1 | Implement `openBeside` command | High | 1.5h | None | VS Code API, TypeScript | Command opens files beside source |
| 2.1.2 | Configure 3-column layout logic | High | 1h | 2.1.1 | Tab Groups API, TypeScript | Layout adapts to preview panel state |
| 2.2.1 | Test multi-root workspace | Medium | 0.5h | 2.1.2 | Workspace API, test fixtures | Cross-root navigation works |
| 2.3.1 | Write extension tests | Medium | 1h | 2.2.1 | Test API, Mocha | Tests pass, coverage ≥70% |

**Total Effort:** 4 hours (conservative estimate; original was 3 hours)

---

## 4. Feature Description and Rationale

Multi-column workflow is an optional UX enhancement that improves developer productivity when working with Hypercode files that reference multiple documents. By automatically arranging source files, referenced files, and preview panel in a logical 3-column layout, developers can:

1. **View source and references side-by-side** without manual window management
2. **Maintain context** while navigating between files
3. **Preview compiled output** alongside source materials
4. **Navigate efficiently** in multi-root workspaces

This feature aligns with VS Code's design philosophy of supporting efficient text editing workflows and complements the existing navigation features (go-to-definition, hover) from VSC-5.

---

## 5. Functional Requirements

### FR-1: `hyperprompt.openBeside` Command
- **Must** register command in VS Code command palette
- **Must** accept invocation when cursor is on a Hypercode link (`@"..."`)
- **Must** use existing `editor.linkAt` and `editor.resolve` RPC methods
- **Must** open resolved file in adjacent editor group (ViewColumn.Beside)
- **Must** handle errors gracefully with user-facing messages

### FR-2: Multi-Column Layout Configuration
- **Must** detect current editor group layout
- **Should** arrange files as source | reference | preview when preview panel is open
- **Should** arrange files as source | reference when preview panel is closed
- **Must** preserve user-configured layout if user manually rearranges groups
- **Must** handle dynamic layout changes (closing groups, moving tabs)

### FR-3: Multi-Root Workspace Support
- **Must** resolve links correctly across workspace roots
- **Must** use appropriate workspace root for `editor.resolve` calls
- **Must** handle ambiguous references (multiple matches across roots)
- **Should** document multi-root behavior in extension README

### FR-4: Error Handling
- **Must** show informative message when no link is at cursor
- **Must** show error message when link resolution fails (with reason from RPC)
- **Must** show error message when target file doesn't exist
- **Must** log errors to console for debugging

---

## 6. Non-Functional Requirements

### NFR-1: Performance
- Command invocation latency: <500ms (including RPC roundtrip)
- Layout reconfiguration: instant (no perceptible delay)
- No impact on existing navigation feature performance

### NFR-2: Reliability
- **Must** handle RPC failures gracefully (timeout, engine crash, invalid response)
- **Must** handle VS Code API edge cases (invalid ViewColumn, closed groups)
- **Must** maintain layout state consistency during rapid navigation

### NFR-3: Usability
- Command name clearly indicates behavior ("Open Beside")
- Error messages are actionable (suggest fixes)
- Layout changes are predictable (follows established patterns)
- Works intuitively with keyboard shortcuts (F12, Ctrl+Click)

### NFR-4: Maintainability
- Reuses existing navigation infrastructure (no code duplication)
- Follows TypeScript best practices
- Includes comprehensive tests (≥70% coverage)
- Documented in extension README

---

## 7. User Interaction Flows

### Flow 1: Basic Multi-Column Navigation

1. **User opens source `.hc` file** in editor
2. **User places cursor on `@"reference.hc"` link**
3. **User invokes `hyperprompt.openBeside` command** (via command palette or keybinding)
4. **Extension calls `editor.linkAt`** with cursor position
5. **Extension calls `editor.resolve`** with link literal and workspace root
6. **Extension determines target editor group** (ViewColumn.Beside)
7. **Extension opens `reference.hc`** in adjacent group
8. **Result:** Source and reference are visible side-by-side

### Flow 2: 3-Column Layout with Preview

1. **User opens source `.hc` file** and invokes `hyperprompt.showPreview`
2. **Preview panel opens** in third column (source | preview)
3. **User places cursor on `@"reference.hc"` link** in source
4. **User invokes `hyperprompt.openBeside` command**
5. **Extension detects preview panel** in column 3
6. **Extension opens reference file** in column 2 (middle)
7. **Result:** 3-column layout (source | reference | preview)

### Flow 3: Error Handling - No Link at Cursor

1. **User places cursor in empty space** (not on a link)
2. **User invokes `hyperprompt.openBeside` command**
3. **Extension calls `editor.linkAt`**, receives `null` response
4. **Extension shows info message:** "No link at cursor position"
5. **Result:** User understands why command didn't navigate

### Flow 4: Multi-Root Workspace Navigation

1. **User has workspace with roots A and B**
2. **User opens `A/source.hc`** containing `@"../B/reference.hc"`
3. **User invokes `hyperprompt.openBeside` command**
4. **Extension resolves link** across workspace boundaries
5. **Extension opens `B/reference.hc`** in adjacent group
6. **Result:** Cross-root navigation works correctly

---

## 8. Edge Cases and Failure Scenarios

### Edge Case 1: Ambiguous Reference Across Roots
- **Scenario:** Link `@"common.hc"` matches files in both root A and root B
- **Behavior:** `editor.resolve` returns `type: 'ambiguous'` with candidates
- **User Experience:** Show error message listing candidates
- **Recovery:** User must disambiguate link (e.g., `@"../root-a/common.hc"`)

### Edge Case 2: Target File Doesn't Exist
- **Scenario:** Link resolves to path that doesn't exist on filesystem
- **Behavior:** `vscode.window.showTextDocument` throws error
- **User Experience:** Show error message "File not found: {path}"
- **Recovery:** User checks link path and file existence

### Edge Case 3: RPC Engine Unavailable
- **Scenario:** EditorEngine process crashed or not running
- **Behavior:** `ensureEngineReady()` returns `null`
- **User Experience:** Show error message from engine discovery (e.g., "Engine not found")
- **Recovery:** User checks engine installation and settings

### Edge Case 4: Maximum Editor Groups Reached
- **Scenario:** VS Code has maximum number of groups open (platform limit)
- **Behavior:** `showTextDocument` with `ViewColumn.Beside` may fail
- **User Experience:** VS Code shows native error or opens in existing group
- **Recovery:** User closes some editor groups

### Edge Case 5: Inline Text Link (Not a File Reference)
- **Scenario:** User invokes command on `@"inline text here"`
- **Behavior:** `editor.resolve` returns `type: 'inlineText'`
- **User Experience:** Show info message "Link is inline text, not a file reference"
- **Recovery:** User understands this is expected behavior

### Edge Case 6: Forbidden File Extension
- **Scenario:** Link resolves to `.exe` or other forbidden extension
- **Behavior:** `editor.resolve` returns `type: 'forbidden'` with extension
- **User Experience:** Show error message "Forbidden extension: .exe"
- **Recovery:** User reviews Hyperprompt security policy

---

## 9. Testing Strategy

### Unit Tests
- Test layout detection logic (2-column vs 3-column scenarios)
- Test editor group assignment (ViewColumn calculation)
- Test error message formatting

### Integration Tests
- Test `openBeside` command end-to-end:
  - Mock RPC client with `linkAt` and `resolve` responses
  - Verify `vscode.window.showTextDocument` called with correct parameters
  - Verify error handling paths
- Test multi-root workspace scenarios:
  - Create multi-root test workspace
  - Verify cross-root link resolution
  - Verify workspace root parameter passed to RPC

### Manual Tests
- Smoke test: open `.hc` file, invoke `openBeside`, verify layout
- Preview integration: verify 3-column layout with preview panel
- Multi-root: verify navigation across workspace roots
- Error scenarios: test all edge cases listed above

### Regression Tests
- Ensure existing navigation features (go-to-definition, hover) still work
- Ensure diagnostics and compile commands unaffected
- Ensure preview panel behavior unchanged

---

## 10. Implementation Notes

### Reusing Navigation Infrastructure
The `openBeside` command should reuse the navigation logic from VSC-5:
- Use `buildLinkAtParams`, `runLinkAtRequest` from `navigation.ts`
- Use `buildResolveParams`, `runResolveRequest` from `navigation.ts`
- Use `ensureEngineReady()` for RPC client lifecycle
- Use `resolvedTargetPath()` to extract file path from resolve result

### ViewColumn Strategy
VS Code provides `ViewColumn` enum for editor group positioning:
- `ViewColumn.One`: Leftmost group (source)
- `ViewColumn.Two`: Middle group (reference)
- `ViewColumn.Three`: Rightmost group (preview)
- `ViewColumn.Beside`: Next to active group (dynamic)

Recommended approach:
1. Use `ViewColumn.Beside` for simplicity (VS Code handles group creation)
2. Check `vscode.window.tabGroups` to detect preview panel
3. Optionally move editor to specific column if 3-column layout desired

### Layout Preservation
To preserve 3-column layout:
1. Before opening file, check if preview panel is in column 3
2. If yes, open reference file in column 2 (middle)
3. If no, open reference file with `ViewColumn.Beside` (creates column 2)

### Multi-Root Workspace Root Resolution
Use the same logic as existing navigation:
```typescript
const resolveWorkspaceRoot = (document: vscode.TextDocument): string => {
    const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
    return workspaceFolder?.uri.fsPath ?? path.dirname(document.uri.fsPath);
};
```

This ensures each file uses its own workspace root for resolution.

---

## 11. Future Enhancements (Out of Scope)

- **Keybinding:** Add default keybinding for `openBeside` command (e.g., `Ctrl+Shift+D`)
- **Context Menu:** Add "Open Beside" to editor context menu for links
- **Layout Persistence:** Save and restore multi-column layout across sessions
- **Breadcrumb Navigation:** Show navigation history in breadcrumb trail
- **Split View:** Support horizontal splits (source above reference)

---

## 12. Acceptance Checklist

- [ ] **Implementation Complete**
  - [ ] `hyperprompt.openBeside` command registered in `package.json`
  - [ ] Command handler implemented in `extension.ts`
  - [ ] Layout detection and configuration logic implemented
  - [ ] Error handling for all edge cases implemented

- [ ] **Testing Complete**
  - [ ] Unit tests written and passing
  - [ ] Integration tests written and passing
  - [ ] Multi-root workspace tests written and passing
  - [ ] Manual smoke tests completed
  - [ ] Test coverage ≥70% for new code

- [ ] **Documentation Complete**
  - [ ] README updated with `openBeside` command description
  - [ ] Multi-root behavior documented
  - [ ] Changelog entry added

- [ ] **Validation Complete**
  - [ ] Command appears in command palette
  - [ ] Multi-column layout works as specified
  - [ ] Preview panel integration works
  - [ ] Cross-root navigation works
  - [ ] Error messages are clear and actionable
  - [ ] No regressions in existing features

---

## 13. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| VS Code API changes in editor groups | Low | High | Pin VS Code engine version, monitor API changelog |
| User confusion with automatic layout | Medium | Medium | Document behavior, provide setting to disable auto-layout |
| Performance impact on large workspaces | Low | Medium | Reuse existing RPC calls (no additional overhead) |
| Multi-root resolution ambiguity | Medium | Medium | Clear error messages, suggest disambiguation |
| Conflict with user's manual layout | Medium | Low | Respect user changes, don't force layout |

---

## 14. Dependencies

### Internal Dependencies (Satisfied)
- **VSC-5** (Navigation Features): ✅ Completed
  - Provides `linkAt` and `resolve` RPC integration
  - Provides `DefinitionProvider` and `HoverProvider` foundation
- **EE-EXT-4** (Multi-Root Workspace Support): ✅ Completed
  - Ensures `editor.resolve` handles multi-root correctly

### External Dependencies
- **VS Code API:** `vscode.window.showTextDocument`, `vscode.window.tabGroups`, `vscode.ViewColumn`
- **Node.js Path Module:** For file path manipulation
- **TypeScript:** For extension development

---

## 15. Success Metrics

- **Adoption:** Command appears in VS Code command palette and is invokable
- **Correctness:** 100% of test scenarios pass (unit + integration)
- **Usability:** Manual testing confirms intuitive multi-column workflow
- **Reliability:** No crashes or errors in smoke testing
- **Performance:** Command latency <500ms (acceptable for optional feature)

---

## 16. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-30 | Hyperprompt Planning System | Initial PRD creation |

---
**Archived:** 2025-12-30

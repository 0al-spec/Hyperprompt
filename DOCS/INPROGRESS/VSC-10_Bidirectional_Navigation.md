# PRD — VSC-10: Bidirectional Navigation (Optional)

**Task ID:** VSC-10
**Task Name:** Bidirectional Navigation (Optional)
**Priority:** P2 (Medium)
**Phase:** Phase 14 — VS Code Extension Development
**Estimated Effort:** 4 hours
**Dependencies:** VSC-7 ✅, EE-EXT-3 ✅
**Status:** In Progress
**Date:** 2025-12-30
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Implement bidirectional navigation between compiled Markdown output and source Hypercode files using source maps. This enables users to click on a line in the preview panel and jump directly to the corresponding source location in the editor.

**Restatement in Precise Terms:**
1. Add click handlers to preview webview that detect line clicks
2. Send clicked line number from webview to extension via message passing
3. Use SourceMap to lookup corresponding source file and location
4. Navigate editor to source file and highlight the relevant range

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Click handler in webview | JavaScript code to detect and send click events |
| Message handler in extension | TypeScript code to receive click messages |
| Source map integration | Lookup source location from output line |
| Navigation logic | Open source file and highlight range |
| Tests | Coverage for bidirectional navigation |

### 1.3 Success Criteria

1. ✅ Click in preview sends message to extension with line number
2. ✅ Extension receives message and looks up source location
3. ✅ Editor navigates to correct source file and line
4. ✅ Range is highlighted in editor
5. ✅ Tests verify end-to-end navigation flow

### 1.4 Constraints

- Depends on SourceMap implementation in EditorEngine (EE-EXT-3)
- Must not break existing preview functionality
- No new dependencies beyond existing VS Code API
- Click should work on any line of output

### 1.5 Assumptions

- SourceMap data is available in compile result
- SourceMap.lookup(outputLine) returns SourceLocation with file path and range
- Preview panel has enableScripts: true (already configured)
- Clicking on output line is a natural UX pattern

### 1.6 External Dependencies

- **EE-EXT-3 (Source Map Generation):** Must provide SourceMap struct with lookup capability
- **CompileResult.sourceMap:** Must be populated by EditorCompiler
- **RPC editor.compile:** Must return sourceMap in response

**Note:** If SourceMap is not yet implemented, this task will need to:
1. Verify SourceMap implementation exists in EditorEngine
2. If missing, either defer VSC-10 or implement minimal SourceMap as subtask

---

## 2. Structured TODO Plan

### Phase 1: Webview Click Handler

#### Task 2.1.1: Add click event listener to preview HTML
**Priority:** High
**Effort:** 1 hour
**Dependencies:** None

**Input:**
- Existing `buildPreviewHtml` in `preview.ts`
- Current webview message passing pattern for scroll

**Process:**
1. Add click event listener to preview body or pre element
2. Capture clicked line number (calculate from click position)
3. Send message to extension with `{ type: 'navigateToSource', line: number }`
4. Follow existing message pattern (similar to scroll sync)

**Expected Output:**
- Preview HTML includes click handler script
- Clicking a line sends message to extension

**Acceptance Criteria:**
- ✅ Click on any line in preview sends message with correct line number
- ✅ Line number calculation is 0-indexed (consistent with VS Code API)

**Tools/Modules:**
- `Tools/VSCodeExtension/src/preview.ts`
- JavaScript `addEventListener` for click events
- `window.postMessage` or VS Code webview API for messaging

---

#### Task 2.1.2: Calculate line number from click position
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** 2.1.1

**Input:**
- Click event target and position

**Process:**
1. Determine which line element was clicked (using pre-formatted content)
2. Calculate 0-indexed line number from DOM structure
3. Handle edge cases (empty lines, trailing newlines)

**Expected Output:**
- Accurate line number extraction from click

**Acceptance Criteria:**
- ✅ Line number matches visual line in preview
- ✅ Edge cases handled (first line, last line, empty lines)

---

### Phase 2: Extension Message Handler

#### Task 2.2.1: Receive and process navigation messages
**Priority:** High
**Effort:** 45 minutes
**Dependencies:** 2.1.1

**Input:**
- Message from webview with `{ type: 'navigateToSource', line: number }`
- Current webview panel instance

**Process:**
1. Add message handler to webview panel (panel.webview.onDidReceiveMessage)
2. Check message type is 'navigateToSource'
3. Extract line number from message
4. Validate line number is within valid range

**Expected Output:**
- Extension receives and validates navigation messages

**Acceptance Criteria:**
- ✅ Message handler registered on panel creation
- ✅ Invalid messages are rejected gracefully

**Tools/Modules:**
- `Tools/VSCodeExtension/src/extension.ts`
- VS Code webview API `onDidReceiveMessage`

---

### Phase 3: Source Map Integration

#### Task 2.3.1: Check SourceMap availability in compile result
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** None (can run in parallel)

**Input:**
- EditorEngine compile RPC response

**Process:**
1. Check if compile result includes sourceMap field
2. If missing, document this as blocker and update task status
3. If present, verify structure matches expectations (lookup method exists)

**Expected Output:**
- Verification of SourceMap availability
- Documentation of SourceMap API surface

**Acceptance Criteria:**
- ✅ Confirmed: compile result includes sourceMap or task marked blocked
- ✅ SourceMap structure documented

**Tools/Modules:**
- `Sources/EditorEngine/` (Swift code inspection)
- RPC protocol documentation

---

#### Task 2.3.2: Implement source location lookup
**Priority:** High
**Effort:** 45 minutes
**Dependencies:** 2.2.1, 2.3.1

**Input:**
- Output line number from webview
- SourceMap from compile result
- Current entry file path

**Process:**
1. Call SourceMap.lookup(outputLine) via RPC or local API
2. Receive SourceLocation with { filePath, startLine, startColumn, endLine, endColumn }
3. Handle missing/invalid mappings (return null or show message)

**Expected Output:**
- Source location retrieved from SourceMap

**Acceptance Criteria:**
- ✅ Lookup returns valid source location for mapped lines
- ✅ Null/undefined handled gracefully for unmapped lines

**Tools/Modules:**
- SourceMap API (EditorEngine)
- RPC client for remote lookup if needed

---

### Phase 4: Editor Navigation

#### Task 2.4.1: Open source file and navigate to location
**Priority:** High
**Effort:** 45 minutes
**Dependencies:** 2.3.2

**Input:**
- SourceLocation { filePath, startLine, startColumn, endLine, endColumn }

**Process:**
1. Use `vscode.workspace.openTextDocument(filePath)`
2. Show document in editor with `vscode.window.showTextDocument`
3. Create Range from startLine/startColumn to endLine/endColumn
4. Set editor selection to range
5. Reveal range in viewport with `editor.revealRange`

**Expected Output:**
- Editor opens source file and highlights range

**Acceptance Criteria:**
- ✅ Correct file opens in editor
- ✅ Cursor positioned at correct line
- ✅ Range highlighted (if multi-line)
- ✅ Viewport scrolls to show selection

**Tools/Modules:**
- `vscode.workspace.openTextDocument`
- `vscode.window.showTextDocument`
- `vscode.Range` and `vscode.Selection`
- `editor.revealRange`

---

#### Task 2.4.2: Handle navigation errors gracefully
**Priority:** Medium
**Effort:** 15 minutes
**Dependencies:** 2.4.1

**Input:**
- Invalid file paths
- Missing files
- Out-of-bounds line numbers

**Process:**
1. Wrap navigation in try-catch
2. Show user-friendly error message if file cannot be opened
3. Log error details for debugging

**Expected Output:**
- Graceful error handling for navigation failures

**Acceptance Criteria:**
- ✅ Invalid paths show informative message
- ✅ No crashes on navigation errors

---

### Phase 5: Testing & Documentation

#### Task 2.5.1: Write integration tests for navigation
**Priority:** High
**Effort:** 1 hour
**Dependencies:** 2.4.2

**Input:**
- Existing extension test infrastructure
- Test fixtures with known source maps

**Process:**
1. Create test fixture with simple .hc file and known output
2. Mock webview message sending
3. Verify navigation opens correct file and position
4. Test edge cases (unmapped lines, invalid files)

**Expected Output:**
- Integration tests for bidirectional navigation

**Acceptance Criteria:**
- ✅ Tests verify end-to-end navigation flow
- ✅ Edge cases covered (unmapped, invalid, missing files)
- ✅ Tests pass in CI

**Tools/Modules:**
- VS Code extension test framework
- `src/test/navigation.test.ts` (extend existing)

---

#### Task 2.5.2: Update documentation
**Priority:** Low
**Effort:** 15 minutes
**Dependencies:** 2.5.1

**Input:**
- Extension README
- Feature completion status

**Process:**
1. Document bidirectional navigation in README
2. Add usage instructions (click in preview to navigate)
3. Note limitations (requires source maps)

**Expected Output:**
- README updated with navigation feature

**Acceptance Criteria:**
- ✅ README describes click-to-navigate feature
- ✅ Limitations documented

---

## 3. Subtask Metadata Table

| ID | Task | Priority | Effort | Dependencies | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- |
| 2.1.1 | Add click event listener to preview HTML | High | 1h | None | Click sends message with line number |
| 2.1.2 | Calculate line number from click position | High | 0.5h | 2.1.1 | Accurate line number extraction |
| 2.2.1 | Receive and process navigation messages | High | 0.75h | 2.1.1 | Message handler registered and validates |
| 2.3.1 | Check SourceMap availability | High | 0.5h | None | SourceMap verified or task blocked |
| 2.3.2 | Implement source location lookup | High | 0.75h | 2.2.1, 2.3.1 | Lookup returns valid locations |
| 2.4.1 | Open source file and navigate | High | 0.75h | 2.3.2 | File opens with correct highlight |
| 2.4.2 | Handle navigation errors | Medium | 0.25h | 2.4.1 | Graceful error handling |
| 2.5.1 | Write integration tests | High | 1h | 2.4.2 | Tests verify navigation |
| 2.5.2 | Update documentation | Low | 0.25h | 2.5.1 | README documents feature |

**Total Estimated Effort:** ~5.75 hours (higher than original 4h estimate due to detailed breakdown)

**Parallel Execution Opportunities:**
- Task 2.3.1 (SourceMap check) can run in parallel with Phase 1 and Phase 2

---

## 4. Feature Description and Rationale

### 4.1 User Workflow

**Before:** User sees compiled output in preview but must manually search for corresponding source

**After:** User clicks on line in preview → editor jumps to exact source location

**Example:**
1. User compiles `main.hc` which includes `section.hc`
2. Preview shows merged output on line 15 from `section.hc`
3. User clicks line 15 in preview
4. Editor opens `section.hc` and highlights original source line

### 4.2 Value Proposition

- **Faster debugging:** Quickly locate source of compiled output
- **Better UX:** Natural interaction pattern (click to navigate)
- **Reduced cognitive load:** No manual correlation between output and source

### 4.3 Feature Rationale

This is an **optional enhancement** (P2) because:
- Core functionality (navigation via go-to-definition) already works
- Source maps are complex to implement and maintain
- Primary use case is debugging, not daily workflow
- Not all users will compile frequently enough to need this

However, it provides significant value for:
- Users working with large, multi-file projects
- Debugging complex inclusion hierarchies
- Understanding how compiler transforms source

---

## 5. Functional Requirements

### FR-1: Click Detection
Preview webview must detect clicks on output lines and send messages to extension with line numbers.

**Verification:** Manual test clicking various lines in preview

### FR-2: Message Passing
Extension must receive messages from webview and extract line numbers correctly.

**Verification:** Unit test for message handler

### FR-3: Source Map Lookup
Extension must lookup source location from output line using SourceMap API.

**Verification:** Integration test with known source map fixture

### FR-4: Editor Navigation
Extension must open source file and position cursor at correct location.

**Verification:** Integration test verifying file, line, and column

### FR-5: Error Handling
Extension must handle missing source maps, invalid files, and out-of-bounds gracefully.

**Verification:** Integration tests for error scenarios

---

## 6. Non-Functional Requirements

### NFR-1: Performance
Navigation latency must be <200ms from click to editor update.

**Verification:** Manual testing with stopwatch or instrumentation

### NFR-2: Robustness
Missing source maps must not crash extension or break preview functionality.

**Verification:** Test with compile result that has no sourceMap field

### NFR-3: Usability
Click target should be intuitive (entire line clickable, visual feedback optional).

**Verification:** Manual UX testing

### NFR-4: Maintainability
Code must follow existing extension patterns (message passing, error handling).

**Verification:** Code review against existing navigation.ts patterns

---

## 7. Edge Cases and Failure Scenarios

| Scenario | Expected Behavior |
| --- | --- |
| User clicks line with no source mapping | Show message "No source location available for this line" |
| Source file deleted/moved | Show error "Cannot open file: [path]" |
| SourceMap not available in compile result | Clicking has no effect (or show message "Source maps not available") |
| Click on empty line | Ignore or navigate to nearest mapped line |
| Multi-file output (include chains) | Navigate to correct source file (not entry file) |
| Line at end of file with trailing newline | Handle boundary correctly (don't navigate past EOF) |
| Concurrent clicks (spam clicking) | Debounce or queue navigation requests |

---

## 8. Verification Checklist

### Pre-Implementation
- [ ] Verify EE-EXT-3 (SourceMap) is fully implemented
- [ ] If not implemented, choose: block VSC-10 or implement SourceMap first
- [ ] Confirm RPC protocol supports returning sourceMap in compile result

### Implementation
- [ ] Click handler added to preview.ts
- [ ] Message handler added to extension.ts
- [ ] Source map lookup integrated
- [ ] Editor navigation implemented
- [ ] Error handling added

### Testing
- [ ] Integration test: click → navigate for simple case
- [ ] Integration test: multi-file navigation
- [ ] Integration test: unmapped lines handled gracefully
- [ ] Integration test: missing source map handled gracefully
- [ ] Manual test: click various lines in preview

### Documentation
- [ ] README documents click-to-navigate feature
- [ ] Limitations noted (requires source maps)
- [ ] RPC protocol documentation updated if needed

---

## 9. Implementation Notes

### 9.1 SourceMap Dependency Risk

**CRITICAL DEPENDENCY:** This task assumes EE-EXT-3 (Source Map Generation) is fully implemented.

**If SourceMap is NOT implemented:**
- **Option 1:** Block VSC-10 and implement EE-EXT-3 first (add 5h effort)
- **Option 2:** Defer VSC-10 until SourceMap is prioritized
- **Option 3:** Implement minimal SourceMap as part of VSC-10 (increases scope)

**Before starting implementation, verify:**
```bash
# Check if SourceMap exists
grep -r "struct SourceMap" Sources/EditorEngine/
# Check if CompileResult has sourceMap field
grep -r "sourceMap" Sources/EditorEngine/
```

### 9.2 Line Number Indexing

**Critical:** VS Code API uses 0-indexed lines, but preview might display 1-indexed.
- Webview calculates 0-indexed line (consistent with output)
- SourceMap.lookup expects 0-indexed line
- VS Code Range expects 0-indexed line

**Always use 0-indexed throughout implementation.**

### 9.3 Message Passing Pattern

Follow existing pattern from scroll sync in `buildPreviewHtml`:
```javascript
window.addEventListener('click', (event) => {
  const line = calculateLineFromClick(event);
  const vscode = acquireVsCodeApi();
  vscode.postMessage({ type: 'navigateToSource', line });
});
```

### 9.4 Navigation Pattern

Follow existing pattern from `navigation.ts` for opening files:
```typescript
const doc = await vscode.workspace.openTextDocument(filePath);
const editor = await vscode.window.showTextDocument(doc);
const range = new vscode.Range(startLine, startColumn, endLine, endColumn);
editor.selection = new vscode.Selection(range.start, range.end);
editor.revealRange(range, vscode.TextEditorRevealType.InCenter);
```

---

## 10. Acceptance Criteria Summary

**Task Complete When:**
1. ✅ Click in preview sends message to extension
2. ✅ Extension looks up source location via SourceMap
3. ✅ Editor opens correct file and highlights range
4. ✅ Edge cases handled gracefully (no crashes)
5. ✅ Integration tests verify end-to-end flow
6. ✅ README documents feature

**Definition of Done:**
- All subtasks completed and checked off
- Integration tests pass in CI
- Manual testing confirms expected behavior
- README updated
- Task summary written in `DOCS/INPROGRESS/VSC-10-summary.md`
- Workplan.md updated with ✅ status

---

**Status:** Ready to Execute
**Next Step:** Run EXECUTE command or start with Task 2.3.1 (verify SourceMap) to validate dependencies

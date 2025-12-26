# PRD: VSC-7A — Compile on Demand Command

## 1. Scope and Intent

### Objective
Surface compile output from the VS Code extension by invoking `editor.compile` and presenting the generated Markdown to the user.

### Deliverables
- Compile command requests Markdown output from the RPC engine.
- Output is surfaced in the VS Code UI (output channel or temporary document).
- Compile command tests covering RPC request parameters and output rendering behavior.
- Documentation updated to describe where compile output appears.

### Success Criteria
- Running `Hyperprompt: Compile` produces visible Markdown output that matches CLI fixtures.
- Errors are reported via diagnostics count and do not silently drop output.
- Tests cover compile command behavior.

### Constraints and Assumptions
- RPC engine supports `editor.compile` with `includeOutput`.
- Output is acceptable in an Output Channel for now (preview wiring comes later).

### External Dependencies
- VS Code Extension API
- Hyperprompt RPC protocol (`editor.compile`)

---

## 2. Structured TODO Plan

### Phase A — Output Wiring
1. **Enable output payload**
   - Set `includeOutput: true` for compile commands.

2. **Surface output in UI**
   - Use a dedicated output channel or open a temporary Markdown document.

### Phase B — Tests
3. **Add compile command tests**
   - Validate compile RPC parameters and output handling.

### Phase C — Documentation
4. **Document compile output behavior**
   - Update extension README command notes.

---

## 3. Subtask Metadata

| ID | Task | Priority | Effort | Dependencies | Tools/Modules | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Enable output payload | High | 0.5h | None | extension.ts | Compile requests include output |
| A2 | Surface output in UI | High | 1h | A1 | VS Code API | Output visible in UI |
| B1 | Add compile command tests | Medium | 1h | A1 | Mocha tests | Tests validate parameters/output |
| C1 | Document output behavior | Medium | 0.5h | A2 | README | Docs updated |

---

## 4. Feature Description and Rationale

The compile command currently reports success without presenting the generated Markdown. Providing visible output aligns with CLI behavior and unblocks workflows that rely on immediate inspection of compiled results.

---

## 5. Functional Requirements

1. Compile command must request output from `editor.compile`.
2. Output must be surfaced in VS Code (output channel or document).
3. Errors must show diagnostic counts; output visibility should still be possible when available.
4. Tests cover compile request parameters and output rendering.

---

## 6. Non-Functional Requirements

- Output rendering should complete within 1 second for typical files.
- Output channel reuse avoids spawning excessive documents.

---

## 7. Edge Cases and Failure Scenarios

- RPC returns no output → show a warning message.
- Output is large → output channel should handle large text safely.
- RPC errors → surface error and avoid stale output.

---

## 8. Verification Checklist

- `npm run compile` in `Tools/VSCodeExtension` passes.
- Compile command shows output in UI.
- Compile command tests pass.

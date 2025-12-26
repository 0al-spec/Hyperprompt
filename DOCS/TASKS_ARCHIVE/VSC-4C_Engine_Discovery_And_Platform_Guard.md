# PRD: VSC-4C — Engine Discovery & Platform Guard

## 1. Scope and Intent

### Objective
Add robust engine discovery and platform gating for the VS Code extension so the RPC process only starts on supported platforms and with a valid Hyperprompt binary built with the Editor trait.

### Deliverables
- Engine discovery module that resolves the Hyperprompt binary in order: `hyperprompt.enginePath` → bundled binary → PATH.
- Platform guard that disables features on unsupported platforms (Windows) with clear messaging.
- Validation that the engine binary is executable and supports the `editor-rpc` subcommand.
- User-facing guidance when the engine is missing, not executable, or built without the Editor trait.
- Discovery tests for missing binary, bad path, and unsupported OS.
- Documentation updates describing engine discovery and remediation steps.

### Success Criteria
- Windows users see a clear unsupported-platform message and commands do not attempt to spawn RPC.
- The extension resolves the engine using the correct precedence and starts RPC only when valid.
- Missing engine or invalid path shows remediation guidance (`enginePath` or PATH).
- Missing Editor trait shows guidance to build with `swift build --traits Editor`.
- Tests cover key discovery failure cases.

### Constraints and Assumptions
- The bundled binary path is optional; if missing, fall back to PATH.
- The Editor trait is detectable by inspecting `hyperprompt --help` output for `editor-rpc`.
- Engine log level is passed via environment variables; CLI flag support is optional.

### External Dependencies
- VS Code extension API (`vscode`)
- Node.js `child_process` and filesystem APIs

---

## 2. Structured TODO Plan

### Phase A — Engine Discovery Utilities
1. **Create engine discovery module**
   - Implement platform checks and engine resolution order.
   - Probe candidate binaries with `--help` to detect `editor-rpc` support.

2. **Validate executability**
   - Verify explicit `enginePath` and bundled binary are executable before probing.

### Phase B — Extension Integration
3. **Wire platform guard and discovery**
   - Short-circuit commands on unsupported platforms.
   - Start RPC only when a valid engine is resolved.

4. **Provide remediation messages**
   - Map discovery failures to user-facing errors (missing binary, non-executable, Editor trait missing).
   - Restart RPC when engine settings change.

### Phase C — Tests
5. **Add discovery tests**
   - Missing binary fallback.
   - Bad enginePath error.
   - Unsupported platform guard.

### Phase D — Documentation
6. **Document engine discovery**
   - Describe enginePath, bundled binary, and PATH fallback.
   - Add Editor trait remediation steps.

---

## 3. Subtask Metadata

| ID | Task | Priority | Effort | Dependencies | Tools/Modules | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Create engine discovery utilities | High | 0.75h | None | engineDiscovery.ts | Discovery order implemented |
| A2 | Integrate discovery + platform guard in extension | High | 1h | A1 | extension.ts | Commands gated and RPC uses resolved engine |
| A3 | Add discovery tests | Medium | 0.75h | A1 | Mocha tests | Tests cover missing binary, bad path, unsupported OS |
| A4 | Update documentation | Medium | 0.25h | A2 | README | Engine discovery and remediation documented |

---

## 4. Feature Description and Rationale

Engine discovery prevents confusing RPC errors by verifying the Hyperprompt binary before launching it. Platform gating avoids unsupported Windows behavior. Clear guidance reduces setup friction when the binary is missing or built without Editor support.

---

## 5. Functional Requirements

1. Resolve engine in order: `hyperprompt.enginePath` → bundled binary → PATH.
2. Validate that resolved engine is executable.
3. Verify Editor trait availability (`editor-rpc` present in `--help`).
4. Do not attempt RPC on Windows; show a clear error message.
5. Provide clear remediation steps when discovery fails.

---

## 6. Non-Functional Requirements

- Discovery must complete within 2 seconds.
- Failures must not crash the extension.
- Messages must be user-actionable.

---

## 7. Edge Cases and Failure Scenarios

- `enginePath` points to a missing file → show missing binary guidance.
- `enginePath` points to non-executable file → show chmod guidance.
- PATH contains `hyperprompt` without Editor trait → show trait guidance.
- Bundled binary missing → continue to PATH fallback.

---

## 8. Verification Checklist

- `npm run compile` in `Tools/VSCodeExtension` passes.
- Discovery tests cover bad path, missing binary, unsupported OS.
- Commands show actionable messages when engine is invalid.

---
**Archived:** 2025-12-26

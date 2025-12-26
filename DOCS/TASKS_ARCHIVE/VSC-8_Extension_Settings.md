# PRD: VSC-8 — Extension Settings

## 1. Scope and Intent

### Objective
Add VS Code extension settings that control compilation behavior, diagnostics, preview updates, and engine discovery so users can configure Hyperprompt behavior without editing code.

### Deliverables
- Configuration schema in `Tools/VSCodeExtension/package.json`.
- Settings: `hyperprompt.resolutionMode`, `hyperprompt.previewAutoUpdate`, `hyperprompt.diagnosticsEnabled`, `hyperprompt.enginePath`, `hyperprompt.engineLogLevel`.
- Settings change handler that updates in-memory behavior and restarts the RPC process when required.
- Documentation of settings in `Tools/VSCodeExtension/README.md`.

### Success Criteria
- Settings appear in VS Code Settings UI with defaults and descriptions.
- `hyperprompt.compile` uses configured resolution mode by default.
- Changing `enginePath` or `engineLogLevel` restarts the RPC process cleanly.
- README documents all settings and defaults.

### Constraints and Assumptions
- CLI RPC interface from VSC-2B is available and functional.
- Extension runs on macOS/Linux only (Windows unsupported).
- Engine log level is passed via CLI args or environment variables (documented in code).

### External Dependencies
- VS Code configuration API
- Node.js child process APIs

---

## 2. Structured TODO Plan

### Phase A — Schema & Defaults
1. **Add configuration schema**
   - Define `contributes.configuration` section in `package.json`.

2. **Define settings entries**
   - Add settings for resolution mode, preview auto-update, diagnostics, engine path, and engine log level with defaults and descriptions.

### Phase B — Extension Wiring
3. **Read settings on activation**
   - Add helper to read configuration values and derive runtime options.

4. **Apply resolution mode**
   - Use `hyperprompt.resolutionMode` as default for `hyperprompt.compile` and preview compile requests.

5. **Apply engine path/log level**
   - Use `hyperprompt.enginePath` as the RPC command override when provided.
   - Pass `hyperprompt.engineLogLevel` to the RPC process (env var or CLI arg).

### Phase C — Settings Change Handling
6. **Handle configuration updates**
   - Listen for configuration changes.
   - Restart RPC process when engine path or log level changes.
   - Update compile options when resolution mode/diagnostics/preview settings change.

### Phase D — Documentation
7. **Document settings**
   - Update extension README with settings table, defaults, and usage notes.

---

## 3. Subtask Metadata

| ID | Task | Priority | Effort | Dependencies | Tools/Modules | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Add configuration schema | High | 0.5h | None | package.json | Settings section visible in VS Code UI |
| A2 | Define settings entries | High | 0.5h | A1 | package.json | Defaults + descriptions present |
| B1 | Read settings on activation | High | 0.5h | A2 | extension.ts | Runtime options loaded |
| B2 | Apply resolution mode | High | 0.5h | B1 | extension.ts | Compile uses configured mode |
| B3 | Apply engine path/log level | Medium | 0.5h | B1 | rpcClient.ts | RPC uses configured command/log level |
| C1 | Handle configuration updates | Medium | 0.5h | B1 | extension.ts | Changes apply without reload |
| D1 | Document settings | Medium | 0.25h | A2 | README | Settings documented |

---

## 4. Feature Description and Rationale

Extension settings allow users to choose strict vs lenient compilation, control preview behavior, disable diagnostics when desired, and point the extension at a specific Hyperprompt binary. This is required for local development workflows and unblocks engine discovery/validation (VSC-4C).

---

## 5. Functional Requirements

1. Provide configurable resolution mode with allowed values `strict` and `lenient`.
2. Provide preview auto-update toggle (`true`/`false`).
3. Provide diagnostics enable toggle (`true`/`false`).
4. Allow overriding engine path and passing a log level to the RPC process.
5. Apply configuration changes without requiring VS Code restart (restart RPC process when necessary).

---

## 6. Non-Functional Requirements

- Configuration changes should apply within 1 second.
- Invalid settings should fail safely with user-facing warnings.
- No crashes on missing/empty configuration values.

---

## 7. Edge Cases and Failure Scenarios

- Engine path set but binary not found or not executable → show error and stop RPC.
- Unsupported log level value → fallback to default and warn.
- Resolution mode set to invalid value → fallback to `strict`.
- Multi-root workspace with no active editor → compile commands should still warn clearly.

---

## 8. Verification Checklist

- `npm run compile` in `Tools/VSCodeExtension` passes.
- Settings appear in VS Code UI with defaults.
- `hyperprompt.compile` uses configured resolution mode.
- Changing engine path/log level restarts RPC process.
- README lists all settings.

---
**Archived:** 2025-12-26

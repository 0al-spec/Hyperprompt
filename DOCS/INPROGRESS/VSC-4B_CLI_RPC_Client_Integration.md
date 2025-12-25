# PRD: VSC-4B — CLI RPC Client Integration

## 1. Scope and Intent

### Objective
Implement a JSON-RPC client in the VS Code extension that spawns the Hyperprompt editor process, sends requests, and handles responses/timeouts reliably.

### Deliverables
- RPC client module with stdio transport.
- Process lifecycle management (spawn, restart on crash, shutdown).
- Request/response handling with timeouts.
- Minimal tests/mocks for request flow.
- Documentation updates for RPC client usage.

### Success Criteria
- Extension spawns `hyperprompt editor-rpc` process on activation.
- Requests receive responses or time out gracefully.
- Client recovers from process crashes.
- Tests cover basic request/response flow.

### Constraints and Assumptions
- CLI RPC interface from VSC-2B exists.
- Extension is running on macOS/Linux only.

### External Dependencies
- VS Code Extension API
- Node.js child process APIs

---

## 2. Structured TODO Plan

### Phase A — Client Scaffold
1. **Add RPC client module**
   - Create client class to manage process and message flow.

2. **Spawn process on activation**
   - Start `hyperprompt editor-rpc` with stdio.
   - Handle shutdown and restart on crash.

### Phase B — Request/Response
3. **Implement JSON-RPC messaging**
   - Track pending requests by id.
   - Parse responses and resolve/reject pending promises.

4. **Timeout handling**
   - Apply default 5s timeout per request.
   - Surface timeout errors to caller.

### Phase C — Tests & Docs
5. **Add tests/mocks**
   - Mock stdio stream to validate request/response flow.

6. **Update docs**
   - Update extension README with RPC client behavior.

---

## 3. Subtask Metadata

| ID | Task | Priority | Effort | Dependencies | Tools/Modules | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Add RPC client module | High | 0.5h | None | VS Code extension | Client class compiles |
| A2 | Spawn process on activation | High | 0.5h | A1 | child_process | Process starts/stops cleanly |
| B1 | Implement request/response | High | 1h | A1 | JSON-RPC | Requests resolve correctly |
| B2 | Add timeouts | High | 0.5h | B1 | Timers | Requests time out at 5s |
| C1 | Add tests/mocks | Medium | 0.5h | B1 | VS Code test | Tests cover request flow |
| C2 | Update docs | Medium | 0.25h | B1 | README | Usage documented |

---

## 4. Feature Description and Rationale

The RPC client is required to connect the VS Code extension to the Hyperprompt EditorEngine CLI without re-implementing compiler logic in TypeScript. Reliable process handling and request timeouts are foundational for navigation, diagnostics, and preview features.

---

## 5. Functional Requirements

1. Spawn CLI process with stdio transport on activation.
2. Send JSON-RPC requests and parse responses.
3. Handle timeouts and process restarts.
4. Provide a minimal API for compile and preview commands.

---

## 6. Non-Functional Requirements

- Robust error handling for malformed responses.
- Avoid memory leaks in pending request tracking.

---

## 7. Edge Cases and Failure Scenarios

- CLI process exits unexpectedly → restart and surface error.
- Response id not found → log and ignore.
- Timeout on request → reject and clear pending entry.

---

## 8. Verification Checklist

- Extension activates and spawns CLI process.
- RPC request round-trip succeeds.
- Timeout path exercised.
- Tests pass.

# PRD: VSC-2A — Language Server Implementation (if LSP chosen)

## 1. Objective & Scope

### 1.1 Goal
Build the Swift Language Server module for Hyperprompt so the project can migrate from the CLI JSON-RPC bridge to a standard LSP-based integration. The server must support core lifecycle and text document interactions, exposing the minimal requests/notifications needed for navigation and diagnostics.

### 1.2 In Scope
- New `Sources/LanguageServer/` module with an executable target.
- JSON-RPC over stdio transport with request/notification handling.
- LSP lifecycle: initialize, shutdown, exit.
- LSP text document notifications: didOpen, didChange, didSave.
- LSP requests: definition, hover.
- LSP diagnostics publishing.
- Integration tests for LSP flows.
- Documentation of LSP capabilities in `DOCS/LSP.md`.

### 1.3 Out of Scope
- Full LSP coverage (completion, formatting, code actions).
- Multi-workspace support beyond the current EditorEngine assumptions.
- Client-side VS Code extension refactor (separate task).

### 1.4 Dependencies
- **VSC-1** Integration Architecture Decision (complete).
- EditorEngine APIs for definition/hover/diagnostics.

---

## 2. Functional Requirements

1. **Server Process**
   - Provide an executable target (e.g., `hyperprompt-lsp`) that runs a stdio JSON-RPC loop.
   - Handle `initialize`, `shutdown`, and `exit` with correct LSP semantics.

2. **Text Document Synchronization**
   - Support `textDocument/didOpen` with full document text.
   - Support `textDocument/didChange` with incremental or full changes.
   - Support `textDocument/didSave` (optional text field accepted).

3. **Language Features**
   - `textDocument/definition` resolves Hyperprompt file references via EditorEngine.
   - `textDocument/hover` returns resolved target metadata.
   - `textDocument/publishDiagnostics` surfaces workspace diagnostics after open/save.

4. **Protocol Compliance**
   - JSON-RPC 2.0 compliant responses and error handling.
   - LSP capability advertisement in `initialize` response.

---

## 3. Non-Functional Requirements

- **Performance:** Request handling must not exceed existing CLI RPC latency targets (baseline: <200ms for medium fixture).
- **Reliability:** Invalid requests must return structured JSON-RPC errors.
- **Determinism:** Responses must be stable for identical inputs.
- **Observability:** Log connection lifecycle and request IDs at debug level.

---

## 4. Acceptance Criteria

1. LSP server binary starts and responds to `initialize`/`shutdown`/`exit` without crash.
2. `definition` and `hover` requests work for `@"..."` file references.
3. Diagnostics are published on `didOpen` and `didSave` for invalid files.
4. Integration tests cover at least:
   - lifecycle sequence
   - open/change/save flow
   - definition request with valid + invalid reference
   - diagnostics publishing
5. Documentation updated in `DOCS/LSP.md` describing supported capabilities.

---

## 5. Task Breakdown

### Phase 1 — Server Skeleton & Transport
| ID | Task | Priority | Effort | Dependencies | Verification |
| --- | --- | --- | --- | --- | --- |
| 1.1 | Add `Sources/LanguageServer/` module and executable target entry point. | High | 1.5h | None | `swift build` produces executable. |
| 1.2 | Implement stdio JSON-RPC loop (read, parse, dispatch, write). | High | 2h | 1.1 | Manual ping test with initialize. |
| 1.3 | Implement lifecycle handlers (`initialize`, `shutdown`, `exit`). | High | 1h | 1.2 | Integration test passes. |

### Phase 2 — Text Document Sync
| ID | Task | Priority | Effort | Dependencies | Verification |
| --- | --- | --- | --- | --- | --- |
| 2.1 | Implement `didOpen` with full document storage. | High | 1h | 1.3 | `didOpen` test passes. |
| 2.2 | Implement `didChange` (full + incremental) and update buffers. | High | 1.5h | 2.1 | `didChange` test passes. |
| 2.3 | Implement `didSave` and trigger diagnostics refresh. | Medium | 1h | 2.1 | Diagnostics emitted on save. |

### Phase 3 — Language Features
| ID | Task | Priority | Effort | Dependencies | Verification |
| --- | --- | --- | --- | --- | --- |
| 3.1 | Wire `textDocument/definition` to EditorEngine. | High | 1.5h | 2.2 | Definition tests pass. |
| 3.2 | Wire `textDocument/hover` to EditorEngine. | Medium | 1h | 2.2 | Hover tests pass. |
| 3.3 | Publish diagnostics after open/save. | High | 1.5h | 2.3 | Diagnostics test passes. |

### Phase 4 — Testing & Documentation
| ID | Task | Priority | Effort | Dependencies | Verification |
| --- | --- | --- | --- | --- | --- |
| 4.1 | Add integration tests for lifecycle + text document flow. | High | 2h | 3.3 | XCTest passes. |
| 4.2 | Add tests for definition/hover/diagnostics. | High | 1.5h | 3.3 | XCTest passes. |
| 4.3 | Document LSP capabilities in `DOCS/LSP.md`. | Medium | 0.5h | 4.1 | Doc updated. |

---

## 6. Implementation Notes

- Prefer existing JSON-RPC utilities if available; otherwise, implement a minimal parser/dispatcher.
- Reuse EditorEngine code paths already exposed for CLI RPC wherever possible.
- Ensure `initialize` advertises only implemented capabilities (definition, hover, diagnostics, textDocumentSync).
- Store open documents in memory to avoid filesystem churn during `didChange`.

---

## 7. Verification Checklist

- [ ] LSP server binary builds and runs.
- [ ] Lifecycle request sequence passes.
- [ ] Text document open/change/save flows tested.
- [ ] Definition & hover requests tested.
- [ ] Diagnostics publishing verified.
- [ ] `DOCS/LSP.md` updated with capability list.
- [ ] `swift test` passes (with build cache restored).

---

## 8. Risks & Mitigations

- **Risk:** JSON-RPC framing errors (Content-Length handling).
  - **Mitigation:** Add strict parser with tests for malformed frames.
- **Risk:** EditorEngine APIs missing for LSP usage.
  - **Mitigation:** Document gaps and adjust Phase 12 tasks if required.

---

## 9. References

- `DOCS/PRD/PRD_EditorEngine.md`
- `DOCS/PRD/v0.0.1/00_PRD_001.md`
- `DOCS/PRD/v0.0.1/01_DESIGN_SPEC_001.md`
- `DOCS/PRD/v0.0.1/02_DESIGN_SPEC_SPECIFICATION_CORE.md`

# Next Task: VSC-2A — Language Server Implementation (if LSP chosen)

**Priority:** P1
**Phase:** Phase 11 — VS Code Extension Integration Architecture
**Effort:** 12 hours
**Dependencies:** VSC-1
**Status:** Selected

## Description

Implement the Swift Language Server module for the LSP path, including JSON-RPC transport and core text document notifications/requests so the extension can migrate from CLI to LSP.

## Checklist

- [ ] Create LanguageServer module + executable target skeleton
- [ ] Implement JSON-RPC transport and core LSP lifecycle/textDocument handlers
- [ ] Add integration tests and document LSP capabilities

## Next Step

Run PLAN command to generate detailed PRD:
$ claude "Выполни команду PLAN"

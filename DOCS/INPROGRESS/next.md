# Next Task: VSC-2B — CLI JSON-RPC Interface

**Priority:** P0
**Phase:** Phase 11: VS Code Extension Integration Architecture
**Effort:** 8 hours
**Dependencies:** VSC-1 (Integration Architecture Decision)
**Status:** Planned

## Description

Add JSON-RPC interface to Hyperprompt CLI for VS Code extension integration. Implement `hyperprompt editor-rpc` subcommand with stdin/stdout message handling. Expose EditorEngine methods (indexProject, parse, resolve, compile, linkAt) via RPC protocol with JSON serialization.

## PRD

See detailed implementation plan: `DOCS/INPROGRESS/VSC-2B_CLI_JSON-RPC_Interface.md`

## Next Step

Run EXECUTE command to implement the PRD:
$ claude "Выполни команду EXECUTE"

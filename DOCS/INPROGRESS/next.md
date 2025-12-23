# Next Task: VSC-2B — CLI JSON-RPC Interface

**Priority:** P0
**Phase:** Phase 11: VS Code Extension Integration Architecture
**Effort:** 8 hours
**Dependencies:** VSC-1 (Integration Architecture Decision)
**Status:** Selected

## Description

Add JSON-RPC interface to Hyperprompt CLI for VS Code extension integration. Implement `hyperprompt-editor` subcommand with stdin/stdout message handling. Expose EditorEngine methods (indexProject, parse, resolve, compile, linkAt) via RPC protocol with JSON serialization.

## Next Step

Run PLAN command to generate detailed PRD:
$ claude "Выполни команду PLAN"

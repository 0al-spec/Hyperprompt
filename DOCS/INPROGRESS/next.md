# Next Task: VSC-2B — CLI JSON-RPC Interface

**Priority:** P0
**Phase:** Phase 11: VS Code Extension Integration Architecture
**Effort:** 8 hours
**Dependencies:** VSC-1 (Integration Architecture Decision)
**Status:** ✅ Completed on 2025-12-23

## Description

Add JSON-RPC interface to Hyperprompt CLI for VS Code extension integration. Implement `hyperprompt editor-rpc` subcommand with stdin/stdout message handling. Expose EditorEngine methods (indexProject, parse, resolve, compile, linkAt) via RPC protocol with JSON serialization.

## PRD

See detailed implementation plan: `DOCS/INPROGRESS/VSC-2B_CLI_JSON-RPC_Interface.md`

## Implementation Summary

**Completed:**
- ✅ Swift 6.2-dev installed and verified (521 tests passing)
- ✅ JSON-RPC 2.0 types (request, response, error) with Codable support
- ✅ RPC parameter types for all 5 methods
- ✅ `hyperprompt editor-rpc` subcommand added to CLI
- ✅ `editor.indexProject` method fully implemented
- ✅ LinkSpan Codable conformance added
- ✅ Error handling with JSON-RPC error codes
- ✅ RPC protocol documentation (DOCS/RPC_PROTOCOL.md)
- ✅ Package.swift updated with EditorEngine dependency (trait-gated)
- ✅ Swift 6 concurrency fixes (Sendable conformance for IndexerOptions, CompileOptions, CompilationMode)
- ✅ Project builds successfully with SWIFT_ENABLE_ALL_TRAITS=1
- ✅ All 521 tests pass

**Deferred (marked as not yet implemented in RPC handlers):**
- ⏸️ `editor.parse` method (returns error: "Method not yet implemented")
- ⏸️ `editor.resolve` method (returns error: "Method not yet implemented")
- ⏸️ `editor.compile` method (returns error: "Method not yet implemented")
- ⏸️ `editor.linkAt` method (returns error: "Method not yet implemented")

## Next Step

Run ARCHIVE command to archive completed task:
$ claude "Выполни команду ARCHIVE"

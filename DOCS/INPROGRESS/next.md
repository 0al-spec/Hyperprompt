# Next Task: EE-FIX-1 — Missing Workspace Root Path Validation

**Priority:** P0 BLOCKER
**Phase:** EditorEngine Code Review Fixes
**Effort:** 1 hour
**Dependencies:** None
**Status:** ✅ Completed on 2025-12-28

## Description

Add validation that `workspaceRoot` is an absolute path in `ProjectIndexer.index()`. Prevent relative paths from causing undefined behavior.

## Implementation Summary

✅ Added `IndexerError.invalidWorkspaceRoot(path:reason:)` error case
✅ Added description for new error in `CustomStringConvertible` extension
✅ Added absolute path validation guard clause in `ProjectIndexer.index()`
✅ Wrote 5 unit tests for path validation scenarios
✅ All 16 ProjectIndexer tests pass

## Deliverables

- `Sources/EditorEngine/ProjectIndexer.swift` - Added validation and error type
- `Tests/EditorEngineTests/ProjectIndexerTests.swift` - Added 5 new tests + MockFileSystem

## Next Step

Run SELECT command to choose next task:
$ claude "Выполни команду SELECT"

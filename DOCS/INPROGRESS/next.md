# Next Task: EE-FIX-1 — Missing Workspace Root Path Validation

**Priority:** P0 BLOCKER
**Phase:** EditorEngine Code Review Fixes
**Effort:** 1 hour
**Dependencies:** None
**Status:** Selected

## Description

Add validation that `workspaceRoot` is an absolute path in `ProjectIndexer.index()`. Prevent relative paths from causing undefined behavior.

## Next Step

Run PLAN command to generate detailed PRD:
$ claude "Выполни команду PLAN"

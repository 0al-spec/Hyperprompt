# Next Task: EE-FIX-2 — Byte Offset Calculation Off-by-One Error

**Priority:** P0 BLOCKER
**Phase:** EditorEngine Code Review Fixes
**Effort:** 2 hours
**Dependencies:** None
**Status:** Selected

## Description

Fix off-by-one error in `computeLineStartOffsets` when file ends with newline. Ensure byte offsets are accurate for all line ending scenarios and LSP-compatible positions.

## Next Step

Run PLAN command to review PRD:
```bash
claude "Выполни команду PLAN"
```

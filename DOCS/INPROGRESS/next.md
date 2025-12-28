# Next Task: EE-FIX-2 — Byte Offset Calculation Off-by-One Error

**Priority:** P0 BLOCKER
**Phase:** EditorEngine Code Review Fixes
**Effort:** 2 hours
**Dependencies:** None
**Status:** ✅ Completed on 2025-12-28

## Description

Review and validate `computeLineStartOffsets` logic for trailing newlines. Ensure byte offsets are accurate for all line ending scenarios and LSP-compatible positions.

## Implementation Summary

✅ Analyzed `computeLineStartOffsets` implementation
✅ Created comprehensive test suite for byte offset accuracy
✅ Added 4 new integration tests covering all edge cases
✅ All tests pass (7/7) - **No bug found**

## Result

**Issue B-002 NOT CONFIRMED**: Current implementation is correct.
- Byte offsets accurate for files with/without trailing newlines
- Multi-byte UTF-8 characters handled properly
- Link span byte ranges extract correct content
- No fix needed

## Deliverables

- `Tests/EditorEngineTests/LinkSpanTests.swift` - Added 4 comprehensive byte offset tests

## Next Step

Run SELECT command to choose next task:
```bash
claude "Выполни команду SELECT"
```

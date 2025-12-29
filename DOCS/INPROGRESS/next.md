# Next Task: EE-FIX-5 — Silent Regex Failure Fallback

**Priority:** P1
**Phase:** EditorEngine Code Review Fixes
**Effort:** 2 hours
**Dependencies:** EE-FIX-4
**Status:** ✅ Completed on 2025-12-28

## Description

Handle invalid glob regex patterns safely in GlobMatcher by surfacing errors during ignore file loading and avoiding silent fallback behavior.

## Checklist

- [x] Add debug assertion for invalid regex compilation and keep safe non-match fallback.
- [x] Validate ignore patterns on load with line-numbered errors.
- [x] Add tests for invalid ignore pattern handling.

## Next Step

Run ARCHIVE to clean workspace or SELECT for the next task:
$ claude "Выполни команду ARCHIVE"

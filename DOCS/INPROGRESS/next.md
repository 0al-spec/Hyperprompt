# Next Task: EE-EXT-1B — Fix EditorParser linkAt Regression

**Priority:** P0
**Phase:** Phase 12 — EditorEngine API Enhancements
**Effort:** 2 hours
**Dependencies:** EE-EXT-1
**Status:** ✅ Completed on 2025-12-27

## Description

Restore link span extraction so EditorParser linkAt tests pass and ranges are correct for @"..." and UTF-8 offsets.

## Subtasks

- [x] Fix link span extraction for EditorParser linkAt
- [x] Verify UTF-8 byte/column ranges for @"..." links
- [x] Run `swift test --traits Editor` and confirm EditorParserLinkAtTests pass

## Next Step

Run PLAN command to generate detailed PRD:
$ claude "Выполни команду PLAN"

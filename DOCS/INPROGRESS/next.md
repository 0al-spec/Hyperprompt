# Next Task: EE-EXT-1B — Fix EditorParser linkAt Regression

**Priority:** P0
**Phase:** Phase 12 — EditorEngine API Enhancements
**Effort:** 2 hours
**Dependencies:** EE-EXT-1
**Status:** Selected

## Description

Restore link span extraction so EditorParser linkAt tests pass and ranges are correct for @"..." and UTF-8 offsets.

## Subtasks

- [x] Fix link span extraction for EditorParser linkAt
- [ ] Verify UTF-8 byte/column ranges for @"..." links
- [ ] Run `swift test --traits Editor` and confirm EditorParserLinkAtTests pass

## Next Step

Run PLAN command to generate detailed PRD:
$ claude "Выполни команду PLAN"

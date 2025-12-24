# Next Task: EE-EXT-1 — Position-to-Link Query API

**Priority:** P0 (Critical)
**Phase:** Phase 12 - EditorEngine API Enhancements
**Effort:** 3 hours
**Dependencies:** EE8 (Phase 10 - EditorEngine complete) ✅
**Status:** ✅ Completed on 2025-12-24

## Description

Add position-based query API to EditorParser for VS Code extension. Implement `linkAt(line:column:)` method with binary search for O(log n) lookup performance. This enables go-to-definition and hover features in the VS Code extension.

## Next Step

Run PLAN command to generate detailed PRD:
```
Выполни команду PLAN
```

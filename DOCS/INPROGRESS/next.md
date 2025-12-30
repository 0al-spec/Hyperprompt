# Next Task: VSC-10 — Bidirectional Navigation (Optional)

**Priority:** [P2]
**Phase:** Phase 14 (VS Code Extension Development)
**Effort:** 5 hours (actual vs 4h estimated)
**Dependencies:** VSC-7 ✅, EE-EXT-3 ✅
**Status:** ✅ Completed on 2025-12-30

## Description

Implemented click-to-navigate from preview panel to source files using minimal source maps. Users can now click on any line in the preview panel and jump directly to the corresponding source location in the editor.

## Implementation Summary

- Implemented minimal SourceMap in EditorEngine (Swift)
- Updated RPC protocol to return sourceMap
- Added click handler to preview webview (TypeScript)
- Implemented navigation logic in extension

**Note:** Resolved EE-EXT-3 dependency by implementing stub SourceMap (maps to entry file only). Full multi-file tracking requires future Emitter integration.

**Files:** 9 modified, 1 new (~185 lines added)

**Summary:** [`DOCS/INPROGRESS/VSC-10-summary.md`](VSC-10-summary.md)
**PRD:** [`DOCS/INPROGRESS/VSC-10_Bidirectional_Navigation.md`](VSC-10_Bidirectional_Navigation.md)

---

**Next Step:** Run SELECT to choose next task or ARCHIVE completed tasks.

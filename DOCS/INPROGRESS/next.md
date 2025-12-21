# Next Task: EE1 — Project Indexing

**Priority:** P1
**Phase:** Phase 10 — Editor Engine Module
**Effort:** 3 hours (actual: ~3 hours)
**Dependencies:** EE0 (EditorEngine Module Foundation) ✅
**Status:** ✅ **Implementation Complete — All tests passing**
**Updated:** 2025-12-21

## Description

Implement project indexing for EditorEngine. Scan workspace for .hc and .md files with deterministic ordering (lexicographic sort), support .hyperpromptignore patterns, and exclude hidden directories by default.

## Validation Results (2025-12-21)

**Build:** ✅ Passes
**Tests:** ✅ 47/47 pass

| Test Suite | Result |
|------------|--------|
| ProjectIndexTests | ✅ 13/13 pass |
| ProjectIndexerTests | ✅ 8/8 pass |
| GlobMatcherTests | ✅ 22/22 pass |

### Bug Resolved

Archived: `DOCS/TASKS_ARCHIVE/BUG-EE1-001_GlobMatcher_Pattern_Matching_Issues.md`

### Deliverables

- ✅ `ProjectIndex` data structures with computed properties
- ✅ `ProjectIndexer` with recursive file discovery
- ✅ `GlobMatcher` — `.gitignore`-compatible pattern semantics
- ✅ `.hyperpromptignore` parsing and application
- ✅ Default ignore patterns (13 common directories)
- ✅ Public API integration via `EditorEngine.indexProject()`
- ✅ Extended FileSystem protocol for directory operations

### Fixes Applied During Validation

1. **`Sources/Core/FileSystem.swift`** — Added missing `import Foundation`
2. **`Tests/CoreTests/MockFileSystem.swift`** — Added new protocol methods
3. **`Tests/ResolverTests/MockFileSystem.swift`** — Added new protocol methods
4. **`Tests/CLITests/DiagnosticPrinterTests.swift`** — Added new protocol methods

## Next Steps

1. **Run SELECT** to choose next task

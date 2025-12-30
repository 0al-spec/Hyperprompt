# Next Task: EE-EXT-3-FULL — Complete Source Map Implementation

**Priority:** [P2]
**Phase:** Phase 12 (EditorEngine API Enhancements)
**Effort:** 12-18 hours
**Dependencies:** EE-EXT-3 (stub) ✅, EE8 ✅
**Status:** 🔵 Ready to start

## Description

Complete the Source Map Generation implementation by integrating with Emitter to track actual source locations during compilation. Current stub implementation maps all output lines to entry file only — this task adds multi-file support and accurate source tracking.

## Objectives

1. **Emitter Integration** — Track source ranges during compilation
2. **Multi-File Support** — Map output lines to actual source files (not just entry)
3. **Unit Tests** — Comprehensive test coverage for source map accuracy
4. **Remove Stub** — Replace `buildStubSourceMap()` with real implementation

## Current Gap

- ⚠️ Stub implementation in `EditorCompiler.buildStubSourceMap()`
- ❌ No Emitter integration (critical requirement)
- ❌ All lines map to entry file (incorrect for @"..." includes)
- ❌ No unit tests
- ❌ VSC-10 bidirectional navigation limited to entry file only

## Expected Outcome

- ✅ Source maps track actual source files through Emitter
- ✅ Multi-file projects navigate correctly in VS Code
- ✅ Output line → source location mapping is accurate
- ✅ Unit tests verify complex scenarios (nested files, transformations)

## Subtasks

- [ ] Read and understand Emitter implementation
- [ ] Design source tracking mechanism (SourceMapBuilder integration)
- [ ] Update Emitter to track source locations per output line
- [ ] Pass SourceMapBuilder through compilation pipeline
- [ ] Replace stub with Emitter-based implementation
- [ ] Write unit tests for SourceMap
- [ ] Write integration tests with multi-file projects
- [ ] Verify VSC-10 works with nested files
- [ ] Update documentation

---

**PRD:** Will be created in `DOCS/INPROGRESS/EE-EXT-3-FULL_Complete_Source_Map_Implementation.md`
**Next Step:** Run PLAN to generate detailed PRD

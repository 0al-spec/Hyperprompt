# Next Task: PERF-3 — Incremental Compilation — Dependency Graph

**Priority:** P0
**Phase:** Phase 13: Performance & Incremental Compilation
**Effort:** 4 hours
**Dependencies:** PERF-2
**Status:** ✅ Completed on 2025-12-25

## Description

Build a dependency graph for incremental compilation so only dirty files and their dependents are recompiled, ensuring outputs match full compilation with improved performance.

## Mini TODO (Tracker)

- [x] A1: Define dependency graph model + expose graph accessors
- [x] A2: Capture dependencies during compile path (root + nested)
- [x] B1: Dirty tracking and dependent propagation helpers
- [x] B2: Topological order for compilation / reuse cached ASTs deterministically
- [x] B3: Handle deletion invalidation in resolver/cache
- [x] C1: Unit tests for graph, dirty propagation, deletion handling

## Next Step

Run SELECT to choose the next task:
$ claude "Выполни команду SELECT"

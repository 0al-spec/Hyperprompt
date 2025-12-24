# Next Task: PERF-3 — Incremental Compilation — Dependency Graph

**Priority:** P0
**Phase:** Phase 13: Performance & Incremental Compilation
**Effort:** 4 hours
**Dependencies:** PERF-2
**Status:** Selected

## Description

Build a dependency graph for incremental compilation so only dirty files and their dependents are recompiled, ensuring outputs match full compilation with improved performance.

## Mini TODO (Tracker)

- [ ] A1: Define dependency graph model + expose graph accessors
- [ ] A2: Capture dependencies during compile path (root + nested)
- [ ] B1: Dirty tracking and dependent propagation helpers
- [ ] B2: Topological order for compilation / reuse cached ASTs deterministically
- [ ] B3: Handle deletion invalidation in resolver/cache
- [ ] C1: Unit tests for graph, dirty propagation, deletion handling

## Next Step

Run PLAN command to generate detailed PRD:
$ claude "Выполни команду PLAN"

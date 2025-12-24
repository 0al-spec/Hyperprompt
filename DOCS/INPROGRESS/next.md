# Next Task: PERF-4 — Performance Validation

**Priority:** P0
**Phase:** Phase 13: Performance & Incremental Compilation
**Effort:** 2 hours
**Dependencies:** PERF-3
**Status:** Selected

## Description

Validate incremental compilation performance against benchmarks and document results, including <200ms targets and regression checks.

## Flow Steps (Tracker)

- [x] SELECT
- [x] PLAN
- [x] INSTALL_SWIFT
- [ ] EXECUTE
- [ ] PROGRESS (optional)
- [ ] ARCHIVE

## Mini TODO (Tracker)

- [x] A1: Re-run benchmark suite with incremental compilation
- [ ] A2: Verify <200ms for medium project (second compile)
- [ ] A3: Verify <200ms for PRD medium fixture in release build
- [ ] A4: Verify <1s for large project (120 files)
- [ ] A5: Profile hot paths (Instruments or perf)
- [ ] A6: Update DOCS/PERFORMANCE.md with findings
- [ ] A7: Add/update performance regression tests in CI

## Next Step

Run PLAN command to generate detailed PRD:
$ claude "Выполни команду PLAN"

# Next Task: D3 — Diagnostic Printer

**Priority:** P1
**Phase:** Phase 6 (CLI & Integration)
**Effort:** 4 hours
**Dependencies:** A2 ✅
**Status:** ✅ Completed on 2025-12-12

## Description

Implement error message formatting with source context. Format error messages as `<file>:<line>: error: <message>`, show context line with caret indicators, support plain text and colored output for terminal display.

## Deliverables

- ✅ DiagnosticPrinter struct with full error formatting
- ✅ Source context extraction from files
- ✅ Caret indicator positioning (^ or ^^^)
- ✅ ANSI color support with terminal auto-detection
- ✅ Plain text mode for non-terminal output
- ✅ Multi-error aggregation and grouping
- ✅ 22 comprehensive unit tests (all passing)

## Verification

- ✅ Build: PASS (0 warnings)
- ✅ Tests: 22/22 passed
- ✅ All test suite: 424 tests passed
- ✅ Performance: <1ms per error (target met)
- ✅ Coverage: >90% (all acceptance criteria met)

## Next Step

Run SELECT command to choose next task:
```bash
$ claude "Выполни команду SELECT"
```

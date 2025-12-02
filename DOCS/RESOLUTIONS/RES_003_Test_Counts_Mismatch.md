# Resolution #3: Test Counts Mismatch

**Status:** RESOLVED
**Date:** December 2, 2025

## Problem

Validation report identified discrepancies in test count references across documents:

- **Reported:** §8.1 lists "V01...V15" = 15 valid tests
- **Reported:** §8.2 lists "I01...I09" = 9 invalid tests
- **Reported:** §9 Acceptance Criteria requires "All 15 valid" and "All 9 invalid"
- **Reality (after RES_001 and RES_002):**
  - Valid tests: V01, V03-V14 (14 tests) [V02 reclassified, V15 removed]
  - Invalid tests: I01-I10 (10 tests) [I10 added for multiple roots]

The count mismatch created confusion between stated requirements and actual test corpus.

## Decision: Update All Test Count References

**Rationale:**
1. RES_001 removed Test V15 (non-.md/.hc file embedding) → 14 valid tests
2. RES_002 moved V02 to invalid as I10 (multiple root nodes) → 10 invalid tests
3. All documents must consistently reference the updated counts
4. Acceptance criteria must reflect actual test corpus

## Changes Required

### PRD (00_PRD_001.md)

**Section 8.1 Valid Input Tests:**
- ✅ **DONE:** Already updated to list V01, V03-V14 (14 tests)
- ✅ V02 correctly omitted
- ✅ V15 correctly removed

**Section 8.2 Invalid Input Tests:**
- ✅ **DONE:** Already updated to include I01-I10 (10 tests)
- ✅ I10 added: "Multiple root nodes (depth 0), which should produce a syntax error"

**Section 9. Acceptance Criteria Summary:**
- **UPDATED:** Reference counts now match actual test corpus
- Current criteria: "All valid tests match golden files" (14 tests)
- Current criteria: "All invalid tests fail predictably" (10 tests)

### Design Spec (01_DESIGN_SPEC_001.md)

- ✅ No explicit test count references (test corpus defined in PRD)
- ✅ No updates required

### VALIDATION_REPORT.md

- ✅ **DONE:** Updated to reflect false alarms and corrected issue count
- ✅ Executive Summary now correctly states: "5 genuine critical issues"

## Test Count Summary

| Category | Old | New | Change |
|----------|-----|-----|--------|
| Valid Tests | 15 | 14 | -1 (V15 removed, V02 moved) |
| Invalid Tests | 9 | 10 | +1 (V02→I10 added) |
| **Total** | **24** | **24** | No net change |

## Acceptance Criteria Impact

**Updated (from RES_001 + RES_002 + RES_003):**
- ✅ 14 valid input tests produce output matching golden files
- ✅ 10 invalid input tests produce appropriate error messages and non-zero exit codes
- ✅ V02 now correctly tested as invalid scenario (multiple roots)
- ✅ I10 formalizes the multiple-root error case
- ✅ All test counts consistent across all documents

## Files Status

**PRD (00_PRD_001.md):**
- Section 8.1: ✅ Updated with correct valid test list (14 tests)
- Section 8.2: ✅ Updated with correct invalid test list (10 tests)
- Section 9: ✅ Acceptance criteria consistent with actual counts

**No Breaking Changes:** This resolution only confirms what was already fixed by RES_001 and RES_002.

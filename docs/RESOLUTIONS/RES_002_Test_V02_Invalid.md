# Resolution #2: Test V02 Now Invalid

**Status:** RESOLVED
**Date:** November 25, 2025

## Problem

Test V02 is now **invalid** due to requirement change:

- **Old V02 Description:** "covers multiple root nodes forming a document forest"
- **New Requirement:** "Only one root node allowed (depth 0)" → Syntax Error (exit 2)

The change to single-root requirement (from earlier resolution) made V02 contradict the spec.

## Decision: Move V02 to Invalid Tests as I10

**Rationale:**
1. V02 is a legitimate edge case to test
2. It should be an **invalid** test (multiple root nodes → Syntax Error)
3. Rename to I10: "Multiple root nodes (depth 0) should produce Syntax Error"
4. This is already covered in RES_001, but formalizing here

## Changes Required

### PRD (00_PRD_001.md)

**Section 8.1 Valid Input Tests:**
- Remove Test V02 from valid tests list (already done in RES_001)
- Current valid tests: V01, V03-V14 (14 total)

**Section 8.2 Invalid Input Tests:**
- Add Test I10: "Multiple root nodes (depth 0), which should produce a syntax error" (already done in RES_001)
- Current invalid tests: I01-I10 (10 total)

### Test Corpus Format

**V02 becomes I10:**

Example I10 input (invalid.hc):
```hypercode
"Root 1"
    "child.md"

"Root 2"
    "sibling.md"
```

Expected: Syntax Error (exit 2)
Error message: "Multiple root nodes not allowed. Only one root (depth 0) permitted."

## Test Count Summary

| Category | Old | New |
|----------|-----|-----|
| Valid Tests | 15 | 14 |
| Invalid Tests | 9 | 10 |
| **Total** | **24** | **24** |

All tests still covered; V02 reclassified from valid → invalid.

## Acceptance Criteria Impact

Updated (from RES_001 + RES_002):
- ✅ 14 valid input tests produce output matching golden files
- ✅ 10 invalid input tests produce appropriate error messages and non-zero exit codes
- ✅ V02 now tests invalid scenario (multiple roots)
- ✅ I10 formalizes the multiple-root error case


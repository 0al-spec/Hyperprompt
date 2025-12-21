# Build Issues & Warnings

**Last Updated:** 2025-12-21
**Build Status:** ⚠️ Successful (warnings present)

## Active Warnings

### 1. Unused `result` variable in integration tests ⚠️

**Severity:** Low (Code Quality)
**Location:** `Tests/IntegrationTests/CompilerDriverTests.swift:207:13`, `Tests/IntegrationTests/CompilerDriverTests.swift:222:13`
**Type:** Unused immutable value
**Status:** Active

**Issue:**
Two tests assign `let result = ...` but never use the value.

**Suggested Fix:**
Replace the binding with `_ =` or remove the unused assignment.

### 2. Unreachable code after `XCTSkip` ⚠️

**Severity:** Low (Code Quality)
**Location:** `Tests/IntegrationTests/CompilerDriverTests.swift:117:9`, `Tests/IntegrationTests/CompilerDriverTests.swift:133:9`, `Tests/IntegrationTests/CompilerDriverTests.swift:150:9`, `Tests/IntegrationTests/CompilerDriverTests.swift:167:9`, `Tests/IntegrationTests/CompilerDriverTests.swift:185:9`, `Tests/IntegrationTests/CompilerDriverTests.swift:203:9`, `Tests/IntegrationTests/CompilerDriverTests.swift:218:9`, `Tests/IntegrationTests/CompilerDriverTests.swift:291:9`, `Tests/IntegrationTests/CompilerDriverTests.swift:572:9`
**Type:** Unreachable code
**Status:** Active

**Issue:**
Test bodies include code after `throw XCTSkip(...)`, which is never executed and triggers compiler warnings.

**Suggested Fix:**
Move skip to the end, or wrap the rest of the test body in a conditional that only runs when not skipping.

---

## Resolved Issues

### 1. Unnecessary Pattern Binding in MarkdownEmitter ✅

**Severity:** Low (Code Quality)
**Location:** `Sources/Emitter/MarkdownEmitter.swift:172:14`
**Type:** Unnecessary Pattern Binding
**Status:** Fixed 2025-12-12

**Issue:**
The `let` keyword was used in a pattern match but both associated values were discarded with wildcards (`_`), so no variables were actually being bound.

**Fix Applied:**
Removed the unnecessary `let` keyword from the pattern match.

---

## Summary

- **Total Warnings:** 11
- **Critical Issues:** 0
- **Resolved Issues:** 1
- **Build Time:** ~1.4s

## Notes

The codebase builds successfully but emits warnings in integration tests. The unnecessary pattern binding warning has been resolved by removing the `let` keyword from the pattern match in MarkdownEmitter.swift.

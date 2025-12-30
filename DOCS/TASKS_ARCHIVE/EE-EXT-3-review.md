# EE-EXT-3: Source Map Generation — Status Review

**Task ID:** EE-EXT-3
**Status in Workplan:** ✅ **COMPLETED** on 2025-12-26
**Actual Status:** ⚠️ **PARTIALLY IMPLEMENTED** (Stub Only)
**Review Date:** 2025-12-30
**Reviewer:** Analysis by Claude

---

## Summary

Task EE-EXT-3 is marked as complete in the work plan, but **only a minimal stub implementation was delivered**. The task requirements have not been fully met.

**Key Finding:** Instead of integrating source map generation with the Emitter to track actual source ranges during compilation, a temporary stub was implemented that simply maps output lines 1:1 to the entry file.

---

## Task Requirements (from Workplan.md:375-392)

| Requirement | Status | Evidence |
|------------|--------|----------|
| ✓ Define `SourceMap` struct (output line → source location mapping) | ✅ DONE | `Sources/EditorEngine/SourceMap.swift:11` |
| ✗ Extend `Emitter` to track source ranges during compilation | ❌ NOT DONE | No integration with Emitter found |
| ✓ Add `CompileResult.sourceMap` field (optional) | ✅ DONE | `Sources/EditorEngine/CompileResult.swift:20` |
| ~ Implement JSON source map format (compatible with browser devtools) | ⚠️ PARTIAL | Codable implemented, but not browser-compatible format |
| ✓ Add `SourceMap.lookup(outputLine:) -> SourceLocation?` method | ✅ DONE | `Sources/EditorEngine/SourceMap.swift:23` |
| ✗ Write unit tests (verify source map accuracy for nested files) | ❌ NOT DONE | No tests found in `Tests/` |

**Completion Rate:** 3/6 requirements fully met, 1 partially met, 2 not implemented

---

## What Was Actually Implemented

### ✅ Implemented Components

1. **SourceMap struct** (`Sources/EditorEngine/SourceMap.swift:11-81`)
   - Basic data structure with mappings from output lines to source locations
   - `lookup(outputLine:)` method works correctly
   - Codable support for JSON serialization
   - Thread-safe SourceMapBuilder for construction

2. **CompileResult.sourceMap field** (`Sources/EditorEngine/CompileResult.swift:20`)
   - Optional `sourceMap` field added
   - Properly integrated into compile workflow

3. **Stub Implementation** (`Sources/EditorEngine/EditorCompiler.swift:118-147`)
   - `buildStubSourceMap()` function generates minimal mappings
   - Maps each output line to corresponding line in entry file

### ❌ Missing Components

1. **Emitter Integration**
   - No code in `Sources/Core/Emitter.swift` tracks source ranges
   - Source map is NOT built during actual compilation
   - Emitter doesn't emit source location metadata

2. **Multi-File Support**
   - Current stub maps ALL output lines to entry file only
   - Included files (via `@"file.hc"`) are not tracked
   - Navigation to nested sources is impossible

3. **Browser-Compatible Format**
   - Current implementation uses custom JSON format
   - Not compatible with standard source map v3 format
   - No support for segments, mappings encoding, etc.

4. **Unit Tests**
   - No tests in `Tests/EditorEngineTests/` for SourceMap
   - No integration tests for source map accuracy
   - Nested file scenarios untested

---

## Evidence from Code

### Stub Implementation (EditorCompiler.swift:118-147)

```swift
/// Build stub source map that maps all output lines to entry file.
///
/// This is a minimal implementation for VSC-10 (bidirectional navigation).
/// TODO: Replace with full source tracking through Emitter to support multi-file navigation.
///
/// - Parameters:
///   - output: Compiled markdown output
///   - entryFile: Path to entry .hc file
/// - Returns: SourceMap with basic line mappings
private func buildStubSourceMap(output: String?, entryFile: String) -> SourceMap? {
    guard let output = output, !output.isEmpty else {
        return nil
    }

    let builder = SourceMapBuilder()
    let lines = output.split(separator: "\n", omittingEmptySubsequences: false)

    // Map each output line to corresponding line in entry file
    // This is approximate since we don't track actual source ranges yet
    // Note: outputLine is 0-indexed (array enumeration), but SourceLocation requires 1-indexed lines
    for (outputLine, _) in lines.enumerated() {
        let sourceLocation = SourceLocation(
            filePath: entryFile,
            line: outputLine + 1  // Convert 0-indexed to 1-indexed for source location
        )
        builder.addMapping(outputLine: outputLine, sourceLocation: sourceLocation)
    }

    return builder.build()
}
```

**Critical Issues:**
- Line 121: `// TODO: Replace with full source tracking through Emitter`
- Line 136: `// This is approximate since we don't track actual source ranges yet`
- Loops through output lines without any knowledge of source files
- All lines mapped to `entryFile`, regardless of actual source

### Documentation Acknowledgments

**VSC-10-summary.md:13:**
> **Critical Dependency Resolution:** EE-EXT-3 (Source Map Generation) was marked complete but not implemented. Resolved by implementing minimal SourceMap as part of VSC-10.

**VSC-10-summary.md:63-66:**
> - **Decision:** Implemented stub source map (maps all lines to entry file) instead of blocking on full EE-EXT-3 implementation
> - **Rationale:** VSC-10 is P2 (optional), full source map requires changes to Core (Emitter), stub provides working functionality
> - **Limitation:** Only supports navigation to entry file, not included files

**Workplan.md:785:**
> **Note:** Implemented minimal SourceMap (stub) as EE-EXT-3 was not previously implemented. Maps all output lines to entry file. Full multi-file source tracking requires Emitter integration (future enhancement).

---

## Impact Assessment

### What Works

- Basic bidirectional navigation from preview to source **for entry file only**
- VSC-10 (Bidirectional Navigation) feature is functional with limitations
- Click-to-navigate works in VS Code extension preview panel

### What Doesn't Work

1. **Multi-File Navigation:**
   - Clicking on content from included files navigates to WRONG location (entry file)
   - No way to jump to actual source of nested content

2. **Accuracy:**
   - Line mappings are approximate (output line N → source line N)
   - No tracking of actual transformations (heading adjustments, includes, etc.)
   - Source locations are incorrect for most non-trivial compilations

3. **Use Cases:**
   - Cannot debug complex multi-file projects
   - Cannot trace output back to actual source for included content
   - Limited utility beyond simple single-file documents

---

## Recommendations

### Short-term (Workplan Update)

1. **Update Task Status:** Change EE-EXT-3 status from ✅ **COMPLETED** to ⚠️ **PARTIALLY IMPLEMENTED (Stub)**
2. **Add Follow-up Task:** Create EE-EXT-3-FULL for proper Emitter integration
3. **Document Limitation:** Update PRD validation report to note source map limitations
4. **Adjust Priority:** Consider whether full implementation is needed before v1.0

### Long-term (Full Implementation)

1. **Emitter Integration (5-8 hours):**
   - Modify `Emitter` to track source locations during compilation
   - Store (outputLine, sourceFile, sourceLine) tuples as content is emitted
   - Pass source map builder through compilation pipeline

2. **Multi-File Support (2-3 hours):**
   - Track source location for each emitted line
   - Handle heading adjustments, includes, and transformations
   - Verify mappings for nested file scenarios

3. **Testing (2-3 hours):**
   - Write unit tests for SourceMap struct
   - Write integration tests with multi-file projects
   - Verify accuracy for complex compilation scenarios

4. **Browser-Compatible Format (Optional, 3-4 hours):**
   - Implement standard source map v3 encoding
   - Support VLQ encoding for mappings
   - Enable devtools integration

**Total Estimated Effort for Full Implementation:** 12-18 hours

---

## Conclusion

**Task EE-EXT-3 is NOT complete.** Only 50% of requirements were implemented, and the critical requirement (Emitter integration) was bypassed with a stub.

The current implementation provides limited functionality for single-file navigation but fails for multi-file projects. This should be documented clearly to avoid confusion about feature completeness.

**Recommended Action:** Update Workplan.md to reflect partial implementation status and create follow-up task for full source map support.

---

## References

- **Task Definition:** `DOCS/Workplan.md:375-392`
- **Implementation:** `Sources/EditorEngine/SourceMap.swift`, `Sources/EditorEngine/EditorCompiler.swift:118-147`
- **Documentation:** `DOCS/INPROGRESS/VSC-10-summary.md`, `DOCS/INPROGRESS/VSC-10_Bidirectional_Navigation.md`
- **Usage:** `Sources/CLI/EditorRPCCommand.swift` (RPC serialization)

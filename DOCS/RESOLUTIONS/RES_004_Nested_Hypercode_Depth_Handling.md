# Resolution #4: Depth Handling in Nested Hypercode

**Status:** RESOLVED
**Date:** December 2, 2025

## Problem

When Hypercode files recursively reference other Hypercode files, the depth of nodes in the referenced file is ambiguous:

```
# main.hc (root level, depth 0)
"Main Document"
    "sub/chapter.hc"  # Embedded at depth 1

# chapter.hc (own file context)
"Chapter Title"       # Parsed as depth 0 in this file
    "content.md"      # Parsed as depth 1 in this file
```

**Questions:**
1. What depth should "Chapter Title" have in the final output?
   - Option A: Keep as depth 0 (parsed depth)?
   - Option B: Adjust to depth 1 (parent embedding depth)?
   - Option C: Adjust to depth 2 (parent depth + parsed depth)?

2. The Design Spec shows `emit(child, node.depth, output)` but the emit function signature accepts `parentDepth` but **never uses it**. This is a bug.

**Example Impact:**
If we compile the above structure:
- Expected: "Chapter Title" should be H2 (##), "content.md" should be H3 (###)
- Actual (with bug): "Chapter Title" becomes H1 (#), heading adjustment is wrong
- Reason: "Chapter Title" keeps its parsed depth of 0, ignoring that it's embedded at depth 1

## Decision: Option B - Adjust Depth by Embedding Depth

**Rationale:**
1. **Consistency:** Nodes should reflect their position in the final output hierarchy
2. **Correctness:** Heading levels adjust to reflect nesting depth
3. **Simplicity:** Single source of truth (node.depth in final AST)
4. **Current Intent:** Design Spec already passes `parentDepth` to emit() - it's just unused

## Implementation Approach

### Design Spec Section 4.3 - emit() Function Update

**Current (Buggy):**
```swift
emit(node, parentDepth, output):
    headingLevel ← node.depth + 1  // Bug: ignores parentDepth
    // ...
    for child in childAST.children:
        emit(child, node.depth, output)
```

**Fixed:**
```swift
emit(node, parentDepth, output):
    // Calculate effective depth: parent's depth + node's depth
    effectiveDepth ← parentDepth + node.depth

    headingLevel ← effectiveDepth + 1

    if effectiveDepth >= 6:
        title ← "**" + node.literal + "**"
    else:
        hashes ← repeat("#", headingLevel)
        title ← hashes + " " + node.literal

    output.append(title)
    output.append("\n")

    // Emit content based on resolution
    if node.resolution == ResolutionKind.markdownFile:
        content ← node.resolution.content
        adjusted ← adjustHeadings(content, effectiveDepth + 1)
        output.append(adjusted)

    else if node.resolution == ResolutionKind.hypercodeFile:
        childAST ← node.resolution.ast
        for child in childAST.children:
            emit(child, effectiveDepth, output)  // Pass effective depth

    // Emit children
    for i, child in node.children:
        if i > 0:
            output.append("\n")
        emit(child, effectiveDepth, output)  // Pass effective depth
```

### Key Changes:
1. **Calculate effective depth** at function entry: `effectiveDepth ← parentDepth + node.depth`
2. **Use effective depth** everywhere (heading level, adjustHeadings call)
3. **Pass effective depth** to all recursive emit() calls

### Resolution During Parse/Compile

**Note:** Node.depth is **not modified** during parse or resolve. Nodes retain their depth relative to their file. The embedding depth is only applied during emission.

### Example Walkthrough

**Files:**
```
# main.hc
"Main"           # depth=0
    "sub.hc"     # depth=1

# sub.hc
"Chapter"        # depth=0 (in sub.hc context)
    "content.md" # depth=1
```

**Parse Phase:**
- main.hc root: Node(depth=0)
- sub.hc reference: Node(depth=1) [in main.hc AST]
- sub.hc root (from recursive compile): Node(depth=0) [in sub.hc AST]

**Emit Phase:**
- emit(main, parentDepth=0):
  - effectiveDepth = 0 + 0 = 0 → "# Main" (H1)
  - emit(sub.hc ref, parentDepth=0):
    - effectiveDepth = 0 + 1 = 1 → "## sub.hc" (H2)
    - For child "Chapter" from sub.hc AST:
      - emit(chapter, parentDepth=1):
        - effectiveDepth = 1 + 0 = 1 → "## Chapter" (H2) ✓
        - For child "content.md":
          - emit(content, parentDepth=1):
            - effectiveDepth = 1 + 1 = 2 → "### content.md" (H3) ✓

## Changes Required

### Design Spec (01_DESIGN_SPEC_001.md)

**Section 4.3 - Markdown Emission Algorithm:**
- Replace current emit() pseudocode with corrected version
- Add note: "parentDepth parameter is used to calculate effective depth"
- Add example walkthrough showing depth calculation for nested .hc files

### PRD (00_PRD_001.md)

- No changes needed (PRD already specifies heading behavior correctly)

## Depth Validation

**Existing validation (preserved):**
- No single node may have depth > 10
- This is a per-file validation (depth 10 in one file + depth 5 embedding = depth 15 in output)

**New constraint to clarify:**
- "Depth is measured relative to file; effective depth during emission may exceed 10"
- "Maximum practical depth is bounded by file reference nesting + heading limits"

## Test Impact

**Existing tests affected:**
- Test V07 (nested .hc files) - currently passes because depth handling works in special cases
- Test V13 (depth 10 maximum) - remains valid (10 is max per-file depth)
- New tests could verify: recursive .hc files produce correct heading levels

**New test V15 (if added):**
- Verify: A.hc references B.hc (B has root + children); confirm heading levels reflect nesting
- Example: If B's root is embedded at depth 2, its headings should start at ### (H3)

## Acceptance Criteria Impact

**Updated:**
- ✅ Nested Hypercode files produce correct heading levels (heading depth = parent embedding depth + node depth)
- ✅ parentDepth parameter in emit() is actually used
- ✅ Recursive .hc compilation respects depth hierarchy

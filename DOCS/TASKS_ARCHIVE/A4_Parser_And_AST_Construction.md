# PRD: A4 — Parser & AST Construction

**Task ID:** A4
**Task Name:** Parser & AST Construction
**Version:** 1.0.0
**Date:** 2025-12-06
**Status:** Ready for Implementation
**Priority:** P0 (Critical)
**Estimated Effort:** 8 hours
**Phase:** Phase 2: Lexer & Parser (Core Compilation)
**Track:** A (Core Compiler)

---

## 1. Scope & Intent

### 1.1 Objective

Implement the **AST (Abstract Syntax Tree) parser** that transforms a stream of tokens (produced by the Lexer) into a hierarchical tree structure. The parser must:

1. Construct a tree from tokens based on **indentation depth**.
2. Establish **parent-child relationships** using depth changes.
3. Create **semantic AST nodes** (`Node` and `Program` structures).
4. Enforce **single root node constraint** (exactly one node at depth 0).
5. Report **detailed syntax errors** with source locations.
6. Handle **blank and comment lines structurally** without adding them to the AST.

### 1.2 Success Criteria

The parser is **successful** when it:

- ✅ Parses a token stream into a valid AST
- ✅ Produces correct depth calculations (depth = indentation_spaces / 4)
- ✅ Establishes correct parent-child relationships via depth stack
- ✅ Enforces single root node (fails with clear error if multiple roots or no root)
- ✅ Skips comment tokens (not added to AST)
- ✅ Preserves blank line structure for output generation (but doesn't add to AST)
- ✅ Reports all syntax errors with source file, line number, and issue description
- ✅ Achieves >90% test coverage on all valid/invalid structures
- ✅ All existing lexer tests continue to pass

### 1.3 Primary Deliverables

1. **`Node` struct** — AST node element (literal, depth, location, children, resolution)
2. **`Program` struct** — Root container for the AST
3. **`Token` enum** — Classified input (blank, comment, node) with metadata
4. **`Parser` type** — Main parsing logic with tree construction algorithm
5. **Parser tests** — >20 test cases covering valid/invalid structures
6. **Error handling** — Comprehensive syntax error reporting

### 1.4 Constraints & Assumptions

- **Input**: Token stream from Lexer (guaranteed to be valid tokens)
- **Single-line content**: All literals are single-line (enforced by Lexer)
- **Indentation**: Indentation is always a multiple of 4 spaces (enforced by Lexer)
- **No tabs**: Tabs are forbidden in indentation (enforced by Lexer)
- **Output**: AST with depth 0-10 (depth > 10 rejected as syntax error)
- **Error reporting**: All errors include `SourceLocation` (file + line number)

---

## 2. Decomposition into TODO Plan

### Phase 1: Data Structures (2 hours)

#### 1.1 Implement `SourceLocation` struct (if not in A2)
- **Input**: File path (String), line number (Int)
- **Output**: `SourceLocation` struct with file, line, and optional column
- **Acceptance Criteria**: Can be created, printed, and used in error messages
- **Effort**: 0.5 hours
- **Priority**: High

#### 1.2 Implement `Node` struct
- **Input**: Literal (String), depth (Int), location (SourceLocation)
- **Output**: Mutable struct with fields:
  - `literal: String` — Raw quoted content
  - `depth: Int` — Indentation / 4
  - `location: SourceLocation` — Source file + line
  - `children: [Node]` — Nested nodes (mutable array)
  - `resolution: ResolutionKind?` — For later resolution phase (optional)
- **Acceptance Criteria**:
  - Struct can be instantiated with required fields
  - Children array is mutable and supports append
  - Structure matches Design Spec §3.1
- **Effort**: 1 hour
- **Priority**: High

#### 1.3 Implement `Program` struct
- **Input**: Root node (Node)
- **Output**: Struct containing:
  - `root: Node` — Single root node (depth 0)
  - Metadata: source file path, compilation metadata (optional)
- **Acceptance Criteria**:
  - Can be instantiated with a root node
  - Root node must have depth 0 (enforced or validated)
- **Effort**: 0.5 hours
- **Priority**: High

#### 1.4 Define `Token` enum (if not in Lexer)
- **Input**: Lexer output
- **Output**: Enum with cases:
  - `blank` — Empty line
  - `comment(indent: Int)` — Comment with indentation level
  - `node(indent: Int, literal: String)` — Node line with indentation and quoted content
- **Acceptance Criteria**: Matches Lexer output exactly
- **Effort**: 0.5 hours
- **Priority**: High

### Phase 2: Parser Core Logic (4 hours)

#### 2.1 Implement `Parser` type structure
- **Input**: Configuration (strict mode, depth limits)
- **Output**: Parser instance with methods for tree construction
- **Acceptance Criteria**: Parser can be instantiated and has required methods
- **Effort**: 0.5 hours
- **Priority**: High

#### 2.2 Implement depth stack for tree construction
- **Input**: Token stream
- **Process**: Maintain a stack of (depth, node) pairs
- **Output**: Parent-child relationships established correctly
- **Algorithm**:
  1. Initialize empty depth stack
  2. For each token:
     - If token is blank or comment, skip (don't add to AST)
     - If token is node:
       - Pop stack until top.depth < token.depth
       - Create new node at token.depth
       - Append to top of stack as child
       - Push new node onto stack
  3. Final stack.count == 1 and stack[0].depth == 0 (single root)
- **Acceptance Criteria**:
  - Depth stack correctly maintains hierarchy
  - Parent-child relationships established via append
  - All nodes except root have parents
- **Effort**: 2 hours
- **Priority**: High

#### 2.3 Implement root node validation
- **Input**: Parsed tree
- **Process**:
  1. Verify exactly one node exists at depth 0
  2. All other nodes are descendants (depth > 0)
  3. No gaps in depth (e.g., depth 0 → depth 3 invalid)
- **Output**: Root node or syntax error
- **Acceptance Criteria**:
  - Single root node enforced
  - Multiple roots rejected with clear error
  - No root rejected with clear error
  - Depth gaps detected and reported
- **Effort**: 1 hour
- **Priority**: High

#### 2.4 Implement error reporting
- **Input**: Parse failure (syntax error)
- **Output**: Error with format:
  ```
  <file>:<line>: error: <description>
  ```
- **Errors to detect**:
  - Multiple root nodes (depth 0)
  - No root node
  - Depth gaps (e.g., 0 → 3)
  - Depth exceeding limit (> 10)
  - Invalid indentation (enforced by Lexer, but validate)
- **Acceptance Criteria**:
  - All errors include SourceLocation
  - Messages are clear and actionable
  - Errors match specification format
- **Effort**: 1 hour
- **Priority**: High

### Phase 3: Integration & Testing (2 hours)

#### 3.1 Integrate parser with Lexer
- **Input**: Lexer output (Token stream)
- **Output**: Parser consumes tokens and produces AST
- **Acceptance Criteria**:
  - Parser correctly uses Token enum from Lexer
  - Token stream flows from Lexer → Parser
  - No data loss or transformation
- **Effort**: 0.5 hours
- **Priority**: High

#### 3.2 Write parser tests
- **Input**: Valid and invalid test cases
- **Output**: >20 test cases with golden outputs
- **Test Categories**:
  1. **Valid structures** (15+ tests):
     - Single root + single child
     - Single root + nested hierarchy (3+ levels)
     - Multiple siblings at same depth
     - Deep nesting (up to depth 10)
     - Mixed depths with correct jumps
     - Blank lines between nodes
     - Comment lines mixed with nodes
  2. **Invalid structures** (10+ tests):
     - Multiple root nodes (depth 0)
     - No root node (all depth > 0)
     - Depth gaps (0 → 2, 0 → 3)
     - Depth exceeding 10
     - Invalid indentation alignment
- **Acceptance Criteria**:
  - All valid tests produce correct AST
  - All invalid tests reject with appropriate error
  - >90% test coverage
  - Test output matches golden files
- **Effort**: 1 hour
- **Priority**: High

#### 3.3 Verify backward compatibility
- **Input**: Existing lexer tests
- **Output**: Verify lexer still works correctly
- **Acceptance Criteria**:
  - All Lexer tests (20+) still pass
  - No regressions in Lexer output
  - Lexer changes (if any) are documented
- **Effort**: 0.5 hours
- **Priority**: Medium

---

## 3. Functional Requirements

### 3.1 AST Construction

**Requirement FR-1: Tree Construction from Token Stream**

The parser must transform a token stream into a hierarchical tree using indentation-based depth tracking.

- **Input**: Sequence of `Token` values (blank, comment, node)
- **Process**:
  1. Iterate through tokens
  2. Skip blank and comment tokens (don't add to AST)
  3. For node tokens, calculate depth = indentation / 4
  4. Maintain a stack of (depth, node) pairs
  5. Pop stack until top.depth < current.depth
  6. Create new Node, append to top.children
  7. Push new node onto stack
- **Output**: Single root Node with full subtree
- **Example**:
  ```
  "A"        (depth 0)
  "  B"      (depth 1) → B is child of A
  "  C"      (depth 1) → C is child of A
  "    D"    (depth 2) → D is child of C
  ```
  Result: A(children: [B(children: []), C(children: [D])])

**Requirement FR-2: Single Root Node Constraint**

Exactly one node must exist at depth 0. All other nodes must be descendants.

- **Input**: Parsed tree
- **Process**:
  1. Count nodes at depth 0
  2. Verify count == 1
  3. Verify all depth > 0 nodes have ancestors
- **Output**: Validated tree or error
- **Error cases**:
  - `parse_error_multiple_roots`: "Multiple root nodes (depth 0) found"
  - `parse_error_no_root`: "No root node (depth 0) found"

**Requirement FR-3: Depth Calculation**

Depth must be computed as indentation_spaces / 4.

- **Input**: Indentation count (spaces)
- **Process**: depth = indentation / 4 (integer division)
- **Output**: Depth value 0-10
- **Constraints**:
  - Indentation must be multiple of 4 (enforced by Lexer)
  - Depth must be 0-10
  - No gaps in depth progression (e.g., 0 → 3 invalid)

**Requirement FR-4: Depth Gap Detection**

Detect invalid indentation jumps (e.g., depth 0 → depth 3).

- **Input**: Node sequence
- **Process**: For each node, verify depth ≤ previous_depth + 1
- **Output**: Error if gap detected
- **Error**: `parse_error_invalid_depth_jump`: "Invalid depth jump from {prev} to {current} at line {line}"

**Requirement FR-5: Depth Limit Enforcement**

Maximum allowed depth is 10.

- **Input**: Node with depth > 10
- **Output**: Syntax error
- **Error**: `parse_error_depth_exceeded`: "Depth exceeds maximum (10) at line {line}"

### 3.2 Node Structure

**Requirement FR-6: Node Attributes**

Each AST node must contain:

| Attribute | Type | Description | Required |
|-----------|------|-------------|----------|
| `literal` | String | Raw quoted content (1-2000 chars) | Yes |
| `depth` | Int | Indentation level (0-10) | Yes |
| `location` | SourceLocation | Source file + line number | Yes |
| `children` | [Node] | Child nodes (mutable array) | Yes (empty initially) |
| `resolution` | ResolutionKind? | File reference classification | No (set during Phase 4) |

**Requirement FR-7: Program Root Container**

The Program struct wraps a single root Node.

| Attribute | Type | Description |
|-----------|------|-------------|
| `root` | Node | Node at depth 0 |
| (optional) | | Source metadata (file path, etc.) |

### 3.3 Token Handling

**Requirement FR-8: Blank Line Handling**

Blank lines are recognized by Lexer but not added to AST.

- **Input**: `Token.blank`
- **Process**: Skip (do not create Node)
- **Output**: Blank line structure preserved in source but absent from AST
- **Note**: Blank lines matter for output formatting (Phase 5), but not for AST structure

**Requirement FR-9: Comment Line Handling**

Comment lines are recognized by Lexer but not added to AST.

- **Input**: `Token.comment(indent: Int)`
- **Process**: Skip (do not create Node)
- **Output**: Comments absent from AST
- **Note**: Comments stripped during parsing; output has no comment markers

**Requirement FR-10: Node Token Processing**

Only `Token.node` creates AST nodes.

- **Input**: `Token.node(indent: Int, literal: String)`
- **Process**:
  1. Create Node with literal
  2. Calculate depth from indent
  3. Append to parent via depth stack
- **Output**: Node added to tree

---

## 4. Non-Functional Requirements

### 4.1 Performance

**Requirement NFR-1: Linear Time Complexity**

Parser must complete in O(n) time where n = token count.

- **Target**: Parse 10,000 tokens in <1 second
- **Measurement**: Benchmark with large token streams
- **Acceptance**: No quadratic or worse loops

**Requirement NFR-2: Linear Space Complexity**

Memory usage must be O(n) where n = AST node count.

- **Target**: 100,000-node tree in <100 MB
- **Measurement**: Memory profiling during tests
- **Acceptance**: No memory leaks, no unnecessary allocations

### 4.2 Reliability & Error Handling

**Requirement NFR-3: Comprehensive Error Reporting**

All syntax errors must include source location and actionable message.

- **Format**: `<file>:<line>: error: <message>`
- **Information**:
  - Exact file path (relative to root)
  - Exact line number
  - Clear description of the issue
  - (Optional) Suggested fix

**Requirement NFR-4: Graceful Failure**

Invalid input must produce clear error, not crash.

- **No panics** on malformed input
- **No unhandled exceptions**
- **All errors** must be catchable and reportable

### 4.3 Testing & Quality

**Requirement NFR-5: Test Coverage**

All parser functionality must be tested.

- **Target**: >90% code coverage
- **Test corpus**: 20+ test cases
- **Categories**: Valid structures, invalid structures, edge cases, boundary conditions

**Requirement NFR-6: Deterministic Output**

Same input always produces identical AST.

- **No random behavior**
- **No timestamp-dependent logic**
- **Reproducible** across runs

---

## 5. Edge Cases & Error Scenarios

### 5.1 Edge Cases to Handle

| Case | Input | Expected Output | Error? |
|------|-------|-----------------|--------|
| Single node | `"root"` | Program(root: Node("root", depth: 0)) | No |
| Deep nesting | 10 levels | Valid AST with depth 10 | No |
| Wide tree | 100 siblings | All at depth 1 as children of root | No |
| Depth jumps | 0 → 2 | Error: invalid depth jump | Yes |
| Multiple roots | Two nodes at depth 0 | Error: multiple roots | Yes |
| No root | Only depth 1+ nodes | Error: no root | Yes |
| Blank lines | Interspersed nodes | Skipped, not in AST | No |
| Comments | Mixed with nodes | Skipped, not in AST | No |
| Exceeds depth | Depth 11 | Error: depth exceeded | Yes |

### 5.2 Failure Scenarios

| Scenario | Error Code | Message | Exit Code |
|----------|-----------|---------|-----------|
| Multiple roots | `parse_error_multiple_roots` | "Multiple root nodes (depth 0) found at lines X and Y" | 2 |
| No root | `parse_error_no_root` | "No root node (depth 0) found" | 2 |
| Depth gap | `parse_error_invalid_depth_jump` | "Invalid depth jump from 0 to 3 at line 5" | 2 |
| Depth exceeded | `parse_error_depth_exceeded` | "Depth exceeds maximum (10) at line 15" | 2 |

---

## 6. Execution Plan (Step-by-Step)

### Step 1: Data Structures (2 hours)
1. Verify `SourceLocation` struct exists (from A2)
2. Implement `Node` struct with all required fields
3. Implement `Program` struct wrapping root Node
4. Define (or verify) `Token` enum from Lexer

**Verification**: All structs compile and have correct signatures

### Step 2: Core Parser Logic (4 hours)
1. Create `Parser` type with initializer
2. Implement depth stack algorithm:
   - Maintain `[(depth: Int, node: Node)]` stack
   - Process each token, updating stack and tree
3. Implement single root validation
4. Implement error detection and reporting
5. Write parser public interface (main `parse()` method)

**Verification**: Parser compiles, can be called with token stream

### Step 3: Testing & Refinement (2 hours)
1. Write test suite with 20+ test cases
2. Test valid structures (different trees, depths, widths)
3. Test invalid structures (multiple roots, gaps, exceeded depth)
4. Verify all error messages are clear
5. Measure code coverage (aim for >90%)
6. Run lexer tests to ensure no regressions

**Verification**: All tests pass, >90% coverage, lexer unaffected

---

## 7. Definition of Done

### Code Complete
- [ ] `Node` struct implemented with all fields
- [ ] `Program` struct implemented
- [ ] `Token` enum defined/verified
- [ ] `Parser` type with `parse(tokens: [Token]) -> Result<Program, ParserError>` method
- [ ] All tree construction logic implemented
- [ ] All error detection and reporting implemented

### Tests Pass
- [ ] 20+ parser test cases written and passing
- [ ] All valid structure tests pass
- [ ] All invalid structure tests fail correctly
- [ ] >90% code coverage achieved
- [ ] Existing lexer tests still pass (no regressions)

### Documentation
- [ ] Code comments explain algorithms
- [ ] Error messages are clear and actionable
- [ ] Test cases are well-organized and documented

### Quality Checks
- [ ] No compiler warnings
- [ ] Code follows Swift conventions
- [ ] Deterministic output verified
- [ ] Performance acceptable (O(n) time, O(n) space)

---

## 8. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Code coverage | >90% | Swift test coverage report |
| Test cases | 20+ | Count of test functions |
| Error clarity | 100% | Manual review of error messages |
| Regression rate | 0% | All prior tests still pass |
| Performance | <1s for 10K nodes | Benchmark timing |
| Determinism | 100% | Identical output on repeated runs |

---

## 9. Blockers & Risks

### Potential Blockers
1. **Lexer output format mismatch** — Confirm Token enum matches Lexer output
2. **Indentation calculation** — Ensure depth = indentation / 4 is consistent across codebase
3. **Error handling framework** — Verify CompilerError protocol is implemented in A2

### Risk Mitigation
1. **Validation**: Test with lexer output early
2. **Integration tests**: Run parser immediately after lexer in pipeline
3. **Error handling**: Use consistent error reporting from A2

---

## 10. Related Phases & Dependencies

| Phase | Task | Dependency | Notes |
|-------|------|-----------|-------|
| Phase 2 | Lexer Impl | A2 | ✅ Completed — provides Token stream |
| Phase 1 | A2: Core Types | — | ✅ Completed — provides SourceLocation, error handling |
| Phase 4 | B4: Recursive Compilation | A4 | Requires AST from A4 |
| Phase 5 | C2: Markdown Emitter | A4 | Requires AST from A4 |

---

## 11. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-06 | Claude | Initial PRD from task A4 |

---

## Appendix: Test Case Template

```swift
// TEMPLATE: Parser Test Case

func test_parser_valid_single_root() {
    // Setup
    let tokens: [Token] = [
        .node(indent: 0, literal: "root")
    ]
    let parser = Parser()

    // Execute
    let result = parser.parse(tokens: tokens)

    // Assert
    XCTAssertTrue(result.isSuccess, "Single root should parse successfully")
    let program = try XCTUnwrap(result.value)
    XCTAssertEqual(program.root.literal, "root")
    XCTAssertEqual(program.root.depth, 0)
    XCTAssertEqual(program.root.children.count, 0)
}

func test_parser_invalid_multiple_roots() {
    // Setup
    let tokens: [Token] = [
        .node(indent: 0, literal: "root1"),
        .node(indent: 0, literal: "root2")
    ]
    let parser = Parser()

    // Execute
    let result = parser.parse(tokens: tokens)

    // Assert
    XCTAssertTrue(result.isFailure, "Multiple roots should fail")
    let error = try XCTUnwrap(result.error)
    XCTAssertEqual(error.code, "parse_error_multiple_roots")
}
```

---

**END OF PRD**

---

**Archived:** 2025-12-06

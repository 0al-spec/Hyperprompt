# PRD — PERF-1: Performance Baseline & Benchmarks

**Task ID:** PERF-1
**Phase:** Phase 13 — Performance & Incremental Compilation
**Priority:** P0 (Critical)
**Estimated Effort:** 3 hours
**Dependencies:** EE8 (Phase 10 — EditorEngine complete) ✅
**Status:** In Progress
**Blocks:** PERF-2 (Incremental Compilation — File Caching)

---

## 1. Scope & Intent

### 1.1 Objective

Establish **performance baseline measurements** and create a **comprehensive benchmark suite** for the Hyperprompt compiler to:
- Define reproducible "medium project" benchmark (50 files, 5000 lines total)
- Measure and document current compiler performance characteristics
- Enable performance regression tracking in CI/CD pipeline
- Provide baseline for Phase 13 optimization work (targeting <200ms compile time)

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Synthetic benchmark corpus | 50 .hc files, 5000 total lines, realistic project structure |
| Performance test suite | XCTest suite using XCTMeasure for compilation benchmarks |
| Baseline measurements | Documented metrics for full compile, parse, resolve, emit |
| CI integration | GitHub Actions job tracking performance over commits |
| DOCS/PERFORMANCE.md | Performance characteristics, baselines, methodology |

### 1.3 Success Criteria

- ✅ Benchmark corpus generates valid compilable output
- ✅ Performance test suite runs successfully (XCTest passes)
- ✅ Baseline metrics documented with specific numbers (ms, files/sec)
- ✅ CI job runs on every commit, fails on >20% regression
- ✅ PERFORMANCE.md provides reproducible methodology

### 1.4 Constraints & Assumptions

**Constraints:**
- Benchmarks must run on CI (GitHub Actions macOS runner)
- Total benchmark execution time <60 seconds
- Synthetic corpus must be deterministic (same output every time)
- No external dependencies (Python, Ruby, etc.) for corpus generation

**Assumptions:**
- Current EditorCompiler API is stable (no API changes during Phase 13)
- XCTest XCTMeasure provides sufficient precision (±5%)
- macOS-only testing acceptable for baseline (Linux performance may differ)
- "Medium project" definition (50 files, 5000 lines) represents typical use case

### 1.5 External Dependencies

| Dependency | Purpose | Status |
|-----------|---------|--------|
| EE8 (EditorEngine) | Compiler API for benchmarking | ✅ Complete |
| XCTest | Testing framework with XCTMeasure | Built-in |
| GitHub Actions | CI infrastructure | Available |
| Swift 6.1 | Compiler and stdlib | Required |

---

## 2. Structured TODO Plan

### Phase 1: Benchmark Corpus Definition (P0)

#### 2.1.1 Define "medium project" benchmark specification

**Input:**
- Workplan.md requirement (50 files, 5000 lines)
- Realistic Hyperprompt project structure (entry file, modules, shared components)

**Process:**
1. Define file distribution (entry file, 10 modules with 4-5 files each)
2. Calculate lines per file (average 100 lines, range 50-200)
3. Design link density (average 5 links per file, cross-module references)
4. Plan directory structure (`entry.hc`, `modules/auth/`, `modules/db/`, etc.)

**Output:**
- Specification document (embedded in PERFORMANCE.md)
- File count: 50
- Total lines: 5000 ±100
- Link count: ~250

**Metadata:**
- Priority: High (P0)
- Effort: 30 minutes
- Tools: Text editor, calculator
- Acceptance Criteria:
  - File distribution defined
  - Line count targets set
  - Link density specified

---

#### 2.1.2 Generate synthetic benchmark corpus

**Input:**
- Benchmark specification from 2.1.1
- Swift script for corpus generation (create new tool)

**Process:**
1. Create `Tools/BenchmarkGenerator/` Swift package
2. Implement `CorpusGenerator` struct with configurable parameters
3. Generate file tree with realistic content:
   - Markdown headings (H1-H6)
   - Text paragraphs (Lorem ipsum variants)
   - File references (`[](modules/auth/login.hc)`)
   - Cross-module links
4. Write to `Tests/PerformanceTests/Fixtures/MediumProject/`
5. Verify corpus compiles successfully

**Output:**
- Swift script: `Tools/BenchmarkGenerator/main.swift`
- Corpus files: `Tests/PerformanceTests/Fixtures/MediumProject/`
- Entry file: `entry.hc`
- 50 .hc files, 5000 lines total

**Metadata:**
- Priority: High (P0)
- Effort: 1 hour
- Tools: Swift, Foundation, FileManager
- Acceptance Criteria:
  - Corpus generates 50 files
  - Total line count within ±2% of 5000
  - All files compile without errors
  - Deterministic output (same files on every run)

**Implementation Notes:**
```swift
struct CorpusGenerator {
    let fileCount: Int = 50
    let targetLines: Int = 5000
    let linkDensity: Double = 5.0 // links per file

    func generate(at path: String) throws { ... }
}
```

---

### Phase 2: Performance Test Suite (P0)

#### 2.2.1 Create performance test target

**Input:**
- Existing test infrastructure (`Tests/`)
- XCTest framework

**Process:**
1. Add `PerformanceTests` target to `Package.swift`
2. Create `Tests/PerformanceTests/CompilerPerformanceTests.swift`
3. Import EditorEngine module
4. Set up test fixtures (corpus path)

**Output:**
- New test target in SPM
- Test file skeleton with `XCTestCase` subclass

**Metadata:**
- Priority: High (P0)
- Effort: 15 minutes
- Tools: Swift Package Manager
- Acceptance: `swift test --filter PerformanceTests` runs

---

#### 2.2.2 Implement full compilation benchmark

**Input:**
- Synthetic corpus at `Fixtures/MediumProject/entry.hc`
- EditorCompiler API

**Process:**
1. Write `testFullCompilationPerformance()` method
2. Use `measure { }` block from XCTest
3. Call `EditorCompiler.compile(entryFile:options:)`
4. Measure wall-clock time (10 iterations, report median)
5. Assert compilation succeeds (no errors)

**Output:**
- Test method measuring full compile time
- Baseline metric: X ms per full compilation

**Metadata:**
- Priority: High (P0)
- Effort: 20 minutes
- Tools: XCTest, XCTMeasure
- Acceptance: Test passes, reports time in Xcode/console

**Implementation Notes:**
```swift
func testFullCompilationPerformance() throws {
    let corpus = try loadMediumProjectCorpus()
    let compiler = EditorCompiler()

    measure {
        let result = try! compiler.compile(entryFile: corpus.entryPath, options: .default)
        XCTAssertTrue(result.success)
    }
}
```

---

#### 2.2.3 Implement parse-only benchmark

**Input:**
- Single representative file from corpus
- EditorParser API

**Process:**
1. Write `testParsePerformance()` method
2. Select medium-sized file (100 lines, 5 links)
3. Measure `EditorParser.parse(filePath:)` time
4. Extrapolate to files/second metric

**Output:**
- Test method measuring parse time per file
- Baseline: Y ms per file, Z files/sec

**Metadata:**
- Priority: High (P0)
- Effort: 15 minutes
- Acceptance: Test reports parse throughput

---

#### 2.2.4 Implement resolution benchmark

**Input:**
- Parsed file with link spans
- EditorResolver API

**Process:**
1. Write `testResolutionPerformance()` method
2. Parse file, extract link spans
3. Measure `EditorResolver.resolve(link:context:)` per link
4. Calculate links/second

**Output:**
- Test method measuring resolution time per link
- Baseline: A ms per link, B links/sec

**Metadata:**
- Priority: High (P0)
- Effort: 15 minutes

---

#### 2.2.5 Implement emission benchmark

**Input:**
- Compiled AST
- Emitter API

**Process:**
1. Write `testEmissionPerformance()` method
2. Measure `Emitter.emit(ast:)` time
3. Calculate output size (bytes, lines)

**Output:**
- Test method measuring emission time
- Baseline: C ms, D lines/sec

**Metadata:**
- Priority: High (P0)
- Effort: 15 minutes

---

### Phase 3: Baseline Documentation (P1)

#### 2.3.1 Run baseline measurements

**Input:**
- Complete performance test suite
- Clean build (no caching)

**Process:**
1. Run `swift test --filter PerformanceTests` 3 times
2. Record median values for each metric
3. Note hardware specs (GitHub Actions runner)
4. Document Swift version, OS version

**Output:**
- Baseline metrics table:
  - Full compilation: X ms
  - Parse per file: Y ms
  - Resolution per link: A ms
  - Emission total: C ms
  - Files/second: Z
  - Links/second: B

**Metadata:**
- Priority: Medium (P1)
- Effort: 15 minutes

---

#### 2.3.2 Write DOCS/PERFORMANCE.md

**Input:**
- Baseline measurements
- Benchmark corpus specification
- Test methodology

**Process:**
1. Create `DOCS/PERFORMANCE.md`
2. Document benchmark corpus structure
3. Document baseline metrics (table format)
4. Explain measurement methodology
5. Add instructions for running benchmarks locally
6. Document performance targets (<200ms for Phase 13)

**Output:**
- DOCS/PERFORMANCE.md file

**Metadata:**
- Priority: Medium (P1)
- Effort: 30 minutes
- Acceptance: Document is complete, reproducible

**Template:**
```markdown
# Hyperprompt Compiler Performance

## Benchmark Corpus

- **Size:** 50 files, 5000 lines
- **Structure:** Entry file + 10 modules
- **Link density:** ~5 links/file

## Baseline Metrics (as of 2025-12-24)

| Metric | Time | Throughput |
|--------|------|------------|
| Full compilation | X ms | - |
| Parse per file | Y ms | Z files/sec |
| Resolution per link | A ms | B links/sec |
| Emission | C ms | D lines/sec |

**Hardware:** GitHub Actions macOS runner (specs)
**Swift Version:** 6.1
**OS:** macOS 14

## Methodology

Run benchmarks: `swift test --filter PerformanceTests`

## Targets

- **Phase 13 Goal:** <200ms full compilation (medium project)
- **Incremental Compile:** <50ms (single file change)
```

---

### Phase 4: CI Integration (P1)

#### 2.4.1 Add CI job for performance tracking

**Input:**
- Existing `.github/workflows/` configuration
- Performance test suite

**Process:**
1. Edit `.github/workflows/swift.yml` (or create `performance.yml`)
2. Add job `performance-tests`:
   - Runs on: macOS-latest
   - Steps: checkout, build, run performance tests
   - Store results as artifact
3. Add regression check (compare with main branch baseline)
4. Fail if >20% slower

**Output:**
- CI job running performance tests on every PR
- Regression detection enabled

**Metadata:**
- Priority: Medium (P1)
- Effort: 30 minutes
- Tools: GitHub Actions YAML
- Acceptance: CI runs, reports performance

**Implementation Notes:**
```yaml
- name: Run performance tests
  run: swift test --filter PerformanceTests

- name: Check for regressions
  run: |
    # Compare with baseline (stored in PERFORMANCE.md or artifact)
    # Fail if >20% slower
```

---

## 3. Functional Requirements

### FR-1: Synthetic Benchmark Corpus

**ID:** FR-1
**Priority:** P0
**Description:** Deterministic synthetic corpus representing medium-sized Hyperprompt project.

**Acceptance Criteria:**
- 50 .hc files generated
- 5000 ±100 total lines
- Realistic directory structure (modules)
- All files compile successfully
- Deterministic (same output every run)

---

### FR-2: Performance Test Suite

**ID:** FR-2
**Priority:** P0
**Description:** XCTest suite measuring compiler performance.

**Acceptance Criteria:**
- Tests for: full compile, parse, resolve, emit
- Uses XCTest `measure { }` blocks
- Reports median time over 10 iterations
- All tests pass (no compilation errors)
- Runs in <60 seconds total

---

### FR-3: Baseline Documentation

**ID:** FR-3
**Priority:** P1
**Description:** Document current performance characteristics.

**Acceptance Criteria:**
- DOCS/PERFORMANCE.md exists
- Contains baseline metrics table
- Explains methodology
- Provides reproduction instructions
- Documents hardware/software specs

---

### FR-4: CI Performance Tracking

**ID:** FR-4
**Priority:** P1
**Description:** CI job tracking performance over commits.

**Acceptance Criteria:**
- GitHub Actions job runs performance tests
- Detects regressions (>20% slower)
- Stores results as artifacts
- Fails PR on regression

---

## 4. Non-Functional Requirements

### NFR-1: Determinism

**Priority:** P0
**Description:** Benchmark corpus must be deterministic.

**Rationale:** Reproducible performance measurements require identical input.

**Acceptance:** Running generator twice produces identical files (byte-for-byte).

---

### NFR-2: Execution Time

**Priority:** P1
**Description:** Benchmark suite completes in <60 seconds.

**Rationale:** CI time constraints, developer iteration speed.

**Acceptance:** `swift test --filter PerformanceTests` completes in <60s on CI.

---

### NFR-3: Precision

**Priority:** P1
**Description:** Measurements have ±5% precision.

**Rationale:** Need to detect meaningful regressions without false positives.

**Acceptance:** XCTMeasure reports standard deviation <5% of median.

---

### NFR-4: Portability

**Priority:** P2
**Description:** Benchmarks run on macOS (Linux optional).

**Rationale:** Primary development platform is macOS.

**Acceptance:** Tests pass on macOS 13+, Swift 6.1+.

---

## 5. Edge Cases & Failure Scenarios

### Edge Case Matrix

| Scenario | Expected Behavior | Mitigation |
|----------|-------------------|------------|
| Corpus generation fails | Tool reports error, exits non-zero | Validate parameters before generation |
| Performance test timeout | XCTest aborts after 60s | Fail test, investigate performance issue |
| CI runner variance | Performance varies ±10% | Use median of 10 runs, allow 20% threshold |
| Disk I/O slow | Parse time inflated | Measure in-memory operations separately |
| Compiler crash | Test fails with exception | Catch and report error, investigate bug |

---

## 6. Implementation Plan

### Step 1: Create Benchmark Generator (45 min)

1. Create `Tools/BenchmarkGenerator/` package
2. Implement `CorpusGenerator` struct
3. Generate 50 files with realistic content
4. Verify compilation succeeds

### Step 2: Implement Performance Tests (60 min)

1. Add `PerformanceTests` target to Package.swift
2. Write 4 test methods (compile, parse, resolve, emit)
3. Run tests, verify they pass
4. Record baseline numbers

### Step 3: Document Baseline (30 min)

1. Run tests 3 times, record medians
2. Write DOCS/PERFORMANCE.md
3. Include methodology and hardware specs

### Step 4: CI Integration (30 min)

1. Add CI job to `.github/workflows/`
2. Run performance tests on every PR
3. Store results as artifacts
4. Add regression check

---

## 7. Testing Strategy

### Unit Tests (N/A)

Not applicable — this task creates tests, not testable code.

---

### Performance Tests (P0)

**Location:** `Tests/PerformanceTests/CompilerPerformanceTests.swift`

**Coverage:**
- Full compilation (entry file → output)
- Parse time per file
- Resolution time per link
- Emission time

**Tools:** XCTest, XCTMeasure

---

### Integration Tests (P1, Deferred)

**Scope:** Verify CI job runs correctly

**Coverage:**
- CI job executes on PR
- Regression detection triggers on slowdown
- Artifacts stored correctly

**Deferral:** Manual verification after CI setup

---

## 8. Documentation Requirements

### DOCS/PERFORMANCE.md (P1)

**Content:**
- Benchmark corpus specification
- Baseline metrics table
- Measurement methodology
- Reproduction instructions
- Hardware/software specs
- Performance targets

**Audience:** Developers, CI maintainers

---

### Code Comments (P0)

**Scope:** Inline comments in CorpusGenerator and test files

**Guidelines:**
- Explain corpus generation parameters
- Document measurement methodology
- Clarify performance targets

---

## 9. Dependencies & Blockers

### Dependencies

| Dependency | Status | Notes |
|-----------|--------|-------|
| EE8 (EditorEngine API) | ✅ Done | Stable API for benchmarking |
| XCTest | ✅ Available | Built-in Swift testing framework |
| GitHub Actions | ✅ Available | CI infrastructure |
| Swift 6.1 | ✅ Available | Compiler and stdlib |

### Blocks

| Task | Priority | Reason |
|------|---------|--------|
| PERF-2 (File Caching) | P0 | Needs baseline to measure improvement |
| PERF-3 (Dependency Graph) | P0 | Needs baseline for validation |
| PERF-4 (Performance Validation) | P0 | Needs baseline for comparison |

---

## 10. Acceptance Checklist

### Implementation Complete

- [ ] Benchmark corpus generator implemented
- [ ] Corpus generates 50 files, 5000 lines
- [ ] Performance test suite created (4 test methods)
- [ ] All tests pass successfully
- [ ] Baseline measurements recorded

### Documentation Complete

- [ ] DOCS/PERFORMANCE.md written
- [ ] Baseline metrics documented
- [ ] Methodology explained
- [ ] Reproduction instructions provided

### CI Integration Complete

- [ ] CI job added to `.github/workflows/`
- [ ] Performance tests run on every PR
- [ ] Regression detection enabled
- [ ] Artifacts stored

### Quality Gates

- [ ] Corpus compiles without errors
- [ ] Tests complete in <60 seconds
- [ ] Measurements have <5% variance
- [ ] Code review approved

---

## 11. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-24 | Claude (AI) | Initial PRD for PERF-1 |

---

## Appendix A: Example Corpus Structure

```
MediumProject/
├── entry.hc
└── modules/
    ├── auth/
    │   ├── login.hc
    │   ├── logout.hc
    │   ├── session.hc
    │   └── tokens.hc
    ├── database/
    │   ├── connection.hc
    │   ├── queries.hc
    │   ├── schema.hc
    │   └── migrations.hc
    ├── api/
    │   ├── routes.hc
    │   ├── handlers.hc
    │   ├── middleware.hc
    │   └── validation.hc
    ... (7 more modules)
```

---

## Appendix B: Performance Targets

**Current State (Unknown):**
- Full compilation: ? ms
- Parse per file: ? ms
- Resolution per link: ? ms

**Phase 13 Goal:**
- Full compilation: <200ms (medium project)
- Incremental compile: <50ms (single file change)
- Parse per file: <2ms
- Resolution per link: <0.1ms

**Measurement Context:**
- Hardware: GitHub Actions macOS runner
- Swift: 6.1
- Build: Release mode

---

**End of PRD**

---
**Archived:** 2025-12-24

# Hyperprompt Compiler Performance

**Document Version:** 1.0.0
**Last Updated:** 2025-12-25
**Status:** PERF-4 Validation Complete

---

## Overview

This document describes the Hyperprompt compiler performance characteristics, benchmark methodology, and baseline measurements. Performance tests are located in `Tests/PerformanceTests/`.

---

## Benchmark Corpus

### Specification

The benchmark corpus represents a "medium-sized" Hyperprompt project:

| Metric | Value |
|--------|-------|
| **Files** | 50 |
| **Total Lines** | ~6,500 |
| **File References (Links)** | ~250 |
| **Module Structure** | 10 modules (auth, database, api, cache, queue, storage, config, logging, metrics, workers) |
| **Files per Module** | 4-5 |
| **Average Lines per File** | ~130 |
| **Average Links per File** | ~5 |

### Directory Structure

```
MediumProject/
├── entry.hc                    # Entry point (references all modules)
└── modules/
    ├── auth/                   # 5 files
    │   ├── index.hc
    │   ├── core.hc
    │   ├── utils.hc
    │   ├── types.hc
    │   └── impl.hc
    ├── database/               # 4 files
    │   ├── index.hc
    │   ├── core.hc
    │   ├── utils.hc
    │   └── types.hc
    ├── api/                    # 5 files
    ├── cache/                  # 4 files
    ├── queue/                  # 5 files
    ├── storage/                # 4 files
    ├── config/                 # 5 files
    ├── logging/                # 4 files
    ├── metrics/                # 5 files
    └── workers/                # 4 files
```

### Generation

The corpus is automatically generated using `Tools/BenchmarkGenerator/`:

```bash
cd Tools/BenchmarkGenerator
swift run
```

**Output:** `Tests/PerformanceTests/Fixtures/MediumProject/`

**Characteristics:**
- **Deterministic:** Same output every run
- **Realistic:** Markdown headings, paragraphs, code examples, cross-references
- **Valid:** All files compile successfully with Hyperprompt compiler

---

## Baseline Metrics

**Hardware:** GitHub Actions Ubuntu 24.04 (macOS-latest for local)
**Swift Version:** 6.2-dev (LLVM fa1f889407fc8ca, Swift 687e09da65c8813)
**Build Configuration:** Debug (performance tests), Release (production benchmarks)
**Date:** 2025-12-24

### PERF-4 Validation Results (Local macOS arm64)

**Hardware:** Apple Silicon (arm64), macOS 14.x
**Swift Version:** 6.2.1 (swiftlang-6.2.1.4.8 clang-1700.4.4.1)
**Date:** 2025-12-25

| Metric | Debug | Release | Target | Status |
|--------|-------|---------|--------|--------|
| **Full compile (avg)** | 93 ms | 76 ms | <200 ms | ✅ |
| **Stress test (avg)** | 89.77 ms | 73.41 ms | <200 ms | ✅ |
| **Stress test (median)** | 89.67 ms | 73.32 ms | <200 ms | ✅ |

**Notes:**
- Stress test uses `comprehensive_test.hc` corpus (50 files). A separate 120-file fixture is not available yet.
- Profiling was not required because targets were met; use Instruments if regressions appear.

### Full Compilation

| Metric | Baseline | Target | Status |
|--------|----------|--------|--------|
| **Time (median)** | TBD | <200ms | ⏳ Pending |
| **Throughput** | TBD | - | ⏳ Pending |
| **Memory** | TBD | <100MB | ⏳ Pending |

**Test:** `testFullCompilationPerformance()`

### Parse Performance

| Metric | Baseline | Target | Status |
|--------|----------|--------|--------|
| **Time per File** | TBD | <2ms | ⏳ Pending |
| **Throughput** | TBD | >500 files/sec | ⏳ Pending |

**Test:** `testParsePerformance()`

### Resolution Performance

| Metric | Baseline | Target | Status |
|--------|----------|--------|--------|
| **Time per Link** | TBD | <0.1ms | ⏳ Pending |
| **Throughput** | TBD | >10,000 links/sec | ⏳ Pending |

**Test:** `testResolutionPerformance()`

### Emission Performance

| Metric | Baseline | Target | Status |
|--------|----------|--------|--------|
| **Time** | TBD | <10ms | ⏳ Pending |
| **Output Size** | ~8,000 lines | - | ⏳ Pending |

**Test:** `testEmissionPerformance()`

---

## Methodology

### Running Benchmarks

**Local (Debug Mode):**
```bash
swift test --filter PerformanceTests
```

**Local (Release Mode - Accurate):**
```bash
swift test -c release --filter PerformanceTests
```

**CI (GitHub Actions):**
```yaml
- name: Run Performance Tests
  run: swift test --filter PerformanceTests
```

### Measurement Approach

1. **XCTest `measure` Blocks:**
   - Each test uses `measure { }` to record execution time
   - XCTest runs 10 iterations by default
   - Reports: Average, median, std deviation

2. **Verification:**
   - Each benchmark verifies correctness (compilation succeeds, output valid)
   - Performance-only measurements don't catch regressions in correctness

3. **Stability:**
   - Run 10 iterations per test
   - Report median (more stable than average)
   - Detect regressions >20% from baseline

### Corpus Characteristics

- **Files:** 50 (entry + 49 module files)
- **Lines:** ~130 per file (range: 50-200)
- **Links:** ~5 per file (total ~250)
- **Content:**
  - Markdown headings (H1-H6)
  - Text paragraphs (realistic content)
  - Code examples (Swift snippets)
  - File references (inter-module links)

---

## Performance Targets

### Phase 13 Goal (Current)

**Medium Project (<200ms):**
- 50 files, 5000-7000 lines
- Full compilation: <200ms
- Enables live preview in VS Code extension

**Large Project (<1s):**
- 120 files, 12,000 lines
- Full compilation: <1 second

### Phase 13 Incremental Compilation (Future)

**Single File Change (<50ms):**
- Incremental recompilation
- Only re-process changed file + dependents

**Dependencies:**
- File caching (PERF-2)
- Dependency graph (PERF-3)

---

## CI Integration

### Performance Regression Detection

**Workflow:** `.github/workflows/performance.yml` (Pending - PERF-1)

**Triggers:**
- Every PR
- Every push to main

**Process:**
1. Run performance tests
2. Compare with baseline (stored in PERFORMANCE.md or artifact)
3. Fail if >20% slower

**Artifacts:**
- Performance results (JSON)
- Comparison report (Markdown)

---

## Known Limitations

1. **Debug Mode:** Performance tests run in debug mode by default (slower)
   - For accurate results, use `-c release`
2. **Synthetic Corpus:** Not representative of real-world projects
   - Uniform file sizes, predictable link patterns
3. **Single-threaded:** No parallel compilation yet
4. **No Caching:** Full recompilation every time (until PERF-2)

---

## Future Optimizations

### Phase 13 Roadmap

1. **PERF-2:** File Caching
   - Cache parsed ASTs with checksums
   - 80% reduction in parse time on second compile

2. **PERF-3:** Incremental Compilation
   - Dependency graph tracking
   - Recompile only dirty files + dependents

3. **PERF-4:** Performance Validation
   - Verify <200ms target met
   - Profile hot paths
   - Memory optimization

### Potential Future Work

- Parallel parsing (multi-threaded)
- Lazy resolution (resolve only used references)
- AST caching across compiler invocations
- Streaming emission (reduce memory)

---

## Reproduction Instructions

### Generate Corpus

```bash
cd Tools/BenchmarkGenerator
swift run
# Output: Tests/PerformanceTests/Fixtures/MediumProject/
```

### Run Performance Tests

```bash
# Quick (debug mode)
swift test --filter PerformanceTests

# Accurate (release mode)
swift test -c release --filter PerformanceTests

# Specific test
swift test --filter testFullCompilationPerformance
```

### Analyze Results

```bash
# Verbose output (shows timing)
swift test -v --filter PerformanceTests 2>&1 | grep "📊"

# Extract median times
swift test --filter PerformanceTests 2>&1 | grep "measured"
```

---

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-24 | Claude | Initial performance baseline (PERF-1) |

---

## References

- **PRD:** `DOCS/INPROGRESS/PERF-1_Performance_Baseline_And_Benchmarks.md`
- **Tests:** `Tests/PerformanceTests/CompilerPerformanceTests.swift`
- **Corpus Generator:** `Tools/BenchmarkGenerator/`
- **Workplan:** `DOCS/Workplan.md` (Phase 13)

---

**Note:** Baseline metrics will be populated after first test run. Run `swift test --filter PerformanceTests` and update this document with results.

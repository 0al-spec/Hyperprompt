# PRD — D4: Statistics Reporter

**Task ID:** D4 — Statistics Reporter  
**Priority:** P2  
**Phase:** Phase 6 — CLI & Integration  
**Effort Estimate:** 3 hours  
**Dependencies:** D1 (Compiler Driver)  
**Status:** Selected — INPROGRESS

## 1. Objective

Implement a statistics collection and reporting capability so the `--stats` flag and verbose mode emit accurate compilation metrics. The feature must capture per-run totals (files, bytes, depth, duration) without affecting determinism or performance guarantees.

## 2. Scope

- **In Scope:**
  - Instrumentation to collect compilation metrics during a single run.
  - Formatting and emission of metrics via CLI (`--stats`) and verbose logging.
  - Tests that validate metrics correctness across representative scenarios.
- **Out of Scope:**
  - Persistent or historical metrics storage.
  - Telemetry/remote reporting.
  - Performance optimizations beyond adding lightweight counters.

## 3. Success Criteria

- Metrics reported when `--stats` is enabled (and optionally when verbose logging is on) without requiring code changes elsewhere.
- Counts and totals match actual compilation activity for mixed `.hc` and embedded `.md` files.
- Maximum depth and elapsed time reflect real traversal and end-to-end execution.
- Feature does not change compilation output or determinism.

## 4. Constraints & Assumptions

- Must not introduce nondeterminism (no timing in output unless explicitly gated by `--stats`).
- Execution overhead should be negligible (<1% runtime impact on 120-file corpus baseline of 206ms).
- Runs within existing Swift toolchain and project structure; no new external dependencies.
- Works for both strict and lenient modes without additional flags.

## 5. Functional Requirements

1. **Metrics Captured (per run):**
   - Total Hypercode files processed.
   - Total Markdown files embedded.
   - Total input bytes (sum of source + embedded content read).
   - Total output bytes (emitted Markdown + manifest if applicable).
   - Maximum depth encountered while resolving/embedding.
   - Elapsed wall-clock time (ms) for compilation pipeline.
2. **Interfaces:**
   - `StatsCollector` API to record increments for files, bytes, and depth updates.
   - `StatsReporter` API to format metrics into human-readable output.
   - CLI integration: `--stats` flag triggers final metrics print; verbose mode may print incremental checkpoints if already supported.
3. **Behavior:**
   - Metrics default to disabled unless `--stats` is set; when disabled, collector is a no-op or lightweight stub.
   - Depth tracking updates whenever entering deeper nesting; ensures maximum depth recorded.
   - Timing starts before compilation begins and stops after manifest/output generation completes.

## 6. Non-Functional Requirements

- **Performance:** <1% overhead vs. baseline when stats enabled; effectively zero overhead when disabled.
- **Determinism:** Stats output must not alter compilation outputs (manifests, Markdown). Ordering of metrics is fixed and stable.
- **Reliability:** No panics on zero-file or empty-input runs; handles large byte totals without overflow (use 64-bit counters).
- **Observability:** Metrics formatting clearly labels units (files, bytes, ms, depth).

## 7. Implementation Plan (Phased TODOs)

### Phase 1 — Design & Data Model (High, 0.5h)

- Define `StatsCollector` structure with 64-bit counters for files, bytes (input/output), maximum depth, and elapsed time tracking (start/stop timestamps).
- Specify immutable `CompilationStats` value returned at completion.
- Decide on no-op behavior when stats are disabled (e.g., `StatsCollector.disabled`).

### Phase 2 — Instrumentation Hooks (High, 1h)

- Integrate collector into `CompilerDriver` (depends on D1) to start timing before pipeline begins and stop after emit/manifest finalize.
- Add hooks in parsing/resolution to increment Hypercode file count and track nesting depth updates.
- Add hooks in emitter/manifest generation to accumulate embedded Markdown file count and byte totals for inputs/outputs.
- Ensure hooks are conditional on stats being enabled to keep overhead minimal.

### Phase 3 — Reporting (Medium, 0.5h)

- Implement `StatsReporter` to format metrics in a deterministic order with clear labels and units.
- Wire CLI `--stats` flag to emit final metrics after successful compilation; align with verbose output conventions if applicable.
- Provide a stable string format suitable for tests (no locale-dependent formatting).

### Phase 4 — Testing & Verification (High, 1h)

- Unit tests for `StatsCollector` and `CompilationStats` to validate increments, depth calculation, and timing boundaries (mockable clock if available; otherwise tolerance-based check).
- Integration tests executing compilation with `--stats` on representative inputs:
  - Single `.hc` file with no embeds (baseline counts).
  - Mixed corpus with embedded Markdown to verify file/byte counts and depth.
  - Large corpus smoke test to ensure overhead remains small (can assert execution completes under a generous threshold).
- Verify stats-disabled path remains no-op and does not alter existing outputs.

## 8. Risks & Mitigations

- **Risk:** Timing variability makes tests flaky.  
  **Mitigation:** Use tolerance windows or mockable clock; avoid asserting exact milliseconds unless deterministic clock available.
- **Risk:** Stats hooks accidentally mutate output order or content.  
  **Mitigation:** Keep stats side effects isolated; ensure existing outputs are byte-identical when stats disabled.
- **Risk:** Performance regression with large inputs.  
  **Mitigation:** Use constant-time counter increments; guard hooks when disabled; measure against baseline.

## 9. Deliverables

- `StatsCollector` and `CompilationStats` data structures with enable/disable semantics.
- `StatsReporter` formatting utility with deterministic output order.
- CLI integration for `--stats` flag (and verbose alignment if applicable).
- Automated tests covering collector logic, reporting, and integration runs.

## 10. Acceptance Criteria

- All functional requirements met with automated tests demonstrating metric accuracy for single-file, embedded-file, and large-corpus scenarios.
- Stats output is deterministic, labeled with units, and produced only when `--stats` is requested.
- No changes to generated Markdown or manifests when stats are disabled; outputs remain byte-identical to pre-feature baselines.
- Overhead remains under 1% relative to the 206ms 120-file corpus baseline when stats are enabled.

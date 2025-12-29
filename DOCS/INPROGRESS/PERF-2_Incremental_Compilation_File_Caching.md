# PRD: PERF-2 — Incremental Compilation — File Caching

## 1. Scope & Intent

### Objective
Implement a file-level parse cache for the EditorEngine incremental compilation pipeline so unchanged files are not re-parsed, while ensuring correct invalidation and bounded memory usage.

### Deliverables
- A `ParsedFileCache` component that maps file paths to `(checksum, ParsedFile)` entries.
- Checksum computation for input files to detect changes.
- Cache hit/miss logic integrated into parsing flow to skip unchanged files.
- Correct invalidation when files change or dependencies require reparse.
- Cache eviction policy (LRU, max 1000 entries) to limit memory use.
- Unit tests covering hit/miss, invalidation, and eviction behavior.
- Updated performance baseline evidence showing >80% parse time reduction on second compile.

### Success Criteria
- Second compile on an unchanged project reduces parse time by >80% compared to baseline.
- Incremental compile output remains identical to full compile output.
- Cache does not grow beyond configured limits and evicts least recently used entries.

### Constraints & Dependencies
- **Dependencies:** PERF-1 baseline suite and fixtures must exist and be runnable.
- **Constraints:** Must preserve deterministic output and existing parsing semantics.
- **Assumptions:** File contents are available on disk; checksum computation is deterministic and stable across runs.

---

## 2. Functional Requirements

1. **ParsedFileCache storage**
   - Store entries keyed by absolute file path.
   - Each entry stores checksum and `ParsedFile`.

2. **Checksum computation**
   - Compute a stable checksum for file contents (e.g., SHA256 or fast hash).
   - Avoid caching when checksum computation fails (return parse error instead).

3. **Cache hit/miss logic**
   - On parse request, compute checksum and check cache.
   - If checksum matches, return cached `ParsedFile` without parsing.
   - If checksum mismatches or cache miss, parse file and update cache.

4. **Invalidation**
   - When a file changes, invalidate its cache entry and dependents if needed.
   - Ensure references to invalidated entries cannot be reused.

5. **Eviction (LRU, max 1000)**
   - Maintain access order to evict least recently used entries.
   - Evict when inserting and cache size exceeds max.

6. **Integration**
   - Ensure cache is used by the EditorEngine compilation pipeline (parsing stage).
   - Ensure cache logic does not affect non-incremental flows (full compile remains valid).

---

## 3. Non-Functional Requirements

- **Performance:** >80% parse time reduction on second compile with unchanged inputs.
- **Determinism:** Compiled output must be identical to full parse/compile.
- **Memory:** Cache size capped at 1000 entries; eviction policy enforced.
- **Reliability:** No crashes on cache misses or corrupted entries; fallback to re-parse.

---

## 4. Edge Cases & Failure Scenarios

- File deleted between checksum and parse: return a clear error and remove stale cache entry.
- File modified during parse: checksum mismatch should trigger re-parse on next run.
- Checksum computation error (I/O error): surface parse error; do not update cache.
- Symlinked paths: cache should key on resolved absolute path to avoid duplicates.
- Very large files: checksum computation should not cause excessive memory spikes.

---

## 5. Implementation Plan (TODO Breakdown)

### Phase A — Core Cache Implementation
1. **Define ParsedFileCache type**
   - **Priority:** High
   - **Effort:** 1h
   - **Tools:** Swift standard library
   - **Acceptance:** New type exists with get/put APIs and unit test scaffolding.

2. **Add checksum computation helper**
   - **Priority:** High
   - **Effort:** 0.5h
   - **Tools:** CryptoKit or existing hashing utility
   - **Acceptance:** Helper returns deterministic checksum for file contents.

3. **Integrate cache lookups in parsing flow**
   - **Priority:** High
   - **Effort:** 1h
   - **Tools:** EditorParser integration
   - **Acceptance:** Cache hit skips parsing and returns cached `ParsedFile`.

### Phase B — Invalidation & Eviction
4. **Implement invalidation logic**
   - **Priority:** High
   - **Effort:** 1h
   - **Tools:** Cache + dependency tracking (if available)
   - **Acceptance:** Stale entries invalidated on checksum mismatch.

5. **Add LRU eviction policy**
   - **Priority:** Medium
   - **Effort:** 1h
   - **Tools:** Ordered dictionary / linked list
   - **Acceptance:** Cache evicts least recently used entries at >1000 items.

### Phase C — Tests & Verification
6. **Unit tests for cache hit/miss**
   - **Priority:** High
   - **Effort:** 0.5h
   - **Tools:** XCTest
   - **Acceptance:** Tests verify cached parse re-use and miss updates.

7. **Unit tests for invalidation & eviction**
   - **Priority:** Medium
   - **Effort:** 1h
   - **Tools:** XCTest
   - **Acceptance:** Tests verify invalidation after content change and LRU eviction.

8. **Performance verification**
   - **Priority:** High
   - **Effort:** 0.5h
   - **Tools:** Existing PERF-1 benchmarks
   - **Acceptance:** Benchmark results show >80% parse time reduction.

---

## 6. Verification & Validation

- Run existing performance benchmarks and compare to baseline (PERF-1).
- Run unit tests for cache behavior and ensure deterministic outputs match full compile.
- Add or update performance documentation if benchmark results change materially.

---

## 7. Notes

- If dependency graph logic is required for invalidation, align with PERF-3’s implementation to avoid redundant tracking.
- Prefer using existing hashing utilities if present to avoid introducing new dependencies.

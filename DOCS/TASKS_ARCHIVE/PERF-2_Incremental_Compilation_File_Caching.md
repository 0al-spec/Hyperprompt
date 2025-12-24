# PRD: PERF-2 — Incremental Compilation — File Caching

## 1. Scope and Intent

### Objective
Implement a parsed file cache that avoids re-parsing unchanged files during compilation by using checksums and invalidation, with a bounded eviction policy and unit test coverage.

### Deliverables
- A `ParsedFileCache` implementation that stores `ParsedFile` instances keyed by file path and checksum.
- Integration of the cache into the EditorEngine compilation/parse flow so unchanged files reuse cached parse results.
- Invalidation logic for changed files and cascading invalidation for referenced dependencies.
- An eviction policy (LRU, max 1000 entries).
- Unit tests covering cache hit/miss, invalidation, and eviction scenarios.
- Documentation updates if needed (performance notes or internal comments).

### Success Criteria
- Second compile of an unchanged workspace skips parsing for unchanged files.
- Cache invalidation occurs when file contents change.
- Cascading invalidation ensures dependent files are re-parsed if referenced files change.
- Cache size is bounded and evicts the least-recently-used entries when over limit.
- All new tests pass.

### Constraints & Assumptions
- Swift toolchain and XCTest are available.
- Existing parsing and compilation APIs remain deterministic.
- Cache is memory-resident (no disk persistence required).
- Thread-safety requirements align with current EditorEngine usage (single-threaded or synchronized access).

### External Dependencies
- None beyond existing Swift standard library and project modules.

---

## 2. Structured TODO Plan

### Phase A — Design & Data Structures
1. **Locate parse/compile entrypoints**
   - Identify where `ParsedFile` is produced and reused (EditorEngine/EditorParser/EditorCompiler).
   - Confirm the call graph to insert cache usage without breaking existing behavior.

2. **Define cache interface**
   - Define `ParsedFileCache` API: `get(path:checksum:)`, `set(path:checksum:file:)`, `invalidate(path:)`, `invalidateAll()`.
   - Define LRU bookkeeping (e.g., linked list or ordered dictionary behavior).

### Phase B — Implementation
3. **Checksum computation**
   - Implement a checksum function for file contents (SHA256 or fast hash acceptable).
   - Ensure consistent hashing for identical content across runs.

4. **Cache integration**
   - On parse request: compute checksum → return cached `ParsedFile` when checksum matches.
   - On mismatch: parse, store in cache, and update LRU state.

5. **Invalidation logic**
   - Invalidate cache entries on file change (checksum mismatch).
   - Implement cascading invalidation for dependent files (from dependency graph or referenced files list).

6. **Eviction policy**
   - Enforce max size (1000 entries).
   - Evict least-recently-used entries when adding beyond limit.

### Phase C — Testing
7. **Unit tests**
   - Cache hit with unchanged file.
   - Cache miss with changed checksum.
   - Cascading invalidation when a referenced file changes.
   - LRU eviction removes least-recently-used entries.
   - Cache respects max size.

### Phase D — Validation
8. **Performance sanity check**
   - Run existing benchmark or measure parse invocation count to verify skipped parsing on second compile.

---

## 3. Subtask Metadata

| ID | Task | Priority | Effort | Dependencies | Tools/Modules | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Locate parse/compile entrypoints | High | 0.5h | None | Sources/EditorEngine | Entry points identified and documented in notes/comments |
| A2 | Define cache interface | High | 0.5h | A1 | Sources/EditorEngine | `ParsedFileCache` API agreed and implemented |
| B1 | Implement checksum computation | High | 1h | A2 | Swift Crypto/Stdlib | Checksum stable and tested |
| B2 | Integrate cache into parse flow | High | 1.5h | B1 | EditorParser/EditorEngine | Unchanged files reuse cached parse results |
| B3 | Implement invalidation logic | High | 1h | B2 | EditorEngine | Invalidations on file change and dependency change |
| B4 | Add LRU eviction | Medium | 0.5h | B2 | ParsedFileCache | Eviction enforced at size limit |
| C1 | Write unit tests | High | 1h | B2-B4 | Tests | All cache behaviors covered |
| D1 | Performance sanity check | Medium | 0.5h | C1 | Tests/Benchmarks | Second compile shows reduced parsing |

---

## 4. Feature Description & Rationale

Introducing a parsed file cache reduces redundant parsing, which is a primary cost in compilation. By caching `ParsedFile` outputs and reusing them when file contents have not changed, the compiler can significantly reduce time spent on repeated compiles, enabling the <200ms performance target for medium projects.

---

## 5. Functional Requirements

1. **Cache Retrieval**: When a file parse is requested, if the checksum matches the cached entry, return the cached `ParsedFile` without parsing.
2. **Cache Population**: When a file is parsed due to cache miss, store it with checksum and update LRU order.
3. **Invalidation**: When file contents change, the cache entry is invalidated. Dependent files referencing the changed file are also invalidated.
4. **Eviction**: Cache evicts the least-recently-used entries when exceeding max capacity (1000 entries).
5. **Compatibility**: Existing API behavior and outputs remain identical to pre-cache compilation.

---

## 6. Non-Functional Requirements

- **Performance**: Second compile should reduce parse time by >80% for unchanged files.
- **Determinism**: Cache usage must not alter the compilation output.
- **Memory Bound**: Cache should never exceed the configured maximum entries.
- **Maintainability**: Cache code should be isolated and testable.

---

## 7. Edge Cases & Failure Scenarios

- File deletion: cache entry removed or ignored gracefully.
- Rapid file changes: repeated checksum mismatches must not corrupt cache.
- Dependency cycles: cascading invalidation must not loop indefinitely.
- Partial parse failures: cache should not store failed parse results.
- Large projects: eviction should prevent unbounded growth.

---

## 8. Verification Plan

- Run unit tests for cache hit/miss, invalidation, and eviction.
- Compare compile outputs before and after cache integration for identical results.
- Measure parse invocation count or timing across two successive compiles.

---

## 9. Notes

- If a dependency graph exists (from PERF-3), use its data structures to determine cascading invalidation. If not available yet, derive dependencies from current parse results (e.g., referenced files list).
- Keep cache interface internal to EditorEngine unless future requirements need exposure.

---
**Archived:** 2025-12-24

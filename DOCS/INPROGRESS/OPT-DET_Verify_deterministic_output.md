# OPT-DET — Verify deterministic output (repeated compilations identical)

**Task ID:** OPT-DET  
**Priority:** P0  
**Phase:** Phase 9 — Optimization & Finalization  
**Effort:** 3 hours  
**Status:** ✅ Completed on 2025-12-12
**Dependencies:** E2 (Cross-Platform Testing)  
**Related Docs:** DOCS/Workplan.md §Optimization & Release, DOCS/RESOLUTIONS/RES_005_Determinism_Requirements.md

---

## 1. Objective
Ensure repeated compilations of identical inputs produce byte-for-byte identical outputs across supported platforms after cross-platform testing (E2). Determinism covers emitted Markdown, manifest JSON, binaries (where applicable), and any auxiliary artifacts.

---

## 2. Hierarchical Task Breakdown

### Phase 1: Preparation
- Confirm E2 artifacts and findings are available for reference.
- Identify canonical input corpus for determinism checks (reuse E2 samples and regression fixtures).
- Enumerate outputs to compare: emitted Markdown, manifest JSON, CLI binary (if built), logs.

### Phase 2: Determinism Validation
- Build and test the compiler to establish a clean baseline.
- Run two end-to-end compilation passes against the corpus without cleaning intermediates; capture SHA256 for all outputs.
- Repeat compilation with a clean build directory to detect stateful influences.
- Compare hashes across runs; investigate any divergence (timestamps, ordering, randomness, filesystem ordering).

### Phase 3: Stabilization & Documentation
- Patch any non-deterministic behaviors discovered (e.g., timestamp sources, non-sorted iteration, temp file naming) following RES_005 guidance.
- Add regression tests or scripts to enforce determinism for future builds.
- Document findings and resolution steps; record evidence of matching hashes.

---

## 3. Acceptance Criteria
- ✅ Two consecutive compilations with identical inputs and environment produce byte-for-byte identical outputs (all artifacts).  
- ✅ Clean rebuild followed by recompilation still yields identical outputs to previous runs.  
- ✅ Any non-determinism sources identified during testing are remediated or documented with rationale.  
- ✅ Regression guard added (test or script) to prevent recurrence.  
- ✅ Results summarized in task notes with hash evidence.

---

## 4. Assumptions & Constraints
- Cross-platform findings from E2 are available; focus here is repeatability within a given platform and toolchain version.
- Build environment uses reproducible settings (stable Swift toolchain, deterministic filesystem ordering where possible).
- No network access during compilation to avoid external variability.

---

## 5. Quality Checklist
- [x] Swift build succeeds.
- [x] Swift test suite passes.
- [x] Determinism checks executed twice without mutation of inputs between runs.
- [x] Hash comparisons documented.
- [x] Added regression guard covers discovered risk areas.

---

## 6. Validation Commands
Run in repository root unless noted.

```bash
# Build & test baseline
swift build
swift test

# Example determinism probe (adjust corpus path as needed)
OUTPUT_DIR=.build/determinism-run1
./.build/debug/hyperprompt compile Examples/Corpus --output $OUTPUT_DIR
find $OUTPUT_DIR -type f -print0 | sort -z | xargs -0 shasum -a 256 > run1.sha

OUTPUT_DIR2=.build/determinism-run2
./.build/debug/hyperprompt compile Examples/Corpus --output $OUTPUT_DIR2
find $OUTPUT_DIR2 -type f -print0 | sort -z | xargs -0 shasum -a 256 > run2.sha

diff -u run1.sha run2.sha
```

If any differences appear, capture artifacts and investigate sources (timestamps, ordering, randomness). Re-run after fixes to confirm stability.

---

## 7. Risk Log
- Hidden timestamps or UUIDs in generated artifacts.  
- Non-deterministic collection iteration or file ordering.  
- Platform-specific newline handling despite RES_005 requirements.  
- Build directory reuse introducing stale artifacts.

---

## 8. Deliverables
- Updated code/tests/scripts ensuring deterministic output.
- Validation evidence (hash logs) recorded in task notes or summaries.
- Commit implementing fixes and documentation, referencing this task ID (OPT-DET).

---

## 9. Validation Evidence (2025-12-12)

- Added deterministic timestamp resolution with environment overrides and file modification fallback in `DeterministicTimestampProvider`.
- Verified reproducible builds with fixed epoch:
  - Command set: `HYPERPROMPT_BUILD_TIMESTAMP=1700000000` with `.build/debug/hyperprompt` on `Tests/IntegrationTests/Fixtures/Valid/V01.hc`.
  - Hash comparisons:
    - `fd3ba1c5ee1a3b668246b5bcda864533c220f47938b6f022cf71150884be0150  manifest.json`
    - `92669ca9e003b6f3ae15b3d15b08d23fe24b0dc52ba06adb2c7bc92f1b92d323  out.md`
  - `diff -u run1.sha run2.sha` → no differences (paths only).

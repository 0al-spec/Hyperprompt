# OPT-DET — Verify deterministic output (repeated compilations identical)

**Version:** 1.0.0
**Date:** 2025-12-12
**Status:** Draft
**Priority:** P0 (Critical)
**Effort:** 3 hours
**Phase:** Phase 9 — Optimization & Finalization
**Dependencies:** E2 (post-integration test coverage complete)

---

## 1. Executive Summary

Ensure the Hyperprompt compiler produces byte-for-byte identical artifacts across repeated runs on the same platform and consistent outputs across supported platforms once dependency E2 is satisfied. The goal is to eliminate nondeterminism from timestamps, file ordering, random seeds, environment-dependent paths, and concurrency scheduling so that release builds are reproducible and verifiable before release preparation.

**Deliverables:**
1. Deterministic build checklist and configuration applied to the build pipeline.
2. Automated determinism verification script/report demonstrating identical outputs across at least two repeated runs per platform.
3. Documented root-cause fixes for all nondeterministic sources found, with code/config changes recorded or referenced.

---

## 2. Functional Requirements

- Builds of the same source and dependency set must produce identical binary/text artifacts (hash matches) when executed repeatedly on the same platform.
- Build outputs must be stable across supported platforms after dependency E2 completion, with any platform-specific differences documented and justified.
- The build process must include a reproducibility mode that normalizes timestamps, locale, and environment-sensitive inputs.
- Any randomness used during compilation must be explicitly seeded with a stable value or removed.
- File system traversal and linking steps must use deterministic ordering.
- Artifacts must include a machine-readable manifest enumerating outputs and hashes for verification.

---

## 3. Non-Functional Requirements

- **Performance:** Determinism fixes must not regress build time by more than 5% compared to the baseline E2 build.
- **Security/Compliance:** Deterministic mode must avoid embedding absolute local paths or user identifiers in artifacts.
- **Reliability:** Verification scripts must fail-fast with explicit diagnostics when hash mismatches occur.
- **Maintainability:** All configuration toggles for determinism must be documented and covered by regression tests.

---

## 4. Constraints & Assumptions

- Dependency **E2** (cross-platform integration tests) is available to validate outputs across OS targets.
- Build tooling versions are locked (Swift toolchain, package manager, third-party dependencies) as per project manifest.
- Access to stable system clocks is assumed; if not, normalized timestamps must be injected.
- No network-dependent build steps are allowed in deterministic mode.

---

## 5. TODO Plan (Execution Breakdown)

| ID | Subtask | Priority | Effort | Dependencies | Owner | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| T1 | Enumerate current build artifacts and capture baseline hashes for two consecutive runs on reference platform. | High | 0.5h | E2 | Release | Hashes from run A and B are identical or all discrepancies are logged with file paths. |
| T2 | Identify nondeterministic sources (timestamps, random seeds, path embeddings, file order, concurrency) using diff of run outputs. | High | 0.5h | T1 | Release | List of nondeterminism sources with reproduction notes and impact assessment. |
| T3 | Implement deterministic ordering for file discovery/linking and normalize metadata timestamps to fixed value (e.g., `SOURCE_DATE_EPOCH`). | High | 1h | T2 | Compiler | Repeated runs show stable ordering; artifact metadata timestamps match configured epoch. |
| T4 | Enforce stable random seeds or remove randomness in code generation/emission paths; document configuration knob. | High | 0.5h | T2 | Compiler | No random-driven differences between runs; configuration documented. |
| T5 | Add reproducible build mode to build scripts/CLI that sets environment (locale, timezone UTC, umask, temp paths) and disables non-deterministic plugins. | Medium | 0.5h | T3, T4 | DevOps | CLI flag or config documented; environment normalized in build logs. |
| T6 | Create verification script to run two builds, compute hashes, and emit a manifest (JSON) of outputs and SHA-256 values; integrate into CI. | High | 0.5h | T3, T4, T5 | QA | Script fails on mismatches and uploads manifest/logs as artifacts. |
| T7 | Cross-platform validation after E2: run determinism verification on all supported platforms; document any irreducible differences with mitigations. | High | 0.5h | T6, E2 | QA | Reports for each platform with either zero diffs or documented exceptions with rationale. |
| T8 | Update release checklist to include determinism verification gate and remediation steps. | Medium | 0.5h | T6 | Release | Checklist updated; gate referenced in release preparation tasks. |

---

## 6. Verification & Acceptance Tests

- Determinism verification script produces identical manifests (hash and file count) across two consecutive runs on the same platform.
- CI job for deterministic mode passes without hash mismatches and surfaces readable logs for failures.
- Cross-platform runs (post-E2) either match byte-for-byte or include a documented exceptions list with justifications and remediation backlog items.
- Performance comparison shows <=5% build time regression relative to baseline E2 measurement.

---

## 7. Risks & Mitigations

- **Hidden nondeterminism in third-party tools** → Pin versions; enable deterministic flags; capture tool versions in manifest.
- **Platform-specific file metadata differences** → Normalize timestamps and permissions; strip platform-specific extended attributes in deterministic mode.
- **Concurrency-induced ordering differences** → Introduce stable sorting before emission; serialize critical sections that affect output ordering.
- **CI environment drift** → Use containerized builds with locked toolchain; record image digest in manifests.

---

## 8. Deliverable Artifacts

- `scripts/verify-determinism.sh` (or equivalent) that runs duplicate builds, compares hashes, and generates `artifacts-manifest.json`.
- Sample manifest and log outputs stored under `artifacts/determinism/` for audit.
- Documentation updates describing deterministic build mode, configuration flags, and troubleshooting steps appended to release checklist.

---

## 9. Go/No-Go Criteria

- **Go:** All determinism checks pass on reference platform; cross-platform differences (if any) are documented with mitigation; build time regression within threshold.
- **No-Go:** Any unresolved hash mismatches, undocumented platform differences, or regressions >5% remain open.

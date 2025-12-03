# CI Setup PRD (GitHub Actions, Linux)

## 1. Scope & Intent
- **Objective:** Design an actionable CI pipeline on GitHub Actions for the Hyperprompt repository, focused on Linux runners only.
- **Primary Deliverables:**
  - GitHub Actions workflow(s) covering checkout, dependency setup, static checks (if available), and test execution for Linux.
  - Documentation for required secrets, caching strategy, and artifact handling.
  - Approval criteria enabling automated verification (status checks) on pull requests and default branch.
- **Success Criteria:**
  - Linux workflow completes within targeted SLA and provides deterministic pass/fail signals.
  - Pipeline blocks merges on failing checks and exposes logs/artifacts for debugging.
  - Configuration remains self-contained in repository (no external services beyond GitHub Actions).
- **Constraints & Assumptions:**
  - Only Linux GitHub-hosted runners (e.g., `ubuntu-latest`) are in scope; Windows/macOS deferred.
  - No proprietary dependencies requiring paid licenses or self-hosted runners.
  - Repository currently lacks defined test suites; PRD mandates placeholders and extensible structure for future tasks.

## 2. Functional Requirements
1. **Triggers**
   - On pull requests targeting default branch **only when source code or GitHub Actions files change** (e.g., include `src/**/*`, `*.py`, `.github/workflows/**`).
   - On pushes to default branch with the same path filters (source code and GitHub Actions changes only).
   - Manual dispatch for release verification.
2. **Job Stages (Linux)**
   - **Prepare:** checkout, set up languages/toolchains (detected from repo or configurable), enable caching.
   - **Static Analysis:** optional linters/formatters; run only if defined scripts exist.
   - **Tests:** run unit/integration tests via repository scripts (fallback: no-op with notice).
   - **Artifacts:** upload test reports (e.g., `junit.xml`), coverage, and workflow logs on failure.
3. **Reporting & Gates**
   - Status checks required for merge (name to be confirmed in Workplan).
   - Clearly surfaced summaries (steps echo configuration, versions, cache hits/misses).
4. **Extensibility**
   - Workflow structured with reusable steps/matrices for adding other OS/toolchains later.
   - Inputs (node/python version, cache keys, script names) centralized via environment variables.

## 3. Non-Functional Requirements
- **Performance:** Baseline workflow completes ≤ 10 minutes on `ubuntu-latest` with cold cache; ≤ 5 minutes warm cache.
- **Reliability:** Retry strategy for flaky steps limited to network-bound actions (e.g., dependency install) with max 2 retries.
- **Security/Compliance:**
  - Use least-privilege permissions (read-only for contents, no default token escalation).
  - Secrets masked; fail pipeline on missing required secrets instead of skipping silently.
- **Maintainability:** Clear comments and step names; version-pinned actions where feasible (semantic tags).

## 4. User Interaction Flows
- **Developer PR Flow:**
  1. Developer opens PR → Linux workflow auto-runs.
  2. Failing steps block merge; logs/artifacts downloadable from workflow run.
  3. Reruns available via GitHub UI; manual dispatch for confirmation before release.
- **Maintainer Flow:**
  1. Maintainer updates default branch → workflow validates mainline.
  2. Maintainer checks summarized results and artifacts; addresses failures or reverts.

## 5. Edge Cases & Failure Scenarios
- Missing language runtime: workflow fails with actionable message and guidance to update matrix variables.
- Absent test script: step emits warning and marks job success while noting gap in summary; tracked as TODO.
- Dependency installation failure (network): step retries once before failing with captured logs.
- Cache corruption: detect via checksum mismatch and fall back to clean install.

## 6. Execution Metadata (per subtask)
| Subtask | Priority | Effort | Dependencies | Tools/Inputs | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- |
| Define workflow structure (triggers, jobs) | High | 1-2h | None | GitHub Actions YAML | Triggers configured; workflow syntax passes `act` or lint check |
| Configure Linux job env & toolchains | High | 1-2h | Workflow skeleton | setup actions (node/python/go as needed) | Correct versions installed; cache keys parameterized |
| Add static analysis stage (optional) | Medium | 1h | Toolchain setup | repo scripts | Step conditionally runs when scripts exist; fails on non-zero |
| Add test stage & artifacts | High | 1-2h | Toolchain setup | test runner, `actions/upload-artifact` | Tests executed; artifacts uploaded on success/failure |
| Permissions & security hardening | High | 0.5h | Workflow defined | permissions block | Permissions minimized; secrets not required for baseline |
| Documentation in repo | High | 0.5h | Workflow defined | Markdown | Instructions added to DOCS/CI |

## 7. Dependencies & Risks
- **Dependencies:** Knowledge of project language/toolchain (to be discovered); GitHub Actions availability.
- **Risks:** Lack of tests/linters may reduce utility; long dependency installs may breach SLA; future OS expansion may require refactor (mitigated by modular design).

## 8. Acceptance Criteria Summary
- GitHub Actions Linux workflow present under `.github/workflows/` with documented triggers and stages.
- Workflow runs on PRs and default branch pushes; manual dispatch enabled.
- Clear logs, artifacts, and caching with version-pinned actions.
- Documentation in `DOCS/CI` describing configuration, variables, and extension steps.
- Meets non-functional targets (time, permissions, retry policy) or documents deviations.

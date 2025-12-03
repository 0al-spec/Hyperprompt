# CI Setup Workplan (GitHub Actions, Linux)

## 1. Goal
Implement GitHub Actions CI for the Hyperprompt repository targeting Linux runners, aligned with PRD requirements.

## 2. Task Breakdown
| ID | Task | Priority | Effort | Dependencies | Owner | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| CI-01 | Audit repository to identify primary language, package manager, and existing scripts (`test`, `lint`) | High | 0.5h | None | Dev | Inventory documented; missing scripts noted | 
| CI-02 | Define workflow triggers (PR to default branch, push to default, manual dispatch) | High | 0.5h | CI-01 | Dev | `.github/workflows/ci.yml` contains required triggers | 
| CI-03 | Configure Linux job environment (runner, checkout, toolchain setup, caching) | High | 1h | CI-02 | Dev | Job installs toolchain versions; cache keys parameterized; workflow lint passes | 
| CI-04 | Add static analysis step conditioned on available scripts (e.g., `npm run lint`, `ruff check`, `flake8`, `pylint`, or `black --check`) | Medium | 1h | CI-03 | Dev | Step skips with message if script missing; fails on non-zero exit |
| CI-05 | Add test step with artifact upload (reports, coverage if available) | High | 1h | CI-03 | Dev | Tests run via repo script; artifacts uploaded on success/failure | 
| CI-06 | Implement retry wrappers for network-prone steps (dependency install) | Medium | 0.5h | CI-03 | Dev | Retries configured (max 2) with clear logging | 
| CI-07 | Set permissions block and secrets handling (least privilege; fail fast on missing secrets) | High | 0.5h | CI-02 | Dev | Permissions minimized; no implicit write scopes | 
| CI-08 | Document CI usage, variables, and extension guidance in `DOCS/CI/README.md` or existing doc | High | 0.5h | CI-02–CI-07 | Dev | Documentation explains workflow structure and customization | 
| CI-09 | Validate workflow locally with `act` (if available) or GitHub syntax check | Medium | 0.5h | CI-02–CI-07 | QA | Validation output archived; issues resolved | 
| CI-10 | Enable required status checks on default branch (naming aligned with workflow job) | High | 0.5h | CI-05 | Maintainer | Branch protection updated; documented | 

## 3. Phase Plan
1. **Discovery (CI-01)**: Determine languages and scripts; adjust toolchain setup accordingly.
2. **Workflow Skeleton (CI-02, CI-03, CI-07)**: Add triggers, permissions, checkout, caching, runtime setup.
3. **Quality Gates (CI-04, CI-05, CI-06)**: Integrate lint/test stages, retries, artifact handling.
4. **Validation & Docs (CI-08, CI-09, CI-10)**: Document usage; validate syntax; ensure status checks enforced.

## 4. Scheduling & Parallelization
- CI-01 must precede all configuration tasks.
- CI-02/CI-07 can proceed in parallel after CI-01.
- CI-04 and CI-05 depend on environment setup (CI-03) but can run concurrently afterward.
- CI-08 and CI-09 depend on workflow definition; CI-10 after job name finalized.

## 5. Risks & Mitigations
- **Unclear project language/scripts:** Mitigate via CI-01 audit; add conditional steps with informative skips.
- **Long install times:** Use caching and version pinning; consider dependency caching per lockfile hash.
- **Missing tests:** Provide placeholder step that warns but succeeds; add TODO for adding tests.
- **Flaky network:** Retry installs; fail with logs if retries exhausted.

## 6. Acceptance Checklist
- [ ] Linux workflow YAML committed under `.github/workflows/` with triggers, permissions, and stages.
- [ ] Toolchain setup and caching confirmed for detected language.
- [ ] Static analysis and test steps run or skip with clear messaging based on script availability.
- [ ] Artifacts uploaded for test outputs and failures.
- [ ] Documentation in `DOCS/CI` explains configuration, variables, and extension to other OSes/toolchains.
- [ ] Branch protection updated to require the Linux CI status check.

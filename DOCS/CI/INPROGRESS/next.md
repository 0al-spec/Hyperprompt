# Next Task: CI-02 — Define Workflow Triggers

**Priority:** High
**Phase:** Workflow Skeleton
**Effort:** 0.5 hours
**Dependencies:** CI-01 (Repository Audit) ✅ Completed
**Blocks:** CI-03 (Linux job environment), CI-04 (static analysis), CI-05 (test step), CI-06 (retry wrappers)
**Status:** 🔄 In Progress

---

## Description

Define and implement GitHub Actions workflow triggers for the Hyperprompt CI pipeline. This task creates the `.github/workflows/ci.yml` file with:
- Pull request triggers to default branch
- Push triggers to default branch
- Manual workflow dispatch capability
- Path filters for source code and GitHub Actions files

This is the foundation that enables all subsequent CI configuration tasks.

---

## Tasks Checklist

- [ ] Create `.github/workflows/` directory structure
  - [ ] Create `.github/workflows/ci.yml` file
  - [ ] Set workflow name and description

- [ ] Configure pull request triggers
  - [ ] Add `pull_request` trigger for default branch
  - [ ] Add path filters for `Sources/**/*.swift`
  - [ ] Add path filters for `Tests/**/*.swift`
  - [ ] Add path filters for `Package.swift` and `Package.resolved`
  - [ ] Add path filters for `.github/workflows/**`

- [ ] Configure push triggers
  - [ ] Add `push` trigger for default branch
  - [ ] Apply same path filters as PR triggers
  - [ ] Ensure consistency between push and PR filters

- [ ] Add manual dispatch capability
  - [ ] Add `workflow_dispatch` trigger
  - [ ] Document usage in workflow comments

- [ ] Validate trigger configuration
  - [ ] Verify YAML syntax is valid
  - [ ] Confirm path filters match repository structure
  - [ ] Document trigger behavior

---

## Acceptance Criteria

- [ ] `.github/workflows/ci.yml` exists and contains all required triggers
- [ ] Pull request trigger configured for default branch with path filters
- [ ] Push trigger configured for default branch with same path filters
- [ ] Manual dispatch (`workflow_dispatch`) enabled
- [ ] Path filters include:
  - `Sources/**/*.swift`
  - `Tests/**/*.swift`
  - `Package.swift`
  - `Package.resolved`
  - `.github/workflows/**`
- [ ] YAML syntax validates successfully
- [ ] Workflow triggers documented in comments

---

## Output

**Expected Deliverable:** `.github/workflows/ci.yml` (initial version with triggers only)

Workflow should include:
```yaml
name: CI

on:
  pull_request:
    branches: [main]  # or master, depending on default branch
    paths:
      - 'Sources/**/*.swift'
      - 'Tests/**/*.swift'
      - 'Package.swift'
      - 'Package.resolved'
      - '.github/workflows/**'

  push:
    branches: [main]
    paths:
      - 'Sources/**/*.swift'
      - 'Tests/**/*.swift'
      - 'Package.swift'
      - 'Package.resolved'
      - '.github/workflows/**'

  workflow_dispatch:

jobs:
  # Placeholder for CI-03
```

---

## Next Task After Completion

**CI-03: Configure Linux Job Environment [High Priority]**
- Dependencies: CI-02 (this task)
- Estimated: 1 hour
- Will configure runner, checkout, toolchain setup, and caching

**Alternative (can run in parallel after CI-02):**
**CI-07: Set Permissions Block [High Priority]**
- Dependencies: CI-02
- Estimated: 0.5 hours
- Will configure workflow permissions and secrets handling

---

## References

- **CI Workplan:** `/home/user/Hyperprompt/DOCS/CI/Workplan.md` (Task CI-02)
- **CI PRD:** `/home/user/Hyperprompt/DOCS/CI/PRD.md`
- **Audit Report:** `/home/user/Hyperprompt/DOCS/CI/audit-report.md`
- **GitHub Actions Docs:** https://docs.github.com/en/actions/using-workflows/triggering-a-workflow

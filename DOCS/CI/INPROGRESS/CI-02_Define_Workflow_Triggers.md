# CI-02 — Define Workflow Triggers

**Version:** 1.0.0
**Date:** 2025-12-04
**Status:** Ready for Implementation

---

## 1. Context

- **Phase:** Workflow Skeleton (Phase 2 of 4)
- **Priority:** High
- **Dependencies:** CI-01 (Repository Audit) — ✅ Completed
- **Effort:** 0.5 hours
- **Blocks:** CI-03, CI-04, CI-05, CI-06, CI-07

---

## 2. Objectives

Create the foundational GitHub Actions workflow file with properly configured triggers and path filters. This task establishes when and why the CI pipeline should run, forming the basis for all subsequent CI configuration.

**Primary Goals:**
1. Create `.github/workflows/ci.yml` with trigger configuration
2. Configure pull request triggers with path filters
3. Configure push triggers with path filters
4. Add manual dispatch capability for on-demand runs
5. Ensure triggers target the default branch only
6. Optimize CI runs by filtering for relevant file changes

**Expected Outcome:**
A minimal but complete workflow file that triggers appropriately for code changes, PR events, and manual dispatch, ready for CI-03 to add job configuration.

---

## 3. Implementation Plan

### 3.1 Phase 1: Directory Setup (2 minutes)

**Goal:** Create GitHub Actions directory structure

**Steps:**
1. **Create .github directory** (if not exists)
   ```bash
   mkdir -p .github/workflows
   ```

2. **Verify permissions**
   - Ensure directory is writable
   - No special permissions needed (standard file creation)

### 3.2 Phase 2: Workflow File Creation (10 minutes)

**Goal:** Create ci.yml with basic structure and metadata

**Steps:**
1. **Create workflow file**
   - Path: `.github/workflows/ci.yml`
   - Initial content: workflow name and description

2. **Add workflow metadata**
   ```yaml
   name: CI

   # CI workflow for Hyperprompt Swift compiler
   # Triggers on PR, push to main, and manual dispatch
   # Runs on Linux (ubuntu-latest) with Swift 6.0.3
   ```

3. **Document workflow purpose**
   - Add comments explaining trigger logic
   - Note path filter rationale
   - Reference audit report (CI-01)

### 3.3 Phase 3: Pull Request Triggers (8 minutes)

**Goal:** Configure PR triggers with path filters from audit

**Steps:**
1. **Add pull_request trigger**
   ```yaml
   on:
     pull_request:
       branches: [main]
   ```

2. **Determine default branch**
   - Check current branch name: `git branch --show-current`
   - Verify remote default: `git remote show origin | grep "HEAD branch"`
   - Use `main` or `master` as appropriate

3. **Add path filters**
   ```yaml
       paths:
         - 'Sources/**/*.swift'
         - 'Tests/**/*.swift'
         - 'Package.swift'
         - 'Package.resolved'
         - '.github/workflows/**'
   ```

4. **Document filter rationale**
   - Sources: Application code changes
   - Tests: Test code changes
   - Package.swift: Dependency/target configuration
   - Package.resolved: Dependency version locks
   - Workflows: CI configuration itself

### 3.4 Phase 4: Push Triggers (5 minutes)

**Goal:** Configure push triggers with identical filters

**Steps:**
1. **Add push trigger**
   ```yaml
     push:
       branches: [main]
   ```

2. **Apply same path filters**
   - Copy exact path list from pull_request
   - Maintain consistency between triggers
   - Prevents divergent behavior

3. **Rationale for push trigger**
   - Validates merged code on main branch
   - Detects integration issues post-merge
   - Required for status badge accuracy

### 3.5 Phase 5: Manual Dispatch (2 minutes)

**Goal:** Enable on-demand workflow runs

**Steps:**
1. **Add workflow_dispatch trigger**
   ```yaml
     workflow_dispatch:
   ```

2. **Usage documentation**
   - Add comment: "Allows manual workflow runs from Actions tab"
   - No inputs needed for CI-02 (may add in future)

3. **Purpose**
   - Testing CI changes without code push
   - Re-running failed builds
   - Validation during development

### 3.6 Phase 6: Placeholder Job (3 minutes)

**Goal:** Add minimal job structure for YAML validity

**Steps:**
1. **Add jobs section**
   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - name: Placeholder
           run: echo "Job configuration will be added in CI-03"
   ```

2. **Document placeholder**
   - Comment: "Full job configuration in CI-03"
   - Note: Runner, checkout, Swift setup will be added next
   - This ensures valid YAML for CI-02 completion

---

## 4. Acceptance Criteria

### 4.1 File Structure

- [ ] `.github/workflows/` directory exists
- [ ] `.github/workflows/ci.yml` file created
- [ ] File is valid YAML (no syntax errors)
- [ ] File is UTF-8 encoded with LF line endings

### 4.2 Trigger Configuration

- [ ] `pull_request` trigger configured
- [ ] `push` trigger configured
- [ ] `workflow_dispatch` trigger configured
- [ ] Default branch correctly identified (`main` or `master`)
- [ ] Both PR and push target same branch

### 4.3 Path Filters

- [ ] Path filter includes `Sources/**/*.swift`
- [ ] Path filter includes `Tests/**/*.swift`
- [ ] Path filter includes `Package.swift`
- [ ] Path filter includes `Package.resolved`
- [ ] Path filter includes `.github/workflows/**`
- [ ] Same filters applied to both PR and push triggers
- [ ] No documentation-only paths (e.g., `DOCS/**`, `*.md`) in filters

### 4.4 Documentation

- [ ] Workflow has descriptive name ("CI")
- [ ] Comments explain trigger purpose
- [ ] Path filter rationale documented
- [ ] Manual dispatch usage noted
- [ ] Reference to CI-03 for next steps

### 4.5 Validation

- [ ] YAML syntax validates (GitHub Actions tab or `actionlint`)
- [ ] No workflow errors appear in repository
- [ ] Placeholder job successfully runs (optional validation step)

---

## 5. GitHub Actions Specifics

### 5.1 Workflow Triggers (from Audit CI-01)

**Trigger Events:**
- **pull_request:** Run on PR creation and updates
- **push:** Run on direct commits to default branch
- **workflow_dispatch:** Manual runs from GitHub UI

**Branch Targeting:**
- Target: Default branch only (`main` or `master`)
- Rationale: Protect main branch quality, optimize CI usage
- Future: May expand to release branches

### 5.2 Path Filters (from Audit CI-01 §5.3)

**Included Paths:**
```yaml
paths:
  - 'Sources/**/*.swift'        # Application source code
  - 'Tests/**/*.swift'          # Test source code
  - 'Package.swift'             # SPM manifest
  - 'Package.resolved'          # Dependency lock file
  - '.github/workflows/**'      # CI configuration
```

**Optimization Benefits:**
- Skip CI for documentation-only changes
- Skip CI for README updates
- Skip CI for .gitignore changes
- Reduces unnecessary workflow runs by ~40-60%
- Faster feedback for relevant changes

**Excluded Paths (implicit):**
- `DOCS/**` — Documentation
- `*.md` — Markdown files (README, etc.)
- `.gitignore` — Git configuration
- Other non-code files

### 5.3 Runner Configuration (Placeholder)

**Runner:** `ubuntu-latest` (Ubuntu 24.04 as of Dec 2025)
**Note:** Full runner configuration will be added in CI-03

**Workflow File Template:**
```yaml
name: CI

on:
  pull_request:
    branches: [main]
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
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Placeholder
        run: echo "Job configuration will be added in CI-03"
```

---

## 6. Testing & Validation

### 6.1 Pre-Implementation Validation

**Check Default Branch:**
```bash
# Option 1: Current branch
git branch --show-current

# Option 2: Remote default
git remote show origin | grep "HEAD branch"

# Option 3: GitHub repository settings
# Navigate to: Settings → General → Default branch
```

**Expected:** `main` (or `master` for older repos)

### 6.2 Post-Implementation Validation

**Step 1: YAML Syntax Check**
```bash
# Option A: Using actionlint (if installed)
actionlint .github/workflows/ci.yml

# Option B: GitHub Actions tab
# Navigate to Actions tab → Workflows → Look for workflow errors
```

**Expected:** No syntax errors, workflow appears in Actions tab

**Step 2: Trigger Verification (Optional)**
```bash
# Create a test branch with Source change
git checkout -b test-ci-triggers
echo "// Test" >> Sources/Core/Placeholder.swift
git add .
git commit -m "Test: Verify CI triggers"
git push origin test-ci-triggers

# Open PR on GitHub → Verify workflow runs
# Expected: CI workflow triggers automatically
```

**Step 3: Manual Dispatch Test (Optional)**
```bash
# Navigate to: Actions → CI workflow → Run workflow
# Select branch: main
# Click "Run workflow"
# Expected: Workflow starts with placeholder output
```

**Step 4: Path Filter Validation (Optional)**
```bash
# Test: Documentation-only change should NOT trigger CI
git checkout -b test-docs-skip
echo "Test" >> README.md
git add README.md
git commit -m "Docs: Update README"
git push origin test-docs-skip

# Open PR → Expected: No CI workflow run (path filter working)
```

### 6.3 Rollback Test

**Verify rollback procedure:**
1. Create backup: `cp .github/workflows/ci.yml .github/workflows/ci.yml.bak`
2. Delete workflow: `rm .github/workflows/ci.yml`
3. Verify: GitHub Actions tab shows no CI workflow
4. Restore: `mv .github/workflows/ci.yml.bak .github/workflows/ci.yml`
5. Verify: Workflow reappears in Actions tab

---

## 7. Rollback Plan

### 7.1 Rollback Scenarios

**Scenario 1: Invalid YAML Syntax**

**Symptoms:**
- GitHub Actions tab shows workflow error
- Red X icon next to workflow file
- Error message: "Invalid workflow file"

**Rollback:**
```bash
# Remove invalid workflow
git checkout HEAD~1 -- .github/workflows/ci.yml
git commit -m "Rollback CI-02: Fix YAML syntax"
git push
```

**Prevention:** Validate YAML before commit using `actionlint`

---

**Scenario 2: Triggers Too Broad (Runs on Every File)**

**Symptoms:**
- CI runs on documentation changes
- CI runs on .gitignore updates
- Excessive workflow runs

**Rollback:**
```bash
# Fix: Add/correct path filters
# Edit .github/workflows/ci.yml to add paths: section
git commit -m "Fix CI-02: Add path filters"
git push
```

**Prevention:** Test with documentation-only PR before merging

---

**Scenario 3: Workflow Runs But Fails Immediately**

**Symptoms:**
- Workflow triggers correctly
- Placeholder job fails with error

**Rollback:**
```bash
# Quick fix: Update placeholder
# Edit ci.yml: change run: command to valid shell command
git commit -m "Fix CI-02: Update placeholder command"
git push
```

**Prevention:** Ensure placeholder uses valid shell syntax (`echo "..."`)

---

### 7.2 Recovery Steps

**If CI-02 must be reverted entirely:**

1. **Remove workflow file**
   ```bash
   git rm .github/workflows/ci.yml
   git commit -m "Revert CI-02: Remove workflow triggers"
   git push
   ```

2. **Clean up branches**
   - Close any test PRs created during validation
   - Delete test branches: `git push origin --delete test-ci-triggers`

3. **Update documentation**
   - Mark CI-02 as reverted in Workplan
   - Document reason for rollback in next.md
   - Update CI-01 summary if needed

4. **Re-plan if needed**
   - If trigger strategy was wrong, re-run PLAN with new approach
   - Consider alternative trigger configurations
   - Consult team on branch protection requirements

---

## 8. Deliverables Checklist

### 8.1 Primary Deliverable

- [ ] **File:** `.github/workflows/ci.yml`
- [ ] **Content:**
  - [ ] Workflow name: "CI"
  - [ ] pull_request trigger with branch and paths
  - [ ] push trigger with branch and paths
  - [ ] workflow_dispatch trigger
  - [ ] Placeholder job with ubuntu-latest runner
  - [ ] Comments documenting trigger logic

### 8.2 Secondary Deliverables

- [ ] Updated `DOCS/CI/INPROGRESS/next.md` (mark complete)
- [ ] Updated `DOCS/CI/Workplan.md` (mark CI-02 complete, remove INPROGRESS)
- [ ] Task summary: `DOCS/CI/INPROGRESS/CI-02-summary.md`
- [ ] Git commit with workflow file

### 8.3 Quality Gates

- [ ] YAML syntax validates (no errors in Actions tab)
- [ ] Workflow appears in GitHub Actions workflow list
- [ ] Path filters correctly exclude documentation changes
- [ ] All acceptance criteria met (23 items)
- [ ] No blockers for CI-03 identified

---

## 9. Dependencies & Blockers

### 9.1 Upstream Dependencies

- **CI-01 (Repository Audit)** — ✅ Completed
  - Provides: Path filter recommendations
  - Provides: Default branch information
  - Provides: Swift version and toolchain details

### 9.2 Downstream Dependencies

**Blocks:**
- **CI-03:** Configure Linux job environment (needs trigger foundation)
- **CI-04:** Add static analysis step (needs workflow structure)
- **CI-05:** Add test step (needs workflow structure)
- **CI-06:** Implement retry wrappers (needs workflow structure)
- **CI-07:** Set permissions block (can run parallel with CI-03)

### 9.3 Known Blockers

**None identified.** All required information available from CI-01.

**Potential Issues:**
- **Default branch ambiguity:** Mitigated by verification step (§6.1)
- **Path filter edge cases:** Mitigated by validation tests (§6.2)
- **YAML syntax errors:** Mitigated by actionlint validation

---

## 10. References

### 10.1 Project References

- **Audit Report:** `/home/user/Hyperprompt/DOCS/CI/audit-report.md` (§5.3 Triggers)
- **Repository Root:** `/home/user/Hyperprompt/`
- **Sources Directory:** `/home/user/Hyperprompt/Sources/`
- **Package Manifest:** `/home/user/Hyperprompt/Package.swift`

### 10.2 CI References

- **CI Workplan:** `/home/user/Hyperprompt/DOCS/CI/Workplan.md` (Task CI-02)
- **CI PRD:** `/home/user/Hyperprompt/DOCS/CI/PRD.md`
- **Next Task:** `/home/user/Hyperprompt/DOCS/CI/INPROGRESS/next.md`
- **CI-01 PRD:** `/home/user/Hyperprompt/DOCS/CI/INPROGRESS/CI-01_Repository_Audit.md`

### 10.3 External References

- **GitHub Actions Triggers:** https://docs.github.com/en/actions/using-workflows/triggering-a-workflow
- **GitHub Actions Events:** https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows
- **Path Filtering:** https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore
- **workflow_dispatch:** https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_dispatch
- **actionlint:** https://github.com/rhysd/actionlint

---

## 11. Next Task After Completion

**Task ID:** CI-03
**Task Name:** Configure Linux Job Environment
**Priority:** High
**Dependencies:** CI-02 (this task)
**Estimated:** 1 hour
**Description:** Configure the build job with runner, checkout action, Swift toolchain setup, and dependency caching.

**Alternative (Parallel Track):**
**Task ID:** CI-07
**Task Name:** Set Permissions Block
**Priority:** High
**Dependencies:** CI-02 (this task)
**Estimated:** 0.5 hours
**Description:** Configure least-privilege permissions and secrets handling for the workflow.

**Recommendation:** Proceed with CI-03 (critical path) before CI-07.

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-04 | Claude (via PLAN command) | Initial PRD generation from CI-02 task |

---

## 13. Notes for Implementation

### 13.1 Recommended Execution Order

1. Verify default branch name (git command)
2. Create .github/workflows/ directory
3. Create ci.yml with full trigger configuration
4. Validate YAML syntax (actionlint or GitHub)
5. Commit and push
6. Verify workflow appears in Actions tab
7. (Optional) Test with PR to verify path filters
8. Mark task complete in next.md and Workplan

### 13.2 Time Allocation

- Directory setup: 2 minutes
- Workflow creation: 10 minutes
- Pull request triggers: 8 minutes
- Push triggers: 5 minutes
- Manual dispatch: 2 minutes
- Placeholder job: 3 minutes
- **Total:** ~30 minutes (within 0.5 hour estimate)

### 13.3 Common Pitfalls to Avoid

- ❌ Don't use tabs in YAML (use 2 spaces for indentation)
- ❌ Don't forget to match branch name in both push and pull_request
- ❌ Don't add too many path filters (causes maintenance burden)
- ❌ Don't omit .github/workflows/** from paths (CI can't test itself)
- ❌ Don't add jobs configuration yet (belongs in CI-03)

### 13.4 Success Indicators

- ✅ Workflow file validates without errors
- ✅ Workflow appears in GitHub Actions tab
- ✅ Placeholder job runs successfully (if tested)
- ✅ Documentation-only PRs don't trigger CI (if tested)
- ✅ CI-03 can proceed immediately

---

**END OF PRD**

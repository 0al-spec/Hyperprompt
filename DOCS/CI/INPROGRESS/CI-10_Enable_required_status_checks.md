# CI-10 — Enable required status checks on default branch

**Task ID:** CI-10
**Task Name:** Enable required status checks on default branch
**Priority:** High
**Phase:** Validation & Docs
**Estimated Effort:** 0.5 hours
**Dependencies:** CI-05 (Add test step with artifact upload ✅)
**Status:** Selected for Implementation

---

## 1. Context

**Phase:** Validation & Docs (final phase of CI setup)
**Critical Path:** CI-01 → CI-02 → CI-03 → CI-05 → **CI-10**
**Workflow Job Name:** `build` (defined in `.github/workflows/ci.yml`)

---

## 2. Objectives

**Primary Goal:** Enable GitHub branch protection rule on the default branch (`main`) requiring the `build` CI job to pass before merging. This enforces automated quality gates and prevents untested code from being merged.

**Secondary Goals:**
- Document branch protection configuration for team
- Verify that CI job name (`build`) is discoverable in GitHub Actions settings
- Ensure least-privilege permissions are maintained (no additional permissions needed)

**Acceptance Metrics:**
- ✅ Branch protection rule created on default branch
- ✅ Status check `build` is required
- ✅ Status check is functional (PR merge blocked if CI fails)
- ✅ Documentation updated with configuration steps
- ✅ Team members can manage protection rules

---

## 3. Implementation Plan

### Phase 1: Verification (5 mins)

**Task 1.1: Verify CI Job Name**
- [ ] Check `.github/workflows/ci.yml` for job definition
  ```yaml
  jobs:
    build:  # ← This is the status check name
      runs-on: ubuntu-latest
  ```
- [ ] Confirm job name is `build` (used in status checks)
- [ ] Verify workflow file is committed and deployed

**Task 1.2: Verify Workflow Execution**
- [ ] Trigger a test PR or manual workflow dispatch
- [ ] Confirm workflow completes and reports status
- [ ] Note status check appears in PR as `build`

### Phase 2: Branch Protection Configuration (10 mins)

**Task 2.1: Enable Branch Protection**
1. **Navigate to Repository Settings:**
   - Go to GitHub repository main page
   - Click **Settings** tab
   - Left sidebar → **Branches**

2. **Add Branch Protection Rule:**
   - Click **Add rule** button
   - **Branch name pattern:** `main` (or `master` depending on default)

3. **Configure Protection Options:**
   - ✅ **Require status checks to pass before merging**
     - Search for: `build`
     - Select the `build` status check from CI workflow
   - ✅ **Require branches to be up to date before merging**
     - Ensures branch is rebased on latest main
   - Optional: **Require pull request reviews before merging**
     - Can be enabled if team process requires code review
   - Optional: **Include administrators**
     - If enabled, rules apply to repository admins

4. **Save Rule**
   - Click **Create** button
   - Verify rule appears in branch protection list

**Task 2.2: Verify Protection is Active**
- [ ] Go back to main branch settings
- [ ] Confirm rule for `main` is listed
- [ ] Rule details show:
  - Required status checks: `build`
  - Up-to-date branches required: ✓
  - Dismiss stale reviews: (if configured)

### Phase 3: Testing (10 mins)

**Task 3.1: Test Protection with Failing Workflow**
1. Create test PR on a feature branch:
   ```bash
   git checkout -b test/ci-blocking
   echo "invalid syntax" >> Sources/main.swift
   git add .
   git commit -m "Test: intentional syntax error"
   git push -u origin test/ci-blocking
   ```

2. Open PR and observe:
   - [ ] CI workflow (`build`) starts automatically
   - [ ] Workflow fails (due to syntax error)
   - [ ] PR shows red ❌ for `build` status check
   - [ ] **Merge button is DISABLED** (blocked by failed check)
   - [ ] Message appears: "All conversations resolved, but some checks haven't passed yet"

3. Clean up test:
   ```bash
   git checkout main
   git branch -D test/ci-blocking
   ```

**Task 3.2: Test Protection with Passing Workflow**
1. Create test PR with valid change:
   ```bash
   git checkout -b test/ci-passing
   echo "// valid comment" >> Sources/main.swift
   git add .
   git commit -m "Test: valid change"
   git push -u origin test/ci-passing
   ```

2. Open PR and observe:
   - [ ] CI workflow (`build`) starts automatically
   - [ ] Workflow passes (valid code)
   - [ ] PR shows green ✅ for `build` status check
   - [ ] **Merge button is ENABLED** (all checks passed)
   - [ ] Message appears: "All checks have passed"

3. Verify merge behavior:
   - [ ] Can merge PR without additional approvals (if code review not required)
   - [ ] Merge button shows merge options (squash, rebase, merge commit)

4. Clean up test:
   ```bash
   git branch -D test/ci-passing
   ```

---

## 4. Acceptance Criteria

✅ **MUST HAVE:**
1. Branch protection rule exists on default branch (`main` or `master`)
2. Status check `build` is marked as **Required**
3. **Require branches to be up to date before merging** is enabled
4. PR with failing CI cannot be merged (merge button disabled)
5. PR with passing CI can be merged (merge button enabled)
6. Rule is visible in repository Settings → Branches

✅ **SHOULD HAVE:**
- Test PRs created to verify blocking behavior
- Documentation updated with configuration instructions
- Screenshot or video of working branch protection (optional)

---

## 5. GitHub Actions Specifics

### Workflow Definition
- **Workflow File:** `.github/workflows/ci.yml`
- **Job Name:** `build`
- **Trigger:** PR to main, push to main, manual dispatch
- **Status Check Name:** `build` (automatically generated from job name)

### Permissions
- No additional permissions needed for branch protection
- CI workflow uses existing `contents: read` permission
- Branch protection configuration requires repository admin access

### Path Filters
- CI already has path filters (src/, tests/, workflow files)
- Branch protection applies to **all commits** to main regardless of path filters
- This is correct: even documentation-only changes should be validated

---

## 6. Testing & Validation

### Local Verification
```bash
# Check CI job name in workflow
grep -A 5 "^jobs:" .github/workflows/ci.yml

# Output should show:
# jobs:
#   build:  # ← This is the status check name
#     runs-on: ubuntu-latest
```

### GitHub UI Verification
1. **Check branch protection rule:**
   - Settings → Branches
   - Find rule for `main` branch
   - Confirm `build` status check is required

2. **Check PR status:**
   - Create PR to test branch
   - PR should show CI status (pending/running)
   - After CI completes, should show ✅ or ❌

3. **Test merge blocking:**
   - If CI fails: merge button disabled ❌
   - If CI passes: merge button enabled ✅

### Troubleshooting

**Problem:** Status check `build` not appearing in branch protection settings
- **Cause:** Workflow hasn't run yet, or job name mismatch
- **Solution:**
  1. Verify job name in `.github/workflows/ci.yml` is `build`
  2. Trigger workflow (create PR or manual dispatch)
  3. Wait for first workflow run to complete
  4. Status check will appear in settings dropdown

**Problem:** Branch protection rule exists but CI not enforced
- **Cause:** Incorrect status check name selected
- **Solution:**
  1. Edit protection rule (click pencil icon)
  2. Find "Require status checks to pass before merging"
  3. Verify `build` is listed (not `build / ubuntu-latest` or other variant)
  4. Save rule

**Problem:** PR shows "This branch has conflicts that must be resolved"
- **Cause:** Feature branch is behind main (requires rebase)
- **Solution:**
  1. User must rebase feature branch: `git rebase main`
  2. Force-push to PR: `git push -f origin feature-branch`
  3. This satisfies "require branches to be up to date before merging"

---

## 7. Rollback Plan

If branch protection causes issues:

**Disable protection temporarily:**
1. Settings → Branches
2. Find `main` branch rule
3. Click trash/delete icon to remove rule
4. CI will no longer block merges

**Modify protection rules:**
1. Settings → Branches
2. Click pencil icon to edit `main` rule
3. Uncheck "Require status checks to pass before merging"
4. Save changes

**Recovery:**
- Re-run this task to re-enable protection
- No code rollback needed (configuration-only change)

---

## 8. Related Tasks

**Prior Task:** CI-05 (Add test step) — Provides the `build` job that protection rule references

**Related Task:** E2 (Cross-Platform Testing) — Manual testing; CI-10 validates code through automated checks

**Future Tasks (planned, not in current Workplan):**
- **CI-11:** Add macOS runner to matrix (extends platform coverage beyond Ubuntu)
- **CI-12:** Add Windows runner to matrix
- **CI-13:** Optimize CI costs (conditional triggers per OS)
- **CI-14:** Add platform-specific test suites

---

## 9. Notes

- **Branch Protection is per-repository-admin configuration** — Requires Settings access, not available to developers via CI/code
- **Status check name must match job name exactly** — `build` (not `Build`, not `build / ubuntu-latest`)
- **Protection rule applies to all pushes to main**, including automation/bots — Intentional for code quality enforcement
- **Existing PRs may show old status** — Creating new PR will trigger fresh CI run and updated status
- **Team workflow may require code review in addition to CI** — This task only enforces CI; code review is optional separate setting

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-10 | Claude | Initial CI PRD for branch protection |

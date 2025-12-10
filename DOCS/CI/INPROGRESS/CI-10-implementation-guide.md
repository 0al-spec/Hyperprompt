# CI-10 Implementation Guide — Enable Required Status Checks

**Task ID:** CI-10
**Status:** Ready for Manual Execution
**Prerequisites:** ✅ All verified
**Estimated Time:** 15-20 minutes

---

## Pre-Flight Verification ✅ COMPLETE

### 1. CI Workflow Configuration
- **File:** `.github/workflows/ci.yml`
- **Job Name:** `build` (line 35)
- **Status Check Name:** `build` (automatically generated from job name)
- **Workflow Triggers:** PR to main, push to main, manual dispatch
- **Runner:** ubuntu-latest

**Verification:**
```yaml
jobs:
  build:  # ← This is the status check name
    runs-on: ubuntu-latest
```

✅ **Confirmed:** Job name is `build` and workflow is active.

### 2. Workflow Execution History
The workflow should have run at least once for the status check to appear in GitHub's branch protection settings.

**To verify:**
1. Go to: https://github.com/0al-spec/Hyperprompt/actions
2. Check recent workflow runs
3. Confirm "CI" workflow has completed successfully

If no recent runs, trigger manually:
```bash
gh workflow run ci.yml
```

Or create an empty commit:
```bash
git commit --allow-empty -m "Trigger CI for status check registration"
git push
```

---

## Implementation Steps

### Step 1: Access Branch Protection Settings

1. **Navigate to Repository Settings**
   - Go to: https://github.com/0al-spec/Hyperprompt
   - Click **Settings** tab (requires admin access)
   - Left sidebar → **Branches**

2. **Create Branch Protection Rule**
   - Click **Add rule** button
   - **Branch name pattern:** `main`

---

### Step 2: Configure Required Status Checks

**Enable "Require status checks to pass before merging":**
1. Check the box: ☑️ **Require status checks to pass before merging**

2. **Search for status check:**
   - In the search box, type: `build`
   - Select: ✅ **build** (from CI workflow)

   **Note:** If `build` doesn't appear in the dropdown:
   - The workflow may not have run yet
   - Trigger a workflow run (see Pre-Flight Verification step 2)
   - Wait for completion, then refresh the settings page

3. **Require branches to be up to date:**
   - Check the box: ☑️ **Require branches to be up to date before merging**
   - This ensures PRs are rebased on latest main before merging

---

### Step 3: Optional Protection Settings

**Recommended for team workflow:**

1. **Require pull request reviews before merging** (optional)
   - Check: ☑️ **Require a pull request before merging**
   - Set **Required number of approvals**: 1 (or more)
   - This adds human review in addition to CI

2. **Require conversation resolution** (optional)
   - Check: ☑️ **Require conversation resolution before merging**
   - Ensures all PR comments are addressed

3. **Include administrators** (optional)
   - Check: ☑️ **Include administrators**
   - Applies rules to repo admins (recommended for consistency)

**Note:** For this task (CI-10), only the status check requirement is mandatory. Other settings are optional enhancements.

---

### Step 4: Save Configuration

1. **Review settings:**
   - Branch name pattern: `main`
   - Required status checks: `build` ✓
   - Branches must be up to date: ✓

2. **Click "Create" button** (or "Save changes" if editing existing rule)

3. **Verify rule appears:**
   - Should see entry for `main` branch in protection rules list
   - Click rule name to review configuration

---

## Validation & Testing

### Validation 1: Verify Protection Rule

**Check that rule is active:**

1. Go to: Settings → Branches
2. Find `main` branch rule
3. Click rule name to expand
4. Verify:
   - ✅ "Require status checks to pass before merging" is enabled
   - ✅ `build` appears under "Status checks that are required"
   - ✅ "Require branches to be up to date before merging" is enabled

**Expected Output:**
```
Branch protection rule for main

Protect matching branches
☑ Require a pull request before merging
☑ Require status checks to pass before merging
    Status checks that are required:
    ✓ build
☑ Require branches to be up to date before merging
```

---

### Validation 2: Test with Failing CI

**Purpose:** Verify that failed CI blocks PR merge

**Steps:**

1. **Create test branch:**
   ```bash
   git checkout -b test/ci-blocking
   ```

2. **Introduce intentional syntax error:**
   ```bash
   echo "invalid swift syntax !!!" >> Sources/CLI/main.swift
   git add Sources/CLI/main.swift
   git commit -m "Test: intentional syntax error"
   git push -u origin test/ci-blocking
   ```

3. **Create PR:**
   ```bash
   gh pr create --title "Test: CI blocking" --body "Testing branch protection with failing CI"
   ```

4. **Observe PR status:**
   - CI workflow should start automatically
   - After ~2-3 minutes, CI should fail (syntax error)
   - PR should show: ❌ **build** (failing)
   - **Merge button should be DISABLED**
   - Message: "All conversations resolved, but some checks haven't passed yet"

5. **Verify blocking:**
   - Try to click "Merge pull request" button
   - Should be greyed out / disabled
   - Tooltip: "Required status check 'build' has not succeeded"

6. **Clean up:**
   ```bash
   gh pr close --delete-branch
   git checkout main
   ```

**Expected Result:** ✅ PR merge is blocked when CI fails

---

### Validation 3: Test with Passing CI

**Purpose:** Verify that passing CI allows PR merge

**Steps:**

1. **Create test branch with valid change:**
   ```bash
   git checkout -b test/ci-passing
   echo "// Valid Swift comment" >> Sources/CLI/main.swift
   git add Sources/CLI/main.swift
   git commit -m "Test: valid change"
   git push -u origin test/ci-passing
   ```

2. **Create PR:**
   ```bash
   gh pr create --title "Test: CI passing" --body "Testing branch protection with passing CI"
   ```

3. **Observe PR status:**
   - CI workflow should start automatically
   - After ~2-3 minutes, CI should pass
   - PR should show: ✅ **build** (passing)
   - **Merge button should be ENABLED**
   - Message: "All checks have passed"

4. **Verify merge allowed:**
   - "Merge pull request" button should be enabled (green)
   - Can select merge method (squash, rebase, merge commit)

5. **Optional: Complete merge or close:**
   ```bash
   # Option A: Merge the PR
   gh pr merge --squash

   # Option B: Close without merging
   gh pr close --delete-branch
   git checkout main
   ```

**Expected Result:** ✅ PR can be merged when CI passes

---

### Validation 4: Test Branch Update Requirement

**Purpose:** Verify "require up to date" setting works

**Steps:**

1. **Create test branch:**
   ```bash
   git checkout -b test/outdated-branch
   echo "// Change on test branch" >> Sources/CLI/main.swift
   git add Sources/CLI/main.swift
   git commit -m "Test: change on branch"
   git push -u origin test/outdated-branch
   ```

2. **Create PR (don't merge yet):**
   ```bash
   gh pr create --title "Test: outdated branch" --body "Testing branch update requirement"
   ```

3. **Make a change on main (simulate another PR merged):**
   ```bash
   git checkout main
   echo "// Change on main" >> README.md
   git add README.md
   git commit -m "Update README (simulating another merged PR)"
   git push origin main
   ```

4. **Go back to PR:**
   - PR should now show: "This branch is out of date with the base branch"
   - **Merge button may be disabled** (depends on rule strictness)
   - If enabled, it should show warning: "Merge blocked: branch must be up to date"

5. **Update branch:**
   ```bash
   git checkout test/outdated-branch
   git pull --rebase origin main
   git push --force-with-lease
   ```

6. **Verify merge now allowed:**
   - PR should show: "This branch is up to date with main"
   - After CI passes, merge button enabled

7. **Clean up:**
   ```bash
   gh pr close --delete-branch
   git checkout main
   ```

**Expected Result:** ✅ PR requires branch update before merging

---

## Acceptance Criteria Checklist

Use this checklist to verify CI-10 completion:

- [ ] **Pre-Flight**
  - [ ] CI workflow file exists: `.github/workflows/ci.yml`
  - [ ] Job name is `build`
  - [ ] Workflow has run at least once successfully
  - [ ] Status check `build` appears in GitHub (Actions tab)

- [ ] **Configuration**
  - [ ] Branch protection rule created for `main` branch
  - [ ] "Require status checks to pass before merging" enabled
  - [ ] Status check `build` is marked as required
  - [ ] "Require branches to be up to date before merging" enabled
  - [ ] Rule visible in Settings → Branches

- [ ] **Testing**
  - [ ] Test PR with failing CI: merge button disabled ✅
  - [ ] Test PR with passing CI: merge button enabled ✅
  - [ ] Test outdated branch: update required before merge ✅
  - [ ] Test PRs cleaned up (closed/merged)

- [ ] **Documentation**
  - [ ] This implementation guide created
  - [ ] Configuration steps documented
  - [ ] Team notified of new branch protection rules

---

## Troubleshooting

### Issue: Status check `build` not appearing in dropdown

**Symptom:** When configuring required status checks, `build` doesn't appear in search results.

**Cause:** Workflow hasn't run yet, or job name doesn't match.

**Solution:**
1. Go to Actions tab: https://github.com/0al-spec/Hyperprompt/actions
2. Check recent workflow runs for "CI" workflow
3. If no runs, trigger manually:
   ```bash
   gh workflow run ci.yml
   # or
   git commit --allow-empty -m "Trigger CI" && git push
   ```
4. Wait for workflow to complete
5. Refresh branch protection settings page
6. Search for `build` again

---

### Issue: Branch protection rule exists but CI not enforced

**Symptom:** Can merge PR even though CI failed.

**Cause:** Status check name mismatch or rule not saved properly.

**Solution:**
1. Go to Settings → Branches → Edit rule for `main`
2. Find "Require status checks to pass before merging" section
3. Verify `build` is listed under "Status checks that are required"
4. If not listed, search and add it again
5. Click "Save changes"
6. Test with a new PR

---

### Issue: PR shows "This branch has conflicts that must be resolved"

**Symptom:** PR shows merge conflicts, not related to CI blocking.

**Cause:** Changes on main conflict with PR branch.

**Solution:**
1. This is a merge conflict, not a CI issue
2. Resolve conflicts:
   ```bash
   git checkout <pr-branch>
   git pull --rebase origin main
   # Resolve conflicts
   git add <resolved-files>
   git rebase --continue
   git push --force-with-lease
   ```
3. After resolving, CI will run on updated branch

---

### Issue: "Require branches to be up to date" forces too many rebases

**Symptom:** Every time another PR merges, all open PRs become outdated.

**Cause:** Strict branch update requirement.

**Considerations:**
- This is **intentional behavior** to ensure PRs are tested against latest main
- Prevents integration issues where two PRs pass individually but conflict together
- **Recommended:** Keep this setting enabled for code quality

**Alternative (not recommended):**
- Uncheck "Require branches to be up to date before merging"
- Only enable "Require status checks to pass before merging"
- Allows merging stale branches (riskier)

---

## Team Communication

After completing CI-10, notify the team:

**Template message:**
```
Branch protection is now enabled on the `main` branch!

What this means:
✅ All PRs must pass CI tests before merging
✅ PRs must be up to date with main branch
✅ No more accidental merges of failing code

How to work with this:
1. Create PR as usual
2. Wait for CI to pass (green ✓)
3. If CI fails, fix issues and push updates
4. If main advances, update your branch:
   git pull --rebase origin main
   git push --force-with-lease
5. Once CI passes, merge button becomes available

Questions? See: DOCS/CI/INPROGRESS/CI-10-implementation-guide.md
```

---

## Post-Implementation

### Next Steps

1. **Monitor First Few PRs:**
   - Watch how team adapts to new workflow
   - Help with rebase issues if needed
   - Adjust rules if causing excessive friction

2. **Consider Future Enhancements (out of scope for CI-10):**
   - **CI-11:** Add macOS runner to CI matrix
   - **CI-12:** Add Windows runner to CI matrix
   - **Code review requirement:** Add required approvals (team decision)
   - **Additional status checks:** Linting, coverage, etc.

3. **Documentation:**
   - Update CONTRIBUTING.md with PR workflow
   - Add CI status badge to README.md
   - Document branch protection in onboarding guides

---

## Rollback Plan

If branch protection causes critical issues:

**Temporary Disable:**
1. Go to Settings → Branches
2. Find `main` branch rule
3. Click trash icon (delete rule)
4. Confirm deletion
5. CI will still run, but won't block merges

**Modify Rules:**
1. Go to Settings → Branches
2. Click pencil icon to edit `main` rule
3. Uncheck problematic settings (e.g., "Require branches to be up to date")
4. Save changes

**Re-enable Later:**
- Re-run this implementation guide
- Branch protection is a configuration-only change (no code impact)

---

## Task Completion Checklist

To mark CI-10 as complete:

- [x] ✅ Pre-flight verification completed (job name confirmed)
- [ ] ⏸️ Branch protection rule created (requires GitHub UI access)
- [ ] ⏸️ Status check `build` marked as required (requires GitHub UI access)
- [ ] ⏸️ Tested with failing CI (merge blocked) (requires GitHub access)
- [ ] ⏸️ Tested with passing CI (merge allowed) (requires GitHub access)
- [x] ✅ Implementation guide created (this document)
- [ ] ⏸️ Team notified of changes (manual step)

**Status:** Ready for manual execution by repository admin.

---

## References

- **Task PRD:** DOCS/CI/INPROGRESS/CI-10_Enable_required_status_checks.md
- **CI Workflow:** .github/workflows/ci.yml
- **GitHub Docs:** https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches
- **Related Task:** E2 (Cross-Platform Testing) — Manual testing that CI automates

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-11 | Claude | Initial implementation guide for CI-10 |

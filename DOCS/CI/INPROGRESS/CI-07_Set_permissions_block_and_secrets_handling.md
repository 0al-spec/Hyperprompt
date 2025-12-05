# CI-07 — Set permissions block and secrets handling

## 1. Context
- **Phase:** Workflow Skeleton
- **Priority:** High
- **Dependencies:** CI-02 (workflow triggers defined)
- **Effort:** 0.5h
- **Status:** In Progress

## 2. Objectives
1. Implement least-privilege permissions block in `.github/workflows/ci.yml` to minimize token scope exposure.
2. Add secrets validation logic that fails fast if required secrets are missing (rather than silently skipping).
3. Document all required and optional secrets in the workflow and repository configuration.
4. Ensure workflow maintains security best practices per GitHub Actions recommendations.

## 3. Implementation Plan

### Step 1: Add Permissions Block
- Add `permissions:` block at workflow level with minimal required scopes:
  - `contents: read` — required for `actions/checkout@v4`
  - `actions: write` (if status checks needed for artifacts)
  - NO implicit `write` permissions (set explicitly only when needed)
- Reference: GitHub Actions least-privilege best practice

### Step 2: Identify Secret Requirements
- Audit current workflow (ci.yml) for any references to `secrets.*`:
  - Currently: No secrets referenced in existing workflow
  - Future-proof: Add validation placeholder for potential secrets (e.g., CI badges, deployment tokens)
- Document in workflow comments which secrets are optional vs. required.

### Step 3: Implement Secrets Validation
- Add early validation step (before dependency install) using bash:
  ```yaml
  - name: Validate secrets
    run: |
      # Check for required secrets (e.g., CI_TOKEN, DEPLOY_KEY)
      # Fail fast if missing
      if [[ -z "${{ secrets.CI_TOKEN }}" ]]; then
        echo "ERROR: CI_TOKEN secret not configured"
        exit 1
      fi
  ```
- For optional secrets: log warning if missing, continue execution.

### Step 4: Update Workflow Comments
- Add clear section headers in workflow explaining:
  - Why permissions block is needed (security audit trail)
  - Which secrets are required/optional
  - How to add/update secrets in GitHub repository settings
  - Link to `DOCS/CI/README.md` for full documentation

### Step 5: Validate Permissions Configuration
- Ensure no unintended permission escalation:
  - No `contents: write` unless needed for artifact uploads
  - No `id-token: write` unless OIDC federation is planned
  - Runner token scoped to read-only by default

### Step 6: Document in DOCS/CI/README.md
- Add section: "Secrets & Permissions"
- Include:
  - Required secrets list (empty for current state, placeholder for future)
  - Optional secrets list
  - How to configure in GitHub UI (Settings → Secrets and variables → Actions)
  - Example `.env` file structure for local testing with `act`

## 4. Acceptance Criteria

### From Workplan
- [ ] Permissions minimized; no implicit write scopes
- [ ] Permissions block properly scoped for all job actions

### Implementation-Specific
- [ ] `permissions:` block added at workflow level with `contents: read` and any job-specific needs
- [ ] Validation step added to check for required secrets; fails fast with clear error message
- [ ] Workflow comments document permissions rationale and secret requirements
- [ ] No GitHub Actions warnings about implicit permissions
- [ ] `DOCS/CI/README.md` includes "Secrets & Permissions" section with configuration guidance
- [ ] Workflow runs successfully (no permissions errors from `actions/checkout`, `actions/upload-artifact`)

## 5. GitHub Actions Specifics

### Current Workflow State
- **Runner:** ubuntu-latest
- **Triggers:** PR, push to main, manual dispatch (from CI-02)
- **Path filters:** Swift source files, Package.swift, Package.resolved, workflows
- **Actions used:**
  - `actions/checkout@v4` — requires `contents: read`
  - `swift-actions/setup-swift@v2` — no special permissions needed
  - `actions/cache@v4` — no special permissions needed
  - `actions/upload-artifact@v4` — typically requires `contents: read` (check if actions scope needed)

### Permissions Block Structure
```yaml
permissions:
  contents: read
  # actions: write  # Uncomment if using artifact API or deploying
  # id-token: read  # Uncomment if using OIDC federated identity
```

### Secrets Variables (Current)
- **Required:** None (baseline CI does not require external secrets)
- **Optional:** `CI_TOKEN`, `DEPLOY_KEY` (for future stages; document as placeholders)

## 6. Testing & Validation

### Local Validation with `act`
```bash
# Test with permissive permissions (for local dev)
act -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:full-latest --job build

# Test with no secrets (should warn but not fail)
act -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:full-latest --secret EMPTY_SECRET="" --job build
```

### GitHub UI Validation
1. Commit workflow change to feature branch.
2. Push to GitHub and open PR.
3. Verify workflow runs without permission errors.
4. Check "Actions" tab for permission-related warnings.
5. Verify artifact upload succeeds (if applicable).

### Secrets Validation Testing
1. Create test PR with workflow change.
2. Observe validation step output for clarity.
3. If future secrets are added, test by temporarily removing them and verifying fast-fail behavior.

## 7. Rollback Plan

### If Permissions Block Breaks Workflow
1. Identify failing step from workflow logs (e.g., "Permission denied: contents").
2. Add missing permission scope to `permissions:` block.
3. Re-run workflow from GitHub UI or push fix to branch.
4. Commit and update PR.

### If Secrets Validation Blocks CI Unnecessarily
1. Review validation step logic.
2. If secret is truly optional, change from `exit 1` to `echo WARNING`.
3. Re-run workflow.
4. Document in `DOCS/CI/README.md` as optional.

### Full Revert (if needed)
```bash
git revert <commit-hash>
git push origin <branch>
```

## 8. Additional Notes

### Security Considerations
- GitHub Actions automatically masks secrets in logs; validation step confirms this.
- Least-privilege permissions reduce blast radius if workflow is compromised.
- No hardcoded secrets in workflow YAML; all sensitive data via repository secrets.

### Future Extensions
- CI-08: Documentation will expand "Secrets & Permissions" section.
- CI-09: Local validation with `act` will test permissioning.
- CI-10: Status checks will respect permissions configured here.

### Related Tasks
- **CI-02:** Defined triggers and paths (dependency for CI-07).
- **CI-03:** Environment setup completes before permissions are critical.
- **CI-08:** Documentation of secrets handling will reference this task.

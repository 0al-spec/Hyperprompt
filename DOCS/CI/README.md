# GitHub Actions CI Configuration Guide

This document describes the GitHub Actions CI workflow for the Hyperprompt project.

## Overview

The CI workflow (`ci.yml`) is configured to:
- Run on pull requests to the main branch
- Run on pushes to the main branch
- Support manual dispatch via GitHub UI
- Build and test the Swift compiler on Ubuntu Linux
- Cache dependencies for improved performance

## Workflow Structure

### Triggers

The workflow is triggered by:
- **Pull Requests**: When opened or updated against `main` branch
- **Push**: When code is pushed to `main` branch
- **Manual Dispatch**: Via GitHub Actions tab

Path filters are applied to all triggers to only run when relevant files change:
- `Sources/**/*.swift` — Swift source files
- `Tests/**/*.swift` — Test files
- `Package.swift` — Package manifest
- `Package.resolved` — Dependency lock file
- `.github/workflows/**` — Workflow files

### Job Configuration

**Job Name:** `build`

**Runner:** `ubuntu-latest`

**Environment:** Swift 6.0.3 on Linux

**Key Features:**
- Dependency caching based on `Package.resolved` hash
- Swift package build and testing
- Test artifact upload on failure

## Secrets & Permissions

### Permissions Model

This workflow follows the **least-privilege principle** for GitHub Actions token permissions:

```yaml
permissions:
  contents: read
```

**Why?** The workflow only needs to:
1. Read repository contents (for checkout)
2. Upload artifacts on test failure

**No implicit write permissions** are granted. This minimizes the blast radius if the workflow is compromised.

### Required Secrets

**Currently:** None

The baseline CI workflow does not require any external secrets. All operations use repository contents and public resources.

### Optional Secrets (Placeholders for Future Extension)

When CI is extended with features like artifact publishing, deployment, or badge updates, these secrets may be added:

- `CI_TOKEN` — Token for CI-related API operations (e.g., publishing artifacts)
- `DEPLOY_KEY` — SSH key for deployment steps
- `GITHUB_TOKEN` — Automatically available for GitHub API calls (no manual configuration needed)

**Important:** Never commit secrets to the repository. Always configure them in GitHub repository settings:
- Navigate to: **Settings → Secrets and variables → Actions**
- Click "New repository secret"
- Add secret name and value

### Secrets Validation

The workflow includes an early validation step that:
1. Checks for required secrets (currently none, but extensible)
2. Warns about missing optional secrets
3. Fails fast if critical secrets are missing

**To enable secrets validation:**

When adding a required secret, update the "Validate secrets" step:

```yaml
- name: Validate secrets
  run: |
    echo "Checking required secrets..."
    if [[ -z "${{ secrets.CI_TOKEN }}" ]]; then
      echo "ERROR: CI_TOKEN secret not configured"
      exit 1
    fi
    echo "✓ Secrets validation passed"
```

### Security Best Practices

1. **No Hardcoded Secrets** — All sensitive data must be stored in repository secrets
2. **Secret Masking** — GitHub Actions automatically redacts secrets in logs
3. **Minimal Permissions** — Grant only the permissions needed for each action
4. **Regular Rotation** — Review and rotate secrets periodically
5. **Audit Trail** — GitHub logs all secret access attempts

## Customization & Extension

### Adding a Build Step

To add a new step to the workflow, edit `.github/workflows/ci.yml`:

```yaml
- name: My Custom Step
  run: |
    echo "Running custom operation"
    # Your command here
```

### Adding a New Secret

1. Add the secret in GitHub repository settings (Settings → Secrets and variables)
2. Update the "Validate secrets" step if it's required
3. Reference it in your step using `${{ secrets.MY_SECRET }}`

### Modifying Caching

Cache keys are based on the `Package.resolved` hash. To modify caching strategy:

```yaml
- name: Cache Swift dependencies
  uses: actions/cache@v4
  with:
    path: |
      .build
      .swiftpm
    key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
    restore-keys: |
      ${{ runner.os }}-spm-
```

### Local Testing with `act`

To test the workflow locally using `act` (GitHub Actions emulator):

```bash
# Install act
# https://github.com/nektos/act

# Run the workflow locally
act -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:full-latest

# Run a specific job
act -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:full-latest --job build

# With custom secrets (create .env file)
# echo "CI_TOKEN=my_test_token" > .env
# act --env-file .env
```

## Workflow Jobs

### build

**Runs on:** `ubuntu-latest`

**Steps:**

1. **Validate secrets** — Check for required secrets configuration
2. **Checkout code** — Clone repository with full git history
3. **Install Swift 6.0.3** — Install Swift toolchain via `swift-actions/setup-swift`
4. **Verify Swift version** — Confirm Swift 6.0.3 is installed
5. **Cache Swift dependencies** — Cache `.build` and `.swiftpm` directories
6. **Resolve dependencies** — Run `swift package resolve`
7. **Cache statistics** — Log cache size for debugging
8. **Build** — Run `swift build --build-tests`
9. **Run tests** — Run `swift test --parallel`
10. **Upload test results** — Upload artifacts on failure
11. **Build summary** — Display build completion status

## Troubleshooting

### Workflow Failed with Permission Error

**Symptom:** `Error: Permission denied` or similar message

**Solution:**
1. Check the failing action name
2. Update `permissions:` block to include the required scope
3. Common scopes:
   - `contents: read` — For checkout, code analysis
   - `contents: write` — For commits, releases (use cautiously)
   - `actions: write` — For artifact management
   - `id-token: read` — For OIDC federation

### Secrets Not Available in Workflow

**Symptom:** Workflow step references a secret but it's not found

**Solution:**
1. Verify secret is configured in Settings → Secrets and variables → Actions
2. Check the secret name matches exactly (case-sensitive)
3. Ensure the job doesn't have restrictive permissions that block secret access
4. Use `${{ secrets.SECRET_NAME }}` syntax (not shell variable expansion)

### Cache Not Working

**Symptom:** Slow builds, cache not restored

**Solution:**
1. Verify `Package.resolved` hasn't changed (would invalidate cache)
2. Check `.gitignore` doesn't exclude cached directories
3. Review cache size limits (GitHub allows 5GB per repo)
4. Clear cache manually in Settings → Actions → General → Cache

## CI Pipeline Phases

The CI setup is organized in phases:

1. **Discovery** (CI-01) — Audit repository languages and build scripts
2. **Workflow Skeleton** (CI-02, CI-03, CI-07) — Define triggers, environment, permissions
3. **Quality Gates** (CI-04, CI-05, CI-06) — Add linting, testing, retries
4. **Validation & Docs** (CI-08, CI-09, CI-10) — Validate workflow, document, enable status checks

## Related Documentation

- **Workflow Definition:** `.github/workflows/ci.yml`
- **CI Workplan:** `DOCS/CI/Workplan.md`
- **CI PRD:** `DOCS/CI/PRD.md`
- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Security Best Practices:** https://docs.github.com/en/actions/security-guides/

## Questions or Issues?

For questions about the CI workflow:
1. Check the workflow definition in `.github/workflows/ci.yml`
2. Review the relevant task PRD in `DOCS/CI/INPROGRESS/`
3. Consult GitHub Actions documentation
4. Check workflow run logs in GitHub Actions tab

---

**Last Updated:** December 5, 2025
**CI Phase:** Workflow Skeleton
**Current Status:** In Progress (CI-07)

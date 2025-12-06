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

## Configuration Variables

The workflow uses the following configurable parameters:

| Variable | Current Value | Purpose | How to Change |
|----------|---------------|---------|---------------|
| **Swift Version** | `6.0.3` | Compiler toolchain version | Edit `swift-version` in Install Swift step |
| **Runner OS** | `ubuntu-latest` | CI execution environment | Edit `runs-on` in job configuration |
| **Cache Paths** | `.build`, `.swiftpm` | Directories to cache between runs | Edit `path` in Cache Swift dependencies step |
| **Cache Key** | `hashFiles('Package.resolved')` | Cache invalidation trigger | Edit `key` in Cache Swift dependencies step |
| **Artifact Retention** | `7 days` | How long test artifacts are kept | Edit `retention-days` in Upload test results step |
| **Test Parallelism** | `--parallel` | Concurrent test execution | Edit `swift test` command |
| **Path Filters** | `Sources/**/*.swift`, etc. | Files that trigger CI | Edit `on.pull_request.paths` and `on.push.paths` |

### Example: Changing Swift Version

To use Swift 6.1.0 instead of 6.0.3:

```yaml
- name: Install Swift 6.1.0
  uses: swift-actions/setup-swift@v2
  with:
    swift-version: '6.1.0'
```

**Important:** Update the version verification step as well:

```yaml
- name: Verify Swift version
  run: |
    swift --version
    swift --version | grep -q "6.1.0"
```

## Usage Examples

### Manually Triggering the Workflow

1. Navigate to **Actions** tab in GitHub repository
2. Select **CI** workflow from the left sidebar
3. Click **Run workflow** dropdown (top right)
4. Select branch and click **Run workflow** button

**Use case:** Test CI on a feature branch without opening a PR

### Viewing Workflow Logs

1. Go to **Actions** tab
2. Click on the workflow run you want to inspect
3. Click on the **build** job
4. Expand individual steps to see detailed logs

**Tip:** Use the search box to filter logs by keyword

### Checking Cache Performance

After a workflow run, check the "Cache Swift dependencies" step:

- **Cache hit:** `Cache restored from key: Linux-spm-abc123...`
- **Cache miss:** `Cache not found for input keys: Linux-spm-abc123...`

**Expected speedup on cache hit:** 60-80% reduction in dependency resolution time

To view cache statistics:

1. Expand the "Cache statistics" step in workflow logs
2. Look for `.build` and `.swiftpm` directory sizes

### Downloading Test Artifacts

When tests fail, artifacts are uploaded automatically:

1. Navigate to the failed workflow run
2. Scroll down to **Artifacts** section (below job summary)
3. Click on `test-results-{run-id}` to download

**Contains:**
- `.xctest` bundles
- `.swiftmodule` files
- `debug.yaml` configuration

## Customization & Extension

### Adding a Build Step

To add a new step to the workflow, edit `.github/workflows/ci.yml`:

```yaml
- name: My Custom Step
  run: |
    echo "Running custom operation"
    # Your command here
```

**Best practices:**
- Place custom steps after dependency resolution
- Use `if: always()` for steps that should run regardless of previous failures
- Add descriptive echo statements for better log readability

### Adding a New Secret

1. Add the secret in GitHub repository settings (Settings → Secrets and variables)
2. Update the "Validate secrets" step if it's required
3. Reference it in your step using `${{ secrets.MY_SECRET }}`

**Example:**

```yaml
- name: My Step Using Secrets
  run: |
    echo "Connecting to service..."
    curl -H "Authorization: Bearer ${{ secrets.API_TOKEN }}" https://api.example.com
```

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

**Advanced caching patterns:**

```yaml
# Include Swift version in cache key
key: ${{ runner.os }}-swift-${{ matrix.swift-version }}-spm-${{ hashFiles('Package.resolved') }}

# Add multiple fallback keys
restore-keys: |
  ${{ runner.os }}-swift-${{ matrix.swift-version }}-spm-
  ${{ runner.os }}-swift-
  ${{ runner.os }}-
```

### Adding Static Analysis (Linting)

To add SwiftLint or similar tools:

```yaml
- name: Run SwiftLint
  run: |
    if command -v swiftlint &> /dev/null; then
      swiftlint lint --strict
    else
      echo "SwiftLint not found, skipping..."
    fi
```

**Note:** CI-04 (static analysis) is planned for future implementation

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

## Extending CI to Other Operating Systems

The current workflow targets **Linux only** (`ubuntu-latest`). To add support for macOS and Windows:

### Architecture for Multi-OS Support

Use a **matrix strategy** to run the same job across multiple operating systems:

```yaml
jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        swift-version: ['6.0.3']

    runs-on: ${{ matrix.os }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install Swift ${{ matrix.swift-version }}
        uses: swift-actions/setup-swift@v2
        with:
          swift-version: ${{ matrix.swift-version }}

      # Rest of steps remain the same
```

### OS-Specific Considerations

#### macOS

**Advantages:**
- Native Swift support (comes pre-installed)
- Faster Swift builds compared to Linux
- Official Apple platform for Swift development

**Changes needed:**
- Runner: `macos-latest` or specific version (`macos-13`, `macos-14`)
- Cache paths may differ slightly
- Xcode command-line tools should be verified

**Example:**

```yaml
- name: Verify Xcode (macOS only)
  if: runner.os == 'macOS'
  run: xcode-select -p
```

#### Windows

**Advantages:**
- Tests cross-platform compatibility
- Swift for Windows is actively developed

**Challenges:**
- Swift on Windows requires Visual Studio components
- Different path separators (`\` vs `/`)
- Some Swift features may not be available

**Changes needed:**
- Runner: `windows-latest`
- Install Visual Studio Build Tools
- Adjust path separators in scripts
- Cache paths use Windows-style paths

**Example:**

```yaml
- name: Install Visual Studio Build Tools (Windows)
  if: runner.os == 'Windows'
  uses: microsoft/setup-msbuild@v1
```

### Step-by-Step: Adding macOS Support

1. **Update job configuration:**

```yaml
jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
```

2. **Update cache key to include OS:**

```yaml
key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
```

3. **Add OS-specific steps if needed:**

```yaml
- name: Install dependencies (macOS)
  if: runner.os == 'macOS'
  run: brew install <package>

- name: Install dependencies (Linux)
  if: runner.os == 'Linux'
  run: sudo apt-get install <package>
```

4. **Test the workflow:**
   - Create a PR with the changes
   - Verify both Linux and macOS jobs pass
   - Check build times and cache performance

### Multi-Version Testing

To test across multiple Swift versions:

```yaml
jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        swift-version: ['5.9', '6.0.3']

    runs-on: ${{ matrix.os }}

    steps:
      - name: Install Swift ${{ matrix.swift-version }}
        uses: swift-actions/setup-swift@v2
        with:
          swift-version: ${{ matrix.swift-version }}
```

**Result:** Creates 4 jobs (2 OS × 2 Swift versions)

### Performance Considerations

- **Cost:** macOS runners are 10× more expensive than Linux runners
- **Build time:** macOS is typically faster for Swift builds
- **Parallelism:** Matrix jobs run concurrently, no extra wall-clock time
- **Recommendation:** Run all OSes on main branch, Linux-only on PRs to save costs

**Example: Different triggers for different OSes:**

```yaml
jobs:
  linux:
    runs-on: ubuntu-latest
    # Runs on all PRs and pushes

  macos:
    runs-on: macos-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    # Runs only on main branch pushes
```

### Future CI Tasks

The following tasks are planned to enhance multi-platform support:

- **CI-11:** Add macOS runner to matrix (estimated: 1h)
- **CI-12:** Add Windows runner to matrix (estimated: 2h)
- **CI-13:** Optimize CI costs with conditional OS triggers (estimated: 0.5h)
- **CI-14:** Add platform-specific test suites (estimated: 1.5h)

**Status:** Linux-only implementation complete (CI-01 through CI-08)

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

### 1. Workflow Failed with Permission Error

**Symptom:** `Error: Permission denied` or similar message

**Solution:**
1. Check the failing action name
2. Update `permissions:` block to include the required scope
3. Common scopes:
   - `contents: read` — For checkout, code analysis
   - `contents: write` — For commits, releases (use cautiously)
   - `actions: write` — For artifact management
   - `id-token: read` — For OIDC federation

**Example fix:**

```yaml
permissions:
  contents: read
  actions: write  # Add if artifact upload fails
```

### 2. Secrets Not Available in Workflow

**Symptom:** Workflow step references a secret but it's not found

**Solution:**
1. Verify secret is configured in Settings → Secrets and variables → Actions
2. Check the secret name matches exactly (case-sensitive)
3. Ensure the job doesn't have restrictive permissions that block secret access
4. Use `${{ secrets.SECRET_NAME }}` syntax (not shell variable expansion)

**Common mistake:**

```bash
# ❌ Wrong: Using shell variable
echo $CI_TOKEN

# ✓ Correct: Using GitHub Actions syntax
echo "${{ secrets.CI_TOKEN }}"
```

### 3. Cache Not Working

**Symptom:** Slow builds, cache not restored

**Solution:**
1. Verify `Package.resolved` hasn't changed (would invalidate cache)
2. Check `.gitignore` doesn't exclude cached directories
3. Review cache size limits (GitHub allows 5GB per repo)
4. Clear cache manually in Settings → Actions → General → Cache

**Debug steps:**

```yaml
- name: Debug cache
  run: |
    echo "Cache key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}"
    ls -la .build .swiftpm || true
```

### 4. Swift Build Fails with "Cannot find module"

**Symptom:** Build fails with module not found errors

**Solution:**
1. Check that `swift package resolve` completed successfully
2. Verify `Package.resolved` is committed to repository
3. Check for network issues during dependency download
4. Clear cache and retry

**Example fix:**

```yaml
- name: Clean and resolve dependencies
  run: |
    rm -rf .build .swiftpm
    swift package resolve
    swift package update
```

### 5. Tests Fail on CI but Pass Locally

**Symptom:** Tests pass on local machine but fail in GitHub Actions

**Common causes:**
- **Environment differences:** Different Swift versions, OS versions, or dependencies
- **Timing issues:** Tests may be sensitive to execution speed
- **File system differences:** Case-sensitivity on Linux vs macOS
- **Missing environment variables:** Local environment has variables not set in CI

**Solution:**
1. Check Swift version matches: `swift --version` locally vs in CI logs
2. Add debug output to identify environment differences
3. Use `workflow_dispatch` to test on CI without creating PRs
4. Download test artifacts to inspect failure details

**Example: Add environment debugging:**

```yaml
- name: Debug environment
  run: |
    swift --version
    uname -a
    env | grep -i swift || true
    ls -la
```

### 6. Workflow Doesn't Trigger on Push

**Symptom:** Push commits but workflow doesn't run

**Solution:**
1. Check path filters — ensure changed files match the patterns
2. Verify branch name matches trigger configuration
3. Check if workflows are disabled in repository settings
4. Review GitHub Actions logs for any errors

**Path filter debugging:**

```yaml
on:
  push:
    branches: [main]
    paths:
      - '**'  # Temporarily match all paths for debugging
```

### 7. Artifact Upload Fails

**Symptom:** "Error: Artifact upload failed" or similar

**Solution:**
1. Check that artifact paths exist before upload
2. Verify artifact size is within limits (500 MB per artifact)
3. Ensure `actions: write` permission is granted if needed
4. Use wildcard patterns carefully

**Example fix:**

```yaml
- name: Upload test results
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: test-results-${{ github.run_id }}
    path: |
      .build/debug/*.xctest
    if-no-files-found: warn  # Don't fail if no files found
```

### 8. Workflow Runs Too Long / Times Out

**Symptom:** Workflow exceeds 6 hour limit or takes too long

**Solution:**
1. Check cache effectiveness — low cache hit rate increases build time
2. Optimize dependency resolution
3. Use `--parallel` flag for tests
4. Consider splitting into multiple jobs

**Performance optimization:**

```yaml
# Run steps in parallel where possible
- name: Build and Test
  run: |
    swift build --build-tests &
    BUILD_PID=$!
    # Do other work
    wait $BUILD_PID
```

## CI Pipeline Phases

The CI setup is organized in phases:

1. **Discovery** (CI-01) — Audit repository languages and build scripts ✅
2. **Workflow Skeleton** (CI-02, CI-03, CI-07) — Define triggers, environment, permissions ✅
3. **Quality Gates** (CI-04, CI-05, CI-06) — Add linting, testing, retries (CI-05 ✅, CI-04/CI-06 planned)
4. **Validation & Docs** (CI-08, CI-09, CI-10) — Validate workflow, document, enable status checks ✅

## Branch Protection & Status Checks

### Integration with GitHub Branch Protection

This CI workflow is designed to work with GitHub's branch protection rules. Once enabled, branch protection ensures code quality by requiring CI to pass before merging.

### Enabling Branch Protection (CI-10)

To enable required status checks for the main branch:

1. **Navigate to repository settings:**
   - Go to **Settings** → **Branches**
   - Under "Branch protection rules", click **Add rule**

2. **Configure protection rule:**
   - **Branch name pattern:** `main`
   - Enable: **Require status checks to pass before merging**
   - Enable: **Require branches to be up to date before merging**
   - Select status check: **build** (the job name from `ci.yml`)

3. **Optional additional protections:**
   - **Require pull request reviews:** Enforce code review before merge
   - **Require signed commits:** Ensure commit integrity
   - **Include administrators:** Apply rules to repo admins

4. **Save changes**

### Status Check Names

The following status checks are available from the CI workflow:

| Status Check Name | Description | Job in `ci.yml` |
|-------------------|-------------|-----------------|
| **build** | Main CI job (build, test, lint) | `jobs.build` |

**Important:** Status check names must match job names in the workflow file exactly.

### Interpreting CI Status

**On Pull Requests:**

- ✅ **Green check:** CI passed, safe to merge
- ❌ **Red X:** CI failed, review logs before merging
- 🟡 **Yellow dot:** CI in progress, wait for completion
- ⚪ **Gray circle:** CI not triggered (check path filters)

**Status badge for README:**

```markdown
![CI](https://github.com/0al-spec/Hyperprompt/workflows/CI/badge.svg)
```

### Merge Blocking Behavior

When branch protection is enabled with required status checks:

- **Cannot merge** if CI fails
- **Cannot merge** if CI hasn't run yet
- **Cannot bypass** unless admin override is configured
- **Force push** to protected branch is blocked

### Testing Branch Protection

To test that branch protection is working:

1. Create a test PR with a known failure (e.g., syntax error)
2. Observe that CI fails
3. Verify that "Merge" button is disabled
4. Fix the error and push
5. Verify CI passes and merge becomes available

## Related Documentation

- **Workflow Definition:** `.github/workflows/ci.yml`
- **CI Workplan:** `DOCS/CI/Workplan.md`
- **CI PRD:** `DOCS/CI/PRD.md`
- **CI Task PRDs:** `DOCS/CI/INPROGRESS/` (for in-progress tasks)
- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Security Best Practices:** https://docs.github.com/en/actions/security-guides/
- **Branch Protection:** https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches

## Quick Reference

### Common Commands

```bash
# Manually trigger CI workflow
gh workflow run ci.yml

# View latest workflow run
gh run list --workflow=ci.yml --limit 1

# Watch workflow run in real-time
gh run watch

# Download artifacts from latest run
gh run download

# View workflow definition
gh workflow view ci.yml
```

### Key Files

- `.github/workflows/ci.yml` — Main CI workflow definition
- `Package.swift` — Swift package manifest (determines dependencies)
- `Package.resolved` — Locked dependency versions (cache key)
- `.build/` — Build artifacts (cached)
- `.swiftpm/` — Swift Package Manager cache (cached)

### Environment Variables

The workflow uses these GitHub Actions built-in variables:

- `${{ github.ref }}` — Branch or tag ref that triggered the workflow
- `${{ github.sha }}` — Commit SHA that triggered the workflow
- `${{ github.run_id }}` — Unique workflow run ID
- `${{ runner.os }}` — Operating system of the runner
- `${{ github.actor }}` — Username of the person who triggered the workflow

## Questions or Issues?

For questions about the CI workflow:
1. Check the workflow definition in `.github/workflows/ci.yml`
2. Review this README for configuration and troubleshooting guidance
3. Check the CI Workplan in `DOCS/CI/Workplan.md` for task status
4. Review workflow run logs in the GitHub Actions tab
5. Consult GitHub Actions documentation at https://docs.github.com/en/actions

**For bugs or feature requests:** Open an issue in the repository

---

**Last Updated:** December 6, 2025
**CI Phase:** Validation & Docs
**Current Task:** CI-08 (Document CI Usage)
**Status:** ✅ Complete — Linux CI fully documented

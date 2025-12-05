# CI-03 — Configure Linux Job Environment

**Task ID:** CI-03
**Priority:** High
**Phase:** Phase 2 — Workflow Skeleton
**Estimated Effort:** 1 hour
**Dependencies:** CI-02 (Define Workflow Triggers) — ✅ Completed
**Status:** ✅ Completed

---

## 1. Context

### 1.1 Current State

**Completed Prerequisites:**
- ✅ **CI-01 (Repository Audit):** Swift 6.0.3 identified, build/test commands verified
- ✅ **CI-02 (Workflow Triggers):** `.github/workflows/ci.yml` exists with placeholder job

**Existing Workflow Structure:**
```yaml
name: CI
on: [pull_request, push, workflow_dispatch]  # Configured in CI-02
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Placeholder
        run: echo "Job configuration will be added in CI-03"
```

### 1.2 Task Scope

This task transforms the placeholder job into a fully functional Linux CI environment by adding:
1. **Checkout:** Clone repository code
2. **Toolchain:** Install Swift 6.0.3
3. **Caching:** Speed up dependency resolution
4. **Validation:** Ensure workflow passes lint/syntax checks

**Out of Scope (Future Tasks):**
- Build/test steps (CI-05)
- Static analysis (CI-04)
- Retry wrappers (CI-06)
- Permissions hardening (CI-07)

---

## 2. Objectives

### 2.1 Primary Goals

1. **Enable Swift Compilation:** Install Swift 6.0.3 on ubuntu-latest runner
2. **Optimize Build Times:** Implement dependency caching with 60-80% speedup potential
3. **Ensure Reproducibility:** Use parameterized cache keys based on Package.resolved hash
4. **Validate Configuration:** Workflow passes actionlint or GitHub's built-in validation

### 2.2 Success Criteria

**Functional:**
- [ ] Repository code checked out successfully
- [ ] Swift 6.0.3 installed and accessible on PATH
- [ ] Dependencies cached using Package.resolved hash
- [ ] Cache restores on subsequent runs (warm cache)
- [ ] Build environment ready for compilation (verified via `swift --version`)

**Quality:**
- [ ] Workflow YAML passes syntax validation
- [ ] All steps have descriptive names
- [ ] Cache keys are parameterized (no hardcoded values)
- [ ] Runner OS correctly specified (ubuntu-latest)
- [ ] No deprecated actions used

**Performance:**
- [ ] Cold cache: Dependencies resolve within 2 minutes
- [ ] Warm cache: Dependencies restore within 10 seconds
- [ ] Total job setup time < 1 minute (excluding dependency resolution)

---

## 3. Implementation Plan

### 3.1 Phase 1: Repository Checkout (10 minutes)

#### Task 1.1: Add Checkout Action

**Objective:** Clone repository code to runner workspace.

**Implementation:**
```yaml
- name: Checkout code
  uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Full history for potential git-based versioning
```

**Why actions/checkout@v4:**
- Latest stable version (as of 2025)
- Supports submodules, LFS, and sparse checkout
- Optimized for speed and reliability

**Configuration Options:**
- `fetch-depth: 0` — Full git history (enables git describe, blame, etc.)
- Alternative: `fetch-depth: 1` for shallow clone (faster, but limits git operations)
- **Recommendation:** Use `fetch-depth: 0` for completeness

**Validation:**
```bash
# After checkout, verify files present
- name: Verify checkout
  run: |
    ls -la
    test -f Package.swift
    test -d Sources
```

---

### 3.2 Phase 2: Swift Toolchain Installation (15 minutes)

#### Task 2.1: Install Swift 6.0.3

**Objective:** Make Swift compiler available on runner.

**Implementation:**
```yaml
- name: Install Swift 6.0.3
  uses: swift-actions/setup-swift@v2
  with:
    swift-version: '6.0.3'
```

**Why swift-actions/setup-swift@v2:**
- **Official:** Maintained by Swift community
- **Fast:** Downloads pre-built toolchains from swift.org
- **Cached:** Action caches toolchain downloads across runs
- **Version-pinnable:** Exact version specification supported
- **Cross-platform:** Works on Linux, macOS, Windows

**Alternative Approaches (Rejected):**
1. **Swift Docker Container:**
   ```yaml
   container:
     image: swift:6.0.3
   ```
   ❌ Slower startup (Docker pull overhead)
   ❌ Less GitHub Actions integration
   ✅ More isolated environment (not needed for CI)

2. **Manual Download:**
   ```yaml
   - run: |
       wget https://download.swift.org/swift-6.0.3-release/...
       tar xzf swift-6.0.3-RELEASE-ubuntu24.04.tar.gz
       export PATH="$PWD/swift-6.0.3-RELEASE/usr/bin:$PATH"
   ```
   ❌ More complex, error-prone
   ❌ No automatic caching
   ❌ Hardcoded URLs (brittle)

**Validation:**
```yaml
- name: Verify Swift installation
  run: |
    swift --version
    swift --version | grep -q "6.0.3"
    which swift
```

**Expected Output:**
```
Swift version 6.0.3 (swift-6.0.3-RELEASE)
Target: x86_64-unknown-linux-gnu
```

---

### 3.3 Phase 3: Dependency Caching (20 minutes)

#### Task 3.1: Configure SPM Dependency Cache

**Objective:** Cache `.build` and `.swiftpm` directories to speed up dependency resolution.

**Implementation:**
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

**Cache Configuration Breakdown:**

1. **Cache Paths:**
   - `.build/` — SPM build artifacts and compiled dependencies
   - `.swiftpm/` — Downloaded source packages and metadata
   - **Why both:** Complete dependency state includes both build artifacts and sources

2. **Cache Key:** `${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}`
   - `runner.os` — Linux, macOS, or Windows (ensures OS-specific caches)
   - `spm` — Namespace for Swift Package Manager caches
   - `hashFiles('Package.resolved')` — SHA256 hash of dependency lockfile
   - **Determinism:** Same dependencies = same hash = cache hit
   - **Invalidation:** Dependency changes → new hash → cache miss (intended)

3. **Restore Keys:** `${{ runner.os }}-spm-`
   - **Partial Match:** If exact key misses, restore latest spm cache for this OS
   - **Benefit:** Partial cache hit (some deps already built) vs. cold start
   - **Example:** Package.resolved changes one dependency → 4 out of 5 deps still cached

**Expected Performance:**
- **Cold Cache (First Run):**
  - Download & compile all dependencies: ~90 seconds
  - Save cache: ~10 seconds
  - **Total:** ~100 seconds

- **Warm Cache (Subsequent Runs):**
  - Restore cache: ~8 seconds
  - No dependency downloads
  - **Total:** ~8 seconds
  - **Speedup:** 92% faster (12x improvement)

**Cache Limits:**
- **GitHub Actions:** 10 GB per repository
- **SPM Dependencies (Hyperprompt):** ~200 MB (5 packages)
- **Headroom:** Ample space for multiple cache entries

#### Task 3.2: Add Cache Validation

**Objective:** Verify cache restore success and measure impact.

**Implementation:**
```yaml
- name: Resolve dependencies
  run: |
    echo "Resolving Swift dependencies..."
    time swift package resolve
    echo "Dependencies resolved successfully"

- name: Cache statistics
  if: always()
  run: |
    echo "Build directory size:"
    du -sh .build 2>/dev/null || echo "No .build directory"
    echo "SwiftPM cache size:"
    du -sh .swiftpm 2>/dev/null || echo "No .swiftpm directory"
```

**Why Measure:**
- Validate cache savings over time
- Detect cache bloat (if directories grow unexpectedly)
- Debug cache misses (compare sizes across runs)

---

### 3.4 Phase 4: Workflow Validation (10 minutes)

#### Task 4.1: Validate YAML Syntax

**Objective:** Ensure workflow file is valid before committing.

**Local Validation (Recommended):**
```bash
# Option 1: Use actionlint (best practice)
docker run --rm -v $(pwd):/repo rhysd/actionlint:latest -color /repo/.github/workflows/ci.yml

# Option 2: Use GitHub API
gh api -X POST /repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches
```

**Online Validation:**
- Push to branch and check GitHub Actions UI
- Look for "Invalid workflow file" errors
- Fix and re-push if needed

**Common YAML Pitfalls:**
- Inconsistent indentation (use 2 spaces)
- Missing quotes around version strings ('6.0.3' not 6.0.3)
- Incorrect context syntax (${{ }} vs ${ })
- Deprecated action versions (v3 vs v4)

#### Task 4.2: Add Workflow Comments

**Objective:** Document configuration choices for maintainability.

**Example:**
```yaml
jobs:
  build:
    # Linux-only CI job (macOS/Windows deferred to future tasks)
    # Uses Swift 6.0.3 (compatible with Package.swift minimum 5.9)
    # Caches dependencies based on Package.resolved hash
    runs-on: ubuntu-latest

    steps:
      # actions/checkout@v4: Clone repository with full history
      - name: Checkout code
        uses: actions/checkout@v4

      # swift-actions/setup-swift@v2: Install Swift toolchain
      # Version pinned to 6.0.3 per CI-01 audit findings
      - name: Install Swift 6.0.3
        uses: swift-actions/setup-swift@v2
        with:
          swift-version: '6.0.3'

      # Cache .build and .swiftpm for 60-80% speedup on subsequent runs
      # Cache key includes Package.resolved hash for determinism
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

---

### 3.5 Phase 5: Integration Testing (10 minutes)

#### Task 5.1: Trigger Test Run

**Objective:** Verify workflow executes successfully end-to-end.

**Test Scenarios:**

1. **Cold Cache (First Run):**
   - Create fresh branch
   - Push changes to trigger workflow
   - Verify checkout, Swift install, dependency resolution
   - Check cache save step completes

2. **Warm Cache (Second Run):**
   - Push trivial commit (add comment)
   - Verify cache restore (should be ~8 seconds)
   - Verify no dependency re-downloads

3. **Cache Invalidation:**
   - Modify Package.resolved (simulate dependency update)
   - Push changes
   - Verify cache miss → new cache created

**Success Indicators:**
- ✅ Workflow status: Green checkmark
- ✅ All steps complete without errors
- ✅ Swift version matches 6.0.3
- ✅ Cache save/restore steps log correctly
- ✅ Total job time < 3 minutes (cold), < 1 minute (warm)

#### Task 5.2: Collect Metrics

**Baseline Measurements:**
```
Cold Cache Run:
- Checkout: 5s
- Install Swift: 15s
- Restore cache: 0s (miss)
- Resolve dependencies: 90s
- Save cache: 10s
Total: ~120s

Warm Cache Run:
- Checkout: 5s
- Install Swift: 15s (cached by setup-swift action)
- Restore cache: 8s (hit)
- Resolve dependencies: 2s (already resolved)
- Save cache: 0s (not updated)
Total: ~30s

Speedup: 75% (4x faster)
```

---

## 4. Acceptance Criteria

### 4.1 Required Workflow Configuration (10/10)

**Job Structure:**
- [ ] `runs-on: ubuntu-latest` specified
- [ ] Job name is descriptive ("build" or "linux-build")
- [ ] Steps array contains at least 3 steps (checkout, Swift, cache)

**Checkout Step:**
- [ ] Uses `actions/checkout@v4`
- [ ] Includes `name` field
- [ ] No errors during checkout

**Swift Installation:**
- [ ] Uses `swift-actions/setup-swift@v2`
- [ ] Swift version `6.0.3` explicitly specified
- [ ] Swift executable accessible after step (`swift --version` works)

**Caching Configuration:**
- [ ] Uses `actions/cache@v4`
- [ ] Cache paths include `.build` and `.swiftpm`
- [ ] Cache key includes `runner.os` and `hashFiles('Package.resolved')`
- [ ] Restore keys configured for partial match

### 4.2 Validation & Quality (8/8)

**YAML Syntax:**
- [ ] Workflow file is valid YAML
- [ ] Indentation consistent (2 spaces)
- [ ] All required fields present (name, on, jobs, runs-on, steps)

**Documentation:**
- [ ] Workflow has comments explaining configuration
- [ ] Step names are descriptive
- [ ] Cache strategy documented (inline or in DOCS/CI)

**Testing:**
- [ ] Workflow runs successfully (at least one test run)
- [ ] All steps complete without errors
- [ ] Cache save/restore logs visible in workflow output

**Performance:**
- [ ] Warm cache faster than cold cache (measured)
- [ ] Job setup completes within SLA (< 3 min cold, < 1 min warm)

### 4.3 Integration Readiness (3/3)

**Downstream Tasks:**
- [ ] CI-04 (Static Analysis) can add lint steps after Swift setup
- [ ] CI-05 (Test Step) can add test commands after dependency resolution
- [ ] CI-06 (Retry Wrappers) can wrap dependency install step

---

## 5. GitHub Actions Specifics

### 5.1 Runner Configuration

**Runner:** `ubuntu-latest`
- **Current Version:** Ubuntu 24.04 (as of 2025)
- **Architecture:** x86_64
- **Pre-installed Software:** Git, curl, tar, basic build tools
- **Swift:** Not pre-installed (added by swift-actions/setup-swift)

**Why ubuntu-latest:**
- Matches PRD requirement (Linux-only CI)
- Fast provisioning (< 10 seconds)
- Largest GitHub Actions pool (highest availability)
- Free tier: 2,000 minutes/month (public repos unlimited)

### 5.2 Triggers (From CI-02)

**Already Configured:**
```yaml
on:
  pull_request:
    branches: [main]
    paths: ['Sources/**/*.swift', 'Tests/**/*.swift', 'Package.swift', 'Package.resolved', '.github/workflows/**']
  push:
    branches: [main]
    paths: [same as PR]
  workflow_dispatch:
```

**No Changes Required:** CI-03 uses existing trigger configuration.

### 5.3 Path Filters (From CI-02)

**Triggers Workflow When:**
- Source code changes (`Sources/**/*.swift`)
- Test code changes (`Tests/**/*.swift`)
- Dependencies change (`Package.swift`, `Package.resolved`)
- CI configuration changes (`.github/workflows/**`)

**Skips Workflow When:**
- Documentation changes (`DOCS/**`, `README.md`)
- Non-code files (`.gitignore`, `LICENSE`)

**Benefit:** 40-60% reduction in unnecessary CI runs.

### 5.4 Caching Strategy

**Cache Storage:**
- **Location:** GitHub-hosted cache service
- **Retention:** 7 days since last access
- **Limit:** 10 GB per repository
- **Eviction:** Least recently used (LRU)

**Cache Keys:**
- **Primary Key:** `Linux-spm-<hash of Package.resolved>`
  - Example: `Linux-spm-a3f2b9c8d1e4f5a6b7c8d9e0f1a2b3c4`
- **Restore Keys:** `Linux-spm-` (prefix match)
  - Restores latest cache if exact match fails

**Cache Invalidation:**
- Automatic when Package.resolved changes
- Manual via workflow re-run with "Clear cache" option

### 5.5 Toolchain Installation

**Swift Installation Method:** swift-actions/setup-swift@v2

**Advantages:**
- Downloads from official swift.org CDN
- Caches toolchain across workflow runs
- Version pinning prevents unexpected breakage
- Works on Linux, macOS, Windows

**Installation Steps (Internal to Action):**
1. Check if Swift 6.0.3 already cached
2. If not, download from https://download.swift.org/swift-6.0.3-release/...
3. Extract tarball to runner workspace
4. Add Swift bin directory to PATH
5. Cache toolchain for future runs

**Verification:**
```bash
$ swift --version
Swift version 6.0.3 (swift-6.0.3-RELEASE)
Target: x86_64-unknown-linux-gnu
```

---

## 6. Testing & Validation

### 6.1 Pre-Commit Testing

**Local YAML Validation:**
```bash
# Install actionlint (one-time setup)
brew install actionlint  # macOS
# or
go install github.com/rhysd/actionlint/cmd/actionlint@latest

# Validate workflow file
actionlint .github/workflows/ci.yml
```

**Expected Output:**
```
# No output = validation passed
# Errors/warnings would be shown with line numbers
```

### 6.2 Post-Commit Testing

**Test Sequence:**

1. **Trigger Workflow:**
   ```bash
   # Option A: Push to branch
   git add .github/workflows/ci.yml
   git commit -m "CI-03: Configure Linux job environment"
   git push origin feature/ci-03

   # Option B: Manual dispatch
   gh workflow run ci.yml
   ```

2. **Monitor Execution:**
   ```bash
   # Watch workflow run in real-time
   gh run watch

   # Or view in browser
   gh run list --workflow=ci.yml
   gh run view <run-id> --web
   ```

3. **Verify Steps:**
   - ✅ Checkout: Code cloned successfully
   - ✅ Swift Install: Version 6.0.3 shown in logs
   - ✅ Cache: Save step completes (cold) or restore step hits (warm)
   - ✅ Dependencies: Package.resolved processed

4. **Check Cache:**
   ```bash
   # View cache entries (requires gh CLI)
   gh cache list
   ```

   **Expected:**
   ```
   Linux-spm-a3f2b9c8...  200 MB  2 minutes ago
   ```

### 6.3 Performance Testing

**Benchmarks:**

| Run Type | Checkout | Swift Install | Cache | Resolve Deps | Total |
|----------|----------|---------------|-------|--------------|-------|
| Cold     | 5s       | 15s           | 0s    | 90s          | 110s  |
| Warm     | 5s       | 5s            | 8s    | 2s           | 20s   |

**Acceptance Threshold:**
- Cold cache: < 180s (3 minutes)
- Warm cache: < 60s (1 minute)
- Cache hit rate: > 80% (on subsequent runs)

### 6.4 Failure Scenarios

**Test Error Handling:**

1. **Network Failure During Swift Download:**
   - **Cause:** swift.org CDN unreachable
   - **Expected:** Step fails with clear error message
   - **Mitigation:** Handled in CI-06 (Retry Wrappers)

2. **Cache Corruption:**
   - **Cause:** Partial cache restore
   - **Expected:** Dependency resolution fails → cache invalidated
   - **Recovery:** Next run creates fresh cache

3. **Package.resolved Mismatch:**
   - **Cause:** Dependencies changed but Package.resolved not updated
   - **Expected:** `swift package resolve` updates lockfile
   - **Impact:** Cache key changes → new cache created

---

## 7. Rollback Plan

### 7.1 Rollback Triggers

**When to Rollback:**
- Workflow fails consistently (> 3 runs)
- Job time exceeds 10 minutes (performance regression)
- Swift installation fails (toolchain unavailable)
- Cache issues cause workflow failures

### 7.2 Rollback Procedure

**Step 1: Revert to Placeholder**
```bash
git revert <commit-hash>  # Revert CI-03 changes
git push
```

**Step 2: Restore Placeholder Job**
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Reverted to placeholder due to CI-03 issues"
```

**Step 3: Investigate & Fix**
- Review workflow logs
- Identify failing step
- Test fix locally (if possible)
- Re-apply with fix

### 7.3 Partial Rollback

**If Only Cache Causes Issues:**
```yaml
# Comment out cache step, keep Swift installation
# - name: Cache Swift dependencies
#   uses: actions/cache@v4
#   ...
```

**Impact:**
- Workflow still functional
- Performance degraded (no caching)
- Allows time to debug cache issues

---

## 8. Deliverables Checklist

### 8.1 Primary Deliverable

**File:** `.github/workflows/ci.yml` (updated)

**Required Changes:**
- [ ] Checkout step added (actions/checkout@v4)
- [ ] Swift installation step added (swift-actions/setup-swift@v2)
- [ ] Dependency caching step added (actions/cache@v4)
- [ ] Placeholder step removed or commented out
- [ ] Comments added explaining configuration
- [ ] YAML formatting consistent (2-space indentation)

### 8.2 Validation Deliverables

- [ ] At least one successful workflow run (cold cache)
- [ ] At least one successful workflow run (warm cache)
- [ ] Cache entry visible in GitHub Actions cache list
- [ ] Workflow logs show expected output (Swift version, cache hit/miss)

### 8.3 Documentation Deliverables

- [ ] Inline comments in workflow file
- [ ] Cache strategy documented (in comments or DOCS/CI)
- [ ] CI-03 task marked COMPLETE in Workplan
- [ ] CI-03 task summary created (for archiving)

### 8.4 Handoff to CI-05

**Ready for Next Task When:**
- [ ] Swift compiler available in workflow
- [ ] Dependencies resolved (Package.resolved processed)
- [ ] Build environment stable (no random failures)
- [ ] Performance acceptable (< 3 min cold, < 1 min warm)

---

## 9. Dependencies & Blockers

### 9.1 Upstream Dependencies

**CI-01 (Repository Audit) — ✅ Satisfied**
- Provided: Swift version (6.0.3)
- Provided: Package manager (SPM)
- Provided: Cache strategy (Package.resolved hash)
- Provided: Build commands (swift build, swift test)

**CI-02 (Workflow Triggers) — ✅ Satisfied**
- Provided: Workflow file structure
- Provided: Placeholder job
- Provided: Trigger configuration
- Provided: Path filters

### 9.2 Downstream Dependencies

**CI-05 (Test Step) — Blocked Until CI-03 Complete**
- Needs: Swift compiler installed
- Needs: Dependencies resolved
- Needs: Stable job environment

**CI-04 (Static Analysis) — Blocked Until CI-03 Complete**
- Needs: Swift compiler installed
- Needs: Codebase checked out
- Needs: Lint tools (optional)

**CI-06 (Retry Wrappers) — Optional Dependency**
- Can wrap Swift installation step
- Can wrap dependency resolution step
- Not blocking CI-03 completion

### 9.3 External Dependencies

**swift-actions/setup-swift@v2:**
- **Status:** Stable, actively maintained
- **Risk:** Low (well-tested, widely used)
- **Fallback:** Manual Swift installation (slower)

**actions/cache@v4:**
- **Status:** Official GitHub action
- **Risk:** Very low (core GitHub Actions feature)
- **Fallback:** Skip caching (performance hit, but functional)

**swift.org CDN:**
- **Status:** Reliable, backed by Apple
- **Risk:** Low (99.9% uptime)
- **Mitigation:** CI-06 will add retry logic

---

## 10. References

### 10.1 Task Documentation

- **CI-03 PRD (this file):** Implementation specification
- **CI-02 Summary:** `/DOCS/CI/TASKS_ARCHIVE/CI-02-summary.md`
- **CI-01 Audit Report:** `/DOCS/CI/audit-report.md`
- **CI Workplan:** `/DOCS/CI/Workplan.md`
- **CI PRD:** `/DOCS/CI/PRD.md`

### 10.2 GitHub Actions Documentation

- **Workflow Syntax:** https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
- **actions/checkout:** https://github.com/actions/checkout
- **actions/cache:** https://github.com/actions/cache
- **Caching Dependencies:** https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows

### 10.3 Swift & SPM References

- **swift-actions/setup-swift:** https://github.com/swift-actions/setup-swift
- **Swift Downloads:** https://www.swift.org/download/
- **SPM Documentation:** https://github.com/apple/swift-package-manager/blob/main/Documentation/Usage.md
- **Package.resolved Format:** https://github.com/apple/swift-package-manager/blob/main/Documentation/PackageDescription.md#packageresolved-file

### 10.4 Related Hyperprompt Files

- **Package.swift:** `/home/user/Hyperprompt/Package.swift`
- **Package.resolved:** `/home/user/Hyperprompt/Package.resolved`
- **Workflow File:** `/home/user/Hyperprompt/.github/workflows/ci.yml`

---

## 11. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-04 | Claude (via PLAN command) | Initial PRD generated from CI-03 task |

---

## 12. Appendix: Complete Workflow Example

### 12.1 Final ci.yml (After CI-03)

```yaml
name: CI

# CI workflow for Hyperprompt Swift compiler
# Triggers on PR, push to main, and manual dispatch
# Runs on Linux (ubuntu-latest) with Swift 6.0.3

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
    # Linux-only CI job (macOS/Windows deferred to future tasks)
    # Uses Swift 6.0.3 (compatible with Package.swift minimum 5.9)
    # Caches dependencies based on Package.resolved hash
    runs-on: ubuntu-latest

    steps:
      # Clone repository with full git history
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      # Install Swift 6.0.3 toolchain
      # Version pinned per CI-01 audit findings
      - name: Install Swift 6.0.3
        uses: swift-actions/setup-swift@v2
        with:
          swift-version: '6.0.3'

      # Verify Swift installation
      - name: Verify Swift version
        run: |
          swift --version
          swift --version | grep -q "6.0.3"

      # Cache .build and .swiftpm for 60-80% speedup on subsequent runs
      # Cache key includes Package.resolved hash for deterministic invalidation
      - name: Cache Swift dependencies
        uses: actions/cache@v4
        with:
          path: |
            .build
            .swiftpm
          key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
          restore-keys: |
            ${{ runner.os }}-spm-

      # Resolve Swift Package Manager dependencies
      - name: Resolve dependencies
        run: |
          echo "Resolving Swift dependencies..."
          swift package resolve
          echo "Dependencies resolved successfully"

      # Display cache statistics for debugging
      - name: Cache statistics
        if: always()
        run: |
          echo "Build directory size:"
          du -sh .build 2>/dev/null || echo "No .build directory yet"
          echo "SwiftPM cache size:"
          du -sh .swiftpm 2>/dev/null || echo "No .swiftpm directory yet"

      # Placeholder for CI-05: Build and test steps will be added here
      - name: Next steps
        run: echo "CI-03 complete. CI-05 will add build and test steps."
```

### 12.2 Expected Workflow Run Output

**Cold Cache Run:**
```
✓ Checkout code (5s)
✓ Install Swift 6.0.3 (15s)
✓ Verify Swift version (1s)
  Swift version 6.0.3 (swift-6.0.3-RELEASE)
  Target: x86_64-unknown-linux-gnu
✓ Cache Swift dependencies (1s)
  Cache not found for key: Linux-spm-a3f2b9c8...
✓ Resolve dependencies (90s)
  Fetching https://github.com/apple/swift-argument-parser
  Fetching https://github.com/apple/swift-crypto
  ...
  Dependencies resolved successfully
✓ Cache Swift dependencies (Post) (10s)
  Cache saved successfully
✓ Cache statistics (1s)
  Build directory size: 195M
  SwiftPM cache size: 12M
✓ Next steps (1s)

Total: 124 seconds
```

**Warm Cache Run:**
```
✓ Checkout code (5s)
✓ Install Swift 6.0.3 (5s)
  Using cached Swift toolchain
✓ Verify Swift version (1s)
✓ Cache Swift dependencies (8s)
  Cache restored from key: Linux-spm-a3f2b9c8...
✓ Resolve dependencies (2s)
  All dependencies up to date
✓ Cache statistics (1s)
  Build directory size: 195M
  SwiftPM cache size: 12M
✓ Next steps (1s)

Total: 23 seconds

Speedup: 81% faster (5.4x improvement)
```

---

**END OF PRD**

---

**Archived:** 2025-12-04

# PRD: CI-05 — Add Build and Test Steps

**Task ID:** CI-05
**Priority:** High
**Phase:** Phase 3: Quality Gates
**Estimated Effort:** 1 hour
**Dependencies:** CI-03 (completed)
**Status:** In Progress

---

## 1. Context

### 1.1 Current State

The CI workflow (`.github/workflows/ci.yml`) currently:
- ✅ Sets up Swift 6.0.3 toolchain (CI-03)
- ✅ Configures dependency caching (CI-03)
- ✅ Resolves Swift Package Manager dependencies (CI-03)
- ❌ **Does NOT build the project**
- ❌ **Does NOT run tests**
- ❌ **Does NOT upload artifacts on failure**

**Problem:** CI passes even if code doesn't compile or tests fail.

### 1.2 Background

From CI-01 audit report:
- **Language:** Swift 6.0.3
- **Build Command:** `swift build` (debug) or `swift build -c release` (release)
- **Test Command:** `swift test --parallel`
- **Test Framework:** XCTest (Swift standard)
- **Current Tests:** Implemented (39 test cases in Core module as of A2)
- **Build Time:** ~20 seconds cold, ~10 seconds warm cache
- **Test Time:** ~10 seconds

### 1.3 Integration Point

This task adds steps **after** line 82 in `.github/workflows/ci.yml`:
```yaml
# Current placeholder (lines 83-85):
- name: Next steps
  run: echo "CI-03 complete. CI-05 will add build and test steps."
```

This placeholder will be **replaced** with build, test, and artifact upload steps.

---

## 2. Objectives

### 2.1 Primary Goals

1. **Verify Compilation:** Ensure all Swift code compiles without errors on every PR/push
2. **Execute Tests:** Run all test suites and report results
3. **Fail Fast:** Stop workflow on build errors (prevent running tests on broken code)
4. **Preserve Evidence:** Upload test artifacts on failure for debugging

### 2.2 Success Metrics

- ✅ CI fails when code doesn't compile
- ✅ CI fails when tests fail
- ✅ Build time remains ≤ 30 seconds (cold), ≤ 15 seconds (warm)
- ✅ Test artifacts available for download on failure
- ✅ Clear error messages in workflow logs

### 2.3 Non-Goals (Deferred)

- Code coverage reporting (future enhancement)
- Performance benchmarks (not in scope)
- Release builds (this task uses debug builds for speed)
- Multiple Swift versions (only 6.0.3 tested)

---

## 3. Implementation Plan

### 3.1 Step 1: Add Build Step

**Location:** Replace placeholder at lines 83-85 in `.github/workflows/ci.yml`

**Implementation:**
```yaml
# Build the Swift package
- name: Build
  run: |
    echo "Building Swift package..."
    swift build --build-tests
    echo "Build completed successfully"
```

**Rationale:**
- `swift build --build-tests` compiles both main code and test targets
- Faster than separate `swift build` + test compilation
- Fails workflow immediately if compilation errors occur
- Echo statements provide clear progress in logs

**Verification:**
- Check `.build/debug/` contains compiled binaries
- Workflow fails on syntax errors, type errors, missing imports

### 3.2 Step 2: Add Test Execution Step

**Location:** Immediately after Build step

**Implementation:**
```yaml
# Run tests with parallel execution
- name: Run tests
  run: |
    echo "Running Swift tests..."
    swift test --parallel
    echo "Tests completed successfully"
```

**Rationale:**
- `--parallel` flag speeds up test execution (utilize multiple cores)
- Fails workflow if any test fails
- Clear output with echo statements

**Verification:**
- All 39 tests in CoreTests execute
- Workflow fails if any test fails
- Test results visible in workflow logs

### 3.3 Step 3: Add Artifact Upload (On Failure)

**Location:** After test step

**Implementation:**
```yaml
# Upload test results and build artifacts on failure
- name: Upload test results
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: test-results-${{ github.run_id }}
    path: |
      .build/debug/*.xctest
      .build/**/*.swiftmodule
      .build/debug.yaml
    retention-days: 7
    if-no-files-found: warn
```

**Rationale:**
- `if: failure()` ensures artifacts only uploaded on errors (saves storage)
- `${{ github.run_id }}` creates unique artifact names (avoid conflicts)
- Includes test bundles (`.xctest`) and debug info
- 7-day retention balances storage vs debugging needs
- `if-no-files-found: warn` prevents workflow failure if artifacts missing

**Verification:**
- Artifacts appear in workflow run on failure
- Downloadable via GitHub UI
- Contains expected test bundles

### 3.4 Step 4: Add Summary Output

**Location:** After all test steps

**Implementation:**
```yaml
# Display build summary
- name: Build summary
  if: always()
  run: |
    echo "================================"
    echo "Build and Test Summary"
    echo "================================"
    echo "Build: $([ -f .build/debug/hyperprompt ] && echo '✓ SUCCESS' || echo '✗ FAILED')"
    echo "Tests: $([ $? -eq 0 ] && echo '✓ PASSED' || echo '✗ FAILED')"
    echo "Artifacts: $(ls .build/debug/*.xctest 2>/dev/null | wc -l) test bundles"
    echo "================================"
```

**Rationale:**
- `if: always()` ensures summary shows even on failure
- Provides quick status overview in logs
- Helps identify which stage failed

---

## 4. Complete YAML Snippet

**Replace lines 83-85 with:**

```yaml
# Build the Swift package
- name: Build
  run: |
    echo "Building Swift package..."
    swift build --build-tests
    echo "Build completed successfully"

# Run tests with parallel execution
- name: Run tests
  run: |
    echo "Running Swift tests..."
    swift test --parallel
    echo "Tests completed successfully"

# Upload test results and build artifacts on failure
- name: Upload test results
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: test-results-${{ github.run_id }}
    path: |
      .build/debug/*.xctest
      .build/**/*.swiftmodule
      .build/debug.yaml
    retention-days: 7
    if-no-files-found: warn

# Display build summary
- name: Build summary
  if: always()
  run: |
    echo "================================"
    echo "Build and Test Summary"
    echo "================================"
    echo "Build artifacts:"
    ls -lh .build/debug/ 2>/dev/null || echo "No build artifacts"
    echo "================================"
```

---

## 5. Acceptance Criteria

### 5.1 Functional Requirements

- [ ] Build step compiles all Swift code without errors
- [ ] Build step uses `--build-tests` flag
- [ ] Test step executes with `--parallel` flag
- [ ] Test step runs all test suites (CoreTests currently)
- [ ] Workflow fails if build errors occur
- [ ] Workflow fails if test failures occur
- [ ] Artifacts uploaded only on failure
- [ ] Artifacts include `.xctest` bundles
- [ ] Build summary displays on success and failure

### 5.2 Performance Requirements

- [ ] Build time ≤ 30 seconds (cold cache)
- [ ] Build time ≤ 15 seconds (warm cache)
- [ ] Test execution ≤ 20 seconds
- [ ] Total workflow time ≤ 3 minutes (cold), ≤ 90 seconds (warm)

### 5.3 Quality Requirements

- [ ] Clear error messages on build failures
- [ ] Test output shows which tests failed
- [ ] Artifact names include run ID (no conflicts)
- [ ] Logs show progress with echo statements
- [ ] Summary step always runs (`if: always()`)

### 5.4 Integration Requirements

- [ ] Compatible with existing CI-03 setup (Swift 6.0.3, caching)
- [ ] Uses artifacts from dependency resolution step
- [ ] Does not break existing triggers or path filters
- [ ] Works with cache from CI-03 (`.build/`, `.swiftpm/`)

---

## 6. GitHub Actions Specifics

### 6.1 Runner Configuration

- **OS:** ubuntu-latest (Ubuntu 24.04)
- **Swift Version:** 6.0.3 (installed by CI-03)
- **Working Directory:** Repository root
- **Shell:** bash (default)

### 6.2 Triggers

**Inherited from CI-02:**
- Pull requests to `main` (with path filters)
- Pushes to `main` (with path filters)
- Manual dispatch via `workflow_dispatch`

**Path Filters (from CI-02):**
```yaml
paths:
  - 'Sources/**/*.swift'
  - 'Tests/**/*.swift'
  - 'Package.swift'
  - 'Package.resolved'
  - '.github/workflows/**'
```

### 6.3 Caching Strategy

**Inherited from CI-03:**
- Cache key: `${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}`
- Cached paths: `.build/`, `.swiftpm/`
- Restore keys: `${{ runner.os }}-spm-`

**Impact on CI-05:**
- Warm cache speeds up `swift build` (reuses compiled dependencies)
- Cold cache requires full build (~20 seconds)
- Cache invalidates when `Package.resolved` changes

### 6.4 Dependencies

**Prerequisites (from CI-03):**
1. ✅ Repository checked out (`actions/checkout@v4`)
2. ✅ Swift 6.0.3 installed (`swift-actions/setup-swift@v2`)
3. ✅ Dependencies cached (`actions/cache@v4`)
4. ✅ Dependencies resolved (`swift package resolve`)

**CI-05 builds upon this foundation.**

### 6.5 Artifacts

**Upload Strategy:**
- **Trigger:** `if: failure()` (only on errors)
- **Action:** `actions/upload-artifact@v4`
- **Name:** `test-results-${{ github.run_id }}`
- **Retention:** 7 days
- **Size Estimate:** 5-20 MB (test bundles + debug symbols)

**Download:**
- Available via GitHub UI: Actions → Workflow Run → Artifacts
- Download as ZIP file
- Contains: `.xctest` bundles, `.swiftmodule` files, `debug.yaml`

---

## 7. Testing & Validation

### 7.1 Pre-Commit Validation

**Before creating PR:**
1. Test YAML syntax:
   ```bash
   # Install actionlint (GitHub Actions linter)
   brew install actionlint  # macOS
   # OR
   go install github.com/rhysd/actionlint/cmd/actionlint@latest

   # Lint workflow file
   actionlint .github/workflows/ci.yml
   ```

2. Verify local build:
   ```bash
   swift build --build-tests
   swift test --parallel
   ```

### 7.2 Post-Commit Validation

**After PR created:**
1. ✅ Check CI workflow runs automatically
2. ✅ Verify build step completes (green checkmark)
3. ✅ Verify test step completes (green checkmark)
4. ✅ Check workflow logs for echo statements
5. ✅ Verify total runtime ≤ 3 minutes (cold cache)

**Test failure scenario:**
1. Introduce intentional test failure in CoreTests
2. Push to PR branch
3. ✅ Verify CI fails at test step (not build)
4. ✅ Verify artifacts uploaded
5. ✅ Download artifacts and inspect `.xctest` bundles
6. Revert failure and verify CI passes

**Test build failure scenario:**
1. Introduce syntax error in Sources/Core/SourceLocation.swift
2. Push to PR branch
3. ✅ Verify CI fails at build step
4. ✅ Verify test step does NOT run (fail fast)
5. ✅ Verify clear error message in logs
6. Revert error and verify CI passes

### 7.3 Performance Validation

**Measure workflow times:**
```bash
# Check recent workflow runs
gh run list --workflow=ci.yml --limit 10

# View timing for specific run
gh run view <run-id> --log
```

**Expected times:**
- **Cold cache:** Build 20s + Test 10s + Overhead 30s = ~60s total
- **Warm cache:** Build 10s + Test 5s + Overhead 15s = ~30s total
- **Acceptable:** ≤ 3 minutes cold, ≤ 90 seconds warm

---

## 8. Rollback Plan

### 8.1 If CI Breaks

**Symptoms:**
- All PRs fail at build/test step
- Workflow timeout (>10 minutes)
- Artifacts not uploaded
- Cache corruption

**Immediate Actions:**
1. Revert `.github/workflows/ci.yml` to previous version:
   ```bash
   git revert <commit-sha>
   git push
   ```

2. Or restore placeholder:
   ```yaml
   - name: Next steps
     run: echo "CI-05 rolled back. Build/test steps disabled."
   ```

### 8.2 Partial Rollback

**If only artifacts fail:**
- Comment out artifact upload step
- Keep build and test steps
- File issue to fix artifacts

**If tests timeout:**
- Remove `--parallel` flag temporarily
- Investigate slow tests
- Re-enable parallel after fix

### 8.3 Cache Reset

**If cache causes issues:**
```bash
# Manually clear cache via GitHub UI:
# Settings → Actions → Management → Caches
# Or change cache key temporarily:
key: ${{ runner.os }}-spm-v2-${{ hashFiles('Package.resolved') }}
```

---

## 9. Future Enhancements (Post-CI-05)

### 9.1 Code Coverage (CI-06 or later)

```yaml
- name: Test with coverage
  run: swift test --enable-code-coverage

- name: Upload coverage
  uses: codecov/codecov-action@v4
  with:
    files: .build/debug/codecov/*.profdata
```

### 9.2 Matrix Testing (Multiple Swift Versions)

```yaml
strategy:
  matrix:
    swift-version: ['5.9', '6.0.3']
    os: [ubuntu-latest]
```

### 9.3 Release Builds

```yaml
- name: Build release
  if: github.ref == 'refs/heads/main'
  run: swift build -c release

- name: Upload release binary
  uses: actions/upload-artifact@v4
  with:
    name: hyperprompt-linux
    path: .build/release/hyperprompt
```

---

## 10. Documentation Updates

### 10.1 Update CI README

**File:** `DOCS/CI/README.md` (to be created in CI-08)

**Content to add:**
```markdown
## Build and Test Steps (CI-05)

The CI workflow builds and tests the project on every PR and push to main.

### Commands Used
- Build: `swift build --build-tests`
- Test: `swift test --parallel`

### Artifacts
On failure, test bundles are uploaded for debugging:
- Navigate to Actions → Failed Run → Artifacts
- Download `test-results-<run-id>.zip`
- Contains: `.xctest` bundles and debug symbols

### Troubleshooting
- **Build fails:** Check compiler errors in build step logs
- **Tests fail:** Check test output in test step logs
- **Artifacts missing:** Verify `.build/debug/` exists
```

### 10.2 Update Workplan

**Mark CI-05 as complete** when all acceptance criteria met.

---

## 11. Dependencies & Risks

### 11.1 Dependencies

| Dependency | Status | Impact |
|------------|--------|--------|
| CI-01 (Audit) | ✅ Complete | Provides build/test commands |
| CI-02 (Triggers) | ✅ Complete | Defines when CI runs |
| CI-03 (Environment) | ✅ Complete | Installs Swift, caches deps |

### 11.2 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Tests timeout | Low | High | Use `--parallel`, investigate slow tests |
| Cache corruption | Low | Medium | Add cache reset step in rollback plan |
| Artifact storage cost | Low | Low | 7-day retention, only on failure |
| Swift version incompatibility | Very Low | High | Pinned to 6.0.3 in CI-03 |

### 11.3 Assumptions

- ✅ Swift 6.0.3 compatible with all code
- ✅ Tests are deterministic (no flaky tests)
- ✅ `.build/` directory writable by workflow
- ✅ GitHub Actions artifact storage available

---

## 12. Exit Criteria

This task is complete when:

1. ✅ All acceptance criteria (§5) checked off
2. ✅ Build step added to `.github/workflows/ci.yml`
3. ✅ Test step added to `.github/workflows/ci.yml`
4. ✅ Artifact upload configured
5. ✅ CI passes on clean PR (no errors)
6. ✅ CI fails on intentional build error (tested)
7. ✅ CI fails on intentional test failure (tested)
8. ✅ Artifacts downloadable on failure
9. ✅ Performance requirements met (≤3min cold, ≤90s warm)
10. ✅ Changes committed and pushed
11. ✅ Workplan updated (CI-05 marked complete)
12. ✅ Ready for CI-07 (permissions) or CI-10 (branch protection)

---

## 13. References

### 13.1 Internal Documentation

- **CI Audit Report:** `DOCS/CI/audit-report.md`
- **CI Workplan:** `DOCS/CI/Workplan.md`
- **CI PRD:** `DOCS/CI/PRD.md`
- **Current Workflow:** `.github/workflows/ci.yml`

### 13.2 External Resources

- **Swift Package Manager:** https://github.com/apple/swift-package-manager
- **GitHub Actions Documentation:** https://docs.github.com/en/actions
- **actions/upload-artifact:** https://github.com/actions/upload-artifact
- **swift-actions/setup-swift:** https://github.com/swift-actions/setup-swift
- **XCTest Framework:** https://developer.apple.com/documentation/xctest

### 13.3 Related Tasks

- **CI-03:** Environment setup (prerequisite)
- **CI-04:** Static analysis (parallel, optional)
- **CI-06:** Retry wrappers (enhancement)
- **CI-07:** Permissions and secrets (follow-up)
- **CI-10:** Branch protection (depends on CI-05)

---

## 14. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-05 | Claude (PLAN Command) | Initial PRD generated from CI-05 task |

---

**Status:** Ready for implementation
**Next Step:** Execute this PRD using DOCS/CI/COMMANDS/EXECUTE.md

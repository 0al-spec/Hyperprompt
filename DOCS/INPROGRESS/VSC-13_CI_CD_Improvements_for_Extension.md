# PRD: VSC-13 — CI/CD Improvements for Extension

## 1. Scope and Intent

### Objective
Improve the CI/CD pipeline for the VS Code extension to enhance robustness, visibility, and build reproducibility. This includes removing PR-only restrictions, adding dependency caching, splitting CI steps for better observability, and verifying VSIX packaging.

### Deliverables
- Modified `.github/workflows/ci.yml` with improved `vscode-extension-tests` job configuration
- Node.js dependency caching for faster builds
- Separate CI steps for lint, compile, and test
- `npm ci` used instead of `npm install` for reproducible builds
- VSIX packaging verification step
- Updated CI documentation in `Tools/VSCodeExtension/README.md`

### Success Criteria
- ✅ CI runs on all events (PR, push to main, workflow_dispatch)
- ✅ Node.js dependencies cached for faster builds (30-50% speedup expected)
- ✅ Separate steps for lint, compile, and test in CI output
- ✅ `npm ci` used instead of `npm install`
- ✅ VSIX packaging verification added (catches packaging errors early)
- ✅ CI documentation updated in extension README

### Constraints and Assumptions
- VS Code extension tests require Xvfb for headless testing
- Extension already has working test suite (VSC-11 complete)
- CI uses ubuntu-latest runner
- Node.js 20 is the target version

### External Dependencies
- GitHub Actions: `actions/setup-node@v4` with cache support
- VS Code Extension CLI: `@vscode/vsce` for packaging

---

## 2. Structured TODO Plan

### Phase A — Remove PR-Only Restriction
1. **Remove event restriction**
   - Remove `if: github.event_name == 'pull_request'` from `vscode-extension-tests` job
   - Allows CI to run on push to main and manual dispatch

### Phase B — Add Node.js Caching
2. **Add caching to setup-node**
   - Update `actions/setup-node@v4` to include `cache: 'npm'`
   - Specify `cache-dependency-path: Tools/VSCodeExtension/package-lock.json`

### Phase C — Split CI Steps
3. **Add separate lint step**
   - Add step: `npm run lint` before compile

4. **Add separate compile step**
   - Add step: `npm run compile` before test

5. **Keep existing test step**
   - Existing test step remains unchanged

### Phase D — Use npm ci
6. **Replace npm install with npm ci**
   - Change `npm install` to `npm ci` in install dependencies step
   - Ensures reproducible builds from package-lock.json

### Phase E — Add VSIX Verification
7. **Add VSIX packaging step**
   - Install `@vscode/vsce` globally or locally
   - Run `vsce package` to verify extension packages correctly
   - Upload VSIX as artifact for debugging

### Phase F — Update Documentation
8. **Update CI documentation**
   - Document CI behavior (triggers, caching, steps) in `Tools/VSCodeExtension/README.md`
   - Add troubleshooting section for common CI failures

---

## 3. Subtask Metadata

| ID | Task | Priority | Effort | Dependencies | Tools/Modules | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Remove event restriction | High | 0.1h | None | ci.yml | Job runs on push/dispatch |
| B1 | Add Node.js caching | High | 0.2h | None | ci.yml | Cache restored on subsequent runs |
| C1 | Add separate lint step | High | 0.1h | None | ci.yml | Lint step visible in CI output |
| C2 | Add separate compile step | High | 0.1h | None | ci.yml | Compile step visible in CI output |
| C3 | Keep existing test step | High | 0.05h | C2 | ci.yml | Test step runs after compile |
| D1 | Replace npm install with npm ci | High | 0.1h | None | ci.yml | Reproducible builds verified |
| E1 | Add VSIX packaging step | Medium | 0.3h | C2 | ci.yml | VSIX builds successfully |
| F1 | Update CI documentation | Medium | 0.5h | All | README.md | CI documented clearly |

**Total Estimated Effort:** ~1.5 hours

---

## 4. Feature Description and Rationale

The current `vscode-extension-tests` job has several limitations that reduce its effectiveness:

1. **PR-only restriction**: Extension tests only run on PRs, missing issues in main branch pushes
2. **No dependency caching**: Every run downloads all Node.js dependencies from scratch (~30s overhead)
3. **Monolithic test step**: Lint, compile, and test run in one step, making failures harder to diagnose
4. **npm install inconsistency**: Uses `npm install` which can produce non-reproducible builds
5. **No VSIX verification**: Packaging errors only discovered manually before release

This task addresses all five limitations to improve CI robustness and developer experience.

---

## 5. Functional Requirements

1. **FR-1**: CI must run on all trigger events (pull_request, push to main, workflow_dispatch)
2. **FR-2**: Node.js dependencies must be cached using `actions/setup-node` cache feature
3. **FR-3**: Lint, compile, and test must be separate visible steps in CI output
4. **FR-4**: Dependency installation must use `npm ci` for reproducible builds
5. **FR-5**: VSIX packaging must be verified in CI before merging
6. **FR-6**: CI documentation must be updated to reflect new behavior

---

## 6. Non-Functional Requirements

- **Performance**: Node.js caching should reduce CI time by 30-50% for cached runs
- **Observability**: Separate steps should make it immediately clear which phase failed (lint/compile/test/package)
- **Reproducibility**: `npm ci` ensures consistent builds across environments
- **Maintainability**: Documentation should be clear enough for contributors to understand CI behavior

---

## 7. Edge Cases and Failure Scenarios

| Scenario | Expected Behavior |
| --- | --- |
| package-lock.json missing | `npm ci` fails with clear error (better than silent npm install fallback) |
| VSIX packaging fails | CI fails early, preventing merge of broken extension |
| Cache miss (new dependencies) | Full dependency install, subsequent runs cache |
| Lint failure | Fails at lint step, doesn't waste time on compile/test |
| Compile failure | Fails at compile step, doesn't run tests |
| Test failure | Fails at test step, VSIX not packaged |

---

## 8. Verification Checklist

- [ ] Remove `if: github.event_name == 'pull_request'` from ci.yml
- [ ] Add `cache: 'npm'` to setup-node step
- [ ] Add separate lint step (`npm run lint`)
- [ ] Add separate compile step (`npm run compile`)
- [ ] Replace `npm install` with `npm ci`
- [ ] Add VSIX packaging verification step
- [ ] Update `Tools/VSCodeExtension/README.md` with CI documentation
- [ ] Verify CI runs on push to main
- [ ] Verify CI runs on workflow_dispatch
- [ ] Verify cache is restored on second run
- [ ] Verify lint failure stops pipeline early
- [ ] Verify VSIX builds successfully

---

## 9. Implementation Notes

### Current State (ci.yml lines 212-248)
```yaml
vscode-extension-tests:
  name: CI - VS Code Extension Tests
  runs-on: ubuntu-latest
  if: github.event_name == 'pull_request'  # ❌ Remove this

  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        # ❌ Missing: cache: 'npm'

    - name: Install dependencies
      run: npm install  # ❌ Should be: npm ci
```

### Target State
```yaml
vscode-extension-tests:
  name: CI - VS Code Extension Tests
  runs-on: ubuntu-latest
  # ✅ No event restriction

  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'  # ✅ Added
        cache-dependency-path: Tools/VSCodeExtension/package-lock.json

    - name: Install dependencies
      run: npm ci  # ✅ Changed

    - name: Lint
      run: npm run lint  # ✅ New step

    - name: Compile
      run: npm run compile  # ✅ New step

    - name: Run extension tests
      run: # ... existing test logic

    - name: Package extension
      run: npm exec -- vsce package  # ✅ New step
```

---

**Status:** Ready to execute
**Dependencies:** VSC-11 ✅, VSC-12 ✅
**Blocks:** None (quality improvement)

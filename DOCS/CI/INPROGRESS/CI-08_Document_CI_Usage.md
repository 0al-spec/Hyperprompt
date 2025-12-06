# CI-08 — Document CI Usage

## 1. Context
- **Phase:** Validation & Docs
- **Priority:** High
- **Dependencies:** CI-02 (workflow triggers), CI-03 (job environment), CI-04 (static analysis), CI-05 (tests), CI-06 (retries), CI-07 (permissions & secrets)
- **Effort:** 0.5 hours

## 2. Objectives
Create comprehensive documentation in `DOCS/CI/README.md` that explains:
1. GitHub Actions CI workflow structure and purpose
2. How the workflow is triggered and what it validates
3. Configuration variables and how to customize them
4. How developers can extend the workflow for other OSes/toolchains
5. Troubleshooting guide for common CI failures
6. Caching strategy and performance characteristics

## 3. Implementation Plan

### Step 1: Review Existing CI Implementation
- Understand the current `.github/workflows/ci.yml` configuration
- Document all environment variables, paths, and triggers
- Identify customizable parameters and defaults

### Step 2: Create DOCS/CI/README.md Structure
Create sections for:
- **Overview:** What the CI does and why
- **Workflow Triggers:** When and why the workflow runs
- **Job Stages:** Purpose and configuration of each stage
- **Caching Strategy:** How dependencies are cached and cache invalidation
- **Customization Guide:** How to modify versions, paths, scripts
- **Troubleshooting:** Common failure modes and solutions
- **Extending to Other OSes:** Architecture for macOS/Windows additions

### Step 3: Document Configuration Variables
Include:
- Swift version (currently 6.0.3)
- Package manager configuration (Swift Package Manager)
- Cache keys and their purpose
- Artifact retention policies
- Path filters for trigger conditions

### Step 4: Add Usage Examples
Provide:
- How to manually trigger the workflow
- How to view logs and artifacts
- How to check cache hits/misses
- How to add new test categories or builds

### Step 5: Integration Notes
Document:
- Relationship to branch protection rules (CI-10)
- How to interpret job failure messages
- Role of status checks in merge blocking

## 4. Acceptance Criteria

From Workplan:
- [ ] Documentation explains workflow structure and customization for developers

Additional validation:
- [ ] `DOCS/CI/README.md` exists and is accessible from DOCS/CI index
- [ ] All workflow stages (checkout, toolchain setup, caching, build, test, artifacts) are documented
- [ ] Configuration variables (Swift version, cache keys, paths) are clearly listed
- [ ] Customization instructions include step-by-step examples
- [ ] Troubleshooting section covers at least 3 common failure scenarios
- [ ] Documentation is cross-linked to relevant workflow files
- [ ] Extension guidance for other OSes is included
- [ ] Links to GitHub Actions documentation provided where applicable

## 5. GitHub Actions Specifics

- **Runner:** ubuntu-latest (Linux-only, other OSes documented as future additions)
- **Triggers:**
  - Pull requests to main branch on source/workflow changes
  - Pushes to main branch on source/workflow changes
  - Manual dispatch (`workflow_dispatch`)
- **Path Filters:** `Sources/**/*.swift`, `Tests/**/*.swift`, `Package.swift`, `Package.resolved`, `.github/workflows/**`
- **Caching Strategy:**
  - Caches `.build` and `.swiftpm` directories
  - Cache key based on `Package.resolved` hash for deterministic invalidation
  - 60-80% speedup on cache hits
- **Toolchain:** Swift 6.0.3 via `swift-actions/setup-swift@v2`
- **Permissions:** Read-only (least privilege)

## 6. Testing & Validation

How to verify the documentation:
1. **Readability:** Have another developer review for clarity and completeness
2. **Accuracy:** Cross-check all code examples with actual workflow file
3. **Usefulness:** Verify new developers can customize workflow using only the docs
4. **Links:** Ensure all relative links to workflow files and other docs work
5. **Examples:** Test that code snippets are syntactically correct

## 7. Rollback Plan

If documentation is incomplete or misleading:
1. **Revert:** Delete `DOCS/CI/README.md` and restore from previous version
2. **Fix Issues:** Address reviewer feedback in a follow-up task
3. **Re-deploy:** Create new PR with updated documentation
4. **Notify:** Alert team in Slack/GitHub if developers followed incorrect guidance

---

**Task Owner:** Development
**Estimated Time:** 0.5 hours
**Status:** Ready for EXECUTE phase

# Next Task: CI-02 — Define Workflow Triggers

**Priority:** High
**Phase:** Workflow Skeleton
**Effort:** 0.5 hours
**Dependencies:** CI-01 (Repository Audit) ✅ Completed
**Status:** ✅ Completed on 2025-12-04

## Description

Define and implement GitHub Actions workflow triggers for the Hyperprompt CI pipeline: pull request triggers, push triggers, and manual dispatch capability with path filters for source code and GitHub Actions files.

## Deliverables

✅ Created `.github/workflows/ci.yml` with:
- Pull request triggers targeting main branch
- Push triggers targeting main branch
- Manual dispatch capability
- Path filters for Swift source files, tests, and Package files
- Placeholder job for CI-03

## Acceptance Criteria

✅ All 23 acceptance criteria passed:
- File structure (4/4)
- Trigger configuration (5/5)
- Path filters (7/7)
- Documentation (5/5)
- Validation (2/2)

## Next Step

Run SELECT command to choose next CI task:
```
$ claude "Выполни команду SELECT для CI"
```

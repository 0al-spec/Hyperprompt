# Next Task: VSC-13 — CI/CD Improvements for Extension

**Priority:** [P1]
**Phase:** Phase 14 (VS Code Extension Development)
**Effort:** 2 hours
**Dependencies:** VSC-11 ✅, VSC-12 ✅
**Status:** ✅ Completed on 2025-12-30

## Description

Improve CI/CD pipeline for VS Code extension to enhance robustness, visibility, and build reproducibility. This includes removing PR-only restrictions, adding dependency caching, splitting CI steps for better observability, and verifying VSIX packaging.

## Acceptance Criteria

- ✅ CI runs on all events (PR, push to main, workflow_dispatch) — VERIFIED
- ✅ Node.js dependencies cached for faster builds — VERIFIED
- ✅ Separate steps for lint, compile, and test — VERIFIED
- ✅ `npm ci` used instead of `npm install` — VERIFIED
- ✅ VSIX packaging verification added — VERIFIED
- ✅ CI documentation updated in extension README — VERIFIED

## Implementation Tasks

1. **Remove PR-only restriction** — Allow CI to run on push and manual dispatch
2. **Add Node.js caching** — Use `actions/setup-node` with cache option
3. **Split CI steps** — Separate lint, compile, test for visibility
4. **Use npm ci** — Replace `npm install` for reproducible builds
5. **Add VSIX verification** — Ensure extension packages correctly
6. **Update documentation** — Document CI behavior in README

## Next Step

Run PLAN command to create detailed PRD:
```bash
$ claude "Выполни команду PLAN"
```

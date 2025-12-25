# Next Task: VSC-3 — Extension Scaffold (Dev Host Validation)

**Priority:** P0
**Phase:** Phase 11: VS Code Extension Development
**Effort:** 1 hour
**Dependencies:** VSC-2A or VSC-2B or VSC-2C
**Status:** ✅ Completed on 2025-12-26

## Description

Validate the VS Code extension loads in the dev host and document the Editor RPC CLI setup.

## Flow Steps (Tracker)

- [x] SELECT
- [x] PLAN
- [x] INSTALL_SWIFT
- [x] EXECUTE
- [x] PROGRESS (optional)
- [ ] ARCHIVE

## Mini TODO (Tracker)

- [x] A1: Fix editor-rpc wiring for Editor trait builds
- [x] A2: Document dev-host + PATH requirements for RPC CLI; validate `swift build --traits Editor`
- [x] A3: Update INPROGRESS summary with trait-gating context
- [x] A4: Make default traits explicit and keep trait-off EditorEngine guard
- [x] A5: Increase RPC indexProject timeout in extension commands
- [x] A6: Switch compile/preview commands to editor.compile with active file
- [x] A7: Add RPC smoke test script and document it
- [x] A8: Add includeOutput flag to editor.compile and avoid large outputs

## Next Step

Run ARCHIVE to clean up completed tasks:
$ claude "Выполни команду ARCHIVE"

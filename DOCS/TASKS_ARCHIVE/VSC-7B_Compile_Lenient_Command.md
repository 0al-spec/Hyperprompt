# VSC-7B — Compile Lenient Command

## Summary

Add a VS Code command that compiles the active Hypercode file in lenient mode to avoid missing-file diagnostics from strict compilation.

## Goals

- Provide a `Hyperprompt: Compile (Lenient)` command in the extension.
- Use `editor.compile` with `mode: "lenient"` for the active `.hc` file.
- Document the new command for developers and users.

## Non-Goals

- Implement preview rendering or output surfacing.
- Change compile defaults for existing commands.

## Requirements

1. Command `hyperprompt.compileLenient` is registered with activation event.
2. The command calls `editor.compile` with `mode: "lenient"` and `includeOutput: false`.
3. Extension README documents the lenient compile command.

## Implementation Plan

### A1: Register Command
- Update `Tools/VSCodeExtension/package.json` to add `hyperprompt.compileLenient`.
- Add activation event `onCommand:hyperprompt.compileLenient`.

### A2: Implement Handler
- Add a new command handler in `Tools/VSCodeExtension/src/extension.ts`.
- Reuse existing compile logic and pass `mode: "lenient"`.

### A3: Update Documentation
- Update `Tools/VSCodeExtension/README.md` to mention the new command and behavior.

## Acceptance Criteria

- `Hyperprompt: Compile (Lenient)` shows success on missing references that would fail strict mode.
- `npm run compile` succeeds in `Tools/VSCodeExtension`.

## Validation

- `./.github/scripts/restore-build-cache.sh` (if available)
- `swift test 2>&1`
- `npm run compile` (Tools/VSCodeExtension)

---
**Archived:** 2025-12-26

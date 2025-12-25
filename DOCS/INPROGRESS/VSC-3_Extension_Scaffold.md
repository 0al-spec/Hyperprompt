# VSC-3 — Extension Scaffold (Dev Host Validation)

## Summary

Validate the VS Code extension loads in a dev host, ensure the Editor RPC CLI entrypoint is usable, and document trait-gated EditorEngine behavior.

## Goals

- Ensure `hyperprompt editor-rpc` is available when building with the Editor trait.
- Document dev host workflow and PATH requirements for the VS Code extension.
- Provide troubleshooting guidance for RPC startup failures.

## Non-Goals

- Add new RPC methods or extension features beyond activation.
- Change VS Code settings or contribute new commands.

## Requirements

1. CLI supports `editor-rpc` subcommand behind the Editor trait.
2. EditorEngine dependency is wired for trait builds.
3. Docs updated: `README.md`, `Tools/VSCodeExtension/README.md`, `DOCS/TROUBLESHOOTING.md`.
4. Validation: `swift build --traits Editor` succeeds.

## Implementation Notes

- Use a root command with a default `compile` subcommand and an `editor-rpc` subcommand when the Editor trait is enabled.
- Keep PATH guidance generic (use `$PWD/.build/debug`).

## Validation

- `swift build --traits Editor`
- `hyperprompt editor-rpc` runs and waits for JSON-RPC input.

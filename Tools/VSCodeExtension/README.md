# Hyperprompt VS Code Extension

Hyperprompt language support for VS Code, backed by the Hyperprompt EditorEngine RPC.

## Features

- Hypercode syntax highlighting for `.hc` files.
- Compile commands (strict and lenient) with output in the Hyperprompt output channel.
- Live preview panel with compile-on-save updates.
- Navigation helpers: go-to-definition and hover for file references.
- Diagnostics surfaced in the Problems panel on save.

![Hyperprompt preview panel placeholder](./images/preview-placeholder.png)

## Commands

- `Hyperprompt: Compile` — compile in strict mode.
- `Hyperprompt: Compile (Lenient)` — compile in lenient mode.
- `Hyperprompt: Show Preview` — open or refresh the preview panel.

## Settings

- `hyperprompt.resolutionMode` (`strict` | `lenient`, default: `strict`)
- `hyperprompt.previewAutoUpdate` (default: `true`)
- `hyperprompt.diagnosticsEnabled` (default: `true`)
- `hyperprompt.enginePath` (absolute path override, default: empty)
- `hyperprompt.engineLogLevel` (`error` | `warn` | `info` | `debug`, default: `info`)

Changing `hyperprompt.enginePath` or `hyperprompt.engineLogLevel` restarts the RPC process. Disabling diagnostics clears the Problems collection, and `previewAutoUpdate` controls on-save preview refreshes.

## Requirements

- macOS or Linux (Windows is not supported yet).
- Hyperprompt CLI built with the Editor trait (`swift build --traits Editor`).
- `hyperprompt` available on PATH or configured via `hyperprompt.enginePath`.

## Usage

1. Open a `.hc` file to activate the extension.
2. Use Command Palette to run compile or preview commands.
3. Hover or go-to-definition on `@"..."` references.
4. Save files to refresh diagnostics and preview output.

Preview output renders raw Markdown text in a styled panel (Markdown-to-HTML rendering is a future enhancement).

## Project Structure

- `src/extension.ts`: activation, command registration, and feature wiring.
- `src/rpcClient.ts`: JSON-RPC transport for the `hyperprompt editor-rpc` process.
- `src/engineDiscovery.ts`: engine discovery and platform guard logic.
- `src/compileCommand.ts`: compile request helpers and params shaping.
- `src/navigation.ts`: definition/hover utilities for references.
- `src/diagnostics.ts`: diagnostics mapping into VS Code.
- `src/preview.ts`: preview panel rendering and scroll sync.
- `src/test/`: unit and integration coverage (includes mock engine).

## RPC Integration Notes

- Engine resolution order: `hyperprompt.enginePath` → bundled `bin/hyperprompt` → PATH.
- Default request timeout is 5s; adjust only if builds are slow.
- Unsupported platforms (Windows) are blocked with a user-facing error message.
- RPC methods used: `editor.compile`, `editor.linkAt`, `editor.indexProject`.
- Engine probes call `hyperprompt --help` to ensure `editor-rpc` is available.
- Common errors: missing Editor trait build, non-executable engine path, or missing binary on PATH.

## Development Testing

From `Tools/VSCodeExtension`:

```bash
npm install
npm run compile
code --extensionDevelopmentPath="$PWD"
```

Use `npm run watch` while debugging to recompile on changes:

```bash
npm run watch
code --extensionDevelopmentPath="$PWD"
```

In the Extension Development Host:
- Open a `.hc` file to trigger activation.
- Run commands from the Command Palette.
- Watch the "Hyperprompt" output channel for compile output.

If `code` is not found, install it from VS Code: Command Palette → "Shell Command: Install 'code' command in PATH".

## Testing

```bash
npm test
```

The test runner downloads VS Code; slow networks may cause timeouts.

## Engine Setup

Build the CLI with the Editor trait and ensure it is discoverable:

```bash
swift build --traits Editor
export PATH="/path/to/Hyperprompt/.build/debug:$PATH"
```

The extension resolves the engine in this order:

1. `hyperprompt.enginePath` setting
2. Bundled binary (`bin/hyperprompt` inside the extension, if present)
3. `hyperprompt` on PATH

## Release Packaging (VSIX)

```bash
npm install -g @vscode/vsce
npm install
vsce package
code --install-extension hyperprompt-*.vsix
```

## Release Checklist

- Update `CHANGELOG.md` and `README.md` with release notes.
- Run `npm run compile` and `npm test` (expect download time for VS Code).
- Package the extension with `vsce package`.
- Install the VSIX and smoke-test compile, preview, and diagnostics.
- Tag the release once the extension behaves as expected.

## Known Issues

- Preview panel renders raw Markdown (not HTML-rendered).
- Extension integration tests require VS Code download and may time out on slow networks.

## Release Notes

See `CHANGELOG.md` for the full history.

### 0.0.1

- Initial preview release: compile commands, navigation, diagnostics, and preview panel.

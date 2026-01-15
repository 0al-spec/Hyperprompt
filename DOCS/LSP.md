# Hyperprompt Language Server (LSP)

**Version:** 0.1
**Status:** Draft (VSC-2A)

## Overview

Hyperprompt provides a Swift-based Language Server that speaks **JSON-RPC 2.0** over stdio using the **Language Server Protocol (LSP)**. This server is the long-term replacement for the CLI JSON-RPC bridge.

## Capabilities

The current server advertises and supports the following capabilities:

- **Text document sync:** Full document sync (`textDocumentSync: 1`).
- **Definition provider:** `textDocument/definition`.
- **Hover provider:** `textDocument/hover`.
- **Diagnostics:** `textDocument/publishDiagnostics` after open/save/change.

## Supported Requests

| Method | Description |
| --- | --- |
| `initialize` | Initializes the server and returns capabilities. |
| `shutdown` | Gracefully shuts down the server. |
| `textDocument/definition` | Resolves a Hyperprompt file reference under the cursor. |
| `textDocument/hover` | Shows the resolved target path for a reference. |

## Supported Notifications

| Method | Description |
| --- | --- |
| `exit` | Terminates the server process. |
| `textDocument/didOpen` | Opens a document and triggers diagnostics. |
| `textDocument/didChange` | Updates document contents and triggers diagnostics. |
| `textDocument/didSave` | Triggers diagnostics on save. |
| `textDocument/publishDiagnostics` | Emitted by the server after validation. |

## Diagnostics Behavior

- Diagnostics are produced by compiling the opened document in **strict** mode via `EditorCompiler`.
- Results are mapped to LSP diagnostics with 0-based ranges and severity mapping (error/warning/info/hint).

## Running the Server

```bash
swift run --traits Editor hyperprompt-lsp
```

Use any LSP client (e.g., VS Code) to spawn the server over stdio.

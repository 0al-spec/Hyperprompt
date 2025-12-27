# Hyperprompt Editor RPC Protocol

**Version:** 1.0.0 (JSON-RPC 2.0)
**Status:** MVP Implementation
**Last Updated:** 2025-12-26

---

## Overview

The Hyperprompt Editor RPC interface provides JSON-RPC 2.0 communication between the Swift EditorEngine and TypeScript-based editors (e.g., VS Code extension). Communication occurs via stdin/stdout for simplicity and cross-platform compatibility.

**Architecture:** CLI + JSON-RPC (per ADR-001)
**Transport:** Stdin (requests) / Stdout (responses)
**Protocol:** JSON-RPC 2.0 (https://www.jsonrpc.org/specification)

---

## Usage

### Starting the RPC Server

```bash
hyperprompt editor-rpc
```

The server reads newline-delimited JSON-RPC requests from stdin and writes JSON-RPC responses to stdout.

### TypeScript Client Example

```typescript
import { spawn } from 'child_process';

const rpc = spawn('hyperprompt', ['editor-rpc']);

// Send request
const request = {
  jsonrpc: '2.0',
  id: 1,
  method: 'editor.indexProject',
  params: { workspaceRoot: '/path/to/workspace' }
};

rpc.stdin.write(JSON.stringify(request) + '\n');

// Receive response
rpc.stdout.on('data', (data) => {
  const response = JSON.parse(data.toString());
  console.log(response.result);
});
```

---

## RPC Methods

### `editor.indexProject`

**Status:** ✅ Implemented

Indexes a workspace directory to discover all Hypercode (.hc) and Markdown (.md) files.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "editor.indexProject",
  "params": {
    "workspaceRoot": "/absolute/path/to/workspace"
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "workspaceRoot": "/absolute/path/to/workspace",
    "files": [
      {
        "path": "src/main.hc",
        "type": "hypercode",
        "size": 1024,
        "lastModified": "2025-12-23T10:00:00Z"
      },
      {
        "path": "docs/README.md",
        "type": "markdown",
        "size": 512,
        "lastModified": "2025-12-23T09:00:00Z"
      }
    ],
    "discoveredAt": "2025-12-23T10:30:00Z"
  }
}
```

**Error Cases:**
- Workspace not found → code: -32603, message: "Failed to index workspace: directory not found"
- Permission denied → code: -32603, message: "Failed to index workspace: permission denied"

---

### `editor.parse`

**Status:** ✅ Implemented (CLI) — extension wiring in progress

Parses a Hypercode file and returns link spans with a diagnostics flag.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "editor.parse",
  "params": {
    "filePath": "/absolute/path/to/file.hc"
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "sourceFile": "/absolute/path/to/file.hc",
    "linkSpans": [
      {
        "literal": "./other.hc",
        "byteRangeStart": 10,
        "byteRangeEnd": 20,
        "lineRangeStart": 1,
        "lineRangeEnd": 1,
        "columnRangeStart": 5,
        "columnRangeEnd": 15,
        "referenceHint": "fileReference",
        "sourceFile": "/absolute/path/to/file.hc"
      }
    ],
    "hasDiagnostics": false
  }
}
```

---

### `editor.resolve`

**Status:** ✅ Implemented (CLI) — extension wiring in progress

Resolves a link path to a categorized target.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "editor.resolve",
  "params": {
    "linkPath": "./other.hc",
    "sourceFile": "/path/to/main.hc",
    "workspaceRoot": "/path/to"
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "type": "hypercodeFile",
    "path": "/path/to/other.hc"
  }
}
```

---

### `editor.compile`

**Status:** ✅ Implemented (CLI) — extension wiring in progress

Compiles a Hypercode entry file and returns diagnostics with optional output.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "editor.compile",
  "params": {
    "entryFile": "/path/to/main.hc",
    "workspaceRoot": "/path/to",
    "mode": "strict",
    "includeOutput": false
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {
    "diagnostics": [
      {
        "severity": "error",
        "message": "Missing file reference",
        "code": "E001",
        "location": {
          "filePath": "/path/to/main.hc",
          "line": 5
        }
      }
    ],
    "hasErrors": true
  }
}
```

When `includeOutput` is `false`, the `output` field is omitted.

---

### `editor.linkAt`

**Status:** ✅ Implemented (CLI) — extension wiring in progress

Queries link span at a specific line/column position in a file.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "editor.linkAt",
  "params": {
    "filePath": "/path/to/file.hc",
    "line": 1,
    "column": 5
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": {
    "literal": "./other.hc",
    "byteRangeStart": 10,
    "byteRangeEnd": 20,
    "lineRangeStart": 1,
    "lineRangeEnd": 1,
    "columnRangeStart": 5,
    "columnRangeEnd": 15,
    "referenceHint": "fileReference",
    "sourceFile": "/path/to/file.hc"
  }
}
```

If no link at position:
```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": null
}
```

---

## Error Codes

Hyperprompt RPC uses standard JSON-RPC 2.0 error codes:

| Code | Name | Description |
|------|------|-------------|
| -32700 | Parse error | Invalid JSON received |
| -32600 | Invalid Request | JSON-RPC request is invalid |
| -32601 | Method not found | Method does not exist |
| -32602 | Invalid params | Invalid method parameters |
| -32603 | Internal error | EditorEngine error or server failure |

**Error Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32601,
    "message": "Method not found: editor.unknown"
  }
}
```

---

## Implementation Status

| Method | Status | Implementation Date |
|--------|--------|---------------------|
| `editor.indexProject` | ✅ Implemented | 2025-12-23 |
| `editor.parse` | ✅ Implemented (CLI) | 2025-12-26 |
| `editor.resolve` | ✅ Implemented (CLI) | 2025-12-26 |
| `editor.compile` | ✅ Implemented (CLI) | 2025-12-26 |
| `editor.linkAt` | ✅ Implemented (CLI) | 2025-12-26 |

**Note:** This is an MVP CLI implementation. Extension wiring is in progress for `editor.parse`, `editor.resolve`, and `editor.linkAt`.

---

## Testing

### Manual Testing

```bash
# Test indexProject method
echo '{"jsonrpc":"2.0","id":1,"method":"editor.indexProject","params":{"workspaceRoot":"."}}' | hyperprompt editor-rpc

# Test unknown method (should return error -32601)
echo '{"jsonrpc":"2.0","id":99,"method":"unknown"}' | hyperprompt editor-rpc

# Test invalid JSON (should return error -32700)
echo 'invalid json' | hyperprompt editor-rpc
```

### Integration Testing

See `Tests/CLITests/EditorRPCTests.swift` for automated tests (to be implemented).

---

## Performance

**Startup Latency:** ~50-80ms (process spawn)
**Call Latency:** ~3-10ms (warm process)
**Recommendation:** Use long-lived subprocess for best performance

---

## Migration to LSP

Per ADR-001, this CLI RPC interface is the MVP implementation. Migration to Language Server Protocol (LSP) is planned for Phase 14+. The LSP implementation will provide:
- Multi-editor support (Vim, Emacs, Neovim)
- Incremental document sync
- Standard IDE tooling integration

---

## References

- **ADR-001:** ARCHITECTURE_DECISIONS.md
- **PRD:** DOCS/INPROGRESS/VSC-2B_CLI_JSON-RPC_Interface.md
- **JSON-RPC 2.0 Spec:** https://www.jsonrpc.org/specification
- **EditorEngine API:** Sources/EditorEngine/EditorEngine.swift

---

**Last Updated:** 2025-12-26 (VSC-2B MVP implementation)

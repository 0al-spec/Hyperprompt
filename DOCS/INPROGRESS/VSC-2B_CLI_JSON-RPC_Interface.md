# PRD: VSC-2B — CLI JSON-RPC Interface

**Task ID:** VSC-2B
**Priority:** P0 (Critical — Blocks VS Code extension)
**Phase:** Phase 11: VS Code Extension Integration Architecture
**Estimated Effort:** 8 hours
**Dependencies:** VSC-1 (Integration Architecture Decision — ✅ Complete)
**Status:** Planning
**Date:** 2025-12-23

---

## 1. Objective & Scope

### 1.1 Objective

Implement a JSON-RPC 2.0 interface for the Hyperprompt CLI that exposes EditorEngine APIs to VS Code extension via stdin/stdout communication. This enables TypeScript-based editor integration without platform-specific FFI bindings.

### 1.2 Scope

**In Scope:**
- New `hyperprompt editor-rpc` subcommand using ArgumentParser
- JSON-RPC 2.0 message protocol (request/response/error)
- Five RPC methods exposing EditorEngine APIs:
  - `editor.indexProject` — Index workspace files
  - `editor.parse` — Parse file with link spans
  - `editor.resolve` — Resolve link target
  - `editor.compile` — Compile entry file with diagnostics
  - `editor.linkAt` — Query link at position
- JSON serialization for all EditorEngine types (ProjectIndex, ParsedFile, CompileResult, etc.)
- Error handling with JSON-RPC error codes
- Integration tests for all RPC methods

**Out of Scope:**
- LSP protocol (deferred to Phase 14 per ADR-001)
- Long-lived session state management (each request is stateless)
- File watching / change notifications
- Performance optimization (defer to Phase 13)
- Windows support (macOS/Linux only for MVP)

### 1.3 Success Criteria

- ✅ CLI accepts `hyperprompt editor-rpc` command
- ✅ Reads JSON-RPC requests from stdin
- ✅ Writes JSON-RPC responses to stdout
- ✅ All 5 RPC methods implemented and tested
- ✅ Errors return JSON-RPC error responses (not crashes)
- ✅ Integration tests pass for all methods
- ✅ Documentation in DOCS/RPC_PROTOCOL.md

---

## 2. Hierarchical Task Breakdown

### Phase 1: CLI Infrastructure (2 hours)

#### T1.1: Add `editor-rpc` Subcommand [P0, 45 min]
**Input:** Existing `Sources/CLI/Hyperprompt.swift`
**Process:**
1. Read ArgumentParser documentation for subcommands
2. Create `Sources/CLI/EditorRPCCommand.swift`
3. Add `EditorRPCCommand` as subcommand to `Hyperprompt`
4. Implement `run()` method stub (print "RPC mode")
5. Test: `hyperprompt editor-rpc` prints message

**Output:** Working subcommand skeleton

**Acceptance Criteria:**
- [ ] `hyperprompt editor-rpc` executes without errors
- [ ] Command appears in `hyperprompt --help` output
- [ ] No compilation warnings

**Verification:**
```bash
swift build
./hyperprompt editor-rpc  # Should print "RPC mode" or similar
./hyperprompt --help | grep editor-rpc  # Should appear in help
```

---

#### T1.2: JSON-RPC Message Parsing [P0, 1 hour]
**Input:** JSON-RPC 2.0 specification (https://www.jsonrpc.org/specification)
**Process:**
1. Create `Sources/CLI/JSONRPCTypes.swift`
2. Define `JSONRPCRequest` struct (Codable):
   ```swift
   struct JSONRPCRequest: Codable {
       let jsonrpc: String  // Must be "2.0"
       let id: RequestID?   // Int or String
       let method: String
       let params: JSONValue?  // JSON object or array
   }
   ```
3. Define `JSONRPCResponse` struct (Codable):
   ```swift
   struct JSONRPCResponse: Codable {
       let jsonrpc: String  // "2.0"
       let id: RequestID?
       let result: JSONValue?  // Success result
       let error: JSONRPCError?  // Error object
   }
   ```
4. Define `JSONRPCError` struct:
   ```swift
   struct JSONRPCError: Codable {
       let code: Int
       let message: String
       let data: JSONValue?
   }
   ```
5. Add JSON-RPC error codes enum:
   ```swift
   enum JSONRPCErrorCode: Int {
       case parseError = -32700
       case invalidRequest = -32600
       case methodNotFound = -32601
       case invalidParams = -32602
       case internalError = -32603
   }
   ```
6. Write unit tests for Codable conformance

**Output:** JSON-RPC type definitions

**Acceptance Criteria:**
- [ ] Can decode valid JSON-RPC 2.0 requests
- [ ] Can encode JSON-RPC 2.0 responses
- [ ] Invalid JSON returns -32700 (parse error)
- [ ] Missing required fields return -32600 (invalid request)

**Verification:**
```bash
swift test --filter JSONRPCTypesTests
```

---

#### T1.3: Stdin/Stdout Message Loop [P0, 15 min]
**Input:** `EditorRPCCommand.run()` method
**Process:**
1. Implement message loop in `run()`:
   ```swift
   while let line = readLine() {
       let request = try JSONDecoder().decode(JSONRPCRequest.self, from: line.data(using: .utf8)!)
       let response = handleRequest(request)
       let json = try JSONEncoder().encode(response)
       print(String(data: json, encoding: .utf8)!)
   }
   ```
2. Add `handleRequest(_ request: JSONRPCRequest) -> JSONRPCResponse` stub
3. Handle EOF gracefully (exit loop when stdin closes)
4. Catch decoding errors → return JSON-RPC parse error

**Output:** Message loop with error handling

**Acceptance Criteria:**
- [ ] Reads JSON requests line-by-line from stdin
- [ ] Writes JSON responses line-by-line to stdout
- [ ] Invalid JSON → error response (not crash)
- [ ] EOF → graceful exit

**Verification:**
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"ping"}' | ./hyperprompt editor-rpc
# Should print JSON response
```

---

### Phase 2: RPC Method Handlers (4 hours)

#### T2.1: `editor.indexProject` Method [P0, 45 min]
**Input:** EditorEngine.indexProject API
**Process:**
1. Add handler in `handleRequest()`:
   ```swift
   case "editor.indexProject":
       let params = try decode(IndexProjectParams.self, from: request.params)
       let index = try EditorEngine.indexProject(workspaceRoot: params.workspaceRoot)
       return success(id: request.id, result: index)
   ```
2. Define `IndexProjectParams` struct (Codable):
   ```swift
   struct IndexProjectParams: Codable {
       let workspaceRoot: String
   }
   ```
3. Make `ProjectIndex` Codable (add conformance to EditorEngine/ProjectIndex.swift)
4. Make `IndexedFile` Codable
5. Handle errors → JSON-RPC error response

**Output:** Working `editor.indexProject` RPC method

**Acceptance Criteria:**
- [ ] Request: `{"jsonrpc":"2.0","id":1,"method":"editor.indexProject","params":{"workspaceRoot":"/path"}}`
- [ ] Response includes `totalFiles`, `files` array with `path`, `type`, `size`
- [ ] Invalid workspace → error response (code: -32603, message: "Failed to index workspace")

**Verification:**
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"editor.indexProject","params":{"workspaceRoot":"."}}' | ./hyperprompt editor-rpc | jq .
```

---

#### T2.2: `editor.parse` Method [P0, 45 min]
**Input:** EditorParser.parse API
**Process:**
1. Add handler:
   ```swift
   case "editor.parse":
       let params = try decode(ParseParams.self, from: request.params)
       let parsed = try EditorParser.parse(filePath: params.filePath)
       return success(id: request.id, result: parsed)
   ```
2. Define `ParseParams` struct:
   ```swift
   struct ParseParams: Codable {
       let filePath: String
   }
   ```
3. Make `ParsedFile` Codable
4. Make `LinkSpan` Codable (add to EditorEngine/LinkSpan.swift)
5. Include UTF-8 ranges in JSON output

**Output:** Working `editor.parse` RPC method

**Acceptance Criteria:**
- [ ] Returns `ParsedFile` JSON with `filePath`, `content`, `linkSpans`
- [ ] Each `LinkSpan` includes `startOffset`, `endOffset`, `linkText`, `targetPath`
- [ ] Missing file → error response

**Verification:**
```bash
echo '{"jsonrpc":"2.0","id":2,"method":"editor.parse","params":{"filePath":"test.hc"}}' | ./hyperprompt editor-rpc | jq .result.linkSpans
```

---

#### T2.3: `editor.resolve` Method [P0, 45 min]
**Input:** EditorResolver.resolve API
**Process:**
1. Add handler:
   ```swift
   case "editor.resolve":
       let params = try decode(ResolveParams.self, from: request.params)
       let target = try EditorResolver.resolve(
           linkPath: params.linkPath,
           sourceFile: params.sourceFile,
           workspaceRoot: params.workspaceRoot
       )
       return success(id: request.id, result: target)
   ```
2. Define `ResolveParams` struct:
   ```swift
   struct ResolveParams: Codable {
       let linkPath: String
       let sourceFile: String
       let workspaceRoot: String
   }
   ```
3. Make `ResolvedTarget` Codable
4. Handle unresolved links → error response

**Output:** Working `editor.resolve` RPC method

**Acceptance Criteria:**
- [ ] Returns `ResolvedTarget` with `absolutePath`, `exists`, `fileType`
- [ ] Ambiguous links → error with suggestions
- [ ] Missing file → error response

**Verification:**
```bash
echo '{"jsonrpc":"2.0","id":3,"method":"editor.resolve","params":{"linkPath":"./file.hc","sourceFile":"/path/main.hc","workspaceRoot":"/path"}}' | ./hyperprompt editor-rpc | jq .result.absolutePath
```

---

#### T2.4: `editor.compile` Method [P0, 1 hour]
**Input:** EditorCompiler.compile API
**Process:**
1. Add handler:
   ```swift
   case "editor.compile":
       let params = try decode(CompileParams.self, from: request.params)
       let options = CompileOptions(
           mode: params.mode ?? .strict,
           workspaceRoot: params.workspaceRoot
       )
       let result = try EditorCompiler.compile(
           entryFile: params.entryFile,
           options: options
       )
       return success(id: request.id, result: result)
   ```
2. Define `CompileParams` struct:
   ```swift
   struct CompileParams: Codable {
       let entryFile: String
       let workspaceRoot: String
       let mode: String?  // "strict" or "lenient"
   }
   ```
3. Make `CompileResult` Codable
4. Make `Diagnostic` Codable (from EditorEngine/Diagnostics.swift)
5. Include diagnostics array in response

**Output:** Working `editor.compile` RPC method

**Acceptance Criteria:**
- [ ] Returns `CompileResult` with `output`, `diagnostics` array
- [ ] Each diagnostic includes `severity`, `message`, `location`, `code`
- [ ] Compilation errors → diagnostics in result (not JSON-RPC error)
- [ ] Invalid entry file → JSON-RPC error

**Verification:**
```bash
echo '{"jsonrpc":"2.0","id":4,"method":"editor.compile","params":{"entryFile":"main.hc","workspaceRoot":"."}}' | ./hyperprompt editor-rpc | jq .result.diagnostics
```

---

#### T2.5: `editor.linkAt` Method [P0, 45 min]
**Input:** Requirement from EE-EXT-1 (Phase 12)
**Process:**
1. Add handler:
   ```swift
   case "editor.linkAt":
       let params = try decode(LinkAtParams.self, from: request.params)
       let parsed = try EditorParser.parse(filePath: params.filePath)
       let link = parsed.linkAt(line: params.line, column: params.column)
       return success(id: request.id, result: link)
   ```
2. Define `LinkAtParams` struct:
   ```swift
   struct LinkAtParams: Codable {
       let filePath: String
       let line: Int
       let column: Int
   }
   ```
3. Implement `ParsedFile.linkAt(line:column:)` in EditorEngine/ParsedFile.swift:
   - Convert line/column to UTF-8 offset
   - Binary search over `linkSpans` array
   - Return matching `LinkSpan` or nil
4. Return null if no link at position

**Output:** Working `editor.linkAt` RPC method

**Acceptance Criteria:**
- [ ] Returns `LinkSpan` JSON if position inside link
- [ ] Returns `null` if no link at position
- [ ] 1-indexed line numbers (editor convention)
- [ ] 0-indexed column numbers (editor convention)

**Verification:**
```bash
echo '{"jsonrpc":"2.0","id":5,"method":"editor.linkAt","params":{"filePath":"test.hc","line":1,"column":5}}' | ./hyperprompt editor-rpc | jq .result
```

---

### Phase 3: Error Handling & Testing (1.5 hours)

#### T3.1: Comprehensive Error Handling [P1, 45 min]
**Input:** All RPC handlers
**Process:**
1. Wrap all `try` calls with proper error mapping:
   ```swift
   do {
       let result = try handler()
       return success(id: request.id, result: result)
   } catch let error as EditorEngineError {
       return errorResponse(
           id: request.id,
           code: .internalError,
           message: error.localizedDescription
       )
   }
   ```
2. Map EditorEngine errors to JSON-RPC codes:
   - IndexerError → -32603 (internal error)
   - ParserError → -32603
   - ResolverError → -32603
   - CompilerError → -32603
3. Include error details in `data` field
4. Log errors to stderr (not stdout)

**Output:** Robust error handling

**Acceptance Criteria:**
- [ ] All EditorEngine errors → JSON-RPC error responses
- [ ] Error messages are descriptive
- [ ] No crashes on invalid input
- [ ] Stderr shows detailed error logs (stdout clean JSON only)

**Verification:**
```bash
echo '{"jsonrpc":"2.0","id":99,"method":"editor.indexProject","params":{"workspaceRoot":"/nonexistent"}}' | ./hyperprompt editor-rpc 2>/dev/null | jq .error
```

---

#### T3.2: Integration Tests [P1, 45 min]
**Input:** All implemented RPC methods
**Process:**
1. Create `Tests/CLITests/EditorRPCTests.swift`
2. Write test for each RPC method:
   ```swift
   func testIndexProject() throws {
       let request = """
       {"jsonrpc":"2.0","id":1,"method":"editor.indexProject","params":{"workspaceRoot":"."}}
       """
       let response = runRPC(input: request)
       let json = try JSONDecoder().decode(JSONRPCResponse.self, from: response)
       XCTAssertNotNil(json.result)
       XCTAssertNil(json.error)
   }
   ```
3. Test error cases (missing params, invalid method, etc.)
4. Use mock file system for deterministic tests
5. Verify JSON output schema matches expected structure

**Output:** Comprehensive test suite

**Acceptance Criteria:**
- [ ] All 5 RPC methods have happy-path tests
- [ ] Error cases tested (invalid params, missing files)
- [ ] Tests run in CI (swift test)
- [ ] 100% coverage of RPC handlers

**Verification:**
```bash
swift test --filter EditorRPCTests
```

---

### Phase 4: Documentation (30 min)

#### T4.1: RPC Protocol Documentation [P1, 30 min]
**Input:** All implemented RPC methods
**Process:**
1. Create `DOCS/RPC_PROTOCOL.md`
2. Document protocol version (JSON-RPC 2.0)
3. Document each RPC method:
   - Method name
   - Parameters schema (JSON)
   - Response schema (JSON)
   - Error codes
   - Example request/response
4. Add usage examples for TypeScript client:
   ```typescript
   import { spawn } from 'child_process';

   const rpc = spawn('hyperprompt', ['editor-rpc']);
   rpc.stdin.write('{"jsonrpc":"2.0","id":1,"method":"editor.indexProject","params":{"workspaceRoot":"."}}\n');
   rpc.stdout.on('data', (data) => {
       const response = JSON.parse(data.toString());
       console.log(response.result);
   });
   ```
5. Document error handling best practices
6. Add performance notes (startup latency, long-lived process recommendation)

**Output:** Complete RPC protocol documentation

**Acceptance Criteria:**
- [ ] All 5 methods documented with schemas
- [ ] TypeScript usage example included
- [ ] Error codes table included
- [ ] Cross-referenced from DOCS/ARCHITECTURE_DECISIONS.md (ADR-001)

**Verification:**
```bash
cat DOCS/RPC_PROTOCOL.md | grep "editor.indexProject"  # Should exist
```

---

## 3. Functional Requirements

### FR-1: JSON-RPC 2.0 Compliance
- **Requirement:** Implement JSON-RPC 2.0 specification exactly
- **Acceptance:** All requests/responses conform to JSON-RPC 2.0 schema
- **Verification:** Run against JSON-RPC 2.0 test suite

### FR-2: EditorEngine API Exposure
- **Requirement:** Expose all critical EditorEngine APIs via RPC
- **Acceptance:** All 5 methods (`indexProject`, `parse`, `resolve`, `compile`, `linkAt`) callable via RPC
- **Verification:** Integration tests for each method pass

### FR-3: Error Handling
- **Requirement:** All errors return valid JSON-RPC error responses
- **Acceptance:** No crashes, all errors include code/message/data
- **Verification:** Error injection tests pass

### FR-4: Stdin/Stdout Communication
- **Requirement:** Use stdin for requests, stdout for responses
- **Acceptance:** No extraneous output on stdout (only JSON), logs go to stderr
- **Verification:** `echo '...' | ./hyperprompt editor-rpc | jq .` parses cleanly

### FR-5: JSON Serialization
- **Requirement:** All EditorEngine types serializable to JSON
- **Acceptance:** ProjectIndex, ParsedFile, CompileResult, etc. conform to Codable
- **Verification:** Serialization round-trip tests pass

---

## 4. Non-Functional Requirements

### NFR-1: Performance
- **Startup Latency:** <80ms (process spawn time, per ADR-001)
- **Call Latency:** 3-10ms per RPC call (warm process)
- **Throughput:** 100-300 calls/sec (long-lived process)
- **Measurement:** Use `swift test --enable-test-timing` to verify

### NFR-2: Cross-Platform Support
- **Platforms:** macOS (x64, arm64), Linux (x64)
- **Verification:** CI builds on macOS and Linux pass

### NFR-3: Memory Safety
- **Requirement:** No memory leaks, no crashes
- **Verification:** Run with Address Sanitizer (`swift build --sanitize=address`)

### NFR-4: Maintainability
- **Code Quality:** Follow Swift API design guidelines
- **Documentation:** All public APIs documented with doc comments
- **Testing:** >80% code coverage for RPC handlers

---

## 5. Edge Cases & Failure Scenarios

### Edge Case 1: Malformed JSON
**Scenario:** Client sends invalid JSON
**Expected:** Return JSON-RPC parse error (code: -32700)
**Test:**
```bash
echo 'invalid json' | ./hyperprompt editor-rpc
# Should print: {"jsonrpc":"2.0","id":null,"error":{"code":-32700,"message":"Parse error"}}
```

### Edge Case 2: Unknown Method
**Scenario:** Client calls non-existent RPC method
**Expected:** Return method not found error (code: -32601)
**Test:**
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"unknown"}' | ./hyperprompt editor-rpc
# Should print: {"jsonrpc":"2.0","id":1,"error":{"code":-32601,"message":"Method not found"}}
```

### Edge Case 3: Missing Required Params
**Scenario:** Client omits required parameter (e.g., `workspaceRoot`)
**Expected:** Return invalid params error (code: -32602)
**Test:**
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"editor.indexProject","params":{}}' | ./hyperprompt editor-rpc
# Should print: {"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Invalid params"}}
```

### Edge Case 4: Empty Workspace
**Scenario:** Index workspace with no `.hc` or `.md` files
**Expected:** Return success with `totalFiles: 0`, empty `files` array
**Test:**
```bash
mkdir /tmp/empty-workspace
echo '{"jsonrpc":"2.0","id":1,"method":"editor.indexProject","params":{"workspaceRoot":"/tmp/empty-workspace"}}' | ./hyperprompt editor-rpc
# Should print: {"jsonrpc":"2.0","id":1,"result":{"totalFiles":0,"files":[]}}
```

### Edge Case 5: File Not Found (parse)
**Scenario:** Parse non-existent file
**Expected:** Return internal error with file not found message
**Test:**
```bash
echo '{"jsonrpc":"2.0","id":2,"method":"editor.parse","params":{"filePath":"/nonexistent.hc"}}' | ./hyperprompt editor-rpc
# Should print: {"jsonrpc":"2.0","id":2,"error":{"code":-32603,"message":"File not found: /nonexistent.hc"}}
```

### Edge Case 6: Position Outside File Bounds (linkAt)
**Scenario:** Query link at line 9999 in 10-line file
**Expected:** Return `null` result (no link at position)
**Test:**
```bash
echo '{"jsonrpc":"2.0","id":5,"method":"editor.linkAt","params":{"filePath":"test.hc","line":9999,"column":0}}' | ./hyperprompt editor-rpc
# Should print: {"jsonrpc":"2.0","id":5,"result":null}
```

---

## 6. Dependencies & Constraints

### External Dependencies
- **Swift 5.9+** — For Codable, ArgumentParser
- **Foundation** — JSON encoding/decoding
- **ArgumentParser** — CLI subcommand framework (already in Package.swift)

### Internal Dependencies
- **EditorEngine module** — All RPC methods delegate to EditorEngine APIs
- **VSC-1 complete** — Architecture decision (CLI approach) must be finalized

### Constraints
- **No external JSON libraries** — Use Foundation's JSONEncoder/JSONDecoder only
- **Stateless** — Each RPC request is independent (no session state)
- **macOS/Linux only** — Windows support deferred to Phase 14
- **No file watching** — VS Code extension must implement file watching separately

---

## 7. Quality Checklist

### Pre-Implementation
- [x] Read JSON-RPC 2.0 specification
- [x] Review EditorEngine API surface (EditorEngine.swift)
- [x] Review ArgumentParser subcommand examples
- [ ] Create feature branch: `vsc-2b-cli-rpc-interface`

### During Implementation
- [ ] All new types conform to Codable
- [ ] All RPC handlers have error handling
- [ ] No print statements except JSON output on stdout
- [ ] All logs go to stderr
- [ ] Unit tests for JSON-RPC types
- [ ] Integration tests for all RPC methods

### Post-Implementation
- [ ] Run `swift build --configuration release` (0 errors, 0 warnings)
- [ ] Run `swift test` (100% pass rate)
- [ ] Run Address Sanitizer build: `swift build --sanitize=address`
- [ ] Verify RPC protocol documentation complete
- [ ] Manual smoke test: `echo '...' | ./hyperprompt editor-rpc | jq .`
- [ ] Update ADR-001 with implementation notes
- [ ] Mark VSC-2B complete in Workplan.md

---

## 8. Implementation Templates

### 8.1 EditorRPCCommand Skeleton

**File:** `Sources/CLI/EditorRPCCommand.swift`

```swift
import Foundation
import ArgumentParser
import EditorEngine

struct EditorRPCCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "editor-rpc",
        abstract: "JSON-RPC interface for editor integration (VS Code extension)"
    )

    func run() throws {
        // Read JSON-RPC requests from stdin, write responses to stdout
        while let line = readLine() {
            do {
                guard let data = line.data(using: .utf8) else {
                    printError(id: nil, code: .parseError, message: "Invalid UTF-8")
                    continue
                }

                let request = try JSONDecoder().decode(JSONRPCRequest.self, from: data)
                let response = handleRequest(request)
                let responseData = try JSONEncoder().encode(response)

                if let json = String(data: responseData, encoding: .utf8) {
                    print(json)
                    fflush(stdout)
                }
            } catch {
                printError(id: nil, code: .parseError, message: "Invalid JSON-RPC request")
            }
        }
    }

    func handleRequest(_ request: JSONRPCRequest) -> JSONRPCResponse {
        do {
            switch request.method {
            case "editor.indexProject":
                return try handleIndexProject(request)
            case "editor.parse":
                return try handleParse(request)
            case "editor.resolve":
                return try handleResolve(request)
            case "editor.compile":
                return try handleCompile(request)
            case "editor.linkAt":
                return try handleLinkAt(request)
            default:
                return errorResponse(
                    id: request.id,
                    code: .methodNotFound,
                    message: "Method not found: \(request.method)"
                )
            }
        } catch {
            return errorResponse(
                id: request.id,
                code: .internalError,
                message: error.localizedDescription
            )
        }
    }

    func handleIndexProject(_ request: JSONRPCRequest) throws -> JSONRPCResponse {
        let params = try decodeParams(IndexProjectParams.self, from: request.params)
        let index = try EditorEngine.indexProject(workspaceRoot: params.workspaceRoot)
        return successResponse(id: request.id, result: index)
    }

    // ... other handlers

    func printError(id: RequestID?, code: JSONRPCErrorCode, message: String) {
        let response = errorResponse(id: id, code: code, message: message)
        if let data = try? JSONEncoder().encode(response),
           let json = String(data: data, encoding: .utf8) {
            print(json)
            fflush(stdout)
        }
    }
}
```

### 8.2 JSON-RPC Types

**File:** `Sources/CLI/JSONRPCTypes.swift`

```swift
import Foundation

// MARK: - Request ID (can be Int or String)
enum RequestID: Codable, Hashable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                RequestID.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "ID must be int or string"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

// MARK: - JSON-RPC Request
struct JSONRPCRequest: Codable {
    let jsonrpc: String
    let id: RequestID?
    let method: String
    let params: JSONValue?
}

// MARK: - JSON-RPC Response
struct JSONRPCResponse: Codable {
    let jsonrpc: String
    let id: RequestID?
    let result: JSONValue?
    let error: JSONRPCError?
}

// MARK: - JSON-RPC Error
struct JSONRPCError: Codable {
    let code: Int
    let message: String
    let data: JSONValue?
}

// MARK: - JSON-RPC Error Codes
enum JSONRPCErrorCode: Int {
    case parseError = -32700
    case invalidRequest = -32600
    case methodNotFound = -32601
    case invalidParams = -32602
    case internalError = -32603
}

// MARK: - Helper: Generic JSON Value
enum JSONValue: Codable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    // Codable implementation omitted for brevity (see JSON-RPC 2.0 spec)
}
```

### 8.3 RPC Parameter Types

**File:** `Sources/CLI/RPCParams.swift`

```swift
import Foundation

struct IndexProjectParams: Codable {
    let workspaceRoot: String
}

struct ParseParams: Codable {
    let filePath: String
}

struct ResolveParams: Codable {
    let linkPath: String
    let sourceFile: String
    let workspaceRoot: String
}

struct CompileParams: Codable {
    let entryFile: String
    let workspaceRoot: String
    let mode: String?  // "strict" or "lenient"
}

struct LinkAtParams: Codable {
    let filePath: String
    let line: Int  // 1-indexed
    let column: Int  // 0-indexed
}
```

---

## 9. Testing Strategy

### Unit Tests
- **Target:** `Tests/CLITests/JSONRPCTypesTests.swift`
- **Coverage:** Codable conformance, error code mapping, request/response round-trip

### Integration Tests
- **Target:** `Tests/CLITests/EditorRPCTests.swift`
- **Coverage:** All 5 RPC methods, error cases, edge cases

### Manual Testing
```bash
# Test indexProject
echo '{"jsonrpc":"2.0","id":1,"method":"editor.indexProject","params":{"workspaceRoot":"."}}' | swift run hyperprompt editor-rpc | jq .

# Test parse
echo '{"jsonrpc":"2.0","id":2,"method":"editor.parse","params":{"filePath":"Examples/simple.hc"}}' | swift run hyperprompt editor-rpc | jq .result.linkSpans

# Test resolve
echo '{"jsonrpc":"2.0","id":3,"method":"editor.resolve","params":{"linkPath":"./file.hc","sourceFile":"/path/main.hc","workspaceRoot":"/path"}}' | swift run hyperprompt editor-rpc | jq .

# Test compile
echo '{"jsonrpc":"2.0","id":4,"method":"editor.compile","params":{"entryFile":"Examples/simple.hc","workspaceRoot":"."}}' | swift run hyperprompt editor-rpc | jq .result.diagnostics

# Test linkAt
echo '{"jsonrpc":"2.0","id":5,"method":"editor.linkAt","params":{"filePath":"Examples/simple.hc","line":1,"column":5}}' | swift run hyperprompt editor-rpc | jq .
```

---

## 10. Rollout Plan

### Phase 1: Development (6 hours)
1. Implement CLI infrastructure (T1.1-T1.3)
2. Implement RPC handlers (T2.1-T2.5)
3. Add error handling (T3.1)

### Phase 2: Testing (1.5 hours)
1. Write integration tests (T3.2)
2. Run manual smoke tests
3. Fix bugs

### Phase 3: Documentation (30 min)
1. Write RPC protocol docs (T4.1)
2. Update ADR-001 with implementation notes

### Phase 4: Validation (remaining time)
1. Build with `--sanitize=address`
2. Run full test suite
3. Mark VSC-2B complete

---

## 11. Success Metrics

- ✅ All 5 RPC methods callable from command line
- ✅ Zero crashes on invalid input
- ✅ <80ms startup latency (measured with `time echo '...' | ./hyperprompt editor-rpc`)
- ✅ 100% integration test pass rate
- ✅ Documentation complete (DOCS/RPC_PROTOCOL.md)

---

## 12. References

- **ADR-001:** DOCS/ARCHITECTURE_DECISIONS.md (CLI approach chosen)
- **JSON-RPC 2.0 Spec:** https://www.jsonrpc.org/specification
- **EditorEngine API:** Sources/EditorEngine/EditorEngine.swift
- **ArgumentParser Docs:** https://github.com/apple/swift-argument-parser
- **VS Code Extension PRD:** DOCS/PRD/PRD_VSCode_Extension.md

---

## 13. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-23 | Claude (PLAN command) | Initial PRD for VSC-2B |

---

**Status:** Ready for EXECUTE phase
**Next Step:** Run `EXECUTE` command to implement this PRD

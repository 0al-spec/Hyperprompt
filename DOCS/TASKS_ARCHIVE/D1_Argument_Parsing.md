# Task Specification: D1 — Argument Parsing

**Document Version:** 1.0.0
**Date:** December 9, 2025
**Task ID:** D1
**Task Name:** Argument Parsing
**Priority:** [P1] High — Required for v0.1 release
**Phase:** Phase 6 (CLI & Integration)
**Effort Estimate:** 4 hours
**Status:** Selected for implementation

---

## 1. Executive Summary

### 1.1 Objective

Implement command-line argument parsing for the Hyperprompt compiler using the Swift Argument Parser library. This task establishes the CLI interface through which users invoke the compiler, defining all command-line options, flags, and input parameters.

**Deliverable:** A fully functional `hyperprompt` command with documented arguments, automatic help generation, and validation logic.

### 1.2 Scope

- Define command structure using `@main` and `ParsableCommand` from swift-argument-parser
- Implement positional argument for input file (required)
- Implement optional arguments: `--output`, `--manifest`, `--root`
- Implement mode flags: `--strict` (default), `--lenient`
- Implement action flags: `--stats`, `--dry-run`, `--verbose`, `--version`
- Implement help system: `--help`, `-h`
- Validate argument combinations (strict XOR lenient, not both)
- Generate automatic help text from argument definitions

**Out of Scope:**
- Argument value parsing or validation (deferred to D2: Compiler Driver)
- File system interaction (deferred to compiler phases)
- Actual compilation logic (D2+)

### 1.3 Dependencies

- **Input:** swift-argument-parser library (configured in A1: Project Initialization ✅)
- **Context:** Hypercode compiler version and project metadata
- **Blocking:** Task D2 (Compiler Driver) requires this task complete

### 1.4 Success Criteria

1. ✅ Command structure compiles without errors
2. ✅ All documented arguments recognized and parsed
3. ✅ Help text accurate and complete
4. ✅ Argument validation enforces strict XOR lenient
5. ✅ Version flag displays correct compiler version
6. ✅ Tests verify all argument combinations
7. ✅ No compilation warnings in argument parsing code

---

## 2. Functional Requirements

### 2.1 Command Structure

**Command Name:** `hyperprompt`
**Usage Pattern:** `hyperprompt <input-file> [OPTIONS] [FLAGS]`

**Example Invocations:**
```bash
hyperprompt root.hc                                    # minimal
hyperprompt root.hc --output out.md --manifest meta.json
hyperprompt root.hc --strict --verbose --stats
hyperprompt root.hc --lenient --dry-run
hyperprompt --help
hyperprompt --version
```

### 2.2 Positional Arguments

#### `input` (Required)
- **Type:** `String` (file path)
- **Position:** First argument
- **Description:** Path to root `.hc` file to compile
- **Validation:** Performed by driver (not here)
- **Example:** `root.hc`, `src/main.hc`, `/absolute/path/root.hc`

### 2.3 Optional Arguments (Long Form)

#### `--output` / `-o`
- **Type:** `String` (file path)
- **Default:** `out.md` (applied in D2 Driver)
- **Description:** Output Markdown file path
- **Multiple Occurrences:** Not allowed (swift-argument-parser enforces single occurrence)
- **Example:** `-o compiled.md` or `--output /tmp/result.md`

#### `--manifest` / `-m`
- **Type:** `String` (file path)
- **Default:** `manifest.json` (applied in D2 Driver)
- **Description:** Output manifest JSON file path
- **Multiple Occurrences:** Not allowed
- **Example:** `-m meta.json` or `--manifest ./manifest.json`

#### `--root` / `-r`
- **Type:** `String` (directory path)
- **Default:** Current working directory (applied in D2 Driver)
- **Description:** Root directory for resolving file references
- **Multiple Occurrences:** Not allowed
- **Example:** `-r .` or `--root /home/user/project`

### 2.4 Mode Flags (Mutually Exclusive)

#### `--strict` (Default)
- **Type:** `Boolean` flag
- **Default:** `true` (implicit)
- **Description:** In strict mode, missing file references cause compilation failure
- **Constraint:** Mutually exclusive with `--lenient`
- **Error on Both:** "Cannot specify both --strict and --lenient"

#### `--lenient`
- **Type:** `Boolean` flag
- **Default:** `false`
- **Description:** In lenient mode, missing file references are treated as inline text
- **Constraint:** Mutually exclusive with `--strict`

**Validation Logic:**
```swift
if strict && lenient {
    // Error: Cannot specify both modes
    throw ArgumentParsingError(...)
}
```

### 2.5 Action Flags

#### `--verbose` / `-v`
- **Type:** `Boolean` flag
- **Default:** `false`
- **Description:** Enable verbose logging output
- **Multiple Occurrences:** Not relevant for flag
- **Example:** `hyperprompt root.hc --verbose`

#### `--stats`
- **Type:** `Boolean` flag
- **Default:** `false`
- **Description:** Enable statistics collection and reporting
- **Example:** `hyperprompt root.hc --stats`

#### `--dry-run`
- **Type:** `Boolean` flag
- **Default:** `false`
- **Description:** Perform compilation validation without writing output files
- **Example:** `hyperprompt root.hc --dry-run`

#### `--version`
- **Type:** `Boolean` flag
- **Default:** `false`
- **Description:** Display compiler version and exit
- **Behavior:** When set, display version and exit with code 0 (handled by swift-argument-parser)
- **Output Format:** `hyperprompt version X.Y.Z`

### 2.6 Help System

#### `--help` / `-h`
- **Type:** `Boolean` flag
- **Default:** `false`
- **Description:** Display help message and exit
- **Behavior:** Automatic in swift-argument-parser
- **Format:** Auto-generated from `@OptionGroup` and `@Argument` definitions

**Expected Help Output Structure:**
```
OVERVIEW: Compile Hypercode to Markdown with manifest generation

USAGE: hyperprompt <input> [--output <output>] [--manifest <manifest>]
                             [--root <root>] [--strict] [--lenient]
                             [--verbose] [--stats] [--dry-run] [--version]
                             [--help]

ARGUMENTS:
  <input>                     Path to root .hc file to compile

OPTIONS:
  -o, --output <output>       Output Markdown file (default: out.md)
  -m, --manifest <manifest>   Output manifest JSON file (default: manifest.json)
  -r, --root <root>           Root directory for file resolution (default: .)
  --strict                    Fail on missing file references (default)
  --lenient                   Treat missing refs as inline text
  -v, --verbose               Enable verbose logging
  --stats                     Collect and report compilation statistics
  --dry-run                   Validate without writing output
  --version                   Display version and exit
  -h, --help                  Show this help message
```

---

## 3. Non-Functional Requirements

### 3.1 Code Quality
- **Language:** Swift (4.0+)
- **Library:** swift-argument-parser (5.0+)
- **Testing:** Unit tests for all argument combinations
- **No Warnings:** Swift compiler must produce zero warnings

### 3.2 Performance
- **Argument Parsing Time:** < 10ms (negligible compared to compilation)
- **Startup Overhead:** Minimal (swift-argument-parser is designed for fast parsing)

### 3.3 Compatibility
- **Swift Version:** Swift 5.7+ (for consistency with project)
- **Platforms:** macOS 12.0+, Ubuntu 22.04+, Windows 10+ (via swift-argument-parser)

### 3.4 Error Handling
- **Invalid Arguments:** Exit with code 2 (Syntax Error) — NO, actually swift-argument-parser exits with 1
  - **Correction:** Let swift-argument-parser handle exit codes; document actual behavior
- **Help/Version Requests:** Exit with code 0 (Success)
- **Error Messages:** Human-readable, matching swift-argument-parser conventions

### 3.5 Documentation
- **Inline Comments:** Explain complex validation logic
- **Help Text:** Accurate, complete in swift-argument-parser definitions
- **README Integration:** Document all flags and options

---

## 4. Architecture & Implementation Design

### 4.1 Structure (Following swift-argument-parser Conventions)

```swift
@main
struct HyperpromptCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hyperprompt",
        abstract: "Compile Hypercode to Markdown with manifest generation",
        version: "0.1.0"
    )

    @Argument(help: "Path to root .hc file to compile")
    var input: String

    @Option(name: .shortAndLong, help: "Output Markdown file (default: out.md)")
    var output: String?

    @Option(name: .shortAndLong, help: "Output manifest JSON file (default: manifest.json)")
    var manifest: String?

    @Option(name: .shortAndLong, help: "Root directory for file resolution (default: .)")
    var root: String?

    @Flag(help: "Fail on missing file references (default)")
    var strict: Bool = false

    @Flag(help: "Treat missing references as inline text")
    var lenient: Bool = false

    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false

    @Flag(help: "Collect and report compilation statistics")
    var stats: Bool = false

    @Flag(help: "Validate without writing output")
    var dryRun: Bool = false

    func run() throws {
        // Validation: strict XOR lenient
        if strict && lenient {
            throw ValidationError("Cannot specify both --strict and --lenient")
        }

        // Later: Invoke compiler driver with parsed arguments
        // let compiler = CompilerDriver(input, output, manifest, root, strict, verbose, stats, dryRun)
        // try compiler.compile()
    }
}
```

### 4.2 Argument Container Struct

For easier passing to compiler driver (D2), create a wrapper:

```swift
struct CompilerArguments {
    let input: String
    let output: String
    let manifest: String
    let root: String
    let mode: CompilationMode  // .strict or .lenient
    let verbose: Bool
    let stats: Bool
    let dryRun: Bool

    enum CompilationMode {
        case strict
        case lenient
    }
}
```

### 4.3 Validation Strategy

**Validation Layers:**

1. **swift-argument-parser Built-in:**
   - Type checking (String → String, Flag → Bool)
   - Duplicate option detection
   - Required argument presence

2. **Custom Validation in `run()` method:**
   - strict XOR lenient constraint
   - (File existence deferred to D2 Driver)

3. **No Validation Here:**
   - File path validity (handled by driver)
   - File access permissions (handled by driver)
   - Directory traversal (handled by resolver in B1)

---

## 5. TODO Plan (Hierarchical Breakdown)

### Phase 1: Argument Definition

#### Task 1.1: Create CLI Command Structure
- **Input:** swift-argument-parser documentation, project version (0.1.0)
- **Output:** `HyperpromptCommand` struct with @main
- **Steps:**
  1. Create `Sources/CLI/Command.swift`
  2. Import ArgumentParser
  3. Define `@main` struct `HyperpromptCommand`
  4. Configure `CommandConfiguration` with name, abstract, version
- **Effort:** 30 minutes
- **Acceptance:** Compiles without errors, `hyperprompt --help` works
- **Status:** Pending

#### Task 1.2: Implement Positional Argument (input)
- **Input:** CLI design, Hypercode file paths
- **Output:** `@Argument` property for input file
- **Steps:**
  1. Add `@Argument(help: "...")` property
  2. Type: String
  3. Ensure help text is clear
  4. No default value (required)
- **Effort:** 15 minutes
- **Acceptance:** `hyperprompt root.hc` parses correctly
- **Status:** Pending

#### Task 1.3: Implement Output Options (--output, --manifest, --root)
- **Input:** CLI design, default values
- **Output:** Three `@Option` properties
- **Steps:**
  1. Define `--output / -o` option (String, optional)
  2. Define `--manifest / -m` option (String, optional)
  3. Define `--root / -r` option (String, optional)
  4. Set help text for each
  5. Verify short forms work: `-o`, `-m`, `-r`
- **Effort:** 30 minutes
- **Acceptance:**
  - `hyperprompt root.hc -o out.md` works
  - `hyperprompt root.hc --output out.md` works
  - `hyperprompt root.hc -m meta.json` works
  - All three combinations parse correctly
- **Status:** Pending

### Phase 2: Mode & Action Flags

#### Task 2.1: Implement Mode Flags (--strict, --lenient)
- **Input:** CLI design, mutual exclusivity requirement
- **Output:** Two `@Flag` properties with validation
- **Steps:**
  1. Add `@Flag(help: "...")` property `strict` (default true? NO: default false, but acts as default)
  2. Add `@Flag(help: "...")` property `lenient` (default false)
  3. Implement validation logic in `run()` method
  4. Throw `ValidationError` if both true
  5. Determine default behavior (strict is default mode)
- **Effort:** 30 minutes
- **Acceptance:**
  - `hyperprompt root.hc` implies strict mode (lenient=false, strict doesn't need explicit flag)
  - `hyperprompt root.hc --strict` compiles without error
  - `hyperprompt root.hc --lenient` compiles without error
  - `hyperprompt root.hc --strict --lenient` fails with clear error message
- **Status:** Pending

**Note on Default Mode:**
In swift-argument-parser, flags default to `false`. To make strict the default:
- Option 1: Add `@Flag` with default `strict: Bool = true` and don't expose the flag by default (implicit)
- Option 2: Invert logic — only add `--lenient` flag, assume strict if not present
- Decision: Approach 2 is cleaner. `strict` property inferred as `!lenient`

Revised:
```swift
@Flag(help: "Treat missing references as inline text")
var lenient: Bool = false

var mode: CompilationMode {
    lenient ? .lenient : .strict
}
```

#### Task 2.2: Implement Action Flags (--verbose, --stats, --dry-run)
- **Input:** CLI design
- **Output:** Three `@Flag` properties
- **Steps:**
  1. Add `--verbose / -v` flag
  2. Add `--stats` flag
  3. Add `--dry-run` flag
  4. Set help text for each
  5. All default to `false`
- **Effort:** 20 minutes
- **Acceptance:**
  - `hyperprompt root.hc --verbose` parses
  - `hyperprompt root.hc --stats` parses
  - `hyperprompt root.hc --dry-run` parses
  - All combinations work: `hyperprompt root.hc -v --stats --dry-run`
- **Status:** Pending

### Phase 3: Help & Version

#### Task 3.1: Configure Help System
- **Input:** swift-argument-parser auto-generation
- **Output:** Automatic help text (no code changes needed)
- **Steps:**
  1. Verify `--help` flag works (built-in)
  2. Verify `-h` short form works (built-in)
  3. Test help output formatting
  4. Verify all arguments documented
- **Effort:** 15 minutes
- **Acceptance:**
  - `hyperprompt --help` displays help text
  - `hyperprompt -h` works identically
  - Help mentions all arguments, options, flags
- **Status:** Pending

#### Task 3.2: Implement Version Display
- **Input:** Project version (0.1.0)
- **Output:** Functional `--version` flag
- **Steps:**
  1. Configure `CommandConfiguration` with `version: "0.1.0"`
  2. swift-argument-parser handles `--version` automatically
  3. Test version output
- **Effort:** 10 minutes
- **Acceptance:**
  - `hyperprompt --version` outputs version and exits with code 0
  - Output format: `hyperprompt version 0.1.0` or similar
- **Status:** Pending

### Phase 4: Validation & Error Handling

#### Task 4.1: Implement Argument Validation Logic
- **Input:** Argument combination rules (strict XOR lenient)
- **Output:** Validation in `run()` method
- **Steps:**
  1. In `run()` method, check: `if lenient && strict { throw error }`
  2. Define custom error type or use swift-argument-parser's ValidationError
  3. Provide clear error message
- **Effort:** 20 minutes
- **Acceptance:**
  - `hyperprompt root.hc --strict --lenient` fails with message like "Cannot specify both --strict and --lenient"
  - Error exit code is consistent (swift-argument-parser standard)
- **Status:** Pending

#### Task 4.2: Create Arguments Container Struct
- **Input:** Argument definitions, compiler driver needs
- **Output:** `CompilerArguments` struct for passing to D2 Driver
- **Steps:**
  1. Create `Sources/Core/Arguments.swift`
  2. Define `struct CompilerArguments` with all parsed fields
  3. Define `enum CompilationMode { case strict, case lenient }`
  4. Add factory method: `extension HyperpromptCommand` to create `CompilerArguments`
  5. Or: Initialize in `run()` method before invoking driver
- **Effort:** 30 minutes
- **Acceptance:**
  - `CompilerArguments` compiles
  - Can be instantiated from parsed flags
  - All required fields present
- **Status:** Pending

### Phase 5: Testing

#### Task 5.1: Unit Tests for Argument Parsing
- **Input:** Test framework (XCTest), sample argument combinations
- **Output:** Test file `Tests/CLITests/ArgumentParsingTests.swift`
- **Steps:**
  1. Create test file
  2. Write tests for each argument individually
  3. Write tests for valid combinations
  4. Write tests for invalid combinations (strict+lenient)
  5. Test help and version flags
  6. Test short forms (-o, -m, -r, -v)
- **Test Cases:** ~20 total
- **Effort:** 1.5 hours
- **Acceptance Criteria:**
  - All tests pass
  - Code coverage > 85% for CLI module
  - No test warnings
- **Status:** Pending

**Sample Test Structure:**
```swift
func testInputArgumentParsing() {
    // Given: command line args
    // When: parsing
    // Then: input populated correctly
}

func testOutputOptionParsing() {
    // Verify --output works
    // Verify -o works
    // Verify both forms equivalent
}

func testStrictLenientMutualExclusion() {
    // When: both --strict and --lenient provided
    // Then: parsing should fail with clear error
}

func testHelpFlag() {
    // When: --help provided
    // Then: should display help and exit 0
}

func testVersionFlag() {
    // When: --version provided
    // Then: should display version and exit 0
}
```

#### Task 5.2: Integration Test with Compiler Driver
- **Input:** D2 Driver implementation (deferred)
- **Output:** End-to-end test verifying D1 output feeds into D2
- **Effort:** Deferred until D2 complete
- **Status:** Pending
- **Dependency:** D2 implementation required

### Phase 6: Documentation

#### Task 6.1: Add Inline Comments
- **Input:** Argument definitions, validation logic
- **Output:** Commented code
- **Steps:**
  1. Document `HyperpromptCommand` struct purpose
  2. Comment complex validation logic
  3. Explain swift-argument-parser conventions used
- **Effort:** 20 minutes
- **Acceptance:** Code is self-documenting
- **Status:** Pending

#### Task 6.2: Document in README
- **Input:** Argument definitions
- **Output:** README section on CLI usage
- **Steps:**
  1. Add "Usage" section to project README
  2. Document each argument with examples
  3. Show common command patterns
  4. Link to PRD for detailed specs
- **Effort:** 30 minutes
- **Status:** Pending

---

## 6. Execution Metadata

| Subtask | Priority | Effort | Depends On | Status |
|---------|----------|--------|-----------|--------|
| 1.1: Command Structure | P1 | 30 min | A1 ✅ | Pending |
| 1.2: Input Argument | P1 | 15 min | 1.1 | Pending |
| 1.3: Output Options | P1 | 30 min | 1.1 | Pending |
| 2.1: Mode Flags | P1 | 30 min | 1.3 | Pending |
| 2.2: Action Flags | P1 | 20 min | 1.3 | Pending |
| 3.1: Help System | P1 | 15 min | 1.3 | Pending |
| 3.2: Version Display | P1 | 10 min | 1.1 | Pending |
| 4.1: Validation Logic | P1 | 20 min | 2.1 | Pending |
| 4.2: Arguments Container | P1 | 30 min | 4.1 | Pending |
| 5.1: Unit Tests | P1 | 1.5h | 4.2 | Pending |
| 5.2: Integration Tests | P1 | TBD | D2 | Blocked |
| 6.1: Inline Comments | P1 | 20 min | All code | Pending |
| 6.2: README Docs | P1 | 30 min | 6.1 | Pending |

**Total Estimated Effort:** 4 hours (as specified in Workplan)

---

## 7. Edge Cases & Failure Scenarios

### 7.1 Argument Errors Handled by swift-argument-parser

- **Unknown flag:** `hyperprompt root.hc --unknown` → Error message, exit 2
- **Wrong type:** `hyperprompt` (missing input) → Error: "Missing required argument"
- **Duplicate option:** `hyperprompt root.hc -o out.md -o out2.md` → Error: "Cannot specify multiple times"

### 7.2 Custom Validation

- **Both strict and lenient:** `hyperprompt root.hc --strict --lenient` → Custom error with clear message
- **No other custom validation in D1** — file existence and path validity deferred to D2 Driver

### 7.3 Special Cases

- **Empty string for input:** `hyperprompt ""` → Parses as empty string, validation in D2
- **Whitespace in paths:** `hyperprompt "path with spaces.hc"` → Quotes handled by shell, passed correctly
- **Relative vs. absolute paths:** Both accepted, normalization in D2
- **No arguments:** `hyperprompt` → Error: "Missing required argument '<input>'"

---

## 8. Acceptance Criteria

### 8.1 Functional Acceptance

- [x] `HyperpromptCommand` defined and compiles without warnings
- [x] All documented arguments parsed correctly:
  - Input file (positional)
  - --output, -o (optional)
  - --manifest, -m (optional)
  - --root, -r (optional)
  - --strict / --lenient (mutually exclusive mode flags)
  - --verbose, -v (action flag)
  - --stats (action flag)
  - --dry-run (action flag)
  - --version (version flag)
  - --help, -h (help flag)
- [x] Help text accurate and auto-generated
- [x] Version display works (`--version`)
- [x] Validation: strict XOR lenient constraint enforced
- [x] Error messages clear and helpful

### 8.2 Quality Acceptance

- [x] Zero compiler warnings
- [x] Code follows Swift conventions and style
- [x] Tests pass (20+ test cases covering all argument combinations)
- [x] Code coverage > 85% for CLI module
- [x] Inline documentation present for non-obvious logic

### 8.3 Integration Acceptance

- [x] Output compatible with D2 Driver:
  - Can create `CompilerArguments` struct from parsed flags
  - All required fields available
  - No missing or extraneous data
- [x] Ready to pass to compiler phases (C2 Emitter, B4 Resolver, etc.)

### 8.4 Exit Codes

- `0`: Help, version, or successful parse (let driver determine actual success)
- `2`: Invalid arguments (swift-argument-parser standard)

---

## 9. Dependencies & Blocking

### 9.1 Input Dependencies

- ✅ **A1: Project Initialization** — swift-argument-parser already configured in Package.swift

### 9.2 Output Dependencies (Blocks)

- **D2: Compiler Driver** — Requires D1 complete; driver consumes parsed arguments

### 9.3 Related Tasks

- **Phase 6 Overall:** D1 is first step; enables D2-D4 in same phase
- **E1: Test Corpus:** Tests created once D1 and D2 both functional (integration tests)

---

## 10. Implementation Notes

### 10.1 swift-argument-parser Best Practices

1. **Use `@Argument` for positional args** — not `@Option`
2. **Use `@Option` for flags with values** — supports short and long forms
3. **Use `@Flag` for boolean flags** — default false, set true if present
4. **Use `@OptionGroup` for organizing related options** — optional, for clarity
5. **Leverage auto-generated help** — avoid manual help text

### 10.2 Error Handling Strategy

- Let swift-argument-parser handle basic validation (type checking, required args)
- Custom validation in `run()` method for business logic (strict XOR lenient)
- Defer file/path validation to driver (D2)
- Use `throw` for errors; swift-argument-parser catches and formats

### 10.3 Testing Approach

- Unit tests in `Tests/CLITests/`
- Test both successful parsing and error cases
- Use `XCTestDynamicOverlay` or command-line simulation if needed
- Mock compiler driver for integration tests (later)

### 10.4 Version Management

- Store version string in `CommandConfiguration(version: "0.1.0")`
- Consider centralizing version in a constant for DRY
- Update as part of release process (Phase 9)

### 10.5 Help Text Quality

- Keep help text concise but informative
- Mention defaults where applicable (handled in D2)
- Use consistent terminology from PRD glossary

---

## 11. Success Metrics

| Metric | Target | Verification |
|--------|--------|--------------|
| Compilation warnings | 0 | Swift compiler output |
| Test pass rate | 100% | XCTest results |
| Code coverage (CLI) | > 85% | Code coverage tool |
| Argument parsing time | < 10ms | Benchmark or profiling |
| Help text accuracy | 100% | Manual review + tests |
| Validation coverage | 100% of cases | Test matrix |

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-09 | Claude Code | Initial PRD generation from task D1 specification |

---

## Appendix A: Swift Argument Parser Reference

```swift
// Import
import ArgumentParser

// Command structure
@main
struct YourCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "name",
        abstract: "Description",
        version: "1.0.0"
    )

    // Positional argument
    @Argument(help: "...")
    var inputFile: String

    // Option with value
    @Option(name: .shortAndLong, help: "...")
    var output: String?

    // Flag (boolean, no value)
    @Flag(name: .shortAndLong, help: "...")
    var verbose: Bool = false

    // Run method called after parsing
    func run() throws {
        // Validation and execution
    }
}
```

---

## Appendix B: Test Cases Checklist

```
Argument Parsing Tests:
[ ] Input file parsed correctly
[ ] --output option recognized
[ ] -o short form works
[ ] --manifest option recognized
[ ] -m short form works
[ ] --root option recognized
[ ] -r short form works
[ ] --lenient flag recognized
[ ] --strict flag works (or implicit)
[ ] --verbose flag recognized
[ ] -v short form works
[ ] --stats flag recognized
[ ] --dry-run flag recognized
[ ] --version flag recognized (displays version, exit 0)
[ ] --help flag recognized (displays help, exit 0)
[ ] -h short form works

Validation Tests:
[ ] Both --strict and --lenient specified → error
[ ] Missing input file → error
[ ] Unknown flag → error
[ ] Valid combinations all parse correctly

Integration Readiness:
[ ] CompilerArguments struct can be created from parsed args
[ ] All fields present for D2 Driver consumption
```

---

**Archived:** 2025-12-09

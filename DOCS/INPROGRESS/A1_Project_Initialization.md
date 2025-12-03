# PRD: A1 — Project Initialization

**Task ID:** A1
**Task Name:** Project Initialization
**Version:** 1.0.0
**Date:** December 3, 2025
**Status:** Ready for Implementation

---

## 1. Scope and Intent

### 1.1 Objective

Establish the foundational project structure for the Hyperprompt Compiler v0.1. This task creates the Swift package infrastructure, configures all dependencies, defines module boundaries, and verifies the build system. This is the entry point for the entire project — **all other tasks are blocked until this is complete**.

### 1.2 Primary Deliverables

- Working Swift package with proper directory structure
- Package.swift with three dependencies configured:
  - swift-argument-parser (v1.2.0+)
  - swift-crypto (v3.0.0+)
  - SpecificationCore (v1.0.0+)
- Six module targets defined: Core, Parser, Resolver, Emitter, CLI, Statistics
- Matching test targets for all modules
- Verified build system (`swift build` succeeds)
- Verified test framework (`swift test` runs empty suite)

### 1.3 Success Criteria

✅ `swift build` completes without errors
✅ All module directories created and properly structured
✅ All three dependencies resolved successfully
✅ Empty test suite runs with `swift test`
✅ Module boundaries clearly defined in Package.swift
✅ Directory structure matches specification

### 1.4 Constraints

- Swift 5.9+ required for Package.swift format
- Platform support: macOS 12+, Linux
- Must use exact dependency URLs and version constraints
- Module structure must follow Design Spec architecture
- No implementation code in this task (structure only)

### 1.5 External Dependencies

- **Swift toolchain**: Version 5.9 or later
- **GitHub packages**:
  - https://github.com/apple/swift-argument-parser
  - https://github.com/apple/swift-crypto
  - https://github.com/SoundBlaster/SpecificationCore
- **Network access**: Required for dependency resolution

---

## 2. Hierarchical Task Breakdown

### 2.1 Phase 1: Directory Structure Creation

**Goal:** Create all required directories for sources and tests

#### Task 1.1: Create Sources Directory Structure
- **Input:** Empty project directory
- **Process:**
  - Create `Sources/` root directory
  - Create module subdirectories: Core, Parser, Resolver, Emitter, CLI, Statistics
  - Verify directory permissions and ownership
- **Output:** Complete Sources/ directory tree
- **Dependencies:** None
- **Parallel Execution:** Can run in parallel with Task 1.2

#### Task 1.2: Create Tests Directory Structure
- **Input:** Empty project directory
- **Process:**
  - Create `Tests/` root directory
  - Create test subdirectories: CoreTests, ParserTests, ResolverTests, EmitterTests, CLITests, StatisticsTests, IntegrationTests
  - Verify directory permissions and ownership
- **Output:** Complete Tests/ directory tree
- **Dependencies:** None
- **Parallel Execution:** Can run in parallel with Task 1.1

### 2.2 Phase 2: Package Configuration

**Goal:** Configure Package.swift with dependencies and targets

#### Task 2.1: Add Dependencies Section
- **Input:** Package.swift template
- **Process:**
  - Add swift-argument-parser dependency with URL and version
  - Add swift-crypto dependency with URL and version
  - Add SpecificationCore dependency with URL and version
  - Verify dependency syntax
- **Output:** Package.swift with dependencies section
- **Dependencies:** None
- **Parallel Execution:** Can run in parallel with Phase 1

#### Task 2.2: Define Core Module Target
- **Input:** Package.swift with dependencies
- **Process:**
  - Define Core target with swift-crypto dependency
  - Define CoreTests target with Core dependency
  - Specify target type and dependencies
- **Output:** Core module defined
- **Dependencies:** Task 2.1
- **Parallel Execution:** No (sequential after 2.1)

#### Task 2.3: Define Parser Module Target
- **Input:** Package.swift with Core module
- **Process:**
  - Define Parser target with Core dependency
  - Define ParserTests target with Parser dependency
  - Specify target type and dependencies
- **Output:** Parser module defined
- **Dependencies:** Task 2.2
- **Parallel Execution:** No (sequential after 2.2)

#### Task 2.4: Define Resolver Module Target
- **Input:** Package.swift with Parser module
- **Process:**
  - Define Resolver target with Core and Parser dependencies
  - Define ResolverTests target with Resolver dependency
  - Specify target type and dependencies
- **Output:** Resolver module defined
- **Dependencies:** Task 2.3
- **Parallel Execution:** No (sequential after 2.3)

#### Task 2.5: Define Emitter Module Target
- **Input:** Package.swift with Resolver module
- **Process:**
  - Define Emitter target with Core and Parser dependencies
  - Define EmitterTests target with Emitter dependency
  - Specify target type and dependencies
- **Output:** Emitter module defined
- **Dependencies:** Task 2.4
- **Parallel Execution:** No (sequential after 2.4)

#### Task 2.6: Define Statistics Module Target
- **Input:** Package.swift with Emitter module
- **Process:**
  - Define Statistics target with Core dependency
  - Define StatisticsTests target with Statistics dependency
  - Specify target type and dependencies
- **Output:** Statistics module defined
- **Dependencies:** Task 2.5
- **Parallel Execution:** No (sequential after 2.5)

#### Task 2.7: Define CLI Module Target
- **Input:** Package.swift with Statistics module
- **Process:**
  - Define CLI executableTarget with all dependencies
  - Define CLITests target with CLI dependency
  - Specify ArgumentParser dependency
- **Output:** CLI module defined
- **Dependencies:** Task 2.6
- **Parallel Execution:** No (sequential after 2.6)

#### Task 2.8: Define Integration Tests Target
- **Input:** Package.swift with all modules
- **Process:**
  - Define IntegrationTests target with Core, Parser, Resolver, Emitter, CLI dependencies
  - Specify test target type
- **Output:** IntegrationTests module defined
- **Dependencies:** Task 2.7
- **Parallel Execution:** No (sequential after 2.7)

### 2.3 Phase 3: Verification

**Goal:** Verify build system and test framework work correctly

#### Task 3.1: Resolve Dependencies
- **Input:** Complete Package.swift
- **Process:**
  - Run `swift package resolve`
  - Verify all three dependencies downloaded
  - Check Package.resolved created
- **Output:** Dependencies resolved
- **Dependencies:** Tasks 1.1, 1.2, 2.1-2.8
- **Parallel Execution:** No (must run after all previous tasks)

#### Task 3.2: Build Package
- **Input:** Resolved dependencies
- **Process:**
  - Run `swift build`
  - Verify build completes without errors
  - Check build artifacts created
- **Output:** Successful build
- **Dependencies:** Task 3.1
- **Parallel Execution:** No (sequential after 3.1)

#### Task 3.3: Run Test Suite
- **Input:** Built package
- **Process:**
  - Run `swift test`
  - Verify empty test suite runs successfully
  - Check test output for errors
- **Output:** Test suite passes
- **Dependencies:** Task 3.2
- **Parallel Execution:** No (sequential after 3.2)

---

## 3. Task Metadata

### 3.1 Priority and Effort Estimates

| Task | Priority | Effort | Complexity |
|------|----------|--------|------------|
| 1.1 Directory Structure (Sources) | High | 15 min | Low |
| 1.2 Directory Structure (Tests) | High | 15 min | Low |
| 2.1 Add Dependencies | High | 15 min | Low |
| 2.2 Core Module | High | 10 min | Low |
| 2.3 Parser Module | High | 10 min | Low |
| 2.4 Resolver Module | High | 10 min | Low |
| 2.5 Emitter Module | High | 10 min | Low |
| 2.6 Statistics Module | High | 10 min | Low |
| 2.7 CLI Module | High | 15 min | Medium |
| 2.8 IntegrationTests | High | 10 min | Low |
| 3.1 Resolve Dependencies | High | 10 min | Low |
| 3.2 Build Package | High | 5 min | Low |
| 3.3 Run Test Suite | High | 5 min | Low |

**Total Estimated Time:** 2 hours

### 3.2 Required Tools and Frameworks

- **Swift toolchain**: 5.9 or later
- **Terminal/Shell**: For executing build commands
- **Git**: For version control (optional but recommended)
- **Text editor/IDE**: For editing Package.swift

### 3.3 Acceptance Criteria per Task

**Phase 1 Tasks:**
- All directories exist with correct names
- Directory structure matches specification exactly
- No permission errors

**Phase 2 Tasks:**
- Package.swift syntax is valid
- All dependencies specified with correct URLs and versions
- All module targets defined with correct dependencies
- Executable target properly marked

**Phase 3 Tasks:**
- `swift package resolve` completes successfully
- All three dependencies appear in Package.resolved
- `swift build` exits with code 0
- `swift test` exits with code 0

### 3.4 Verification Methods

Each task must be verified using the following methods:

| Task | Verification Method | Expected Result |
|------|---------------------|-----------------|
| 1.1, 1.2 | `ls -la` command | All directories exist |
| 2.1-2.8 | `swift package dump-package` | Valid JSON output |
| 3.1 | `cat Package.resolved` | Three dependencies listed |
| 3.2 | `swift build && echo $?` | Exit code 0 |
| 3.3 | `swift test && echo $?` | Exit code 0 |

---

## 4. Functional Requirements

### 4.1 Directory Structure

The project must implement the following directory structure:

```
Hyperprompt/
├── Package.swift           # Swift package manifest
├── README.md              # Project documentation (pre-existing)
├── Sources/               # Source code root
│   ├── Core/              # Core types and utilities
│   ├── Parser/            # Lexer and parser
│   ├── Resolver/          # Reference resolution
│   ├── Emitter/           # Markdown generation
│   ├── CLI/               # Command-line interface
│   │   └── main.swift     # Executable entry point
│   └── Statistics/        # Metrics collection
├── Tests/                 # Test code root
│   ├── CoreTests/         # Core module tests
│   ├── ParserTests/       # Parser module tests
│   ├── ResolverTests/     # Resolver module tests
│   ├── EmitterTests/      # Emitter module tests
│   ├── CLITests/          # CLI module tests
│   ├── StatisticsTests/   # Statistics module tests
│   └── IntegrationTests/  # End-to-end tests
└── DOCS/                  # Documentation (pre-existing)
    ├── PRD/
    ├── RESOLUTIONS/
    ├── INPROGRESS/
    └── Workplan.md
```

### 4.2 Module Boundaries

Each module has clearly defined responsibilities:

**Core Module**
- Purpose: Basic types, error handling, file system abstraction
- Dependencies: swift-crypto
- Exports: SourceLocation, CompilerError, FileSystem protocol

**Parser Module**
- Purpose: Lexer, AST, Parser
- Dependencies: Core
- Exports: Token, Node, Program, Lexer, Parser

**Resolver Module**
- Purpose: Reference resolution, dependency tracking
- Dependencies: Core, Parser
- Exports: ReferenceResolver, DependencyTracker, FileLoader

**Emitter Module**
- Purpose: Markdown generation, heading adjustment
- Dependencies: Core, Parser
- Exports: MarkdownEmitter, HeadingAdjuster, ManifestGenerator

**CLI Module**
- Purpose: Argument parsing, driver orchestration
- Dependencies: Core, Parser, Resolver, Emitter, Statistics, ArgumentParser
- Exports: Executable target (hyperprompt)

**Statistics Module**
- Purpose: Metrics collection and reporting
- Dependencies: Core
- Exports: StatsCollector, StatsReporter

### 4.3 Dependency Configuration

Package.swift must declare exactly three external dependencies:

1. **swift-argument-parser**
   - URL: `https://github.com/apple/swift-argument-parser`
   - Version: `from: "1.2.0"`
   - Purpose: CLI argument parsing

2. **swift-crypto**
   - URL: `https://github.com/apple/swift-crypto`
   - Version: `from: "3.0.0"`
   - Purpose: SHA256 hash computation

3. **SpecificationCore**
   - URL: `https://github.com/SoundBlaster/SpecificationCore`
   - Version: `from: "1.0.0"`
   - Purpose: Declarative validation rules

### 4.4 Build Products

The package must produce one executable product:

- **Name:** `hyperprompt`
- **Type:** Executable
- **Target:** CLI module

---

## 5. Non-Functional Requirements

### 5.1 Platform Compatibility

- **macOS:** Version 12 or later
- **Linux:** Compatible with Swift on Linux
- **Architecture:** Both Intel (x86_64) and Apple Silicon (ARM64)

### 5.2 Build Performance

- Initial build (clean): Acceptable if completes within 5 minutes
- Incremental builds: Not applicable for this task
- Dependency resolution: Should complete within 2 minutes with good network

### 5.3 Code Organization

- Clear module separation enforced by SPM
- No circular dependencies between modules
- One-way dependency flow: CLI → Emitter/Resolver → Parser → Core

### 5.4 Maintainability

- Package.swift must be readable and well-commented
- Module structure must be obvious from directory layout
- Future modules can be added without refactoring existing structure

---

## 6. Edge Cases and Failure Scenarios

### 6.1 Dependency Resolution Failures

**Scenario:** SpecificationCore repository unavailable or version not found

**Mitigation:**
- Verify internet connectivity before starting
- Check GitHub status if resolution fails
- Consider using cached dependencies if available

**Error Handling:**
- Document error message received
- Verify repository URL is correct
- Try alternative version constraints if needed

### 6.2 Build Failures

**Scenario:** Swift compiler version incompatible

**Mitigation:**
- Verify Swift version with `swift --version` before starting
- Update Swift toolchain if version < 5.9
- Document required Swift version in README

**Error Handling:**
- Clear error message about Swift version requirement
- Provide link to Swift installation instructions

### 6.3 Permission Errors

**Scenario:** Cannot create directories or write Package.swift

**Mitigation:**
- Verify write permissions in project directory
- Run with appropriate user permissions
- Avoid system directories

**Error Handling:**
- Document permission requirements
- Provide troubleshooting steps for permission errors

### 6.4 Platform-Specific Issues

**Scenario:** Different behavior on macOS vs Linux

**Mitigation:**
- Use cross-platform Swift features only
- Test directory creation on both platforms
- Avoid platform-specific APIs in Package.swift

**Error Handling:**
- Document any known platform differences
- Provide platform-specific workarounds if needed

---

## 7. Quality Enforcement Rules

### 7.1 Code Quality Standards

- ✅ All code must compile without warnings
- ✅ Package.swift must follow Swift Package Manager conventions
- ✅ Directory names must use PascalCase for modules
- ✅ No hardcoded paths or platform-specific assumptions
- ✅ Module dependencies must form a directed acyclic graph (DAG)

### 7.2 Testing Standards

- ✅ Each module target must have corresponding test target
- ✅ Test targets must depend only on their module (no cross-test dependencies)
- ✅ IntegrationTests can depend on multiple modules
- ✅ `swift test` must complete successfully even with no tests

### 7.3 Documentation Standards

- ✅ Package.swift must include comments explaining module purposes
- ✅ README must be updated with build instructions (optional for this task)
- ✅ Module directories should include placeholder files to commit structure

### 7.4 Validation Checklist

Before marking this task complete, verify:

- [ ] All 6 source module directories exist
- [ ] All 7 test module directories exist
- [ ] Package.swift contains all 3 dependencies
- [ ] Package.swift defines all 6 module targets
- [ ] Package.swift defines CLI as executableTarget
- [ ] Package.swift defines all test targets
- [ ] `swift package resolve` succeeds
- [ ] Package.resolved contains 3 dependencies
- [ ] `swift build` exits with code 0
- [ ] `swift test` exits with code 0
- [ ] No compiler warnings produced
- [ ] Module dependency graph is acyclic
- [ ] Git repository is clean (if using version control)

---

## 8. Implementation Template

### 8.1 Package.swift Template

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Hyperprompt",
    platforms: [
        .macOS(.v12),
        .linux
    ],
    products: [
        .executable(
            name: "hyperprompt",
            targets: ["CLI"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.2.0"
        ),
        .package(
            url: "https://github.com/apple/swift-crypto",
            from: "3.0.0"
        ),
        .package(
            url: "https://github.com/SoundBlaster/SpecificationCore",
            from: "1.0.0"
        )
    ],
    targets: [
        // Core module
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        ),

        // Parser module
        .target(
            name: "Parser",
            dependencies: ["Core"]
        ),
        .testTarget(
            name: "ParserTests",
            dependencies: ["Parser"]
        ),

        // Resolver module
        .target(
            name: "Resolver",
            dependencies: ["Core", "Parser"]
        ),
        .testTarget(
            name: "ResolverTests",
            dependencies: ["Resolver"]
        ),

        // Emitter module
        .target(
            name: "Emitter",
            dependencies: ["Core", "Parser"]
        ),
        .testTarget(
            name: "EmitterTests",
            dependencies: ["Emitter"]
        ),

        // Statistics module
        .target(
            name: "Statistics",
            dependencies: ["Core"]
        ),
        .testTarget(
            name: "StatisticsTests",
            dependencies: ["Statistics"]
        ),

        // CLI module
        .executableTarget(
            name: "CLI",
            dependencies: [
                "Core",
                "Parser",
                "Resolver",
                "Emitter",
                "Statistics",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "CLITests",
            dependencies: ["CLI"]
        ),

        // Integration tests
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "Core",
                "Parser",
                "Resolver",
                "Emitter",
                "CLI"
            ]
        )
    ]
)
```

### 8.2 CLI Entry Point Template (Sources/CLI/main.swift)

```swift
import ArgumentParser

@main
struct Hyperprompt: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hyperprompt",
        abstract: "Hyperprompt Compiler v0.1",
        version: "0.1.0"
    )

    mutating func run() throws {
        // Implementation in future tasks
        print("Hyperprompt Compiler v0.1 - Placeholder")
    }
}
```

---

## 9. Dependencies and Blockers

### 9.1 Upstream Dependencies

**None** — This is the first task (A1), entry point for the project.

### 9.2 Downstream Blockers

This task blocks **all other tasks** in the project:

- **A2:** Core Types Implementation (requires Core module structure)
- **A3:** Domain Types for Specifications (requires Core module structure)
- **A4:** Parser & AST Construction (requires Parser module structure)
- **B1-B4:** All Resolver tasks (require Resolver module structure)
- **C1-C3:** All Emitter tasks (require Emitter module structure)
- **D1-D4:** All CLI tasks (require CLI module structure)
- **E1-E3:** All Testing tasks (require test infrastructure)
- **Phase 3-9:** All subsequent phases (require foundational structure)

### 9.3 Critical Path Impact

This task is on the **critical path** with estimated duration of 2 hours. Any delay here delays the entire 47-hour critical path.

---

## 10. Next Task After Completion

**Task ID:** A2
**Task Name:** Core Types Implementation
**Priority:** [P0] Critical
**Dependencies:** A1 (this task)
**Estimated Time:** 4 hours
**Description:** Define SourceLocation, CompilerError, FileSystem protocol, and basic error handling infrastructure.

---

## 11. References

- **Workplan:** `/home/user/Hyperprompt/DOCS/Workplan.md` (Phase 1, Section A1)
- **PRD §7.1:** Implementation Plan - Task A1
- **Design Spec §2.1:** Module Organization
- **Critical Path:** First task on 47-hour critical chain

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-03 | Claude (via PLAN command) | Initial PRD generation from task A1 |

---

## 13. Notes for Implementation

### 13.1 Recommended Order of Execution

1. Create directory structure (Phases 1.1 and 1.2 in parallel)
2. Write Package.swift using template (Phase 2 sequentially)
3. Create placeholder main.swift for CLI module
4. Run verification commands (Phase 3 sequentially)
5. Commit to version control (optional but recommended)

### 13.2 Common Pitfalls to Avoid

- ❌ Don't skip creating test directories (required by Package.swift)
- ❌ Don't use older swift-tools-version (must be 5.9+)
- ❌ Don't forget `.executableTarget` for CLI (not `.target`)
- ❌ Don't create circular dependencies between modules
- ❌ Don't add implementation code yet (structure only)

### 13.3 Optional Enhancements

- Create `.gitkeep` files in empty directories
- Add `.gitignore` for Swift build artifacts
- Create placeholder README files in each module
- Set up CI/CD configuration (GitHub Actions, etc.)

These enhancements are **not required** for task completion but may help with workflow.

---

**END OF PRD**

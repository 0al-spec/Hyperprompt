# Next Task: A1 — Project Initialization

**Priority:** [P0] Critical
**Phase:** 1 — Foundation & Core Types
**Track:** A (Core Compiler)
**Estimated Time:** 2 hours
**Dependencies:** None (entry point)
**Blocks:** All other tasks

---

## Description

Establish the foundational project structure for the Hyperprompt Compiler v0.1. This is the entry point for the entire project — nothing else can proceed until this task is complete.

---

## Tasks Checklist

- [ ] Create Swift package with appropriate directory structure
  - [ ] Create `Sources/` directory
  - [ ] Create subdirectories for modules:
    - [ ] `Sources/Core/`
    - [ ] `Sources/Parser/`
    - [ ] `Sources/Resolver/`
    - [ ] `Sources/Emitter/`
    - [ ] `Sources/CLI/`
    - [ ] `Sources/Statistics/`
  - [ ] Create `Tests/` directory with matching structure

- [ ] Configure `Package.swift` with dependencies:
  - [ ] Add `swift-argument-parser` dependency
  - [ ] Add `swift-crypto` dependency
  - [ ] Add `SpecificationCore` dependency from GitHub
  - [ ] Define all target modules (Core, Parser, Resolver, Emitter, CLI, Statistics)
  - [ ] Define test targets for each module

- [ ] Establish module boundaries
  - [ ] Core module: Basic types, error handling, file system abstraction
  - [ ] Parser module: Lexer, AST, Parser
  - [ ] Resolver module: Reference resolution, dependency tracking
  - [ ] Emitter module: Markdown generation, heading adjustment
  - [ ] CLI module: Argument parsing, driver orchestration
  - [ ] Statistics module: Metrics collection and reporting

- [ ] Set up test target structure
  - [ ] CoreTests
  - [ ] ParserTests
  - [ ] ResolverTests
  - [ ] EmitterTests
  - [ ] CLITests
  - [ ] IntegrationTests

- [ ] Verify build system
  - [ ] Run `swift build` — must complete without errors
  - [ ] Run `swift test` — must run empty test suite successfully

---

## Acceptance Criteria

✅ Project builds successfully with `swift build`
✅ All module directories created and properly structured
✅ All three dependencies (argument-parser, swift-crypto, SpecificationCore) resolved
✅ Empty test suite runs with `swift test`
✅ Module boundaries clearly defined in Package.swift

---

## Package.swift Template

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

---

## Directory Structure

```
Hyperprompt/
├── Package.swift
├── README.md
├── Sources/
│   ├── Core/
│   ├── Parser/
│   ├── Resolver/
│   ├── Emitter/
│   ├── CLI/
│   │   └── main.swift
│   └── Statistics/
├── Tests/
│   ├── CoreTests/
│   ├── ParserTests/
│   ├── ResolverTests/
│   ├── EmitterTests/
│   ├── CLITests/
│   ├── StatisticsTests/
│   └── IntegrationTests/
└── DOCS/
    ├── PRD/
    ├── RESOLUTIONS/
    ├── INPROGRESS/
    └── Workplan.md
```

---

## Next Task After Completion

**A2: Core Types Implementation [P0]**
- Dependencies: A1 (this task)
- Estimated: 4 hours
- Defines SourceLocation, CompilerError, FileSystem protocol

---

## Notes

- Swift 5.9+ required for Package.swift format
- macOS 12+ required for platform support
- Linux compatibility must be ensured from the start
- All dependencies should use semantic versioning constraints
- Module boundaries enforce separation of concerns

---

## References

- **Workplan:** `/home/user/Hyperprompt/DOCS/Workplan.md` (Phase 1, Section A1)
- **PRD §7.1:** Implementation Plan - Task A1
- **Critical Path:** First task on 47-hour critical chain

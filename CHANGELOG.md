# Changelog

All notable changes to the Hyperprompt Compiler project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-16

### Added

- **Core Compilation Pipeline**: Complete Hypercode (.hc) to Markdown (.md) compilation
- **Recursive File References**: Support for embedding both Markdown (.md) and Hypercode (.hc) files inline
- **Circular Dependency Detection**: Comprehensive cycle detection preventing infinite recursion
- **Heading Adjustment**: Automatic ATX and Setext heading level adjustment based on nesting depth
- **Manifest Generation**: JSON manifest with SHA256 hashes, ISO 8601 timestamps, and alphabetically sorted keys
- **Strict and Lenient Modes**: Choose between error-on-missing-file (strict, default) or treat-as-text (lenient)
- **Comprehensive CLI**: Full command-line interface with 11 options and flags
- **Declarative Grammar Validation**: SpecificationCore-based composable specifications for all syntax rules
- **Deterministic Output**: Byte-for-byte identical compilation across platforms and runs
- **Cross-Platform Support**: Verified on macOS ARM64 (Apple Silicon) and Linux x86_64 (Ubuntu 22.04/24.04)
- **Error Diagnostics**: Clear error messages with source locations, context lines, and caret positioning
- **ANSI Color Support**: Terminal-aware colorized output with automatic detection

### Performance

- **1000-Node Tree Compilation**: 853ms vs 5000ms target (5.9x faster than requirement)
- **Linear Scaling**: O(n) complexity verified with R² = 0.984 (exceeds 0.95 target)
- **Large File Handling**: 3.5 MB compiled in 853ms
- **Large Corpus**: 120 files compiled in 206ms
- **High Throughput**: ~580 files/second for simple files, ~4-5 MB/s for large embedded files

### Documentation

- **README**: Quick start guide, installation instructions, common workflows
- **USAGE.md**: Comprehensive CLI reference with all flags and examples
- **LANGUAGE.md**: Complete Hypercode grammar specification
- **ARCHITECTURE.md**: System design, module overview, and data flow diagrams
- **ERROR_CODES.md**: Exit code reference with descriptions and troubleshooting
- **FUTURE.md**: Roadmap for v0.2+ features
- **SPECS_INTEGRATION.md**: SpecificationCore integration patterns and examples
- **BUILD_PERFORMANCE.md**: Build optimization strategies
- **Swift Installation Guide**: Complete setup instructions for Linux (DOCS/RULES/02_Swift_Installation.md)

### Testing

- **429 Total Tests**: Comprehensive test suite covering all modules
- **14 Test Corpus Files**: Valid and invalid input scenarios (V01-V14, I01-I10)
- **Cross-Platform Tests**: Verified identical behavior on macOS and Linux
- **Performance Benchmarks**: Scaling tests from 10 to 120 files
- **Manifest Validation**: Python tool validating all specification requirements
- **Zero Test Failures**: 100% test pass rate

### Technical Details

- **Language**: Swift 6.2-dev (compatible with Swift 5.9+)
- **Dependencies**: swift-argument-parser 1.2.0, swift-crypto 3.0.0, SpecificationCore 1.0.0
- **Platforms**: macOS 12+, Linux (Ubuntu 20.04+, Debian 11+)
- **Exit Codes**: 0 (success), 1 (IO error), 2 (syntax error), 3 (resolution error), 4 (internal error)
- **Line Ending Handling**: CRLF/CR normalization to LF, single LF output termination

### Known Limitations

- **No Windows Native Support**: Use WSL (Windows Subsystem for Linux) for Windows
- **No Incremental Compilation**: Full recompilation on every run
- **No IDE Integration**: Command-line interface only (no language server protocol)
- **Statistics Reporting Incomplete**: D4 (Statistics Reporter) deferred to v0.1.1
- **No DMG Package**: macOS users use ZIP archive (DMG planned for v0.1.1)
- **Maximum Nesting Depth**: 10 levels (enforced by specification)

### Security

- **Path Traversal Protection**: Rejects `..` components in file references
- **Extension Validation**: Only `.md` and `.hc` extensions allowed
- **Root Directory Enforcement**: All files must be within specified root
- **No Code Execution**: Compiler does not execute user code
- **Deterministic Hashing**: SHA256 for file integrity verification

## [Unreleased]

### Added

- VS Code extension RPC client with stdio JSON-RPC transport, process lifecycle handling, and basic tests

### Changed

- VS Code extension commands now bootstrap RPC requests to the CLI for indexing
- Performance CI regression check now enforces stress-test thresholds
- Performance test log output clarifies local vs CI targets

### Planned for v0.1.1

- Statistics reporter module completion (D4)
- DMG package for macOS distribution
- Performance profiling with Instruments/Valgrind
- Memory leak detection with sanitizers
- Expanded test corpus (V15+, I11+)

### Planned for v0.2.0

- Incremental compilation support
- Watch mode for iterative development
- Language Server Protocol (LSP) implementation
- Syntax highlighting for editors
- Interactive TUI mode
- Parallel file loading optimization
- Streaming output emitter

---

## Release Notes

For detailed release notes, see [DOCS/RELEASES/v0.1.0/RELEASE_NOTES_v0.1.0.md](DOCS/RELEASES/v0.1.0/RELEASE_NOTES_v0.1.0.md)

## Version History

- [0.1.0] - 2025-12-16 - Initial public release

## Links

- [GitHub Repository](https://github.com/0al-spec/Hyperprompt)
- [Issue Tracker](https://github.com/0al-spec/Hyperprompt/issues)
- [Documentation](https://github.com/0al-spec/Hyperprompt/tree/main/DOCS)

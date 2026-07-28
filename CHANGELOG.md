# Changelog

All notable changes to the Hyperprompt Compiler project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_No unreleased changes yet._

## [0.2.0] - 2026-07-28

### Added

- **Reproducible RFC assembly** with fence-safe composition, deterministic
  manifests, optional exact generated-line source maps, and
  `SOURCE_DATE_EPOCH` support.
- **EditorEngine** as an opt-in Swift package trait, including project indexing,
  link resolution, diagnostics mapping, glob filtering, and editor-oriented
  compilation APIs.
- **Language Server** executable with JSON-RPC framing and core LSP document and
  navigation support.
- **VS Code extension preview** with compilation, diagnostics, navigation,
  live preview, settings, engine discovery, and RPC integration.
- **Incremental parsed-file caching** and dependency-aware invalidation in the
  resolver/compiler pipeline.
- **Statistics reporting** and expanded medium/large performance fixtures.
- **Portable Linux binary artifact contract** for server-side consumers.
- **Automated tagged releases** that build Linux `amd64` and macOS `arm64`
  archives, generate SHA-256 checksums, and publish GitHub Release assets.
- **DocC publication** and expanded architecture, RPC, editor, performance, and
  RFC assembly documentation.

### Changed

- Raised the Swift tools and supported development baseline to Swift 6.2.
- Moved compilation orchestration into a reusable `CompilerDriver` module.
- Made source-map collection opt-in for CLI/server compilation paths that do
  not consume provenance.
- Centralized the product version in `HyperpromptVersion.current`.
- Expanded CI to cover default and Editor traits, no-cache builds, the VS Code
  extension, Linux binary artifacts, documentation, and bounded performance
  regression checks.

### Fixed

- Preserved Markdown fenced examples during hierarchical assembly.
- Prevented included Markdown filenames from becoming synthetic headings.
- Hardened workspace-root validation, path joining, byte-offset handling, glob
  matching, regex failure handling, and NUL-containing ignore patterns.
- Corrected source-map provenance across nested and multi-file compilation.
- Removed a source-map performance regression and made collection lazy.
- Improved signal handling and LSP resolution error behavior.

### Security

- Editor and resolver paths fail closed when inputs escape the configured
  workspace root.
- Invalid ignore patterns and unsupported path forms are rejected rather than
  silently broadened.
- Release artifacts retain exact source commit and repository provenance.

### Compatibility

- The command-line compile workflow remains source-compatible with v0.1.0.
- Swift package consumers now require a Swift 6.2-capable toolchain.
- The VS Code extension remains a preview artifact and is not yet a Marketplace
  release.

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

## Release Notes

For detailed release notes, see
[`Sources/CLI/Documentation.docc/RELEASES/v0.2.0/RELEASE_NOTES_v0.2.0.md`](Sources/CLI/Documentation.docc/RELEASES/v0.2.0/RELEASE_NOTES_v0.2.0.md).

## Version History

- [0.2.0] - 2026-07-28 - Reproducible assembly and editor tooling
- [0.1.0] - 2025-12-16 - Initial public release

## Links

- [GitHub Repository](https://github.com/0al-spec/Hyperprompt)
- [Issue Tracker](https://github.com/0al-spec/Hyperprompt/issues)
- [Documentation](https://github.com/0al-spec/Hyperprompt/tree/main/DOCS)

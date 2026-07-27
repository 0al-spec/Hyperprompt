# Hyperprompt Compiler v0.2.0

**Release date:** 2026-07-28

**Tag:** `v0.2.0`

Hyperprompt v0.2.0 expands the deterministic Hypercode compiler into a
reproducible specification-assembly and editor-tooling platform.

The release keeps the v0.1 command-line compilation workflow while adding exact
source provenance, an optional EditorEngine, an LSP server, a VS Code extension
preview, incremental parsing caches, and portable CI-built server artifacts.

## Highlights

### Reproducible RFC assembly

Hyperprompt can now assemble modular specifications while preserving Markdown
semantics and emitting exact provenance artifacts:

```bash
SOURCE_DATE_EPOCH=1700000000 hyperprompt compile specification.hc \
  --root . \
  --output build/specification.md \
  --manifest build/specification.manifest.json \
  --source-map build/specification.map.json
```

The assembly path provides:

- deterministic Markdown output;
- deterministic manifests;
- opt-in generated-line source maps;
- root-relative source identities;
- nested include provenance;
- fence-safe Markdown composition;
- reproducible timestamps through `SOURCE_DATE_EPOCH`.

Source-map collection remains opt-in so ordinary compilation does not pay its
memory and runtime cost.

### EditorEngine

Swift package consumers can enable the `Editor` trait:

```bash
swift build --traits Editor
swift test --traits Editor
```

EditorEngine includes:

- workspace indexing;
- parsed document models;
- position-to-link queries;
- link resolution;
- diagnostics mapping;
- glob-based include/exclude policies;
- editor-oriented compilation results;
- exact multi-file source maps.

The default package build does not enable the Editor trait.

### Language Server and VS Code preview

The package now includes `hyperprompt-lsp` and an editor-enabled CLI RPC
surface. The repository also contains a VS Code extension preview with:

- syntax highlighting;
- compile and lenient-compile commands;
- diagnostics;
- definition/navigation support;
- live Markdown preview;
- multi-column workflows;
- engine discovery and settings;
- stdio JSON-RPC integration.

The VS Code extension is packaged and tested by CI but is not yet published to
the Visual Studio Marketplace.

### Incremental compilation and performance

The resolver now maintains a parsed-file cache with dependency-aware
invalidation. Performance coverage includes generated medium projects,
stress-test thresholds, and regression checks in CI.

The RFC source-map implementation was also changed from always-on collection to
explicit opt-in after profiling exposed unnecessary overhead for ordinary
compilation.

### Portable server artifact

CI produces a Linux `amd64` binary built with the static Swift standard
library. The artifact includes machine-readable metadata binding it to:

- the source repository;
- the exact source commit;
- the source ref;
- the producing workflow run;
- its OS, architecture, and linkage profile.

## Compatibility

### CLI

Existing v0.1 compilation remains valid:

```bash
hyperprompt root.hc --output compiled.md
```

The explicit form is also supported:

```bash
hyperprompt compile root.hc --output compiled.md
```

### Swift

The package now uses Swift tools version 6.2. Swift package consumers need a
Swift 6.2-capable toolchain.

### Manifest and source-map contracts

Generated manifests continue to identify the compiler version. New source maps
use their own versioned schema and are emitted only when requested.

## Installation

### Prebuilt binaries

Release assets:

- `hyperprompt-0.2.0-macos-arm64.tar.gz`
- `hyperprompt-0.2.0-linux-amd64.tar.gz`
- `SHA256SUMS`

Verify an archive before installation:

```bash
shasum -a 256 -c SHA256SUMS
tar -xzf hyperprompt-0.2.0-macos-arm64.tar.gz
./hyperprompt-0.2.0-macos-arm64/hyperprompt --version
```

On Linux, use `sha256sum -c SHA256SUMS`.

### Build from source

```bash
git clone --branch v0.2.0 --depth 1 \
  https://github.com/0al-spec/Hyperprompt.git
cd Hyperprompt
swift build -c release --product hyperprompt
./.build/release/hyperprompt --version
```

## Security hardening

This release includes:

- workspace-root escape prevention;
- stricter path joining and canonicalization;
- rejection of NUL-containing ignore patterns;
- fail-closed regex handling;
- safer byte-offset and source-location calculations;
- source-bound release artifact metadata.

Hyperprompt compiles declarative documents and does not execute code from
Hypercode input.

## Release validation

The release candidate is validated with:

- 497 default-trait Swift tests;
- 642 Editor-trait Swift tests;
- a production `hyperprompt` build reporting exactly `0.2.0`;
- release metadata consistency checks;
- Linux portable-artifact execution in a minimal container;
- VS Code extension lint, compilation, integration tests, and VSIX packaging;
- bounded performance regression checks.

## Known limitations

- Native Windows binaries are not provided; use WSL.
- The VS Code extension is a preview and is not a Marketplace release.
- Release binaries cover macOS `arm64` and Linux `amd64`.
- Watch mode, interactive TUI, parallel loading, and streaming output remain
  future work.

## Upgrade notes

1. Install Swift 6.2 when building from source.
2. Rebuild clients that import Hyperprompt Swift modules.
3. Request `--source-map` only when exact provenance is needed.
4. Validate generated manifests if downstream tooling pins the compiler version.

For the complete change list, see
[`CHANGELOG.md`](https://github.com/0al-spec/Hyperprompt/blob/v0.2.0/CHANGELOG.md).

# Review — RFC-ASM-1 Deterministic RFC Assembly Hardening

**Branch:** `codex/rfc-asm-1-deterministic-rfc-assembly`  
**Reviewed range:** `origin/main...f4a8651`  
**Date:** 2026-07-27  
**Verdict:** Approve with non-blocking follow-up

## Scope reviewed

- Fence-aware Markdown heading adjustment and source spans.
- Complete compilation provenance and dependency manifest.
- Exact generated-line source map.
- Resolver/cache behavior across strict and lenient compilations.
- Artifact destination validation and publication order.
- Abstract RFC assembly fixtures, documentation, and compatibility surfaces.

## Resolved findings

### Cache and resolution context

Cached resolved programs were previously capable of outliving the source or
resolution context that produced them. Cache entries now bind the exact source
snapshot, canonical resolution root, and resolution mode. Lenient resolution
does not publish resolved programs into the shared cache, preventing
lenient-to-strict and missing-to-created stale reuse.

### Immutable compilation provenance

Manifest generation previously risked hashing a later filesystem state than the
AST used for emission. The resolver now records the exact bytes used for each
source, detects conflicting repeated reads during one compilation, and fails
closed on source drift. Provenance hashes this immutable compilation snapshot
instead of re-reading files.

### Destination and source collision safety

Markdown, manifest, and source-map destinations are now pairwise distinct after
canonicalization. They may not overwrite the root or any resolved source file.
Sidecars are written before Markdown so the primary publication artifact is
never exposed when a sidecar write fails.

### Source-map exactness

Validation now handles a final line without a trailing LF and rejects absolute,
backslash-separated, dot-segment, and non-root-relative source paths. Generated
separator mappings are trimmed together with trailing separators, including the
empty-final-include case. Emitter cardinality checks no longer depend on
release-disabled assertions or truncating `zip` behavior.

### Compatibility and schema evolution

The previous public `CompilationResult` and Editor emitter initializers remain
available. Manifests now emit `schemaVersion: 1`, while pre-versioned manifests
decode as legacy schema version `0`. File metadata size is defined over the same
normalized LF bytes that are hashed.

## Validation

- Default Swift suite: **493 tests passed**, 13 pre-existing skips.
- Editor trait suite: **638 tests passed**, 16 pre-existing skips.
- DocC generation: passed with 3 pre-existing warnings.
- Abstract RFC fixture and focused compiler/manifest/source-map suites: passed.
- `git diff --check`: passed.

## Architecture assessment

The implementation keeps Markdown as the canonical publication format and uses
Hypercode only as a deterministic assembly layer. It introduces no ASP-specific
profiles, semantics, identifiers, or conformance rules, so it remains suitable
for other modular specifications.

The manifest and source map are reproducibility and traceability artifacts.
Consumers must treat a generation as ready only when the compiler exits
successfully from a clean staging directory. A true transactional
multi-artifact publication protocol is intentionally deferred.

## Non-blocking follow-up

1. **RFC-ASM-2 — Stable Anchors and Local Fragment Validation [P1]**
2. **RFC-ASM-3 — Transactional Artifact Bundle and Ready Marker [P2]**
3. **RFC-ASM-4 — Transparent Nested Hypercode Includes [P2]**

The highest-value next slice for ASP publication is RFC-ASM-2 because it makes
cross-module RFC links verifiable without adding protocol-specific behavior.


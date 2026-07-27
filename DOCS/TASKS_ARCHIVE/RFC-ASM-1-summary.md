# RFC-ASM-1 Summary

## Outcome

Hyperprompt can now assemble a large modular Markdown specification with
deterministic provenance and exact generated-line mappings, without embedding
protocol-specific semantics.

## Delivered

- Fence-aware Markdown heading adjustment with exact source-line spans.
- Complete manifest sources and sorted direct include edges.
- Schema-versioned manifests built from the exact immutable resolver snapshot.
- Root containment after symlink resolution and normalized LF hashing.
- Single-pass `CompilationSourceMap` bound to generated Markdown by SHA-256.
- Strict cache-context validation and fail-closed source-drift detection.
- Canonically distinct artifact destinations with source-overwrite prevention.
- Optional CLI `--source-map` artifact and dry-run validation.
- Backward-compatible EditorEngine adapter without AST re-emission.
- Positive and fail-closed abstract RFC assembly fixtures.
- Reproducible assembly and artifact-contract documentation.

## Validation

- Default suite: 493 tests, 13 pre-existing skips, 0 failures.
- Full Editor-trait suite: 638 tests, 16 pre-existing skips, 0 failures.
- DocC generation: pass with three pre-existing warnings.
- Production CLI generated Markdown, manifest, and source-map artifacts.
- `git diff --check`: pass.

## Follow-Ups

- Stable anchor and local-fragment validation.
- Transactional staged artifact bundle with an explicit ready marker.
- Transparent nested `.hc` include semantics.
- Upstream `SpecificationCore` support for newer Swift toolchains.

---
**Archived:** 2026-07-27

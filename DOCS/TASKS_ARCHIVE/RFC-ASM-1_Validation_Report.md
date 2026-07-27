# RFC-ASM-1 Validation Report

**Task:** Deterministic RFC Assembly Hardening  
**Date:** 2026-07-27  
**Verdict:** PASS

## Scope Validated

- CommonMark-style backtick and tilde fences remain literal during heading
  adjustment.
- Setext collapse retains an inclusive two-line source span.
- Manifest provenance includes every resolved `.hc` and `.md` source and each
  direct include edge.
- Manifest hashes and emitted Markdown derive from one immutable resolver
  snapshot, including cache hits and repeated-source drift detection.
- Strict and lenient resolution contexts cannot contaminate one another.
- Manifest and source-map paths are root-relative and fail closed for sources
  outside `--root`.
- Artifact destinations are canonically distinct and cannot overwrite an input
  source.
- `--source-map` emits a schema-versioned, output-hash-bound artifact with
  complete one-based generated-line coverage.
- EditorEngine adapts the compiler result without re-emitting the AST.
- Positive and negative abstract modular-specification fixtures exercise the
  intended RFC assembly workflow.

## Automated Validation

| Command | Result |
|---|---|
| `swift test` | PASS — 493 tests executed, 13 pre-existing skips, 0 failures |
| `swift test --traits Editor` | PASS — 638 tests executed, 16 pre-existing skips, 0 failures |
| Focused `RFCAssemblyFixtureTests` | PASS — 4 tests, 0 failures |
| Focused Editor/source-map regression tests | PASS — 4 tests, 0 failures |
| DocC generation for `CLI` | PASS — archive generated; 3 pre-existing warnings |
| `git diff --check` | PASS |

The abstract golden document is 273 bytes and maps all 18 generated lines. Its
SHA-256 is:

```text
b3493beb641bbb8cab72832f7e442977bfa665fed1c46b1031b11f38708c3c63
```

## CLI Artifact Validation

The production executable successfully generated all three artifacts from
`Tests/IntegrationTests/Fixtures/RFCAssembly/root.hc` with a fixed
`SOURCE_DATE_EPOCH`:

```text
specification.md
specification.manifest.json
specification.map.json
```

The written source map matches the `CompilationResult`, its `outputSha256`
matches the Markdown bytes, and JSON decoding is covered by integration tests.

## Toolchain Note

The installed stable toolchain is Swift 6.3.2 and the beta toolchain is Swift
6.4. The pinned `SpecificationCore` 1.0.0 checkout has a pre-existing ambiguous
generic initializer under both toolchains. Local validation used a type
annotation in the ignored `.build/checkouts` copy only; no dependency source
change is included in this task. The package remains declared for Swift 6.2.

## Known Out-of-Scope Follow-ups

- Validate explicit stable anchors, duplicate anchors, and local fragments.
- Add a transactional staged artifact bundle with a content-addressed ready
  marker. Until then, only exit status `0` makes a clean staging directory
  authoritative.
- Decide whether nested `.hc` includes should be transparent rather than
  producing a visible filename heading.
- Replace the pinned `SpecificationCore` compatibility workaround with an
  upstream release that supports newer Swift toolchains.

---
**Archived:** 2026-07-27

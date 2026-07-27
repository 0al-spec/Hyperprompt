# RFC-ASM-1 — Deterministic RFC Assembly Hardening

**Status:** Completed  
**Priority:** P1  
**Estimated effort:** 12 hours  
**Dependencies:** None  
**Target:** Hyperprompt Compiler v0.1  

## 1. Objective

Harden Hyperprompt so it can reproducibly assemble a large modular Markdown
specification without protocol-specific logic. The compiler must preserve
Markdown examples, describe every compilation input, and optionally emit an
exact source map from generated Markdown lines back to canonical source files.

The implementation is driven by abstract fixtures using generic modules such as
Core, Authorization, Evidence, and Transport. No Agent Surface Protocol text,
identifiers, or conformance rules belong in Hyperprompt.

## 2. Scope

### 2.1 Deliverables

1. A fence-aware Markdown heading adjustment pipeline.
2. A non-empty deterministic manifest containing all `.hc` and `.md` sources.
3. A deterministic direct-include graph in the manifest.
4. An opt-in `--source-map <path>` CLI artifact generated in the same emission
   pass as the Markdown output.
5. Abstract multi-file RFC fixtures with positive and negative coverage.
6. Updated CLI and assembly documentation.

### 2.2 Explicitly out of scope

- ASP-specific semantics, profiles, registries, or identifiers.
- Network link validation.
- GitHub-renderer-generated heading slug compatibility.
- Anchor indexing and local-fragment validation. These require a separate
  publication-validation slice after exact assembly provenance exists.
- Browser Source Map v3 / VLQ encoding.
- Full CommonMark container parsing for fenced blocks inside block quotes or
  lists.

## 3. Functional requirements

### FR-1: Fenced code integrity

Heading adjustment must not transform content inside fenced code blocks.

- Recognize backtick and tilde fences.
- An opening fence contains at least three identical markers.
- Permit zero through three leading spaces.
- A backtick opener is invalid when its info string contains a backtick.
- A closing fence uses the same marker, has a run at least as long as the
  opener, and contains only trailing spaces or tabs.
- A different marker, shorter run, or trailing non-whitespace must not close
  the fence.
- An unclosed fence preserves all remaining content through EOF.
- Normalize line endings to LF as before.
- Four-space-indented ATX and Setext-like lines are code, not headings.

### FR-2: Heading transformation provenance

Heading adjustment must expose the source line span for every emitted Markdown
line while preserving the existing `adjustHeadings(in:offset:) -> String` API.

- Normal, ATX, and fenced lines map `N → N`.
- A collapsed Setext pair maps one output line to source span `N...(N+1)`.
- Output order and trailing-LF behavior remain deterministic.

### FR-3: Complete compilation manifest

The production compiler must populate the existing manifest rather than
constructing it from an empty builder.

- Include the root `.hc` source.
- Include every resolved nested `.hc` and `.md` source exactly once.
- Hash normalized LF content with SHA-256.
- Define `size` as the normalized UTF-8 byte count that was hashed.
- Serialize root and source paths relative to `--root`, using `/` separators
  and no leading `./`.
- Reject a source that cannot be represented below `--root`.
- Sort sources by path.
- Preserve deterministic JSON key ordering and exactly one trailing LF.

### FR-4: Direct include graph

The manifest must contain sorted, deduplicated direct include edges:

```json
{
  "from": "root.hc",
  "to": "modules/core.hc"
}
```

- Record `.hc → .hc` and `.hc → .md` edges.
- Attribute an edge to the source file containing the reference, using the
  referencing AST node's exact source location.
- Do not record unresolved references accepted in lenient mode.
- Do not use the process-wide parsed-file cache as authoritative provenance.
- Decode older manifests without `dependencies` as an empty edge set.

### FR-5: Exact source-map artifact

Add an optional CLI argument:

```text
--source-map <path>
```

When present, compilation emits versioned JSON:

```json
{
  "lineBase": 1,
  "mappings": [
    {
      "generatedLine": 1,
      "kind": "hypercode_heading",
      "source": {
        "endLine": 1,
        "path": "root.hc",
        "startLine": 1
      }
    },
    {
      "generatedLine": 2,
      "kind": "generated_separator",
      "source": null
    }
  ],
  "outputSha256": "<sha256-of-generated-markdown>",
  "schemaVersion": 1
}
```

Requirements:

- Use one-based generated and source line numbers.
- Emit mappings in generated-line order.
- Cover every generated Markdown line exactly once.
- Use `source: null` for compiler-generated separators.
- Map Hypercode headings to the exact `Node.location`.
- Map Markdown lines using heading-adjustment source spans.
- Store only root-relative POSIX paths.
- Bind the artifact to exact generated Markdown bytes with SHA-256.
- Generate Markdown and mappings in one emitter traversal.
- Build and validate the map during `--dry-run`, but write no files.
- Existing invocations without `--source-map` remain compatible.

### FR-6: Editor compatibility

EditorEngine must consume the source map produced by the compiler result rather
than re-emitting the AST solely to approximate mappings. Existing
`SourceMap.lookup(outputLine:)` callers may retain their current zero-based
adapter semantics.

## 4. Non-functional requirements

### Determinism

- Two builds of identical source trees with the same
  `SOURCE_DATE_EPOCH` must produce byte-identical Markdown, manifest, and source
  map artifacts even when checkout directories differ.
- Absolute paths must never appear in manifest or source-map JSON.
- Arrays must have explicit deterministic sort order.

### Security and failure behavior

- Root containment is fail-closed.
- Path comparison must be component-aware, not a raw string prefix.
- The compiler must not access the network.
- Strict-mode missing files and circular includes remain compilation failures.

### Compatibility

- Existing `emit(_:) -> String`, heading-adjustment, and CLI behavior remain
  available.
- Existing manifests without a `dependencies` field remain decodable.
- The default build must expose the new compilation source-map model without
  requiring the `Editor` trait.

## 5. Outside-in TDD plan

### Phase A — Markdown integrity

1. Add failing emitter tests for backtick and tilde fences.
2. Add failing tests for fence length, indentation, info strings, closing
   rules, unclosed fences, and Setext content inside fences.
3. Add failing tests for four-space-indented headings.
4. Introduce mapped heading-adjustment output.
5. Implement the minimal fence state machine and line-span tracking.
6. Add an integration fixture that embeds fenced examples below a non-zero
   Hypercode depth.

### Phase B — Provenance

1. Add a failing compiler integration fixture:

   ```text
   root.hc
   ├── intro.md
   └── modules/core.hc
       └── requirements.md
   ```

2. Assert four unique source entries and three direct edges.
3. Add a per-compilation provenance collector over the resolved AST.
4. Reuse `FileLoader` normalization and hashing.
5. Normalize all serialized paths relative to `--root`.
6. Test cache-hit compilation, duplicate includes, CRLF/LF equivalence,
   deterministic sorting, and outside-root rejection.

### Phase C — Single-pass source maps

1. Add failing emitter tests for exact generated-line coverage.
2. Add the versioned source-map model and deterministic encoder.
3. Refactor the emitter to produce Markdown plus mappings in one traversal.
4. Add CLI parsing and writing for `--source-map`.
5. Replace EditorEngine re-emission with an adapter over the compiler map.
6. Add golden abstract RFC `.md`, manifest, and map expectations.
7. Compile equivalent fixture trees in two temporary absolute directories and
   assert byte equality under a fixed `SOURCE_DATE_EPOCH`.

### Phase D — Documentation and validation

1. Document the abstract modular RFC assembly workflow.
2. Correct manifest documentation so it matches the implemented schema.
3. Run default and Editor-trait test suites.
4. Record validation commands and results in the task validation report.

## 6. Required test matrix

### Heading adjustment

- Backtick and tilde fences.
- Info strings.
- Three- and four-marker fences.
- Longer and shorter closers.
- Opposite markers.
- Trailing text versus trailing whitespace.
- Zero through four leading spaces and leading tab.
- Unclosed fence.
- ATX and Setext content inside a fence.
- Heading immediately after a closing fence.
- CRLF normalization.
- Four-space-indented ATX and Setext-like input.

### Manifest

- Root, nested Hypercode, and Markdown sources.
- Direct `.hc → .hc` and `.hc → .md` edges.
- Duplicate source and edge deduplication.
- Root-relative paths only.
- Identical LF/CRLF hash and normalized size.
- Cache-hit compilation remains complete.
- Stable sorting and JSON encoding.
- Backward decoding without `dependencies`.
- Outside-root source rejection.

### Source map

- Exact Hypercode heading location.
- One-to-one Markdown lines.
- Setext `2 → 1` source span.
- Fenced content.
- Generated separator with `source: null`.
- Overflow heading.
- Full output-line coverage.
- Correct output SHA-256.
- Root-relative paths.
- Byte-identical artifacts across checkout directories.
- CLI parsing, successful write, and dry-run no-write behavior.
- EditorEngine adapter compatibility.

## 7. Acceptance criteria

- [x] Fenced code examples are unchanged except for LF normalization.
- [x] Four-space-indented code is not transformed as a heading.
- [x] Production manifests contain all normalized sources and direct edges.
- [x] Manifest and source-map artifacts contain no absolute paths.
- [x] `--source-map` writes a versioned, output-bound, fully covering map.
- [x] EditorEngine no longer re-emits Markdown to build its map.
- [x] Abstract RFC fixtures pass without protocol-specific content.
- [x] Repeated builds in different directories are byte-identical under fixed
      `SOURCE_DATE_EPOCH`.
- [x] `swift test` passes.
- [x] `swift test --traits Editor` passes.
- [x] `git diff --check` passes.

## 8. Validation commands

```sh
swift test
swift test --traits Editor
swift run hyperprompt compile \
  Tests/IntegrationTests/Fixtures/RFCAssembly/root.hc \
  --root Tests/IntegrationTests/Fixtures/RFCAssembly \
  --output /tmp/hyperprompt-rfc.md \
  --manifest /tmp/hyperprompt-rfc.manifest.json \
  --source-map /tmp/hyperprompt-rfc.map.json
git diff --check
```

## 9. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Partial CommonMark implementation | Limit the scanner to ordinary fences with 0–3 spaces and document container fences as a follow-up |
| Source-map drift | Produce output and mappings in the same traversal |
| Machine-local paths | Normalize after canonical containment checks and test two checkout roots |
| Stale cached AST | Collect provenance from the resolved AST on every compilation |
| Manifest schema compatibility | Default missing `dependencies` to an empty array when decoding |
| Large per-line source maps | Keep emission opt-in; range compression can be a later compatible schema version |

## 10. Success metrics

- Zero fenced-example mutations in the abstract corpus.
- 100% generated-line coverage in source maps.
- 100% compilation inputs represented in the manifest.

---
**Archived:** 2026-07-27
- Three byte-identical output artifacts across directory-independent test runs.
- No regression in the default or Editor-trait suites.

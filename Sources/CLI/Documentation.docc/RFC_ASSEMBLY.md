# Modular Specification Assembly

Use Hyperprompt as a deterministic assembly layer for a large Markdown
specification. Hypercode describes document order and hierarchy; Markdown
modules remain the canonical prose.

## Source Layout

Keep the assembly index small and make module names describe stable conceptual
boundaries:

```text
specification/
├── root.hc
└── sections/
    ├── introduction.md
    ├── core.md
    └── evidence.md
```

```hc
"Abstract Specification"
    "sections/introduction.md"
    "sections/core.md"
    "sections/evidence.md"
```

Hyperprompt adjusts headings to their assembled depth. ATX and Setext headings
inside ordinary Markdown are transformed, while content inside backtick or
tilde fenced code blocks is preserved.

## Build All Artifacts

Create the output directory first, then run:

```bash
mkdir -p build
SOURCE_DATE_EPOCH=1700000000 hyperprompt compile \
  specification/root.hc \
  --root specification \
  --output build/specification.md \
  --manifest build/specification.manifest.json \
  --source-map build/specification.map.json
```

Run publication builds in a clean staging directory. The build produces three
complementary artifacts:

| Artifact | Purpose |
|---|---|
| `specification.md` | The assembled publication document |
| `specification.manifest.json` | Normalized source hashes and direct include edges |
| `specification.map.json` | Exact generated-line provenance |

The artifact set is ready only when the compiler exits successfully. Hyperprompt
writes requested sidecars before the Markdown document, but arbitrary output
paths cannot be committed as one filesystem transaction. If compilation or a
write fails, discard the staging directory; partial sidecars from a nonzero exit
are not authoritative. Publish or move the completed directory only after exit
status `0`.

## Manifest Contract

Manifest paths are relative to `--root`. Sources are sorted by path and direct
include edges are sorted by `(from, to)`. SHA-256 and `size` both describe the
same LF-normalized UTF-8 source bytes.

```json
{
  "dependencies": [
    {
      "from": "root.hc",
      "to": "sections/core.md"
    }
  ],
  "root": "root.hc",
  "schemaVersion": 1,
  "sources": [
    {
      "path": "root.hc",
      "sha256": "<64 lowercase hex characters>",
      "size": 106,
      "type": "hypercode"
    }
  ],
  "timestamp": "2023-11-14T22:13:20Z",
  "version": "0.1.0"
}
```

The compiler rejects a source that resolves outside `--root`, including through
a symbolic link.

## Source-Map Contract

The source map is schema-versioned, one-based, sorted by generated line, and
bound to the exact output bytes:

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
  "outputSha256": "<sha256 of specification.md>",
  "schemaVersion": 1
}
```

Each generated Markdown line has exactly one mapping:

- `hypercode_heading` points to the exact quoted `.hc` node.
- `markdown` points to an inclusive source-line span. A collapsed Setext pair
  therefore maps one output line to two input lines.
- `generated_separator` has a null source.

## Validation-Only Builds

`--dry-run` executes parsing, resolution, emission, manifest construction, and
source-map validation, but writes none of the requested files:

```bash
hyperprompt compile specification/root.hc \
  --root specification \
  --source-map build/specification.map.json \
  --dry-run
```

This is useful as a fast pull-request gate. A publication job should run the
non-dry build and retain all three artifacts.

## Reproducibility Checklist

- Pin the Hyperprompt version.
- Set `SOURCE_DATE_EPOCH` to the source revision timestamp.
- Keep all references under one explicit `--root`.
- Commit source modules, not generated outputs, unless repository policy
  requires checked-in artifacts.
- Compare generated Markdown and JSON byte-for-byte in CI.
- Treat compiler exit status `0`, not file presence, as the readiness signal.
- Build in a disposable staging directory and publish the directory only after
  all requested artifacts validate.

Local anchor and fragment validation is intentionally a separate publication
stage. Hyperprompt's assembly map provides the provenance needed for that
validator, but the compiler does not invent renderer-specific heading slugs or
access the network.

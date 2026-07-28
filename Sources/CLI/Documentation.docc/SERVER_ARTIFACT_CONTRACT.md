# Server Artifact Contract

Status: stable v1 contract for CI-produced server-side consumers.

## Purpose

Hyperprompt publishes a Linux binary artifact so server applications can bundle
the compiler without rebuilding Swift sources during their own release and
deployment pipelines. SpecSpace is the first consumer of this contract.

The artifact is a CI handoff artifact, not a package-manager release. Consumers
should validate its metadata before bundling it into a runtime image.

## Artifact Identity

The GitHub Actions artifact name is:

```text
hyperprompt-linux-amd64
```

The artifact contains exactly:

```text
hyperprompt
hyperprompt-artifact.json
```

`hyperprompt` must be executable and runnable in a minimal Linux runtime image.

## Metadata Schema

`hyperprompt-artifact.json` uses `schema_version: 1`.

Required fields:

```json
{
  "artifact_kind": "hyperprompt_linux_binary",
  "schema_version": 1,
  "binary": "hyperprompt",
  "compiler_version": "<stable SemVer>",
  "os": "linux",
  "arch": "amd64",
  "linkage": "static-swift-stdlib",
  "source_repository": "0al-spec/Hyperprompt",
  "source_commit": "<git sha>",
  "source_ref": "<branch or tag>",
  "workflow_run_id": "<github run id>"
}
```

Field meanings:

- `artifact_kind`: stable discriminator for this artifact family.
- `schema_version`: integer metadata schema version.
- `binary`: executable file name inside the artifact.
- `compiler_version`: stable SemVer reported by the packaged compiler binary.
- `os`: target operating system.
- `arch`: target architecture.
- `linkage`: Swift runtime linkage policy; server consumers expect
  `static-swift-stdlib`.
- `source_repository`: repository that built the artifact.
- `source_commit`: commit that produced the artifact.
- `source_ref`: branch or tag name used by the workflow run.
- `workflow_run_id`: GitHub Actions run id that uploaded the artifact.

Breaking metadata changes require a `schema_version` bump. Additive fields may
be introduced under the same schema version when consumers can safely ignore
them.

## Runtime Target

The supported server-side platform is:

```text
linux/amd64
```

CI verifies the artifact in:

```text
python:3.11-slim
```

This image is the compatibility smoke target for SpecSpace API images. Passing
that smoke means the binary can start without requiring a Swift toolchain or
extra Swift runtime libraries in the consumer image.

## CLI Contract for Server Callers

Server callers should invoke Hyperprompt with list-form subprocess arguments.
Do not invoke through a shell.

Version probe:

```text
hyperprompt --version
```

Expected behavior:

- exits `0`;
- writes a human-readable version string to stdout;
- does not require workspace files.

Compile invocation:

```text
hyperprompt <root.hc> --root <workspace-dir> --output <compiled.md> --manifest <manifest.json> --stats
```

Expected behavior:

- exits `0` on successful compile;
- writes compiled Markdown to the path passed by `--output`;
- writes compiler manifest JSON to the path passed by `--manifest`;
- may write informational output to stdout;
- writes diagnostics to stderr on failure.

Server callers are responsible for:

- passing absolute or sandbox-local paths;
- enforcing timeout and input/output limits;
- owning and cleaning the scratch workspace;
- treating stdout/stderr as diagnostics, not as trusted structured protocol.

## Exit Codes

The CLI exit-code contract is:

| Code | Meaning |
| --- | --- |
| `0` | Success |
| `1` | I/O error |
| `2` | Syntax error |
| `3` | Resolution or circular dependency error |
| `4` | Internal compiler error |

Future exit-code changes that would alter these meanings are breaking for
server callers and require coordination with consumers.

## Consumer Validation

Before bundling the artifact, consumers should verify:

1. `hyperprompt-artifact.json` is valid JSON.
2. `schema_version == 1`.
3. `artifact_kind == "hyperprompt_linux_binary"`.
4. `binary == "hyperprompt"`.
5. `compiler_version` is stable SemVer.
6. `os == "linux"`.
7. `arch == "amd64"`.
8. `linkage == "static-swift-stdlib"`.
9. `source_repository == "0al-spec/Hyperprompt"`.
10. `source_commit`, `source_ref`, and `workflow_run_id` are present.
11. `hyperprompt --version` exits `0` in the consumer base image and exactly
    matches `compiler_version`.

SpecSpace performs this validation before building its API image.

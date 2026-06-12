# Hypercode Core Exercise: Hyperprompt Compile Configuration

This is a consumer-side exercise for the Hypercode project backlog. It models a
small Hyperprompt compile configuration as core Hypercode topology plus cascade
sheet values.

## Files

| File | Role |
|---|---|
| `compile-config.hc` | Stable configuration topology. |
| `compile-config.hcs` | Base compile values, `profile=ci`, `profile=editor`, and contracts. |

## Run

Use the Hypercode CLI from the Hypercode repository:

```bash
hypercode validate DOCS/hypercode-core-exercise/compile-config.hc \
  --hcs DOCS/hypercode-core-exercise/compile-config.hcs \
  --ctx profile=ci

hypercode emit DOCS/hypercode-core-exercise/compile-config.hc \
  --hcs DOCS/hypercode-core-exercise/compile-config.hcs \
  --ctx profile=editor \
  --format json
```

## Result

The exercise fits core Hypercode cleanly when the subject is configuration:

- the `.hc` file gives stable anchors for compile inputs, outputs, resolver mode,
  diagnostics, statistics, and editor behavior;
- the `.hcs` file carries profile-specific values without changing topology;
- contracts catch obvious type drift (`enabled`/`verbose`/`rpc` stay bool,
  paths and modes stay strings);
- the resolved IR is a plausible consumer contract if Hyperprompt later wants
  external configuration materialized ahead of time.

It does **not** justify replacing Hyperprompt's own `.hc` language. Hyperprompt
compiles document trees into Markdown, while core Hypercode resolves topology
plus contextual values into IR. The useful integration boundary is therefore
resolved configuration IR, not a shared parser/runtime.

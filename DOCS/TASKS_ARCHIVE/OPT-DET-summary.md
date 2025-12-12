# OPT-DET Summary — Verify deterministic output

**Completion Date:** 2025-12-12
**Status:** Completed

## Deliverables
- Deterministic timestamp provider honoring `HYPERPROMPT_BUILD_TIMESTAMP`/`SOURCE_DATE_EPOCH` with file modification fallback.
- Manifest generation now consumes deterministic timestamp in compiler driver.
- Regression tests covering timestamp resolution paths.

## Validation
- `swift build`
- `swift test`
- Determinism probe with fixed epoch (1700000000) against `Tests/IntegrationTests/Fixtures/Valid/V01.hc`:
  - `diff -u /tmp/run1.sha /tmp/run2.sha` → no differences aside from file paths.
  - Hashes: manifest `fd3ba1c5ee1a3b668246b5bcda864533c220f47938b6f022cf71150884be0150`, markdown `92669ca9e003b6f3ae15b3d15b08d23fe24b0dc52ba06adb2c7bc92f1b92d323`.

## Notes and Next Steps
- Deterministic builds can be forced via `HYPERPROMPT_BUILD_TIMESTAMP` or the reproducible-builds `SOURCE_DATE_EPOCH` variable.
- Default fallback uses source modification time, avoiding wall-clock variance between repeated runs on unchanged inputs.
- Consider extending determinism probes to larger corpus once additional fixtures are available.

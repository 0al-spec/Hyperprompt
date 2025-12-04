# Task Priority

Tasks are prioritized using a three-level system:

- **P0** — Highest priority (critical path, blockers)
- **P1** — Medium priority (important features)
- **P2** — Lowest priority (nice-to-have, polish)

## Selection Rules

1. Always select P0 tasks first
2. Only consider P1 when no P0 tasks available
3. Only consider P2 when no P0 or P1 tasks available

## Tie-Breaking

When multiple tasks have the same priority:
1. Prefer tasks on the critical path
2. Use sequential order from Workplan if still tied
3. Default to Track A in parallel development tracks

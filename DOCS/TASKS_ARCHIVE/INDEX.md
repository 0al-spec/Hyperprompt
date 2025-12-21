# Archived Tasks

This directory contains completed task PRDs and summaries, organized by phase.

---

## Phase 6: CLI & Integration

### D4 — Statistics Reporter **[P2]** ✓ 2025-12-16
- **PRD:** [D4_Statistics_Reporter.md](./D4_Statistics_Reporter.md)
- **Summary:** [D4-summary.md](./D4-summary.md)
- **Effort:** 3 hours
- **Dependencies:** D1 (Compiler Driver)
- **Description:** Implement statistics collection and reporting capability for `--stats` flag

---

## Phase 10: Editor Engine Module

### EE0 — EditorEngine Module Foundation **[P1]** ✓ 2025-12-20
- **Summary:** [EE0-summary.md](./EE0-summary.md)
- **Effort:** 1 hour
- **Dependencies:** D2 (Compiler Driver)
- **Description:** Create foundational structure for EditorEngine module with SPM configuration

### EE1 — Project Indexing **[P1]** ✓ 2025-12-20
- **PRD:** [EE1_Project_Indexing.md](./EE1_Project_Indexing.md)
- **Summary:** [EE1-summary.md](./EE1-summary.md)
- **Effort:** 3 hours
- **Dependencies:** EE0 (EditorEngine Module Foundation)
- **Description:** Implement deterministic workspace indexing for `.hc` and `.md` files with `.hyperpromptignore` rules, metadata, and EditorEngine API access.

### EE2 — Parsing with Link Spans **[P1]** ✓ 2025-12-21
- **PRD:** [EE2_Parsing_with_Link_Spans.md](./EE2_Parsing_with_Link_Spans.md)
- **Summary:** [EE2-summary.md](./EE2-summary.md)
- **Effort:** 3 hours
- **Dependencies:** EE1 (Project Indexing)
- **Description:** Extend parsing to capture link spans with UTF-8 ranges, heuristic link detection, and graceful diagnostics.

### EE3 — Link Resolution **[P1]** ✓ 2025-12-21
- **PRD:** [EE3_Link_Resolution.md](./EE3_Link_Resolution.md)
- **Summary:** [EE3-summary.md](./EE3-summary.md)
- **Effort:** 2 hours
- **Dependencies:** EE2 (Parsing with Link Spans)
- **Description:** Resolve editor link spans using CLI-equivalent path rules with diagnostics and ambiguity handling.

### BUG-EE1-001 — GlobMatcher Pattern Matching Issues ✓ 2025-12-21
- **PRD:** [BUG-EE1-001_GlobMatcher_Pattern_Matching_Issues.md](./BUG-EE1-001_GlobMatcher_Pattern_Matching_Issues.md)
- **Related Task:** EE1 — Project Indexing
- **Description:** Fix `.gitignore`-compatible wildcard semantics (`*` root-only, `**/` zero-or-more dirs)

---

## Statistics

- **Total Archived:** 6 items
- **Total Effort:** 12 hours (tracked tasks only)
- **Phases Represented:** 2 (Phase 6, Phase 10)

---

## Archive Policy

Tasks are archived when:
1. Marked `[x]` as complete in `DOCS/Workplan.md`
2. PRD or summary exists in `DOCS/INPROGRESS/`
3. Task is no longer active in `next.md`

To restore a task:
```bash
mv DOCS/TASKS_ARCHIVE/{TASK_ID}_*.md DOCS/INPROGRESS/
git commit -m "Restore task {TASK_ID}"
```

---

**Last Updated:** 2025-12-21

# PRD: PERF-1 — Performance Baseline & Benchmarks

## 1. Objective & Scope

### 1.1 Goal
Define the **PRD medium fixture** required for performance validation and benchmarking. The fixture must represent a medium-sized Hyperprompt project (20 `.hc` files, 5 `.md` files, ~200 nodes, depth 6) and integrate cleanly with existing performance tests.

### 1.2 In Scope
- Design a deterministic fixture layout that meets the PRD size/depth requirements.
- Implement the fixture under the established performance corpus directory.
- Wire the fixture into performance documentation and (if needed) test harness references.
- Ensure the fixture is repeatable, deterministic, and uses valid Hypercode syntax.

### 1.3 Out of Scope
- Implementing new compiler optimizations (covered by PERF-2+).
- Changing performance measurement thresholds or hardware baselines.
- Large-project (120-file) fixture creation.

### 1.4 Dependencies
- **EE8** (EditorEngine complete) — already satisfied.
- Existing performance test harness in `Tests/PerformanceTests/CompilerPerformanceTests.swift`.

---

## 2. Functional Requirements

1. **Fixture Composition**
   - Provide 20 `.hc` files and 5 `.md` files.
   - Total node count approx. 200 (±10%).
   - Maximum include depth of 6.

2. **Deterministic Content**
   - No randomness or timestamps.
   - Stable ordering of file references.
   - Consistent line endings (LF).

3. **Fixture Integration**
   - Fixture resides under `Tests/TestCorpus/Performance/`.
   - Clear entry point (`medium_project.hc`) with deterministic includes.
   - Documentation references the fixture for PRD medium benchmarks.

---

## 3. Non-Functional Requirements

- **Performance:** Fixture must be representative for <200ms compile target.
- **Maintainability:** Files are organized and named clearly (no opaque names).
- **Portability:** Works on macOS/Linux without platform-specific paths.

---

## 4. Acceptance Criteria

1. Fixture directory contains exactly 20 `.hc` files and 5 `.md` files.
2. Entry file `medium_project.hc` includes other files with maximum depth = 6.
3. Fixture compiles in strict mode without missing references.
4. Documentation references the PRD medium fixture path and entry file.

---

## 5. Task Breakdown

### Phase 1 — Review & Design
| ID | Task | Priority | Effort | Dependencies | Verification |
| --- | --- | --- | --- | --- | --- |
| 1.1 | Review existing performance corpus (`Tests/TestCorpus/Performance`) and current perf tests to align fixture location/entry file usage. | High | 0.3h | None | Notes captured in PRD checklist. |
| 1.2 | Define fixture layout (directory name, file naming, include graph, depth=6, node count target). | High | 0.4h | 1.1 | Draft layout documented. |

### Phase 2 — Implement Fixture
| ID | Task | Priority | Effort | Dependencies | Verification |
| --- | --- | --- | --- | --- | --- |
| 2.1 | Create fixture directory `Tests/TestCorpus/Performance/medium/` with entry file `medium_project.hc`. | High | 0.4h | 1.2 | Files exist and are tracked. |
| 2.2 | Add 19 additional `.hc` files with deterministic content and references matching the include graph. | High | 1.0h | 2.1 | File count verified. |
| 2.3 | Add 5 `.md` files referenced from `.hc` files (headings, paragraphs, list content). | Medium | 0.4h | 2.2 | File count verified. |
| 2.4 | Validate include depth (max 6) and estimated node count (~200). | High | 0.4h | 2.2 | Manual checklist or small helper script notes. |

### Phase 3 — Integrate & Document
| ID | Task | Priority | Effort | Dependencies | Verification |
| --- | --- | --- | --- | --- | --- |
| 3.1 | Update `Tests/PerformanceTests/CompilerPerformanceTests.swift` to reference `medium_project.hc` for PRD medium fixture validation (if not already present). | Medium | 0.4h | 2.4 | Test file references new entry path. |
| 3.2 | Update performance documentation to mention the medium fixture location and entry file (e.g., `Sources/CLI/Documentation.docc/PERFORMANCE.md`). | Medium | 0.3h | 2.4 | Documentation updated. |

---

## 6. Verification Checklist

- [ ] Fixture directory created with expected file counts.
- [ ] Entry file compiles in strict mode with no missing references.
- [ ] Include depth confirmed (max depth = 6).
- [ ] Documentation updated with fixture path and entry file.

---

## 7. Risks & Mitigations

- **Risk:** Fixture accidentally exceeds depth or node count.  
  **Mitigation:** Maintain a simple include tree diagram and manual counts; keep nodes per file consistent.

- **Risk:** Strict mode fails due to missing references.  
  **Mitigation:** Validate every reference by file path; keep all referenced files inside the fixture directory.

---

## 8. Implementation Notes & Templates

### 8.1 Suggested Directory Layout
```
Tests/TestCorpus/Performance/medium/
├── medium_project.hc
├── section_01.hc
├── section_02.hc
├── section_03.hc
├── section_04.hc
├── section_05.hc
├── section_06.hc
├── section_07.hc
├── section_08.hc
├── section_09.hc
├── section_10.hc
├── section_11.hc
├── section_12.hc
├── section_13.hc
├── section_14.hc
├── section_15.hc
├── section_16.hc
├── section_17.hc
├── section_18.hc
├── section_19.hc
├── section_20.hc
├── notes_01.md
├── notes_02.md
├── notes_03.md
├── notes_04.md
└── notes_05.md
```

### 8.2 Include Graph Guidance
- `medium_project.hc` includes 4 top-level sections.
- Each top-level section includes 3-4 subsections.
- One branch should reach depth 6 to satisfy requirement.
- Markdown files referenced via `@"notes_0X.md"` from multiple sections.

---

## 9. Completion Definition

Task is complete when the PRD medium fixture exists, is referenced in documentation/tests, and matches the required size/depth constraints.

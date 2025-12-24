# PRD: PERF-3 — Incremental Compilation — Dependency Graph

## 1. Scope and Intent

### Objective
Implement a dependency graph for incremental compilation that tracks file relationships, identifies dirty files, and recompiles only affected files while preserving output equivalence with full compilation.

### Deliverables
- Dependency graph (file → referenced files) built during compilation.
- Dirty file tracking with propagation to dependents.
- Incremental compile path that reuses cached ASTs and recompiles only dirty nodes.
- Handling for deleted or missing referenced files.
- Unit tests validating incremental vs full compilation equivalence.

### Success Criteria
- Incremental compilation produces identical Markdown and manifest outputs as full compilation.
- Dirty file edits recompile only impacted files and their dependents.
- Deleting referenced files invalidates dependent nodes and reports errors deterministically.
- Unit tests cover dirty tracking, dependency propagation, and deletion cases.

### Constraints and Assumptions
- Parsed file cache from PERF-2 is available and stable.
- Compiler remains deterministic; incremental path must not change output order or content.
- Dependency information is derived from existing resolver output (no new parsing rules).

### External Dependencies
- None beyond existing compiler modules.

---

## 2. Structured TODO Plan

### Phase A — Graph Model and Collection
1. **Define dependency graph model**
   - Map file path → set of referenced file paths.
   - Support reverse lookups (dependents) for invalidation.

2. **Collect dependencies during compile**
   - Hook into resolver output to capture file references per source file.
   - Store graph in compiler driver or cache layer.

### Phase B — Dirty Tracking and Incremental Build
3. **Track dirty files**
   - Mark file dirty when checksum changes or when deleted.
   - Propagate dirty state to dependents via reverse edges.

4. **Incremental compilation path**
   - Recompile only dirty files and their dependents.
   - Reuse cached ASTs for unaffected files.
   - Merge incremental results into full project output deterministically.

5. **Deletion handling**
   - When a referenced file is missing, invalidate and surface diagnostics.
   - Ensure cache entries for deleted files are removed.

### Phase C — Testing
6. **Unit tests**
   - Dirty file triggers recompile of dependents only.
   - No changes → incremental output equals cached output.
   - File deletion invalidates dependent compilation deterministically.
   - Incremental vs full compile outputs are identical.

---

## 3. Subtask Metadata

| ID | Task | Priority | Effort | Dependencies | Tools/Modules | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Define dependency graph model | High | 0.5h | None | Resolver/Core | Graph structure supports forward + reverse edges |
| A2 | Collect dependencies during compile | High | 0.5h | A1 | CompilerDriver/Resolver | Graph populated per file |
| B1 | Track dirty files and propagate | High | 1h | A2 | CompilerDriver | Dirty propagation works for dependents |
| B2 | Implement incremental compile path | High | 1h | B1 | CompilerDriver | Only dirty files recompiled; output matches full |
| B3 | Handle deletion of referenced files | Medium | 0.5h | B1 | CompilerDriver/Resolver | Deleted files invalidate dependents and cache |
| C1 | Write unit tests | High | 0.5h | B1-B3 | Tests | Incremental equivalence verified |

---

## 4. Feature Description and Rationale

Incremental compilation requires awareness of dependencies between files so changes can be localized. By building a dependency graph and tracking dirty files, the compiler can avoid full recompilation while maintaining deterministic output. This enables the <200ms target for repeated compiles in medium projects.

---

## 5. Functional Requirements

1. Build a dependency graph from resolved references for each file.
2. Maintain reverse dependency mapping to find dependents quickly.
3. Mark dirty files based on checksum mismatch or deletion and propagate to dependents.
4. Recompile only dirty files and dependents while reusing cached ASTs for others.
5. Ensure incremental compilation output matches full compilation output.
6. Handle deletion of referenced files with deterministic diagnostics and cache invalidation.

---

## 6. Non-Functional Requirements

- Deterministic output for identical inputs.
- Incremental compile is faster than full compile for small changes.
- No additional external dependencies or tooling required.

---

## 7. Edge Cases and Failure Scenarios

- Cyclic dependencies: dirty propagation must not loop indefinitely.
- File deletion during compile: must invalidate dependents and surface errors.
- Rapid changes between compiles: dirty state must reset per compile run.

---

## 8. Verification Checklist

- Incremental output equals full output for the same corpus.
- Dirty file only recompiles affected subset.
- Deleting a referenced file invalidates dependents and reports deterministic errors.
- Unit tests cover dependency graph creation and dirty propagation.

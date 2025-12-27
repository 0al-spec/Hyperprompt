# EditorEngine Validation Report

Date: 2025-12-?? (generated during repository review)

## 1. Scope and Sources

**Goal:** validate completed EditorEngine tasks and their alignment with the PRD/Workplan using:
- `DOCS/Workplan.md` (Phase 10: EE0–EE7)
- `DOCS/PRD/PRD_EditorEngine.md`
- `DOCS/TASKS_ARCHIVE/*` (EE0–EE6 archives)
- source code in `Sources/EditorEngine/*` and `Package.swift`

## 2. Workplan Task Validation (Phase 10)

| Task | Workplan Status | Evidence (code/docs) | Outcome |
|------|------------------|----------------------|---------|
| **EE0: Module Foundation** | ✅ | `Package.swift` (EditorEngine product + target), `Sources/EditorEngine/EditorEngine.swift` | ✅ **Done**, but **trait-gating not found** (see notes) |
| **EE1: Project Indexing** | ✅ | `Sources/EditorEngine/ProjectIndexer.swift`, `ProjectIndex.swift`, `GlobMatcher.swift` | ✅ **Done** |
| **EE2: Parsing with Link Spans** | ✅ | `Sources/EditorEngine/EditorParser.swift`, `LinkSpan.swift`, `ParsedFile.swift` | ✅ **Done** |
| **EE3: Link Resolution** | ✅ | `Sources/EditorEngine/EditorResolver.swift`, `ResolvedTarget.swift` | ✅ **Done** |
| **EE4: Editor Compilation** | ✅ | `Sources/EditorEngine/EditorCompiler.swift`, `CompileOptions.swift`, `CompileResult.swift` | ✅ **Done**, but depends on `CLI` (see notes) |
| **EE5: Diagnostics Mapping** | ✅ | `Sources/EditorEngine/Diagnostics.swift`, `DiagnosticMapper.swift` | ✅ **Done** |
| **EE6: Documentation & Testing** | ✅ | `Documentation.docc/EDITOR_ENGINE.md` | ✅ **Done** |
| **EE7: SpecificationCore Decision Refactor** | ✅ | DecisionSpec files: `LinkDecisionSpecs.swift`, `DirectoryDecisionSpecs.swift`, `FileTypeDecisionSpecs.swift`, `CompilePolicyDecisionSpecs.swift`, `OutputPathDecisionSpecs.swift`, `ResolutionDecisionSpecs.swift` | ✅ **Implemented in code**, but **no archive report** `DOCS/TASKS_ARCHIVE/EE7-summary.md` |

**Task archive:**
- Found `EE0-summary.md` … `EE6-summary.md` in `DOCS/TASKS_ARCHIVE/`.
- **Missing** an EE7 summary file.

## 3. PRD Alignment Check (FR-1…FR-7)

| PRD Requirement | Code Check | Outcome |
|----------------|------------|---------|
| **FR-1:** Parse Hypercode + link spans | `EditorParser.parse(...)` extracts `LinkSpan` from tokens (`Sources/EditorEngine/EditorParser.swift`) | ✅ Meets requirement |
| **FR-2:** Resolve file refs identically to CLI | `EditorResolver` uses `.md/.hc` rules, traversal checks, root order (workspace → source dir → cwd) | ✅ Mostly aligned |
| **FR-3:** Programmatic compile | `EditorCompiler.compile(...)` invokes `CompilerDriver` | ✅ Meets requirement |
| **FR-4:** Structured diagnostics | `DiagnosticMapper.map(...)` + `Diagnostics.swift` define the model | ✅ Meets (minimal) |
| **FR-5:** Disable unless `Editor` trait enabled | **No trait-gating in `Package.swift`**; EditorEngine is always available | ⚠️ **Does not meet** |
| **FR-6:** Deterministic indexing + ignore rules | `ProjectIndexer` sorts, reads `.hyperpromptignore`, uses default ignore dirs | ✅ Meets requirement |
| **FR-7:** Offsets for editors | `LinkSpan` stores UTF-8 byte offsets + 1-based line/column | ✅ Meets requirement |

## 4. Non-Functional Requirements (key items)

- **Determinism:** indexing/parsing/compilation are deterministic (sorting + static rules) — ✅.
- **Stability:** parser uses recovery (`parseWithRecovery`) and returns `ParsedFile` with diagnostics — ✅ for syntax errors; **IO errors in `parse(filePath:)` are thrown** — ⚠️ may conflict with “all errors surfaced as diagnostics.”
- **UI isolation:** no UI/LLM dependencies in `EditorEngine` — ✅.
- **Trait-gating:** missing, see above — ❌.

## 5. Notes and Gaps

1. **Trait-gating is missing**
   - PRD requires EditorEngine to be disabled without `--traits Editor`.
   - `Package.swift` has no trait declaration; product/target are always available.
   - `Documentation.docc/EDITOR_ENGINE.md` claims trait-gating, but **code does not confirm this**.

2. **EditorEngine depends on CLI**
   - `Package.swift` lists `CLI` as a dependency of `EditorEngine`.
   - `EditorCompiler` imports `CLI` and uses `CompilerDriver`.
   - PRD Phase 0.2 states the EditorEngine target should be isolated from CLI.

3. **Missing EE7 archive report**
   - `DOCS/TASKS_ARCHIVE` lacks `EE7-summary.md`.
   - DecisionSpec files imply implementation, but the formal archive note is absent.

4. **File-read errors in parsing**
   - `EditorParser.parse(filePath:)` throws `CompilerError` on read failures.
   - PRD expects errors surfaced as diagnostics, so this API behavior is inconsistent.

## 6. Summary

- EE0–EE6 are implemented and supported by source code.
- PRD functional requirements are broadly covered **except trait-gating** and **CLI isolation**.
- `Documentation.docc/EDITOR_ENGINE.md` claims trait-gating but the build configuration does not.
- EE7 appears implemented via DecisionSpecs, but the archive summary is missing.

## 7. Recommendations (no code changes)

1. Record the trait-gating mismatch (`Package.swift`) and update plan/PRD status.
2. Record the CLI dependency mismatch (EditorEngine ← CLI).
3. Add an EE7 archive report in `DOCS/TASKS_ARCHIVE` if the task is complete.
4. Clarify `EditorParser.parse(filePath:)` behavior to align with “all errors surfaced as diagnostics.”

## 8. Mini Workplan (Validation Follow-ups)

1. **Introduce Editor trait-gating**
   - Define the SwiftPM `Editor` trait in `Package.swift`.
   - Gate the `EditorEngine` target and product behind the trait.
   - Update `Documentation.docc/EDITOR_ENGINE.md` to match the build configuration.

2. **Decouple EditorEngine from CLI**
   - Remove `CLI` from `EditorEngine` dependencies.
   - Extract `CompilerDriver` or shared compile orchestration into a non-CLI module if needed.
   - Update `EditorCompiler` to depend on the shared module instead of `CLI`.

3. **Backfill EE7 archive summary**
   - Add `DOCS/TASKS_ARCHIVE/EE7-summary.md` describing the decision refactor work and validation.

4. **Normalize parser IO errors as diagnostics**
   - Adjust `EditorParser.parse(filePath:)` to return diagnostics instead of throwing, consistent with PRD.
   - Add tests covering IO errors surfaced in `ParsedFile.diagnostics`.

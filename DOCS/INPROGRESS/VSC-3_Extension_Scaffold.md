# PRD: VSC-3 - Extension Scaffold

## 1. Scope and Intent

### Objective
Create the initial VS Code extension scaffold for Hyperprompt using the TypeScript template, with core metadata, language assets, activation events, and baseline visuals so the extension loads in VS Code dev mode and recognizes `.hc` files.

### Deliverables
- A TypeScript-based VS Code extension scaffold in the repository.
- `package.json` configured with extension ID, publisher, repository URL, license, language ID, file associations, and activation events.
- TextMate grammar stub for Hypercode (`.tmLanguage.json`).
- Extension icon and basic color theme contributions (if required by PRD).
- A verified dev-mode launch that activates on `.hc` files.

### Success Criteria
- Extension compiles (`npm run compile`) without errors.
- VS Code dev mode activates on `.hc` files.
- Syntax highlighting loads from the TextMate grammar.
- Metadata matches Workplan requirements (ID, publisher, repository, license).

### Constraints and Assumptions
- Extension is a thin UI layer; no EditorEngine integration is required in this task.
- macOS and Linux are supported; Windows handling is deferred to VSC-4C.
- Node.js and VS Code are available locally for scaffold generation and dev-mode testing.
- The extension lives under `Tools/VSCodeExtension/` unless a better project convention is identified during implementation.

### External Dependencies
- VS Code Extension API
- Node.js / npm
- `yo` + `generator-code`

---

## 2. Structured TODO Plan

### Phase A - Scaffold and Baseline Setup
1. **Select extension directory**
   - Create `Tools/VSCodeExtension/` (or confirm an existing standard location).
   - Document the chosen path in the PRD summary section if different.

2. **Generate scaffold**
   - Run `yo code` in the extension directory using TypeScript template.
   - Set extension display name, identifier, and language ID (`hypercode`).

3. **Install dependencies**
   - Run `npm install` in the extension directory.

### Phase B - Manifest and Language Assets
4. **Configure package metadata**
   - Update `package.json` with ID `0al.hyperprompt`, publisher `0al`, repository URL, and license.

5. **Register language and file association**
   - Add language contribution for Hypercode.
   - Associate `.hc` with the `hypercode` language ID.

6. **Configure activation events**
   - Add `onLanguage:hypercode`, `onCommand:hyperprompt.compile`, and `onCommand:hyperprompt.showPreview`.

7. **Add TextMate grammar stub**
   - Create or update `.tmLanguage.json` with a minimal grammar that scopes comments, headings, and links.
   - Wire it to the language contribution.

8. **Add icon and colors**
   - Add an extension icon asset and reference it in `package.json`.
   - Add basic color contributions if needed for the status bar or preview.

### Phase C - Verification
9. **Build and smoke test**
   - Run `npm run compile`.
   - Launch VS Code dev mode and confirm activation on a `.hc` file.
   - Confirm syntax highlighting is applied.

---

## 3. Subtask Metadata

| ID | Task | Priority | Effort | Dependencies | Tools | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Select extension directory | High | 0.25h | None | File system | Directory chosen and documented |
| A2 | Generate scaffold | High | 0.75h | A1 | yo, generator-code | Scaffold created with TypeScript template |
| A3 | Install dependencies | Medium | 0.25h | A2 | npm | `node_modules` installed without errors |
| B1 | Configure package metadata | High | 0.5h | A2 | package.json | ID, publisher, repo, license set |
| B2 | Register language and file association | High | 0.5h | B1 | VS Code manifest | `.hc` opens as `hypercode` |
| B3 | Configure activation events | High | 0.25h | B1 | VS Code manifest | Activation events listed |
| B4 | Add TextMate grammar | Medium | 0.75h | B2 | TextMate grammar | Grammar file loads and scopes basic tokens |
| B5 | Add icon and colors | Medium | 0.5h | B1 | VS Code manifest, assets | Icon referenced and available |
| C1 | Build and smoke test | High | 0.5h | A3, B1-B5 | npm, VS Code | Compile succeeds and activation confirmed |

---

## 4. Feature Description and Rationale

A minimal but complete extension scaffold is required before integrating Hyperprompt features. This task establishes the extension structure, language registration, and activation so subsequent tasks can safely add RPC, navigation, diagnostics, and preview features without reworking the foundation.

---

## 5. Functional Requirements

1. The repository contains a TypeScript-based VS Code extension scaffold.
2. The extension manifest declares `hypercode` as a language with `.hc` file association.
3. Activation events include language activation and two command activations.
4. A TextMate grammar file is present and referenced by the language contribution.
5. Extension metadata (ID, publisher, repository, license) matches Workplan requirements.
6. The extension displays an icon in VS Code.

---

## 6. Non-Functional Requirements

- The scaffold builds without errors using `npm run compile`.
- No compiler or engine logic is duplicated in the extension at this stage.
- The extension remains compatible with macOS and Linux.

---

## 7. Edge Cases and Failure Scenarios

- `yo` or `generator-code` is missing: install via `npm install -g yo generator-code` before scaffolding.
- VS Code dev mode fails to activate: verify activation events and `contributes.languages` entries.
- Grammar file not loading: confirm the path in `package.json` and validate JSON format.
- Icon not displayed: verify the asset path and file extension in `package.json`.

---

## 8. Verification Checklist

- `npm run compile` passes in `Tools/VSCodeExtension/`.
- Opening a `.hc` file in VS Code dev mode activates the extension.
- Syntax highlighting appears on `.hc` content.
- `package.json` metadata matches required ID, publisher, repository, and license.

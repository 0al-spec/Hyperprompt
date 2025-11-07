# Request for Comments: Hyperprompt Framework Specification

## Authors' Addresses / Contact Information

- [[egormerkushev.ru]](Author: Egor Merkushev)
- [[claude.ai]](Author: Claude Code)

## Info

**Date:** 2025, November, 7th
**Version:** 0.0.1

## Status of this Memo

This document is an Experimental Request for Comments representing a draft proposal for the "Hyperprompt Framework" - a deterministic, folder-centric system for generating structured LLM prompts using the declarative Hypercode language (.hc).

## Abstract

Hyperprompt Framework defines a standardized approach to composing complex LLM prompts from modular, version-controlled components. The framework separates concerns into distinct filesystem locations: workflows (process graphs), primitives (atomic LLM instructions), rules (static guidelines), context (cycle-specific parameters), and task definitions (dynamic scope). A compilation script deterministically assembles these components into a single "hyperprompt" document, enabling reproducible, auditable, and maintainable prompt engineering.

## Table of Contents

1. Introduction
2. Motivation
3. Terminology and Definitions
4. Architecture Overview
5. Directory Structure and Roles
6. Core File Formats
7. Compilation Algorithm
8. Dynamic Task Model
9. Variable Interpolation
10. Security Considerations
11. Use Cases
12. Future Work

---

## 1. Introduction

### 1.1 Problem Statement

Current LLM prompt engineering practices suffer from:

- **Monolithic prompts**: Hard to version, review, and reuse
- **Implicit context**: Dynamic values mixed with static instructions
- **Poor reproducibility**: Manual assembly leads to drift between cycles
- **No provenance**: Difficult to audit which sources contributed to a prompt

### 1.2 Purpose and Scope

Hyperprompt Framework provides:

- **Declarative workflow definition** via Hypercode (.hc)
- **Atomic primitives** as reusable LLM "verbs"
- **Deterministic compilation** from filesystem to final prompt
- **Task-driven parameterization** through structured YAML frontmatter
- **Full provenance** via manifest generation

### 1.3 Design Principles

1. **Folder-centric**: Each directory has a single, well-defined role
2. **Computation-only script**: No AI interpretation during compilation
3. **Task as first-class entity**: Dynamic scope comes from structured task records
4. **Primitives in workflow**: .hc defines which primitives are used; .hcs only configures how

---

## 2. Motivation

### 2.1 Linguistic Metaphor

The framework maps to natural language grammar:

- **Subject**: LLM (implicit)
- **Verbs**: Primitives (from `/primitives/*.md`)
- **Objects/Adverbs**: Dynamic task data + context (from `/workplan`, `/prd`, `/todo` + `.hcs`)
- **Modifiers**: Rules (from `/rules/*.md`)

This separation enables:

- Verbs (primitives) remain stable and reusable
- Objects (task scope) change per cycle
- Modifiers (rules) evolve independently

### 2.2 Deterministic Compilation

Unlike template-based systems, Hyperprompt:

- **Computes** the final prompt from source-controlled inputs
- **Never guesses**: All dynamic values must have explicit sources
- **Produces manifests**: Full SHA256-based provenance for each compilation

### 2.3 Ecosystem Integration

Designed to work with:

- **Version control**: All inputs are plain text (`.hc`, `.hcs`, `.md`)
- **CI/CD**: Compilation is a deterministic build step
- **Code review**: Changes to workflow/primitives/rules are reviewable diffs
- **MCP tools**: Primitives can reference external tools via `mcp.use()`

---

## 3. Terminology and Definitions

### 3.1 Core Concepts

**Hypercode (.hc)**
A declarative, indentation-based language for defining workflow graphs. Nodes represent process steps; indentation represents hierarchy.

**Primitive**
An atomic, reusable Markdown document in `/primitives/*.md` representing a single LLM instruction. Primitives are "verbs" - they describe what to do, not what the current task is.

**Hyperprompt**
The final compiled Markdown document containing all sections (SYSTEM, TASK, OBJECTIVE, WORKFLOW, PRIMITIVES, RULES, EVIDENCE, etc.) ready for LLM consumption.

**TaskRecord**
A structured data object extracted from YAML frontmatter in `/workplan`, `/prd`, or `/todo` files. Represents the current development task and provides dynamic values for interpolation.

**Context Configuration (.hcs)**
A YAML file specifying:

- How to embed primitives and rules (full/headings/link)
- Which files to include as evidence
- Allowed capabilities and network modes
- Node-specific properties via selectors

**Selector**
A CSS-like pattern in `.hcs` matching nodes in `.hc` to apply configuration (e.g., `Implement > Commit:` or `.ci:`).

**Manifest**
A JSON document (`/out/<name>.manifest.json`) recording SHA256 hashes, file paths, and sizes of all sources used in compilation.

---

## 4. Architecture Overview

```plaintext
┌─────────────────────────────────────────────────────────────┐
│                    FILESYSTEM (Source)                       │
├──────────────┬──────────────┬──────────────┬────────────────┤
│ /workflows   │ /primitives  │ /rules       │ /context       │
│ *.hc         │ *.md         │ *.md         │ *.hcs          │
│ (Process)    │ (Verbs)      │ (Modifiers)  │ (Config)       │
└──────────────┴──────────────┴──────────────┴────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│            /workplan, /prd, /todo (Task Sources)             │
│                   YAML Frontmatter → TaskRecord              │
└─────────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              COMPILER (Deterministic Script)                 │
│  1. Load .hc + .hcs                                          │
│  2. Extract TaskRecord                                       │
│  3. Resolve primitives                                       │
│  4. Interpolate ${task.*} variables                          │
│  5. Assemble sections                                        │
│  6. Generate manifest                                        │
└─────────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                   /out (Artifacts)                           │
│  ├─ <name>.hyperprompt.md  (Final prompt)                   │
│  └─ <name>.manifest.json    (Provenance)                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Directory Structure and Roles

### 5.1 Core Directories (REQUIRED)

#### `/workflows/*.hc`

**Purpose**: Define process graphs (workflow structure)
**Format**: Hypercode (indentation-based tree)
**Contains**:

- Process nodes (e.g., `Plan`, `Implement`, `Test`)
- Primitive references (nodes with `.primitive` class or under `Primitives/` subtree)
- Node metadata (classes like `.docs`, `.ci`; IDs like `#unit`)

**Example**:

```hypercode
FeatureDelivery
  Primitives
    Summarize.primitive
    Implement.primitive
    Test.primitive
  Plan.docs
  Implement.core#unit
    Commit
  Test.ci
```

#### `/primitives/*.md`

**Purpose**: Atomic LLM instructions ("verbs")
**Format**: Markdown with structured sections
**Naming**: Must match primitive node names in `.hc`

**Required structure**:

```markdown
# <PrimitiveName>
**Intent:** One-line purpose
**Do:** Step-by-step instructions
**Done when:** Completion criteria
```

#### `/context/*.hcs`

**Purpose**: Cycle-specific configuration
**Format**: YAML
**Contains**:

- Title/objective templates
- Embed modes (primitives/rules)
- Include/exclude patterns
- Capabilities, network mode
- Node selectors with properties

**Example**:

```yaml
title: "${task.title}"
objective: "Deliver feature ${task.id}: ${task.scope}"

embed:
  primitives: full
  rules:
    - path: "/rules/CODE_STYLE.md"
      mode: headings

include: ${task.files.include}
exclude: ${task.files.exclude}

capabilities: ["fs.read", "mcp.use('git')"]
net: { mode: off }

outputs: ${task.outputs}

# Selectors
Implement > Commit:
  message_template: "feat(${task.scope}): ${task.title}"
.ci:
  retries: 2
  timeout_seconds: 600
```

#### `/rules/*.md`

**Purpose**: Static guidelines (code style, quality gates, best practices)
**Format**: Markdown
**Embedding**: Controlled by `.hcs.embed.rules`

---

### 5.2 Task Source Directories (At least one REQUIRED)

#### `/workplan/*.md`

**Purpose**: Current development tasks (highest priority for TaskRecord extraction)

#### `/prd/*.md`

**Purpose**: Product requirements (second priority)

#### `/todo/*.md`

**Purpose**: Task tracking (lowest priority)

**Common YAML frontmatter format**:

```yaml
---
task:
  id: "F-142"
  title: "Refactor Media Pipeline"
  scope: "Decoder isolation"
  files:
    include: ["Sources/Media/**/*.swift"]
    exclude: ["**/Generated/**"]
  outputs:
    - "PR: feature/refactor-media"
    - "docs/out/refactor_report.md"
  branch: "feature/refactor-media"
  risk: "medium"
---
```

---

### 5.3 Output Directory

#### `/out/`

**Purpose**: Compilation artifacts
**Contains**:

- `<name>.hyperprompt.md` — Final prompt
- `<name>.manifest.json` — Provenance (SHA256 hashes, paths, sizes)

---

## 6. Core File Formats

### 6.1 Hypercode (.hc) Syntax

**Grammar**:

```ebnf
<node> ::= <indent> <name> [<classes>] [<id>]
<classes> ::= "." <identifier> [<classes>]
<id> ::= "#" <identifier>
<indent> ::= "  " * depth
```

**Semantics**:

- Indentation (2 spaces per level) defines parent-child relationships
- `.primitive` class or `Primitives/` parent marks a node as a primitive reference
- Other classes/IDs are used for selector matching in `.hcs`

**Example**:

```hypercode
FeatureDelivery
  Primitives
    Summarize.primitive
    Implement.primitive
  Plan.docs
  Implement.core#unit
    Commit
  Test.ci
```

**Primitive Resolution**:

- Node `Summarize.primitive` → look for `/primitives/Summarize.md`
- If file missing → compiler emits warning, continues

---

### 6.2 Context Configuration (.hcs) Schema

```yaml
# Metadata interpolation
title: string (supports ${task.*})
objective: string (supports ${task.*})

# Embedding configuration
embed:
  primitives: "full" | "headings" | "link"
  rules:
    - path: string (absolute from repo root)
      mode: "full" | "headings" | "link"

# Evidence (files to include in EVIDENCE section)
include: string[] (supports ${task.*})
exclude: string[] (supports ${task.*})

# Capabilities & Network
capabilities: string[]  # e.g., ["fs.read", "mcp.use('git')"]
net:
  mode: "off" | "read-only" | "full"

# Output contract
outputs: string[] (supports ${task.*})

# Selectors (node-specific properties)
<selector>:
  <property>: <value>
```

**Selector Syntax**:

- `NodeName`: Matches node by exact name
- `.className`: Matches nodes with class
- `#idName`: Matches node with ID
- `Parent > Child`: Matches direct children
- `Parent Child`: Matches descendants

---

### 6.3 TaskRecord Schema

Extracted from first valid `task:` frontmatter in `/workplan → /prd → /todo`:

```yaml
task:
  id: string              # Required
  title: string           # Required
  scope: string           # Optional
  files:
    include: string[]     # Glob patterns
    exclude: string[]     # Glob patterns
  outputs: string[]       # Expected artifacts
  branch: string          # Git branch
  risk: "low" | "medium" | "high"
  # Extensible with custom fields
```

**Variables exposed**:

- `${task.id}`
- `${task.title}`
- `${task.scope}`
- `${task.files.include}` (as JSON array)
- `${task.files.exclude}`
- `${task.outputs}`
- `${task.branch}`
- `${task.risk}`

---

## 7. Compilation Algorithm

### 7.1 Inputs

- Workflow file: `/workflows/<name>.hc`
- Context config: `/context/<name>.hcs`
- Primitives: `/primitives/*.md`
- Rules: `/rules/*.md`
- Task sources: `/workplan`, `/prd`, `/todo`

### 7.2 Steps (Deterministic, 7-stage)

#### Stage 1: Locate Inputs

```python
W = find_file(f"/workflows/{name}.hc")  # Required
C = find_file(f"/context/{name}.hcs")   # Required
if not (W and C):
    raise CompilationError("Missing .hc or .hcs")
```

#### Stage 2: Extract TaskRecord

```python
task_record = None
for directory in ["/workplan", "/prd", "/todo"]:
    for file in sorted(glob(f"{directory}/*.md")):
        frontmatter = parse_yaml_frontmatter(file)
        if "task" in frontmatter:
            task_record = frontmatter["task"]
            break
    if task_record:
        break

if not task_record:
    raise CompilationError("No task: frontmatter found")
```

#### Stage 3: Parse Workflow

```python
workflow_tree = parse_hypercode(W)
primitives = extract_primitives(workflow_tree)
# primitives = [nodes with .primitive class or under Primitives/]
```

#### Stage 4: Resolve Primitives

```python
primitive_content = {}
for prim in primitives:
    path = f"/primitives/{prim.name}.md"
    if exists(path):
        primitive_content[prim.name] = read_file(path)
    else:
        warn(f"Missing primitive: {path}")
        primitive_content[prim.name] = None
```

#### Stage 5: Interpolate Variables

```python
context_config = load_yaml(C)
interpolated_config = substitute_variables(
    context_config,
    variables={"task": task_record}
)
interpolated_primitives = {
    name: substitute_variables(content, {"task": task_record})
    for name, content in primitive_content.items()
}
```

#### Stage 6: Assemble Hyperprompt

```python
hyperprompt = assemble_sections(
    system=get_system_doc(interpolated_config),
    task=build_task_metadata(task_record),
    objective=interpolated_config["objective"],
    workflow=render_workflow_tree(workflow_tree),
    primitives=embed_primitives(
        interpolated_primitives,
        mode=interpolated_config["embed"]["primitives"]
    ),
    rules=embed_rules(
        interpolated_config["embed"]["rules"]
    ),
    evidence=gather_evidence(
        include=interpolated_config["include"],
        exclude=interpolated_config["exclude"]
    ),
    tools=interpolated_config["capabilities"],
    outputs=interpolated_config["outputs"],
    # ... other sections
)
```

#### Stage 7: Generate Manifest

```python
manifest = {
    "timestamp": iso8601_now(),
    "sources": [
        {"path": W, "sha256": sha256(W), "size": size(W)},
        {"path": C, "sha256": sha256(C), "size": size(C)},
        *[{"path": p, "sha256": sha256(p), "size": size(p)}
          for p in all_embedded_files],
    ],
    "task_record": task_record,
}

write_file(f"/out/{name}.hyperprompt.md", hyperprompt)
write_json(f"/out/{name}.manifest.json", manifest)
```

---

## 8. Dynamic Task Model

### 8.1 TaskRecord as Dynamic Scope

Unlike traditional templating systems where variables are ad-hoc, Hyperprompt treats the **current task** as a first-class, structured entity.

**Key insight**: Most prompt variability comes from:

- Which files to analyze (`task.files.include`)
- What to produce (`task.outputs`)
- Contextual metadata (`task.id`, `task.title`, `task.scope`)

By centralizing this in a single `TaskRecord`, the framework ensures:

- **Single source of truth**: Only one place to update per cycle
- **Type safety**: Schema-validated YAML
- **Auditability**: Task definition is version-controlled

### 8.2 Extraction Rules (Deterministic Priority)

1. Scan `/workplan/*.md` (lexicographic order)
2. If no valid `task:` found, scan `/prd/*.md`
3. If still none, scan `/todo/*.md`
4. Take **first** valid frontmatter; ignore rest
5. Validate against TaskRecord schema

### 8.3 Extensibility

TaskRecord schema is extensible:

```yaml
task:
  id: "F-142"
  # ... core fields ...
  custom:
    labels: ["refactor", "high-priority"]
    reviewers: ["alice", "bob"]
```

Access via `${task.custom.labels}`.

---

## 9. Variable Interpolation

### 9.1 Syntax

- **Format**: `${path.to.field}`
- **Scope**: Only `task.*` variables (from TaskRecord)
- **Location**: Anywhere in `.hcs` or primitive `.md` files

### 9.2 Resolution Algorithm

```python
def substitute_variables(text: str, variables: dict) -> str:
    pattern = r'\$\{([^}]+)\}'
    def replacer(match):
        path = match.group(1)  # e.g., "task.files.include"
        value = resolve_path(variables, path)
        if isinstance(value, list):
            return json.dumps(value)  # Arrays as JSON
        return str(value)
    return re.sub(pattern, replacer, text)
```

### 9.3 Examples

```yaml
# In .hcs
title: "${task.title}"
# → "Refactor Media Pipeline"

include: ${task.files.include}
# → ["Sources/Media/**/*.swift"]

# In primitive
## Commit message: feat(${task.scope}): ${task.title}
# → feat(Decoder isolation): Refactor Media Pipeline
```

### 9.4 Escaping

- Literal `${`: Use `\${` (backslash-escaped)
- Undefined variable: Compilation error (fail-fast)

---

## 10. Hyperprompt Output Format

### 10.1 Section Order (REQUIRED)

```markdown
# SYSTEM
# TASK
# OBJECTIVE
# WORKFLOW
# PRIMITIVES
# RULES
# EVIDENCE
# TOOLS
# OUTPUT
# QUALITY
# MANIFEST
# APPENDICES
```

### 10.2 Section Specifications

#### SYSTEM

**Source**: `.hcs.system_doc` or default
**Purpose**: Define LLM's role and constraints
**Example**:

```markdown
# SYSTEM
You are an expert software engineer working in an agentic development environment.
Your responses must be deterministic, traceable, and aligned with the OUTPUT contract.
```

#### TASK

**Source**: `task_record`
**Purpose**: Current task metadata
**Format**:

```markdown
# TASK
- **ID**: F-142
- **Title**: Refactor Media Pipeline
- **Scope**: Decoder isolation
- **Branch**: feature/refactor-media
- **Risk**: medium
```

#### OBJECTIVE

**Source**: `.hcs.objective`
**Purpose**: High-level goal
**Example**:

```markdown
# OBJECTIVE
Deliver feature F-142: Decoder isolation by refactoring the media pipeline
to separate decoder logic into isolated modules.
```

#### WORKFLOW

**Source**: `.hc` workflow tree
**Purpose**: Process structure
**Format**: Markdown headings (H2-H6) mirroring tree depth
**Rules from Delta v0.1.1**:

- depth 0 → `##` (H2)
- depth 1 → `###` (H3)
- depth ≥4 → `######` + path notation

**Example**:

```markdown
# WORKFLOW

## FeatureDelivery
### Primitives
#### Summarize .primitive
#### Implement .primitive

### Plan .docs
- artifact: docs/out/spec.md

### Implement .core #unit
- build_config: ${BUILD_CONFIG:-Debug}

#### Commit
- message_template: "feat(${task.scope}): ${task.title}"

### Test .ci
- retries: 2
- timeout_seconds: 600
```

#### PRIMITIVES

**Source**: `/primitives/*.md` (referenced in `.hc`)
**Purpose**: Embedded LLM instructions
**Embedding modes**:

- `full`: Entire file content
- `headings`: Only `#`-`###` headings + first paragraph under each
- `link`: Relative path only (actual content not embedded; recorded in manifest)

**Example (full mode)**:

```markdown
# PRIMITIVES

## Summarize
**Intent:** Кратко собрать контекст задачи.
**Do:** выпиши цель, входы/выходы, риски, артефакты.
**Done when:** есть 5–8 маркеров, покрывающих scope.

## Implement
**Intent:** Минимально реализовать изменение в целевых файлах.
**Do:** локальная ветка ${task.branch}; маленькие коммиты; следуй CODE_STYLE.
**Done when:** билд зелёный, покрытие не ниже базовой линии.
```

#### RULES

**Source**: `/rules/*.md` (specified in `.hcs.embed.rules`)
**Purpose**: Static guidelines and policies
**Embedding modes**: Same as primitives (full/headings/link)

**Example**:

```markdown
# RULES

## CODE_STYLE.md (mode: headings)

### Swift Style Guide
Use 2-space indentation, max 100 characters per line.

### Naming Conventions
Types: PascalCase, functions: camelCase, constants: SCREAMING_SNAKE_CASE.

## QUALITY_GATE.md (mode: link)
Path: /rules/QUALITY_GATE.md
```

#### EVIDENCE

**Source**: Files matching `.hcs.include` patterns (excluding `.hcs.exclude`)
**Purpose**: Relevant code/docs for context
**Format**: File paths + snippets or full content (configurable)

**Example**:

```markdown
# EVIDENCE

## Included Files
- Sources/Media/Decoder.swift
- Sources/Media/Pipeline.swift
- Tests/MediaTests/DecoderTests.swift

## Excluded Patterns
- **/Generated/**
- **/*.xcodeproj/**
```

#### TOOLS

**Source**: `.hcs.capabilities`
**Purpose**: Declare available tools/MCPs
**Example**:

```markdown
# TOOLS

## Available Capabilities
- `fs.read`: Read files from evidence scope
- `mcp.use('git')`: Git operations (commit, branch, diff)

## Network Mode
**Mode**: off
**Rationale**: No external API calls during feature development.
```

#### OUTPUT

**Source**: `.hcs.outputs` (interpolated from `task.outputs`)
**Purpose**: Expected deliverables
**Example**:

```markdown
# OUTPUT

## Required Artifacts
1. PR: feature/refactor-media
2. docs/out/refactor_report.md

## Completion Criteria
- All tests pass
- Coverage ≥ baseline
- PR approved by 2 reviewers
```

#### QUALITY

**Source**: Implied from rules + task metadata
**Purpose**: Acceptance gates
**Example**:

```markdown
# QUALITY

## Gates
- [ ] Code follows CODE_STYLE.md
- [ ] All QUALITY_GATE.md checks pass
- [ ] Risk level (medium) mitigated by testing
- [ ] No regression in benchmark suite
```

#### MANIFEST

**Source**: Generated during compilation
**Purpose**: Full provenance
**Format**: YAML/JSON block with SHA256 hashes

**Example**:

```markdown
# MANIFEST

```yaml
timestamp: "2025-11-07T14:32:15Z"
sources:
  - path: /workflows/FeatureDelivery.hc
    sha256: a3f5c8...
    size: 1247
  - path: /context/FeatureDelivery.hcs
    sha256: 9d2e1a...
    size: 856
  - path: /primitives/Summarize.md
    sha256: 7b4c3f...
    size: 342
    mode: full
  - path: /primitives/Implement.md
    sha256: 5e8d2a...
    size: 489
    mode: full
  - path: /rules/CODE_STYLE.md
    sha256: 2c9f1b...
    size: 1024
    mode: headings
task_record:
  id: F-142
  title: "Refactor Media Pipeline"
  scope: "Decoder isolation"
  branch: feature/refactor-media
```

```

#### APPENDICES
**Source**: Optional supplementary material
**Purpose**: Extended context, debugging info
**Example**:
```markdown
# APPENDICES

## A. Selector Resolution Log
- `Implement > Commit`: Matched by child selector
  - Applied: message_template = "feat(${task.scope}): ${task.title}"
- `.ci`: Matched 1 node (Test.ci)
  - Applied: retries = 2, timeout_seconds = 600

## B. Primitive Resolution
- Summarize.primitive → /primitives/Summarize.md ✓
- Implement.primitive → /primitives/Implement.md ✓
- Test.primitive → /primitives/Test.md ✓
```

---

## 11. Security Considerations

### 11.1 Threat Model

#### 11.1.1 Supply Chain Attacks

**Risk**: Malicious primitives or rules injected into `/primitives` or `/rules`
**Mitigation**:

- All sources version-controlled
- Manifest includes SHA256 hashes → detect tampering
- Code review required for changes to primitives/rules

#### 11.1.2 Variable Injection

**Risk**: `${task.*}` variables containing malicious payloads
**Mitigation**:

- TaskRecord schema validation (reject non-conforming frontmatter)
- Sanitize interpolated values (escape shell metacharacters if used in commands)
- Compiler logs all variable substitutions

#### 11.1.3 Path Traversal

**Risk**: `.hcs.include` patterns accessing unintended files
**Mitigation**:

- Restrict include/exclude patterns to repository root
- Validate glob patterns before expansion
- Refuse absolute paths outside repo

#### 11.1.4 Denial of Service

**Risk**: Extremely large primitives or deeply nested workflows causing compiler hang
**Mitigation**:

- Enforce limits: max file size (10MB), max workflow depth (10 levels)
- Timeout compilation after configurable period (default: 60s)

### 11.2 Cryptographic Integrity

**Manifest Requirements**:

- Use SHA-256 for all source hashes
- Include full file paths (repo-relative)
- Record timestamp (ISO 8601, UTC)

**Verification Process**:

```python
def verify_manifest(manifest_path: str) -> bool:
    manifest = load_json(manifest_path)
    for source in manifest["sources"]:
        actual_hash = sha256_file(source["path"])
        if actual_hash != source["sha256"]:
            raise IntegrityError(f"Hash mismatch: {source['path']}")
    return True
```

### 11.3 Network Isolation

**Context Config Network Modes**:

- `off`: No network access (default for sensitive tasks)
- `read-only`: Can fetch data, cannot POST/PUT/DELETE
- `full`: Unrestricted (use only for deployment tasks)

**Enforcement**:

- Compiler embeds network mode in TOOLS section
- Runtime environment (e.g., agentifyd) enforces via network policies
- Violations logged and surfaced in OUTPUT

### 11.4 Capability-Based Security

Inspired by Agent Passport (your RFC), Hyperprompt supports capability declarations:

```yaml
# In .hcs
capabilities:
  - fs.read: { scope: ${task.files.include} }
  - mcp.use: { tool: 'git', operations: ['commit', 'branch'] }
  - deny: ['fs.write:/etc/**', 'net.connect:*']
```

**Semantics**:

- Positive capabilities: What LLM *can* do
- Deny rules: Explicit blacklist
- Scope limits: Fine-grained (e.g., only read files in `task.files.include`)

---

## 12. Integration with Hypercode Ecosystem

### 12.1 Relationship to Hypercode RFC

Hyperprompt Framework is a **domain-specific application** of Hypercode:

| Hypercode (General) | Hyperprompt (Specialized) |
|---------------------|---------------------------|
| `.hc` = abstract structure | `.hc` = workflow graph |
| `.hcs` = cascading config | `.hcs` = prompt assembly config |
| Generic execution model | LLM prompt generation |
| Runtime-agnostic | Targets LLM runtimes |

**Key differences**:

- Hyperprompt adds **TaskRecord** as first-class entity (not in base Hypercode)
- Hyperprompt defines **specific section structure** (SYSTEM, TASK, etc.)
- Hyperprompt embeds **primitives** as reusable LLM instructions

### 12.2 Hypercode Cascade Sheet Extensions

Hyperprompt extends HCS with:

#### 12.2.1 Embedding Directives

```yaml
embed:
  primitives: full | headings | link
  rules:
    - path: /rules/STYLE.md
      mode: headings
```

#### 12.2.2 Evidence Inclusion

```yaml
include: ["src/**/*.ts"]
exclude: ["**/node_modules/**"]
```

#### 12.2.3 Capability Declarations

```yaml
capabilities: ["fs.read", "mcp.use('git')"]
net: { mode: off }
```

### 12.3 Compatibility with Hypercode Runtimes

While Hypercode RFC defines a general-purpose execution model, Hyperprompt:

- Does **not** execute code
- Compiles to a **static document** (the hyperprompt)
- The hyperprompt is then consumed by an LLM runtime (not a Hypercode runtime)

**However**: The compiler itself *could* be implemented as a Hypercode application:

```hypercode
HyperpromptCompiler
  LoadInputs.io
  ExtractTaskRecord
  ParseWorkflow
  ResolvePrimitives
  Interpolate
  Assemble
  GenerateManifest
```

This demonstrates Hypercode's versatility: it can describe both the *process* (workflow) and the *tooling* (compiler).

---

## 13. Use Cases

### 13.1 Agentic Software Development

**Scenario**: AI agent iteratively refactors a codebase
**Workflow**: `/workflows/Refactor.hc`

```hypercode
Refactor
  Primitives
    Analyze.primitive
    Plan.primitive
    Implement.primitive
    Test.primitive
    Review.primitive

  Analyze.static-analysis
  Plan.design-doc
  Implement.incremental#safe
    Commit.atomic
  Test.regression
  Review.self-critique
```

**Context**: `/context/Refactor.hcs`

```yaml
title: "Refactor: ${task.title}"
objective: "Safely refactor ${task.scope} with zero regressions"

embed:
  primitives: full
  rules:
    - path: /rules/SAFE_REFACTOR.md
      mode: full

include: ${task.files.include}
exclude: ["**/Tests/**"]  # Tests analyzed separately

capabilities: ["fs.read", "mcp.use('git')"]
net: { mode: off }

Implement > Commit:
  message_template: "refactor(${task.scope}): ${task.title}"
  sign: true
```

**Task**: `/workplan/refactor-decoder.md`

```yaml
---
task:
  id: "R-089"
  title: "Extract decoder interface"
  scope: "Media/Decoder"
  files:
    include: ["Sources/Media/Decoder*.swift"]
  outputs:
    - "PR: refactor/decoder-interface"
    - "docs/arch/decoder-interface.md"
  branch: "refactor/decoder-interface"
  risk: "low"
---
# Refactor Plan
Extract `DecoderProtocol` from concrete implementations...
```

**Result**: Hyperprompt guides LLM through safe, incremental refactoring with atomic commits.

---

### 13.2 Documentation Generation

**Workflow**: `/workflows/DocGen.hc`

```hypercode
DocGen
  Primitives
    ReadCode.primitive
    ExtractAPI.primitive
    GenerateDocs.primitive

  ReadCode.scan
  ExtractAPI.parse-exports
  GenerateDocs.markdown#api-ref
```

**Context**: `/context/DocGen.hcs`

```yaml
title: "Generate docs for ${task.title}"
objective: "Create comprehensive API reference for ${task.scope}"

embed:
  primitives: headings  # Just show structure, not full instructions
  rules:
    - path: /rules/DOC_STYLE.md
      mode: full

include: ${task.files.include}

capabilities: ["fs.read"]
net: { mode: off }

outputs: ${task.outputs}

GenerateDocs:
  format: markdown
  template: /templates/api-ref.md.j2
```

**Task**: `/prd/api-docs-v2.md`

```yaml
---
task:
  id: "DOC-12"
  title: "API Reference v2.0"
  scope: "Public API surface"
  files:
    include: ["Sources/PublicAPI/**/*.swift"]
  outputs:
    - "docs/api/v2/reference.md"
---
```

**Result**: Generated docs follow consistent style, cover all public APIs.

---

### 13.3 Multi-Stage CI/CD Pipeline

**Workflow**: `/workflows/CI.hc`

```hypercode
CI
  Primitives
    Build.primitive
    Test.primitive
    Lint.primitive
    Deploy.primitive

  Lint.style#strict
  Build.release
    Test.unit
    Test.integration
  Deploy.staging#canary
```

**Context**: `/context/CI.hcs`

```yaml
title: "CI Pipeline: ${task.title}"
objective: "Deploy ${task.id} to staging with canary release"

embed:
  primitives: link  # CI doesn't need full primitive text
  rules:
    - path: /rules/CI_QUALITY_GATES.md
      mode: headings

capabilities:
  - "mcp.use('buildkite')"
  - "mcp.use('kubernetes')"
  - "fs.read"

net: { mode: full }

Build:
  config: ${task.build_config}
  targets: ["x86_64-linux-gnu", "aarch64-apple-darwin"]

Deploy:
  environment: staging
  strategy: canary
  health_check_url: "https://staging.example.com/health"
```

**Task**: `/workplan/deploy-f142.md`

```yaml
---
task:
  id: "F-142"
  title: "Media Pipeline Refactor"
  build_config: "Release"
  outputs:
    - "Deploy: staging (canary 10%)"
---
```

**Result**: Hyperprompt coordinates multi-tool CI pipeline, LLM monitors and adjusts deployment.

---

### 13.4 Code Review Automation

**Workflow**: `/workflows/CodeReview.hc`

```hypercode
CodeReview
  Primitives
    FetchDiff.primitive
    AnalyzeChanges.primitive
    SuggestImprovements.primitive
    ApproveOrRequest.primitive

  FetchDiff.github-pr
  AnalyzeChanges.static-analysis
    CheckStyle
    CheckTests
    CheckDocs
  SuggestImprovements.inline-comments
  ApproveOrRequest.decision
```

**Context**: `/context/CodeReview.hcs`

```yaml
title: "Review PR #${task.pr_number}"
objective: "Automated review for ${task.title}"

embed:
  primitives: full
  rules:
    - path: /rules/CODE_REVIEW_CHECKLIST.md
      mode: full

capabilities:
  - "mcp.use('github')"
  - "fs.read"

net: { mode: read-only }

FetchDiff:
  pr_number: ${task.pr_number}
  repo: "owner/repo"

ApproveOrRequest:
  auto_approve_threshold: 0.95  # Confidence score
  require_human_review_if:
    - risk: high
    - changes_lines: ">500"
```

**Task**: `/todo/review-pr-1234.md`

```yaml
---
task:
  id: "PR-1234"
  title: "Fix memory leak in cache"
  pr_number: 1234
  risk: "medium"
---
```

**Result**: LLM reviews PR, posts inline comments, requests changes or approves.

---

## 14. Tooling and Ecosystem

### 14.1 Reference Implementation

**Compiler**: `hyperprompt-cli`

```bash
# Basic compilation
hyperprompt compile \
  --workflow workflows/FeatureDelivery.hc \
  --context context/FeatureDelivery.hcs \
  --output out/FeatureDelivery.hyperprompt.md

# With task override
hyperprompt compile \
  --workflow workflows/CI.hc \
  --context context/CI.hcs \
  --task workplan/deploy-staging.md \
  --output out/CI-staging.hyperprompt.md

# Verify manifest
hyperprompt verify out/CI-staging.manifest.json
```

### 14.2 IDE Integration

**VS Code Extension**: `hyperprompt-vscode`

- Syntax highlighting for `.hc` and `.hcs`
- IntelliSense for TaskRecord variables (`${task.*}`)
- Live preview of compiled hyperprompt
- Manifest viewer (clickable source links)

**Features**:

- Hover over `${task.id}` → show TaskRecord value
- Cmd+Click on primitive name → jump to `/primitives/<Name>.md`
- Cmd+Shift+P → "Hyperprompt: Compile Current Workflow"

### 14.3 CI/CD Integration

**GitHub Action**: `hyperprompt-action`

```yaml
# .github/workflows/hyperprompt.yml
name: Compile Hyperprompts
on: [push, pull_request]
jobs:
  compile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hyperprompt/hyperprompt-action@v1
        with:
          workflows: "workflows/*.hc"
          contexts: "context/*.hcs"
          output-dir: "out/"
      - uses: actions/upload-artifact@v3
        with:
          name: hyperprompts
          path: out/*.hyperprompt.md
```

### 14.4 Runtime Integration

**Agentic Runtime**: Integration with `agentifyd` (from Agent Passport RFC)

```yaml
# agentifyd config
agents:
  - name: feature-delivery-agent
    passport: agents/FeatureDelivery.passport.yaml
    hyperprompt:
      source: out/FeatureDelivery.hyperprompt.md
      manifest: out/FeatureDelivery.manifest.json
      verify_integrity: true

    # Runtime enforces capabilities from hyperprompt TOOLS section
    capabilities:
      from_hyperprompt: true
      additional: []  # Can't exceed hyperprompt declarations
```

**Flow**:

1. `agentifyd` loads hyperprompt
2. Verifies manifest (SHA256 checks)
3. Enforces `capabilities` and `net.mode` from TOOLS section
4. Provides hyperprompt as system context to LLM
5. Monitors LLM actions against declared capabilities

---

## 15. Comparison to Existing Approaches

### 15.1 vs. Template Systems (Jinja, Handlebars)

| Aspect | Templates | Hyperprompt |
|--------|-----------|-------------|
| **Structure** | Imperative loops/conditionals | Declarative tree (Hypercode) |
| **Configuration** | Inline variables | Separate .hcs file |
| **Reusability** | Macros/includes | Primitives as files |
| **Provenance** | None | Full manifest with hashes |
| **Type Safety** | None | TaskRecord schema |

**Example comparison**:

**Jinja**:

```jinja
# template.j2
## Task: {{ task_title }}
{% if env == 'production' %}
Use PostgreSQL at {{ db_host }}
{% else %}
Use SQLite at /tmp/dev.db
{% endif %}
```

**Hyperprompt**:

```hypercode
# workflow.hc
Task
  Database#prod
```

```yaml
# context.hcs
Database:
  driver: "sqlite"
  path: "/tmp/dev.db"

@env[production]:
  '#prod':
    driver: "postgresql"
    host: "${DB_HOST}"
```

**Advantages**:

- No conditionals in prompt logic
- Environment switching via external config
- Full auditability (manifest records which config was active)

---

### 15.2 vs. LangChain/LlamaIndex Prompts

| Aspect | LangChain | Hyperprompt |
|--------|-----------|-------------|
| **Definition** | Python code | Declarative .hc/.hcs |
| **Versioning** | Git (code) | Git (data files) |
| **Modularity** | Functions/classes | Primitives as files |
| **Context Injection** | Runtime variables | Compile-time TaskRecord |
| **Auditability** | Code logs | Manifest with hashes |

**LangChain Example**:

```python
from langchain.prompts import PromptTemplate

template = PromptTemplate(
    input_variables=["task_title", "files"],
    template="""
    Task: {task_title}
    Files: {files}
    Instructions: Refactor these files...
    """
)
prompt = template.format(task_title="Refactor", files=["a.py", "b.py"])
```

**Hyperprompt Equivalent**:

```hypercode
# Refactor.hc
Refactor
  Primitives
    Implement.primitive
  Analyze
  Implement
```

```yaml
# Refactor.hcs
title: "${task.title}"
include: ${task.files.include}
```

**Advantages**:

- Non-programmers can modify prompts (just edit YAML)
- Clear separation: workflow structure vs. data
- Manifest proves exactly which primitives/rules were used

---

### 15.3 vs. OpenAI Function Calling

| Aspect | Function Calling | Hyperprompt |
|--------|------------------|-------------|
| **Tool Definition** | JSON schemas | Primitives + HCS |
| **Context** | Per-request args | Compiled hyperprompt |
| **Workflow** | Implicit (LLM decides) | Explicit (.hc tree) |
| **Provenance** | API logs | Manifest |

**Function Calling**:

```json
{
  "name": "refactor_code",
  "description": "Refactor code files",
  "parameters": {
    "type": "object",
    "properties": {
      "files": {"type": "array"},
      "strategy": {"type": "string"}
    }
  }
}
```

**Hyperprompt**:

- Workflow explicitly defines *when* to refactor (position in tree)
- Primitives provide *how* (detailed instructions)
- TaskRecord provides *what* (files, scope)

**Result**: More structured, auditable workflows than ad-hoc function calls.

---

## 16. Future Work

### 16.1 Advanced Features

#### 16.1.1 Conditional Primitives

**Current**: All primitives in `.hc` are unconditionally embedded
**Future**: Support `@rules` in `.hc` itself:

```hypercode
FeatureDelivery
  Primitives
    Summarize.primitive
    @risk[high]:
      SecurityAudit.primitive
    Implement.primitive
```

**Behavior**: `SecurityAudit` primitive only embedded if `task.risk == "high"`.

#### 16.1.2 Primitive Composition

**Current**: Primitives are atomic
**Future**: Allow primitives to reference other primitives:

```markdown
# Implement.md
**Intent:** Implement changes
**Do:**
1. {{> Summarize}}  <!-- Include Summarize primitive -->
2. Write code
3. {{> Test}}       <!-- Include Test primitive -->
```

**Implementation**: Transitive resolution during compilation.

#### 16.1.3 Multi-Agent Workflows

**Current**: Single hyperprompt for single LLM
**Future**: Compile multiple hyperprompts from one `.hc`:

```hypercode
FeatureDelivery
  Developer.agent#primary
    Plan
    Implement
  Reviewer.agent#secondary
    Review
    Approve
```

**Compilation**:

```bash
hyperprompt compile --workflow FeatureDelivery.hc \
  --multi-agent \
  --output out/Developer.hyperprompt.md out/Reviewer.hyperprompt.md
```

#### 16.1.4 Interactive Compilation

**Current**: Static compilation
**Future**: Interactive mode prompts for missing TaskRecord fields:

```bash
hyperprompt compile --workflow CI.hc --interactive
> No task found. Enter task ID: F-142
> Enter scope: Media Pipeline
> Include files: Sources/Media/**/*.swift
> Output artifacts: PR: feature/refactor-media
```

Generates TaskRecord on-the-fly, saves to `/workplan/interactive-<timestamp>.md`.

---

### 16.2 Ecosystem Extensions

#### 16.2.1 Hyperprompt Registry

**Vision**: Public registry of reusable primitives/workflows

```bash
# Install community primitive
hyperprompt install primitive @community/refactor-safe

# Install workflow template
hyperprompt install workflow @company/microservice-setup
```

**Structure**:

- Packages are Git repos with standard structure
- `hyperprompt.yaml` manifest describes contents
- Semantic versioning for primitives

#### 16.2.2 Visual Workflow Editor

**Vision**: Web-based GUI for editing `.hc` files

**Features**:

- Drag-and-drop nodes
- Live preview of compiled hyperprompt
- Selector tester (highlight which nodes match `.hcs` selectors)
- Task simulator (mock TaskRecord to preview interpolation)

#### 16.2.3 LLM-as-Compiler

**Vision**: Use LLM to optimize hyperprompts

```bash
hyperprompt optimize --workflow CI.hc \
  --objective "Minimize token count while preserving clarity"
```

**Process**:

1. Compile baseline hyperprompt
2. Feed to LLM with meta-prompt: "Reduce verbosity"
3. LLM outputs optimized `.hcs` + primitives
4. Human reviews diff, accepts/rejects

#### 16.2.4 Formal Verification

**Vision**: Prove properties about workflows

**Example property**: "All workflows must include Test primitive before Deploy"

**Verification**:

```bash
hyperprompt verify --workflow CI.hc \
  --property "Test occurs-before Deploy"
```

**Implementation**: Convert `.hc` to temporal logic, use model checker.

---

### 16.3 Research Directions

#### 16.3.1 Hyperprompt Diff

**Problem**: How to review changes to compiled hyperprompts?

**Solution**: Semantic diff tool

```bash
hyperprompt diff out/v1.hyperprompt.md out/v2.hyperprompt.md
```

**Output**:

```diff
PRIMITIVES:
+ Added: SecurityAudit.primitive (from /primitives/SecurityAudit.md)

WORKFLOW:
  Implement.core:
-   message_template: "feat: ${task.title}"
+   message_template: "feat(${task.scope}): ${task.title}"
```

#### 16.3.2 Prompt Compression

**Problem**: Large hyperprompts exceed LLM context windows

**Approach**: Hierarchical compression

1. Compress rarely-used sections (APPENDICES)
2. Keep WORKFLOW, PRIMITIVES, TASK full-fidelity
3. Use retrieval for on-demand expansion

**Syntax**:

```yaml
# In .hcs
compress:
  mode: hierarchical
  preserve: [WORKFLOW, PRIMITIVES, TASK]
  compress: [RULES, EVIDENCE]
```

#### 16.3.3 Learning from Execution

**Problem**: How to improve primitives based on LLM outcomes?

**Vision**: Feedback loop

1. LLM executes workflow, generates artifacts
2. Human reviews, marks success/failure
3. System correlates outcomes with primitives used
4. Suggests primitive improvements

**Example**:

```
Primitive "Implement" used in 50 workflows:
- Success rate: 72%
- Common failure: "Tests not written"
- Suggestion: Add explicit "Done when: tests pass" criterion
```

---

## 17. Formal Specification

### 17.1 Compilation Semantics

**Notation**:

- `W` = Workflow (`.hc` AST)
- `C` = Context (`.hcs` config)
- `T` = TaskRecord
- `P` = Set of primitives
- `H` = Hyperprompt (output)
- `M` = Manifest

**Compilation Function**:

```
compile: (W, C, T) → (H, M)
```

**Preconditions**:

1. `W` is well-formed Hypercode AST
2. `C` is valid YAML conforming to HCS schema
3. `T` is valid TaskRecord (schema-checked)
4. All primitives referenced in `W` exist in `/primitives/` or are marked missing

**Postconditions**:

1. `H` contains exactly sections: SYSTEM, TASK, OBJECTIVE, WORKFLOW, PRIMITIVES, RULES, EVIDENCE, TOOLS, OUTPUT, QUALITY, MANIFEST, APPENDICES
2. `M.sources` contains SHA256 for all embedded files
3. All `${task.*}` variables in `H` are resolved (no unsubstituted templates)

**Invariant**:

```
∀ (W, C, T₁), (W, C, T₂): T₁ = T₂ ⟹ compile(W, C, T₁) = compile(W, C, T₂)
```

(Determinism: same inputs → same output)

---

### 17.2 Selector Resolution Algorithm

Given:

- Node `n` in workflow `W`
- Selector `s` in context `C`

**Match conditions**:

1. **Type selector** (`NodeName`): `n.name == NodeName`
2. **Class selector** (`.class`): `.class ∈ n.classes`
3. **ID selector** (`#id`): `n.id == id`
4. **Child** (`Parent > Child`): `n.parent.name == Parent ∧ n.name == Child`
5. **Descendant** (`Ancestor Descendant`): `∃ ancestor: ancestor.name == Ancestor ∧ n ∈ descendants(ancestor) ∧ n.name == Descendant`

**Specificity** (higher wins):

```
specificity(s) = (id_count, class_count, type_count)
```

**Example**:

- `#main`: `(1, 0, 0)`
- `.ci`: `(0, 1, 0)`
- `Test`: `(0, 0, 1)`
- `Implement > Commit`: `(0, 0, 2)`

**Resolution**: For node `n`, collect all matching selectors, sort by specificity (descending), merge properties (later overwrites earlier).

---

### 17.3 Variable Interpolation Formal Definition

**Syntax**:

```
<variable> ::= "${" <path> "}"
<path> ::= <ident> ("." <ident>)*
```

**Semantics**:

```python
def resolve(path: str, context: dict) -> Any:
    parts = path.split(".")
    value = context
    for part in parts:
        if part not in value:
            raise UndefinedVariableError(path)
        value = value[part]
    return value

def interpolate(text: str, context: dict) -> str:
    def replacer(match):
        path = match.group(1)
        value = resolve(path, context)
        if isinstance(value, (list, dict)):
            return json.dumps(value)
        return str(value)
    return re.sub(r'\$\{([^}]+)\}', replacer, text)
```

**Example**:

```python
context = {"task": {"id": "F-142", "files": {"include": ["a.py"]}}}
text = "Task ${task.id} includes ${task.files.include}"
result = interpolate(text, context)
# → "Task F-142 includes [\"a.py\"]"
```

---

## 18. IANA Considerations

### 18.1 Media Type Registration

**Proposed Media Types**:

- `application/vnd.hyperprompt+markdown`: Compiled hyperprompt documents
- `application/vnd.hyperprompt.manifest+json`: Manifest files
- `application/vnd.hypercode+yaml`: Hypercode `.hc` files (shared with Hypercode RFC)
- `application/vnd.hypercode-cascade+yaml`: HCS `.hcs` files

**Registration Template** (per RFC 6838):

```
Type name: application
Subtype name: vnd.hyperprompt+markdown
Required parameters: none
Optional parameters: version (e.g., version=0.1)
Encoding considerations: UTF-8
Security considerations: See Section 11
Interoperability considerations: Compatible with Markdown parsers
Published specification: [This RFC]
Applications that use this media type: Hyperprompt compilers, LLM runtimes
Fragment identifier considerations: Standard Markdown heading anchors
Additional information:
  File extension: .hyperprompt.md
  Macintosh file type code: TEXT
Person & email address to contact: [Author contact]
```

### 18.2 URI Scheme

**Proposed**: `hyperprompt://` for referencing compiled prompts

**Syntax**:

```
hyperprompt://<repository>/<workflow>[@<version>][#<section>]
```

**Examples**:

```
hyperprompt://github.com/org/repo/FeatureDelivery
hyperprompt://github.com/org/repo/CI@v1.2.3#PRIMITIVES
```

**Resolution**:

1. Fetch repository
2. Compile workflow (using context at version)
3. Return full hyperprompt or specific section (if fragment present)

---

## 19. Acknowledgements

This specification builds upon:

- **Hypercode RFC** (Egor Merkushev): Foundation for declarative structures
- **Agent Passport RFC** (Egor Merkushev): Security model inspiration
- **CSS Cascading Specification** (W3C): Selector semantics
- **YAML 1.2 Spec**: Configuration format
- **Markdown Spec** (CommonMark): Output format

Special thanks to early reviewers and the open-source community for feedback on draft versions.

---

## 20. References

### 20.1 Normative References

- **[HYPERCODE]**: Hypercode: A Declarative Paradigm for Context-Aware Programming, Egor Merkushev, 2025
- **[AGENT-PASSPORT]**: Agent Passport Specification RFC, Egor Merkushev, 2025
- **[YAML]**: YAML Ain't Markup Language v1.2.2, OASIS, 2021
- **[COMMONMARK]**: CommonMark Spec v0.30, John MacFarlane, 2021
- **[RFC2119]**: Key words for use in RFCs to Indicate Requirement Levels, S. Bradner, 1997
- **[RFC6838]**: Media Type Specifications and Registration Procedures, N. Freed et al., 2013

### 20.2 Informative References

- **[CSS-CASCADE]**: CSS Cascading and Inheritance Level 4, W3C, 2022
- **[LANGCHAIN]**: LangChain Documentation, <https://langchain.com>
- **[LLAMAINDEX]**: LlamaIndex Documentation, <https://llamaindex.ai>
- **[JINJA]**: Jinja Template Engine, <https://jinja.palletsprojects.com>

---

## 21. Change Log

### Version 0.1 (2025-11-07)

- Initial draft specification
- Core concepts: TaskRecord, primitives, compilation algorithm
- Security considerations
- Integration with Hypercode RFC
- Use cases and examples

---

## Appendix A: Complete Example

### A.1 Directory Structure

```
/project
├── workflows/
│   └── FeatureDelivery.hc
├── primitives/
│   ├── Summarize.md
│   ├── Implement.md
│   ├── Test.md
│   └── Report.md
├── rules/
│   ├── CODE_STYLE.md
│   └── QUALITY_GATE.md
├── context/
│   └── FeatureDelivery.hcs
├── workplan/
│   └── refactor-media.md
└── out/
    ├── FeatureDelivery.hyperprompt.md
    └── FeatureDelivery.manifest.json
```

### A.2 Source Files

**workflows/FeatureDelivery.hc**:

```hypercode
FeatureDelivery
  Primitives
    Summarize.primitive
    Implement.primitive
    Test.primitive
    Report.primitive

  Plan.docs
  Implement.core#unit
    Commit
  Test.ci
  Review.pr
  Deliver.tagged
```

**context/FeatureDelivery.hcs**:

```yaml
title: "${task.title}"
objective: "Deliver feature ${task.id}: ${task.scope}"

embed:
  primitives: full
  rules:
    - path: /rules/CODE_STYLE.md
      mode: headings
    - path: /rules/QUALITY_GATE.md
      mode: link

include: ${task.files.include}
exclude: ${task.files.exclude}

capabilities: ["fs.read", "mcp.use('git')"]
net: { mode: off }

outputs: ${task.outputs}

Implement > Commit:
  message_template: "feat(${task.scope}): ${task.title}"
  sign: true

.ci:
  retries: 2
  timeout_seconds: 600
```

**workplan/refactor-media.md**:

```yaml
---
task:
  id: "F-142"
  title: "Refactor Media Pipeline"
  scope: "Decoder isolation"
  files:
    include: ["Sources/Media/**/*.swift"]
    exclude: ["**/Generated/**"]
  outputs:
    - "PR: feature/refactor-media"
    - "docs/out/refactor_report.md"
  branch: "feature/refactor-media"
  risk: "medium"
---

# Refactor Plan
Extract decoder logic into separate module...
```

### A.3 Compilation

```bash
hyperprompt compile \
  --workflow workflows/FeatureDelivery.hc \
  --context context/FeatureDelivery.hcs \
  --output out/FeatureDelivery.hyperprompt.md
```

### A.4 Output (Abbreviated)

**out/FeatureDelivery.hyperprompt.md**:

````markdown
# SYSTEM
You are an expert software engineer in an agentic development environment.

# TASK
- **ID**: F-142
- **Title**: Refactor Media Pipeline
- **Scope**: Decoder isolation
- **Branch**: feature/refactor-media
- **Risk**: medium

# OBJECTIVE
Deliver feature F-142: Decoder isolation by refactoring the media pipeline.

# WORKFLOW

## FeatureDelivery
### Primitives
#### Summarize .primitive
#### Implement .primitive
#### Test .primitive
#### Report .primitive

### Plan .docs
- artifact: docs/out/spec.md

### Implement .core #unit
- build_config: Debug

#### Commit
- message_template: "feat(Decoder isolation): Refactor Media Pipeline"
- sign: true

### Test .ci
- retries: 2
- timeout_seconds: 600

# PRIMITIVES

## Summarize
**Intent:** Кратко собрать контекст задачи.
**Do:** выпиши цель, входы/выходы, риски, артефакты.
**Done when:** есть 5–8 маркеров, покрывающих scope.

## Implement
**Intent:** Минимально реализовать изменение в целевых файлах.
**Do:** локальная ветка feature/refactor-media; маленькие коммиты; следуй CODE_STYLE.
**Done when:** билд зелёный, покрытие не ниже базовой линии.

# RULES

## CODE_STYLE.md (mode: headings)

### Swift Style Guide
Use 2-space indentation...

# EVIDENCE

## Included Files
- Sources/Media/Decoder.swift
- Sources/Media/Pipeline.swift

## Excluded Patterns
- **/Generated/**

# TOOLS

## Available Capabilities
- `fs.read`: Read files from evidence scope
- `mcp.use('git')`: Git operations

## Network Mode
**Mode**: off

# OUTPUT

## Required Artifacts
1. PR: feature/refactor-media
2. docs/out/refactor_report.md

# MANIFEST

```yaml
timestamp: "2025-11-07T14:32:15Z"
sources:
  - path: /workflows/FeatureDelivery.hc
    sha256: a3f5c8914b2d...
    size: 347
  - path: /context/FeatureDelivery.hcs
    sha256: 9d2e1a473c8f...
    size: 856
  - path: /primitives/Summarize.md
    sha256: 7b4c3f92e1d5...
    size: 342
    mode: full
task_record:
  id: F-142
  title: "Refactor Media Pipeline"
  scope: "Decoder isolation"
```
````

---

## Appendix B: Schema Definitions

### B.1 TaskRecord JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "TaskRecord",
  "type": "object",
  "required": ["id", "title"],
  "properties": {
    "id": {
      "type": "string",
      "description": "Unique task identifier"
    },
    "title": {
      "type": "string",
      "description": "Human-readable task title"
    },
    "scope": {
      "type": "string",
      "description": "Scope or component being modified"
    },
    "files": {
      "type": "object",
      "properties": {
        "include": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Glob patterns for files to include"
        },
        "exclude": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Glob patterns for files to exclude"
        }
      }
    },
    "outputs": {
      "type": "array",
      "items": {"type": "string"},
      "description": "Expected artifacts"
    },
    "branch": {
      "type": "string",
      "description": "Git branch name"
    },
    "risk": {
      "type": "string",
      "enum": ["low", "medium", "high"],
      "description": "Risk level assessment"
    }
  },
  "additionalProperties": true
}
```

### B.2 HCS Configuration Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "HCS Configuration",
  "type": "object",
  "properties": {
    "title": {"type": "string"},
    "objective": {"type": "string"},
    "embed": {
      "type": "object",
      "properties": {
        "primitives": {
          "type": "string",
          "enum": ["full", "headings", "link"]
        },
        "rules": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "path": {"type": "string"},
              "mode": {
                "type": "string",
                "enum": ["full", "headings", "link"]
              }
            },
            "required": ["path", "mode"]
          }
        }
      }
    },
    "include": {
      "type": "array",
      "items": {"type": "string"}
    },
    "exclude": {
      "type": "array",
      "items": {"type": "string"}
    },
    "capabilities": {
      "type": "array",
      "items": {"type": "string"}
    },
    "net": {
      "type": "object",
      "properties": {
        "mode": {
          "type": "string",
          "enum": ["off", "read-only", "full"]
        }
      },
      "required": ["mode"]
    },
    "outputs": {
      "type": "array",
      "items": {"type": "string"}
    }
  },
  "required": ["title", "objective", "embed"],
  "patternProperties": {
    "^[A-Z]": {
      "description": "Node selectors and their properties"
    }
  }
}
```

---

**End of Hyperprompt Framework Specification v0.1**

---

Это полная RFC-спецификация Hyperprompt Framework в стиле Agent Passport RFC. Ключевые улучшения:

1. **Структура RFC**: Следует стандартному формату (Abstract, Motivation, Terminology, Architecture, etc.)
2. **Формальная спецификация**: Включает математические определения (Section 17)
3. **Безопасность**: Детальный раздел Security Considerations с моделью угроз
4. **Интеграция**: Четкая связь с Hypercode RFC и Agent Passport
5. **Примеры**: Полные use cases с кодом
6. **Extensibility**: Future Work с конкретными направлениями развития
7. **Schemas**: JSON Schema для валидации TaskRecord и HCS

Готов детализировать любой раздел или добавить дополнительные примеры!

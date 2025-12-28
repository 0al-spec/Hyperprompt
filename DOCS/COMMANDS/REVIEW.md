# REVIEW — Code Review for Committed Changes

**Version:** 1.0.0

## Purpose

Perform systematic, rigorous code review of committed changes on the current working branch using the Code Reviewer role methodology. This command applies deep technical review across correctness, architecture, maintainability, performance, security, and concurrency concerns.

## Input

- `DOCS/RULES/07_Code_Review_Prompt.md` — Code Reviewer role and methodology
- Current git branch — committed changes to review
- Git history — commits since divergence from base branch
- Modified files — diff output for analysis

## Algorithm

### 1. Identify Review Scope

```bash
# Get current branch name
git branch --show-current

# Identify commits to review (since divergence from main/master)
git log --oneline origin/main..HEAD  # or origin/master..HEAD

# Get full diff of all changes
git diff origin/main...HEAD
```

### 2. Gather Context

- Read commit messages to understand intent
- Identify scope of changes (feature, refactor, fix, security, performance)
- List all modified, added, and deleted files
- Extract relevant architectural context from codebase

### 3. Apply Code Reviewer Role

Activate the Code Reviewer persona from `DOCS/RULES/07_Code_Review_Prompt.md` and perform multi-layer review:

#### 2.1 Correctness & Logic
- Verify logical correctness and edge-case handling
- Identify bugs, race conditions, undefined behavior
- Check for undocumented side effects

#### 2.2 Architecture & Design
- Evaluate separation of concerns and coupling
- Detect architectural drift or leaky abstractions
- Assess alignment with project principles

#### 2.3 Maintainability & Readability
- Review naming, structure, cognitive load
- Identify hard-to-maintain or test code
- Flag duplication or unclear responsibilities

#### 2.4 Performance & Resource Usage
- Identify unnecessary allocations or blocking calls
- Mark issues as measured, suspected, or hypothetical

#### 2.5 Security & Safety
- Analyze attack surface and trust boundaries
- Flag injection risks, unsafe operations
- Check validation, authentication, authorization

#### 2.6 Concurrency & State (if applicable)
- Verify thread safety and async correctness
- Flag race conditions, deadlocks, shared mutable state

### 4. Classify and Document Findings

For each issue found, assign severity:

- **Blocker** — must be fixed before merge
- **High** — serious risk, strongly recommended to fix
- **Medium** — improvement with clear benefits
- **Low** — minor, stylistic, or optional
- **Nit** — purely cosmetic or preference-based

### 5. Generate Structured Review Report

Produce output following this structure:

```markdown
## Code Review Report

**Branch:** [branch-name]
**Commits Reviewed:** [commit-range]
**Files Changed:** [count]

### Summary Verdict
- [ ] Approve
- [ ] Approve with comments
- [ ] Request changes
- [ ] Block

[One-paragraph justification]

### Critical Issues
[Blocker & High issues with proposed fixes]

### Non-Critical Issues
[Medium / Low / Nit items]

### Architectural Notes
[High-level observations beyond immediate diff]

### Test Coverage Assessment
[Analysis of test quality and coverage]

### Suggested Follow-Ups
[Out-of-scope improvements, clearly marked]
```

## Output

- **Report location**: `DOCS/INPROGRESS/{readable_name}.md`
  - `{readable_name}` should describe the review scope (e.g., `REVIEW_add_code_reviewer_role.md`)
- Structured code review report in markdown format
- Actionable findings with severity classification
- Proposed fixes for critical issues
- Assessment of test coverage and quality

## Usage Examples

### Review current branch changes

```bash
# Review all commits on current branch since divergence from main
REVIEW
```

### Review specific commit range

```bash
# Review specific commits
git log --oneline abc123..def456
git diff abc123..def456
# Then apply REVIEW methodology
```

### Review uncommitted changes

```bash
# Review staged changes before commit
git diff --cached
# Apply REVIEW methodology to staged diff
```

## Exceptions

- **No commits to review**: Branch is up-to-date with base branch — exit with message
- **Merge conflicts present**: Resolve conflicts before review
- **No base branch found**: Specify base branch explicitly (e.g., `origin/main`)
- **Large changeset (>50 files)**: Consider breaking review into logical components
- **Missing tests**: Flag as blocker or high severity depending on change type

## Quality Enforcement

- No vague language ("probably", "maybe", "looks fine")
- Every claim justified by code evidence
- Concrete fixes for all Blocker and High issues
- Test coverage explicitly assessed
- Security implications explicitly stated

## Integration with FLOW

REVIEW can be used:

- **After EXECUTE**: Before pushing changes, review commits for quality
- **Before PR creation**: Final check before opening pull request
- **During PR review**: Apply systematic review to PR changes
- **After merging**: Post-merge analysis for lessons learned

## Related Documentation

- `DOCS/RULES/07_Code_Review_Prompt.md` — Code Reviewer role definition
- `DOCS/COMMANDS/EXECUTE.md` — Development execution workflow
- `DOCS/RULES/03_XP_TDD_Workflow.md` — XP/TDD methodology
- `DOCS/COMMANDS/FLOW.md` — Overall development workflow

# COMMIT — Record Changes

**Version:** 1.0

## Purpose

Capture a clean, descriptive snapshot of your work and leave the tree in the desired state.

## Usage

```
$ git status -sb             # confirm staged vs unstaged files
$ git add <files…>            # stage only what belongs to this task
$ git commit -m "…short message…"
```

## Guidelines

- Keep commits focused: include only the files touched while implementing the current PRD.
- Use the present-tense summary (e.g., `Archive EE1 task`, `Implement EE2 parser`) followed by optional context in a longer body when needed.
- If you are batching results of multiple tasks, commit each archive/integration step separately.
- After committing, run `git status -sb` again to ensure the working tree is clean before pushing.

## Integration

This primitive is referenced by commands such as `EXECUTE` and `ARCHIVE` when they need an explicit git snapshot before pushing. When you need a quicker reminder of the commit steps, open this file for the minimal checklist.

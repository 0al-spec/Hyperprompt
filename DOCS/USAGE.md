# Hyperprompt Usage Guide

Complete reference for all CLI arguments, options, and flags.

## Table of Contents

1. [Basic Syntax](#basic-syntax)
2. [Positional Arguments](#positional-arguments)
3. [Options](#options)
4. [Mode Flags](#mode-flags)
5. [Action Flags](#action-flags)
6. [Help & Version](#help--version)
7. [Examples](#examples)
8. [Exit Codes](#exit-codes)

---

## Basic Syntax

```bash
hyperprompt <input> [OPTIONS] [FLAGS]
```

**Required:** `<input>` — Path to root .hc file
**Optional:** All options and flags

---

## Positional Arguments

### `<input>`

**Type:** File path (string)
**Required:** Yes
**Description:** Path to the root Hypercode file to compile

**Examples:**
```bash
hyperprompt root.hc
hyperprompt src/main.hc
hyperprompt /absolute/path/file.hc
hyperprompt ./relative/path/file.hc
```

**Error if missing:**
```
Error: Missing required argument '<input>'
```

---

## Options

Options take values and can be specified in short (`-`) or long (`--`) form.

### `--output` / `-o`

**Type:** File path
**Default:** `out.md`
**Description:** Path where compiled Markdown will be written

**Syntax:**
```bash
hyperprompt input.hc --output <file>
hyperprompt input.hc -o <file>
```

**Examples:**
```bash
# Long form
hyperprompt root.hc --output compiled.md
hyperprompt root.hc --output ./build/output.md
hyperprompt root.hc --output /tmp/result.md

# Short form
hyperprompt root.hc -o compiled.md
hyperprompt root.hc -o ./build/output.md

# With spaces in filename (quote the path)
hyperprompt root.hc --output "my output.md"
```

**Notes:**
- Output file will be created or overwritten
- Parent directory must exist (not automatically created)
- Use `-` to write to stdout (if supported): `hyperprompt root.hc -o -`

### `--manifest` / `-m`

**Type:** File path
**Default:** `manifest.json`
**Description:** Path where compilation manifest JSON will be written

**Syntax:**
```bash
hyperprompt input.hc --manifest <file>
hyperprompt input.hc -m <file>
```

**Examples:**
```bash
# Long form
hyperprompt root.hc --manifest build-manifest.json
hyperprompt root.hc --manifest ./meta/manifest.json

# Short form
hyperprompt root.hc -m meta.json
hyperprompt root.hc -m ./build/manifest.json
```

**Manifest Contents:**
The manifest file contains:
- List of all referenced files
- Compilation statistics (line count, node count, max depth)
- Dependency graph for circular reference detection
- Compiler version and metadata

**Example manifest:**
```json
{
  "version": "0.1.0",
  "timestamp": "2025-12-12T20:38:35Z",
  "statistics": {
    "lines": 42,
    "nodes": 15,
    "maxDepth": 3,
    "totalReferences": 8
  },
  "files": [
    "root.hc",
    "sections/intro.md",
    "sections/details.hc"
  ],
  "dependencies": {
    "root.hc": ["sections/intro.md", "sections/details.hc"],
    "sections/details.hc": ["subsections/more.md"]
  }
}
```

### `--root` / `-r`

**Type:** Directory path
**Default:** `.` (current directory)
**Description:** Root directory for resolving file references

**Syntax:**
```bash
hyperprompt input.hc --root <directory>
hyperprompt input.hc -r <directory>
```

**Examples:**
```bash
# Long form - compile in specific project directory
hyperprompt root.hc --root /home/user/myproject
hyperprompt root.hc --root ./project

# Short form
hyperprompt root.hc -r .
hyperprompt root.hc -r ~/documents/project

# Absolute path
hyperprompt root.hc --root /var/documents
```

**Behavior:**
- All file references are resolved relative to this directory
- Prevents path traversal outside this directory (security boundary)
- Example: If `--root /home/user/docs` and file references `../etc/passwd`, compilation will fail with "path traversal" error

**Notes:**
- Directory must exist
- Use this to sandbox compilation to specific folders
- Particularly useful for CI/CD pipelines

---

## Mode Flags

Mode flags are mutually exclusive. Default is strict mode.

### `--lenient`

**Type:** Boolean flag
**Default:** Disabled (strict mode active)
**Description:** Treat missing file references as inline text instead of failing

**Syntax:**
```bash
hyperprompt input.hc --lenient
```

**Behavior:**
- When a file reference (`.md` or `.hc`) is missing, treat it as literal text
- Compilation continues instead of exiting with error
- Useful for partial compilations during development
- Incompatible with `--strict` flag

**Example:**

Given file `root.hc`:
```
"Document"
    "missing-file.md"
    "another-missing.hc"
```

**Strict mode (default):**
```bash
hyperprompt root.hc
# Error: File not found: missing-file.md
# Exit code: 1
```

**Lenient mode:**
```bash
hyperprompt root.hc --lenient
# Success: Treats "missing-file.md" as text
# Output: Document
#   missing-file.md
#   another-missing.hc
# Exit code: 0
```

### Strict Mode (Default)

**Type:** Boolean flag (implicit, default)
**Description:** Missing file references cause compilation failure

**Behavior:**
- All file references must exist and be readable
- Compilation fails (exit code 1) if any file is missing
- This is the default if neither `--lenient` nor `--strict` is specified
- Prevents accidental data loss from incomplete documents

**Example:**
```bash
hyperprompt root.hc              # Strict mode (default)
hyperprompt root.hc --strict     # Explicit strict mode (same as above)
```

---

## Action Flags

Action flags modify compilation behavior or output. Can be combined.

### `--verbose` / `-v`

**Type:** Boolean flag
**Default:** Disabled
**Description:** Enable detailed logging output

**Syntax:**
```bash
hyperprompt input.hc --verbose
hyperprompt input.hc -v
```

**Output:**
- File resolution steps
- AST parsing details
- Reference resolution process
- Emission steps

**Example:**
```bash
$ hyperprompt root.hc -v
[INFO] Reading root.hc
[INFO] Parsing root.hc
  └─ Found 3 nodes
[INFO] Resolving references
  ├─ Resolved: intro.md (12 lines)
  ├─ Resolved: content/main.hc (24 lines, 5 nodes)
  └─ Resolved: content/subsection/detail.md (8 lines)
[INFO] Emitting Markdown output
[INFO] Writing to out.md (256 bytes)
[INFO] Compilation complete: Success
```

### `--stats`

**Type:** Boolean flag
**Default:** Disabled
**Description:** Collect and report compilation statistics

**Syntax:**
```bash
hyperprompt input.hc --stats
```

**Output includes:**
- Total lines processed
- Total nodes in AST
- Maximum nesting depth
- Files referenced
- Compilation time
- Output size

**Example:**
```bash
$ hyperprompt root.hc --stats
Compilation Statistics:
  Lines processed:        156
  Nodes in AST:           42
  Max nesting depth:      5
  Files referenced:       8
  Compilation time:       0.234s
  Output size:            4.2 KB
```

**Combination:**
```bash
# Verbose output with statistics
hyperprompt root.hc -v --stats
```

### `--dry-run`

**Type:** Boolean flag
**Default:** Disabled
**Description:** Validate syntax and references without writing output files

**Syntax:**
```bash
hyperprompt input.hc --dry-run
```

**Behavior:**
- Performs full compilation pipeline
- Skips writing `--output` and `--manifest` files
- Useful for validation before actual compilation
- Exit codes indicate success/failure normally

**Example:**
```bash
# Validate without writing files
hyperprompt root.hc --dry-run

# Output: (no files written)
# Exit code: 0 (if valid), 1-4 (if errors)
```

**Use cases:**
- CI/CD validation steps
- Pre-commit hooks
- Syntax checking in editor plugins
- Format conversion testing

---

## Help & Version

### `--help` / `-h`

**Type:** Boolean flag
**Description:** Display help message and exit

**Syntax:**
```bash
hyperprompt --help
hyperprompt -h
```

**Output:**
```
OVERVIEW: Compile Hypercode to Markdown with manifest generation

USAGE: hyperprompt <input> [--output <output>] [--manifest <manifest>]
                          [--root <root>] [--lenient] [--verbose]
                          [--stats] [--dry-run] [--version] [--help]

ARGUMENTS:
  <input>                 Path to root .hc file to compile

OPTIONS:
  -o, --output <output>   Output Markdown file (default: out.md)
  -m, --manifest <manifest>
                          Output manifest JSON file (default: manifest.json)
  -r, --root <root>       Root directory for file resolution (default: .)

FLAGS:
  --lenient               Treat missing references as inline text
  -v, --verbose           Enable verbose logging
  --stats                 Collect and report compilation statistics
  --dry-run               Validate without writing output files
  --version               Show the version.
  -h, --help              Show help information.
```

### `--version`

**Type:** Boolean flag
**Description:** Display compiler version and exit

**Syntax:**
```bash
hyperprompt --version
```

**Output:**
```
hyperprompt version 0.1.0
```

**Exit code:** Always 0 (success)

---

## Examples

### Minimal Usage

```bash
# Compile with defaults
hyperprompt root.hc
# Creates: out.md, manifest.json
```

### Specified Output Filenames

```bash
hyperprompt root.hc --output compiled.md --manifest meta.json
# Short form
hyperprompt root.hc -o compiled.md -m meta.json
```

### Project-Specific Root Directory

```bash
# Compile project files with specific root
hyperprompt docs/main.hc --root /home/user/project
# All file references resolve relative to /home/user/project
```

### Development Workflow (Lenient + Verbose + Dry-Run)

```bash
# Test changes without writing files, see details
hyperprompt root.hc --lenient --verbose --dry-run
```

### Production Validation (Strict + Stats)

```bash
# Full validation with statistics
hyperprompt root.hc --stats
```

### CI/CD Pipeline

```bash
# Validate in strict mode, capture manifest for reporting
hyperprompt root.hc --root ./docs --manifest build/manifest.json --stats

# Check for validation errors
if [ $? -ne 0 ]; then
    echo "Compilation failed"
    exit 1
fi
```

### Watch Mode Integration (Example)

```bash
# Validate file before committing
hyperprompt src/main.hc --dry-run --verbose

# Or compile and report
hyperprompt src/main.hc --output build/docs.md --manifest build/manifest.json --stats
```

### Debug Problematic Files

```bash
# Get detailed output
hyperprompt problem.hc --verbose --lenient

# Validate syntax only
hyperprompt problem.hc --dry-run --verbose

# Check what would be generated
hyperprompt problem.hc --dry-run --verbose --stats
```

---

## Exit Codes

The exit code indicates compilation result:

| Code | Meaning | Example |
|------|---------|---------|
| 0 | Success | Compilation completed, all validations passed |
| 1 | IO Error | File not found, permission denied, disk full |
| 2 | Syntax Error | Invalid Hypercode syntax (unclosed quote, bad indentation) |
| 3 | Resolution Error | Missing file (strict mode), circular dependency detected |
| 4 | Internal Error | Compiler bug (should not occur) |

**Exit code in scripts:**
```bash
hyperprompt root.hc
case $? in
    0) echo "Compilation successful" ;;
    1) echo "IO error - check file paths" ;;
    2) echo "Syntax error - check Hypercode syntax" ;;
    3) echo "Resolution error - check file references" ;;
    4) echo "Internal compiler error" ;;
esac
```

---

## Argument Combinations

### Valid Combinations

```bash
# Minimal
hyperprompt root.hc

# Output options
hyperprompt root.hc -o file.md -m manifest.json -r ./project

# Mode + actions
hyperprompt root.hc --lenient --verbose --stats

# All options
hyperprompt root.hc -o out.md -m meta.json -r . --verbose --stats --dry-run
```

### Invalid Combinations

```bash
# Missing required input
hyperprompt
# Error: Missing required argument '<input>'

# Unknown flag
hyperprompt root.hc --unknown
# Error: Unknown flag --unknown

# Duplicate option
hyperprompt root.hc -o file1.md -o file2.md
# Error: Cannot specify multiple times
```

---

## Performance Tips

1. **Use `--dry-run` for validation** - Faster than full compilation
2. **Avoid deep nesting** - Compilation time increases with depth
3. **Use lenient mode for drafts** - Faster than strict mode
4. **Enable `--stats` periodically** - Identify performance bottlenecks
5. **Keep files organized** - Shorter relative paths resolve faster

---

## See Also

- [README.md](../README.md) — Quick start and overview
- [LANGUAGE.md](LANGUAGE.md) — Hypercode syntax specification
- [ERROR_CODES.md](ERROR_CODES.md) — Detailed error descriptions
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — Solutions to common problems

---

**Last Updated:** December 12, 2025

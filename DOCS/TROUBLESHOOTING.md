# Troubleshooting Guide

Common issues, frequently asked questions, and solutions.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Build & Compilation](#build--compilation)
3. [CLI Usage](#cli-usage)
4. [Syntax & Language](#syntax--language)
5. [File References](#file-references)
6. [Performance](#performance)
7. [Output Issues](#output-issues)
8. [Getting Help](#getting-help)

---

## Installation Issues

### "swift: command not found"

**Cause:** Swift is not installed or not in PATH

**Solutions:**

1. **Check if Swift is installed:**
   ```bash
   swift --version
   ```

2. **Install Swift:**
   - **macOS:** Uses system Swift or Xcode
   - **Linux:** See [DOCS/RULES/02_Swift_Installation.md](RULES/02_Swift_Installation.md)

3. **Add Swift to PATH:**
   ```bash
   export PATH="/usr/bin/swift:$PATH"
   source ~/.bashrc
   ```

### Build fails with dependency errors

**Cause:** Missing dependencies or incompatible versions

**Solutions:**

1. **Clean and rebuild:**
   ```bash
   swift package clean
   swift build
   ```

2. **Update dependencies:**
   ```bash
   swift package update
   swift build
   ```

3. **Check Package.swift compatibility:**
   - Verify swift-argument-parser version
   - Verify swift-crypto version
   - Verify SpecificationCore version

### Permission denied during build

**Solutions:**

```bash
# Check directory permissions
ls -la .

# Make directory writable
chmod +w .

# Or use different build directory
swift build -Xswiftc -debug-prefix-map -Xswiftc /tmp/build
```

---

## Build & Compilation

### "error: could not find Package.swift"

**Cause:** Running from wrong directory

**Solutions:**

```bash
# Navigate to project root
cd Hyperprompt
pwd  # Verify you see /path/to/Hyperprompt

swift build
```

### Long build times

**Cause:** First build compiles all dependencies

**Solutions:**

1. **First build is normal:**
   - C crypto libraries take time to compile
   - Subsequent builds are faster

2. **Use release configuration:**
   ```bash
   swift build -c release  # Optimized binary
   ```

3. **Parallel compilation:**
   ```bash
   swift build -j 8  # Use 8 cores
   ```

### Tests fail

**Cause:** Various issues (syntax errors, missing files, etc.)

**Solutions:**

1. **Run verbose tests:**
   ```bash
   swift test -v
   ```

2. **Run specific test:**
   ```bash
   swift test --filter ResolverTests
   ```

3. **Check test fixtures exist:**
   ```bash
   ls Tests/IntegrationTests/Fixtures/Valid/
   ```

---

## CLI Usage

### "hyperprompt: command not found"

**Cause:** Built executable not in PATH or name incorrect

**Solutions:**

```bash
# Find the executable
find .build -name hyperprompt -type f

# Run with full path
./.build/debug/hyperprompt --help
./.build/release/hyperprompt --help

# Add to PATH temporarily
export PATH="$PWD/.build/release:$PATH"
hyperprompt --help
```

### "Hyperprompt: compile failed (Error: RPC process failed to start. Ensure hyperprompt is on PATH.)"

**Cause:** The VS Code extension cannot find `hyperprompt`, or the CLI was built without the Editor trait.

**Solutions:**

```bash
# Build with the Editor trait enabled
swift build --traits Editor

# Add the debug build to PATH for the current shell
export PATH="$PWD/.build/debug:$PATH"

# Verify the RPC subcommand is available
hyperprompt editor-rpc
```

Restart VS Code after updating PATH so the Extension Host inherits it.

### "Missing required argument '<input>'"

**Cause:** No input file specified

**Solutions:**

```bash
# Correct usage
hyperprompt root.hc

# Check file exists
ls -la root.hc
```

### "Unknown flag: --unknown"

**Cause:** Typo in flag name

**Solutions:**

```bash
# Get help
hyperprompt --help

# Common flags
--output    # Short: -o
--manifest  # Short: -m
--root      # Short: -r
--lenient
--verbose   # Short: -v
--stats
--dry-run
--version
--help      # Short: -h
```

### Cannot specify multiple times

**Cause:** Using same option twice

**Solutions:**

```bash
# Wrong
hyperprompt root.hc -o out1.md -o out2.md

# Correct (use one output)
hyperprompt root.hc -o output.md
```

---

## Syntax & Language

### "Unclosed quote"

**Problem:** String not properly closed

**Example:**
```
"Missing closing quote
```

**Solutions:**

1. **Add closing quote:**
   ```
   "Missing closing quote"
   ```

2. **Use editor with bracket matching:**
   - Highlights quote pairs
   - Shows mismatches

### "Invalid indentation"

**Problem:** Indentation not multiple of 4 spaces

**Examples:**
```
"Root"
  "Child"      <- 2 spaces (wrong)

"Root"
 	"Child"    <- Tab (wrong)

"Root"
    "Child"    <- 4 spaces (correct)
```

**Solutions:**

1. **Convert to spaces:**
   ```bash
   expand -t 4 file.hc > file-fixed.hc
   ```

2. **Check indentation in editor:**
   - VS Code: Show Whitespace (Cmd+Shift+P > "Toggle Render Whitespace")
   - View tab characters: `cat -A file.hc`

3. **Fix indentation:**
   ```bash
   # Replace tabs with 4 spaces
   sed 's/^\t/    /g' file.hc > file-fixed.hc
   ```

### Newlines not working

**Problem:** Content on multiple lines

**Invalid:**
```
"Text on
multiple lines"
```

**Valid:**
```
"Text on line 1"
    "Text on line 2"
```

**Solution:** Use nested nodes for multi-line content

### Comments not working

**Problem:** Comments appearing in output

**Invalid:**
```
"Title" # This is a comment
```

**Valid:**
```
# This is a comment line
"Title"
```

**Note:** Comments must be on their own line

---

## File References

### "File not found" (Strict Mode)

**Cause:** Referenced file doesn't exist

**Solutions:**

1. **Use lenient mode (temporary):**
   ```bash
   hyperprompt root.hc --lenient
   ```

2. **Create missing file:**
   ```bash
   touch missing-file.md
   ```

3. **Fix file path:**
   - Check relative path from root directory
   - Verify file extension (.md or .hc)
   - Check working directory

### Missing file resolution

**Problem:** Relative paths not resolving correctly

**Example:**
```
"Document"
    "docs/intro.md"  <- Where is docs/ relative to?
```

**Solutions:**

1. **Use explicit root directory:**
   ```bash
   hyperprompt root.hc --root /home/user/project
   # Now "docs/intro.md" is /home/user/project/docs/intro.md
   ```

2. **Use absolute paths in file:**
   ```
   "/home/user/project/docs/intro.md"
   ```

3. **Check working directory:**
   ```bash
   pwd  # Current directory
   hyperprompt root.hc
   ```

### Circular dependency error

**Problem:** Files reference each other (infinite loop)

**Example:**
```
a.hc: "A" -> "b.hc"
b.hc: "B" -> "a.hc"
```

**Solutions:**

1. **Break the cycle:**
   - Remove one reference
   - Create separate files
   - Restructure hierarchy

2. **Example fix:**
   ```
   root.hc: "Root" -> "a.hc", "b.hc"
   a.hc: "A content"
   b.hc: "B content" (no reference back to a.hc)
   ```

### "Path traversal" error

**Problem:** Reference tries to escape root directory

**Example:**
```
"Doc"
    "../../etc/passwd"  <- Tries to escape root
```

**Solutions:**

1. **Use relative path within root:**
   ```
   "Doc"
       "docs/file.md"   <- Valid path
   ```

2. **Adjust root directory:**
   ```bash
   hyperprompt root.hc --root /correct/directory
   ```

### File shows as text instead of being included

**Problem:** File reference not detected

**Cause:** No `/` or `.` in filename

**Example:**
```
"Content"
    "docs"    <- Ambiguous: is this a file or text?
```

**Solutions:**

1. **Include extension:**
   ```
   "Content"
       "docs/intro.md"  <- Clear: file reference
   ```

2. **Use full path:**
   ```
   "Content"
       "docs/"          <- Clear: directory reference
   ```

---

## Performance

### Slow compilation

**Causes:**
- Large files
- Deep nesting
- Many references
- Slow disk

**Solutions:**

1. **Use --dry-run for validation:**
   ```bash
   hyperprompt root.hc --dry-run  # Faster validation
   ```

2. **Split large files:**
   ```
   root.hc -> chapter1.hc, chapter2.hc, chapter3.hc
   ```

3. **Reduce nesting depth:**
   - Flatten hierarchy if possible
   - Limit to 5-6 levels deep

4. **Use --stats to profile:**
   ```bash
   hyperprompt root.hc --stats
   ```

### High memory usage

**Cause:** Large compiled documents

**Solutions:**

1. **Split into smaller compilations:**
   ```bash
   # Instead of one huge file:
   hyperprompt part1.hc --output part1.md
   hyperprompt part2.hc --output part2.md
   ```

2. **Use lenient mode:**
   ```bash
   hyperprompt root.hc --lenient  # Faster, less memory
   ```

---

## Output Issues

### No output file created

**Cause:** Compilation failed or --dry-run used

**Solutions:**

1. **Check exit code:**
   ```bash
   hyperprompt root.hc
   echo $?  # 0 = success, 1-4 = error
   ```

2. **Use verbose mode:**
   ```bash
   hyperprompt root.hc --verbose
   ```

3. **Check file permissions:**
   ```bash
   ls -la .
   chmod +w .
   ```

### Output file empty

**Cause:** Input file empty or only comments/whitespace

**Solutions:**

1. **Check input file:**
   ```bash
   cat root.hc
   ```

2. **Verify content:**
   ```
   # Valid .hc file must have at least one node:
   "Root"
   ```

### Manifest file missing

**Cause:** Not specified or --dry-run used

**Solutions:**

```bash
# Explicitly request manifest
hyperprompt root.hc --manifest my-manifest.json

# Check output
ls -la my-manifest.json
```

### Output encoding issues

**Cause:** File system or terminal encoding mismatch

**Solutions:**

```bash
# Check file encoding
file out.md

# Force UTF-8
iconv -f UTF-8 -t UTF-8 out.md > out-fixed.md
```

---

## Getting Help

### Documentation

- **[README.md](../README.md)** — Quick start
- **[USAGE.md](USAGE.md)** — CLI reference
- **[LANGUAGE.md](LANGUAGE.md)** — Grammar specification
- **[ERROR_CODES.md](ERROR_CODES.md)** — Error messages
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — System design

### Reporting Issues

1. **GitHub Issues:** [Report on GitHub](https://github.com/0al-spec/Hyperprompt/issues)

2. **Information to include:**
   - Hyperprompt version: `hyperprompt --version`
   - Swift version: `swift --version`
   - Operating system: `uname -a`
   - Minimal reproduction case (test .hc file)
   - Full error message and exit code

3. **Example issue:**
   ```
   Title: Circular dependency error with valid input

   Description:
   Files a.hc and b.hc are not circular but get error.

   Steps to reproduce:
   1. Create a.hc with "A" -> "b.hc"
   2. Create b.hc with "B" (no references)
   3. Run: hyperprompt a.hc
   4. Error: Circular dependency detected

   Expected: Should compile successfully

   Actual: Error message and exit code 3

   Environment:
   - Swift 6.0.3
   - Ubuntu 22.04
   - Hyperprompt v0.1.0
   ```

### Common Debugging Steps

```bash
# 1. Test with simple file
echo '"Hello"' > test.hc
hyperprompt test.hc

# 2. Use verbose output
hyperprompt root.hc --verbose

# 3. Use dry-run to validate
hyperprompt root.hc --dry-run --verbose

# 4. Check file system
ls -la root.hc
cat root.hc

# 5. Use specific root directory
hyperprompt root.hc --root $(pwd)

# 6. Try lenient mode
hyperprompt root.hc --lenient
```

---

## Quick Reference

| Issue | Command | Link |
|-------|---------|------|
| Help | `hyperprompt --help` | [USAGE.md](USAGE.md) |
| Syntax errors | Review [LANGUAGE.md](LANGUAGE.md) | [LANGUAGE.md](LANGUAGE.md) |
| File not found | Use `--lenient` or create file | [ERROR_CODES.md](ERROR_CODES.md) |
| Indentation problem | Check tabs/spaces | [LANGUAGE.md](LANGUAGE.md) |
| Path traversal | Use valid path within --root | [ERROR_CODES.md](ERROR_CODES.md) |
| Circular dependency | Fix file references | [ERROR_CODES.md](ERROR_CODES.md) |

---

**Last Updated:** December 12, 2025

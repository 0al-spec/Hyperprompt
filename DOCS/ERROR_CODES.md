# Error Codes and Solutions

Reference guide for all exit codes, error messages, and solutions.

## Exit Code Overview

| Code | Category | Cause | Common Fix |
|------|----------|-------|-----------|
| 0 | Success | Compilation completed successfully | — |
| 1 | IO Error | File not found, permission denied, disk issue | Check file paths and permissions |
| 2 | Syntax Error | Invalid Hypercode syntax | Review syntax rules in LANGUAGE.md |
| 3 | Resolution Error | Missing file (strict) or circular dependency | Fix references or use --lenient |
| 4 | Internal Error | Compiler bug | Report to maintainers |

---

## Exit Code 0: Success

**Meaning:** Compilation completed successfully without errors.

**Scenarios:**
- File parsed correctly
- All references resolved (or lenient mode used)
- Output files written successfully
- All validations passed

**Example:**
```bash
$ hyperprompt root.hc --output out.md
$ echo $?
0
```

---

## Exit Code 1: IO Error

**Meaning:** File system related error — file not found, permission denied, disk full, etc.

### Input File Not Found

**Error Message:**
```
Error: Input file not found: <filename>
```

**Causes:**
- File doesn't exist
- Wrong path specified
- Working directory is incorrect
- File was deleted

**Solutions:**

1. **Verify file exists:**
   ```bash
   ls -la root.hc
   ```

2. **Check absolute path:**
   ```bash
   hyperprompt /absolute/path/root.hc
   ```

3. **Check working directory:**
   ```bash
   pwd
   cd /correct/directory
   hyperprompt root.hc
   ```

4. **Use relative path:**
   ```bash
   hyperprompt ./src/root.hc
   ```

### Referenced File Not Found (Strict Mode)

**Error Message:**
```
Error: File not found: <referenced-file>
```

**Context:** File is referenced in a .hc file but doesn't exist.

**Example:**
```
"Document"
    "missing-section.md"    <- This file doesn't exist
```

**Solutions:**

1. **Use lenient mode (temporary):**
   ```bash
   hyperprompt root.hc --lenient
   ```

2. **Create the missing file:**
   ```bash
   touch missing-section.md
   ```

3. **Fix the reference:**
   - Update .hc file to reference correct file
   - Check file path is correct
   - Verify file is in correct directory

4. **Use correct root directory:**
   ```bash
   hyperprompt root.hc --root /correct/path
   ```

### Permission Denied

**Error Message:**
```
Error: Permission denied: <filename>
```

**Causes:**
- File not readable by current user
- Output directory not writable
- File locked by another process

**Solutions:**

1. **Check file permissions:**
   ```bash
   ls -la root.hc
   chmod +r root.hc  # Make readable
   ```

2. **Check output directory is writable:**
   ```bash
   ls -la .
   chmod +w .  # Make writable
   ```

3. **Use different output path:**
   ```bash
   hyperprompt root.hc --output /tmp/out.md
   ```

4. **Run with appropriate privileges:**
   ```bash
   sudo hyperprompt root.hc --output /var/docs/out.md
   ```

### Disk Full

**Error Message:**
```
Error: No space left on device
```

**Solutions:**
1. **Free up disk space:**
   ```bash
   df -h  # Check disk usage
   rm -rf ~/Downloads/*  # Free space
   ```

2. **Use different output location:**
   ```bash
   hyperprompt root.hc --output /mnt/external/out.md
   ```

---

## Exit Code 2: Syntax Error

**Meaning:** Invalid Hypercode syntax in source file.

### Unclosed Quote

**Error Message:**
```
Error: Unclosed quote at line <N>
```

**Example File:**
```
"Root Section"
    "Missing closing quote
```

**Solutions:**

1. **Check line for closing quote:**
   ```bash
   sed -n '2p' root.hc  # Show line 2
   ```

2. **Fix the quote:**
   ```
   "Root Section"
       "Missing closing quote"  <- Add closing quote
   ```

3. **Use text editor with bracket matching:**
   - VS Code, Vim, or other editor
   - They highlight matching quotes

### Invalid Indentation

**Error Message:**
```
Error: Invalid indentation at line <N>
```

**Examples:**

**Using tabs (not allowed):**
```
"Root"
→"Child"    <- Tab character (shown as →)
```

**Wrong space count:**
```
"Root"
  "Child"   <- 2 spaces (should be 4)
```

**Inconsistent indentation:**
```
"Root"
    "Child 1"
      "Grandchild"  <- 6 spaces (should be 8)
```

**Solutions:**

1. **Verify no tabs used:**
   ```bash
   cat -A root.hc  # Shows tabs as ^I
   ```

2. **Convert tabs to spaces:**
   ```bash
   # In many editors: Select all, replace tabs with 4 spaces
   # Or use command line:
   expand -t 4 root.hc > root-fixed.hc
   ```

3. **Fix indentation programmatically:**
   ```bash
   # Example: Convert to 4-space indentation
   sed 's/^\t/    /g' root.hc > root-fixed.hc
   ```

4. **Use editor auto-formatting:**
   - VS Code: Format Document (Shift+Alt+F)
   - Vim: `:set expandtab` then `:retab`

### Mixed Tabs and Spaces

**Error Message:**
```
Error: Inconsistent indentation at line <N>
```

**Solutions:**
See "Tab" and "Invalid Indentation" sections above.

### Line Ending Issues

**Error Message:**
```
Error: Invalid line ending at line <N>
```

**Causes:**
- Mixed line endings in file
- Windows line endings in Unix environment or vice versa

**Solutions:**

1. **Check line endings:**
   ```bash
   file root.hc
   # Output: CRLF (DOS)  or  LF (Unix)
   ```

2. **Convert to Unix line endings:**
   ```bash
   dos2unix root.hc  # If available
   # Or:
   sed -i 's/\r$//' root.hc
   ```

3. **Convert to Windows line endings:**
   ```bash
   unix2dos root.hc  # If available
   # Or:
   sed -i 's/$/\r/' root.hc
   ```

---

## Exit Code 3: Resolution Error

**Meaning:** Reference resolution failure — missing files or circular dependencies.

### Missing File Reference (Strict Mode)

**Error Message:**
```
Error: File not found: <filename>
Error: In strict mode, missing file references cause compilation failure
```

**Solutions:**

1. **Use lenient mode (accept missing files as text):**
   ```bash
   hyperprompt root.hc --lenient
   ```

2. **Create the file:**
   ```bash
   touch missing-file.md
   ```

3. **Fix the reference:**
   - Update path in .hc file
   - Use correct relative path
   - Verify file extension

4. **Use correct root directory:**
   ```bash
   hyperprompt root.hc --root /path/containing/files
   ```

### Circular Dependency

**Error Message:**
```
Error: Circular dependency detected
Cycle: <file1> → <file2> → ... → <file1>
```

**Example:**

**a.hc:**
```
"A"
    "b.hc"
```

**b.hc:**
```
"B"
    "a.hc"  <- References back to a.hc
```

**Error output:**
```
Error: Circular dependency detected
Cycle: a.hc → b.hc → a.hc
```

**Solutions:**

1. **Break the cycle:**
   ```
   a.hc: "A" -> "b.hc"
   b.hc: "B" (remove reference to a.hc)
   ```

2. **Use different structure:**
   ```
   main.hc: "Root" -> "a.hc", "b.hc"
   a.hc: "A" (standalone)
   b.hc: "B" (standalone)
   ```

3. **Use shared content file:**
   ```
   main.hc: "Root" -> "shared.hc", "content.hc"
   shared.hc: Common content
   content.hc: Additional content (no back-reference)
   ```

### Path Traversal Blocked

**Error Message:**
```
Error: Path traversal outside root: <path>
```

**Example:**
```
"Doc"
    "../etc/passwd"  <- Tries to go outside root
```

**Solutions:**

1. **Use path within root:**
   ```
   "Doc"
       "docs/file.md"  <- Valid path
   ```

2. **Adjust root directory:**
   ```bash
   hyperprompt root.hc --root /correct/root
   ```

3. **Move file within project:**
   ```bash
   # Instead of: ../../../shared/file.md
   # Use: ./files/shared/file.md
   ```

### Forbidden File Extension

**Error Message:**
```
Error: Forbidden file type: .<ext>
```

**Allowed extensions:** `.md`, `.hc`

**Example:**
```
"Doc"
    "script.js"  <- .js not allowed
```

**Solutions:**

1. **Use allowed extension:**
   - `.md` for Markdown files
   - `.hc` for Hypercode files

2. **Create wrapper file:**
   ```
   script.md: Contains reference to script.js (as text)
   Or: Create script.hc with "script.js" as inline text
   ```

---

## Exit Code 4: Internal Error

**Meaning:** Compiler encountered an unexpected error (bug).

**Error Message:**
```
Error: Internal compiler error: <description>
Stack trace: <backtrace>
```

**When to report:**
- You followed all syntax rules correctly
- Error mentions "internal" or shows stack trace
- Error is reproducible

**How to report:**

1. **Collect information:**
   ```bash
   # Save the problematic file
   cp root.hc root.hc.bak

   # Run with verbose output
   hyperprompt root.hc -v > error.log 2>&1

   # Save output file if it exists
   cp out.md out.md.bak
   ```

2. **Report on GitHub:**
   ```
   Title: Internal compiler error: <error message>
   Description:
   - Steps to reproduce
   - Input file (.hc)
   - Command run
   - Error output
   - Swift version: $(swift --version)
   ```

3. **Include reproduction case:**
   - Minimal .hc file that triggers error
   - Exact command line used
   - Full error message and stack trace

---

## Common Error Combinations

### Scenario: "File not found" but file exists

**Diagnosis:**
```bash
# Check working directory
pwd

# Check file exists
ls root.hc

# Check if path matches
hyperprompt ./root.hc
```

**Solution:**
- Use explicit relative path: `./root.hc`
- Or absolute path: `/full/path/root.hc`

### Scenario: Works locally, fails in CI/CD

**Causes:**
- Different working directory in CI
- Files not checked out
- Path assumptions wrong

**Solutions:**
```bash
# Use absolute paths
hyperprompt /home/ci/project/root.hc --root /home/ci/project

# Or specify all paths explicitly
hyperprompt root.hc --root . --output ./build/out.md
```

### Scenario: "Invalid indentation" but looks correct

**Causes:**
- Tabs mixed with spaces
- Copy/paste from web introduced wrong characters

**Solutions:**
```bash
# Check actual characters
cat -A root.hc  # Shows tabs as ^I

# Rewrite file from scratch in editor
# Or use conversion tools:
expand root.hc > root-fixed.hc
```

---

## Prevention Tips

### Before Running

```bash
# 1. Validate syntax
hyperprompt root.hc --dry-run

# 2. Check with verbose output
hyperprompt root.hc --dry-run --verbose

# 3. Preview manifest
hyperprompt root.hc --manifest /tmp/manifest.json
cat /tmp/manifest.json
```

### In Scripts

```bash
# Check exit code
hyperprompt root.hc
if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

# Or
hyperprompt root.hc || exit 1
```

### In CI/CD

```bash
# Use strict mode and explicit paths
hyperprompt /project/root.hc \
    --root /project \
    --output /build/docs.md \
    --manifest /build/manifest.json \
    --verbose \
    --stats

# Check result
if [ $? -ne 0 ]; then
    echo "Documentation build failed"
    exit 1
fi
```

---

## See Also

- [LANGUAGE.md](LANGUAGE.md) — Syntax rules
- [USAGE.md](USAGE.md) — CLI reference
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — General FAQ

---

**Last Updated:** December 12, 2025

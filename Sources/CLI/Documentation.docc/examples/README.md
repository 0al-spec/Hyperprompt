# Example Files

This directory contains example Hypercode (.hc) files demonstrating various features and usage patterns.

## Files

### hello.hc

The simplest example - a single root node.

```bash
hyperprompt hello.hc --output out.md
```

### nested.hc

Demonstrates hierarchical structure with multiple nesting levels.

```bash
hyperprompt nested.hc
```

### with-markdown.hc

Shows how to reference Markdown files within Hypercode structure.

```bash
# Requires: introduction.md and prerequisites.md to exist
hyperprompt with-markdown.hc
```

### comments.hc

Demonstrates comment syntax (lines starting with #).

```bash
hyperprompt comments.hc
```

## Running Examples

1. Compile an example:
   ```bash
   hyperprompt nested.hc --output example-output.md
   ```

2. View the result:
   ```bash
   cat example-output.md
   ```

3. Use verbose output:
   ```bash
   hyperprompt nested.hc -v
   ```

4. Validate without writing:
   ```bash
   hyperprompt nested.hc --dry-run
   ```

## Creating Your Own

To create a new Hypercode file:

1. Create a .hc file:
   ```bash
   cat > myfile.hc << 'EOF'
   "Root Section"
       "Subsection 1"
       "Subsection 2"
   EOF
   ```

2. Compile it:
   ```bash
   hyperprompt myfile.hc
   ```

3. View output:
   ```bash
   cat out.md
   ```

See [../LANGUAGE.md](../LANGUAGE.md) for complete syntax documentation.

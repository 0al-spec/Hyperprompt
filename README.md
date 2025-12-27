# Hyperprompt Compiler v0.1

A Swift-based compiler for the Hypercode language that transforms nested document structures into Markdown with comprehensive manifest generation and specification-driven validation.

## Features

- **Hierarchical Compilation:** Nested document structures with indentation-based nesting
- **File References:** Include Markdown (.md) and Hypercode (.hc) files inline
- **Recursive Compilation:** .hc files compiled recursively with automatic depth adjustment
- **Circular Dependency Detection:** Prevent infinite loops in nested references
- **Declarative Validation:** Grammar validated via composable specifications (SpecificationCore)
- **Deterministic Output:** Byte-for-byte identical across platforms
- **Strict and Lenient Modes:** Choose between strict error handling and lenient missing-file tolerance
- **Comprehensive Statistics:** Optional compilation metrics and detailed manifest generation

## Quick Start

### Installation

**Prerequisites:** Swift 5.9 or later (recommended: Swift 6.2+)

#### macOS

```bash
git clone https://github.com/0al-spec/Hyperprompt.git
cd Hyperprompt
swift build -c release
./.build/release/hyperprompt --version
```

#### Linux (Ubuntu 20.04+)

```bash
git clone https://github.com/0al-spec/Hyperprompt.git
cd Hyperprompt
swift build -c release
./.build/release/hyperprompt --version
```

**Note:** On Linux, ensure Swift is installed. See [DOCS/RULES/02_Swift_Installation.md](DOCS/RULES/02_Swift_Installation.md) for detailed instructions.

### Your First Compilation

Create a simple Hypercode file:

```bash
# Create a .hc file
cat > hello.hc << 'EOF'
"Hello, Hypercode!"
EOF

# Compile it
./.build/release/hyperprompt hello.hc --output output.md

# View the result
cat output.md
```

Expected output:
```markdown
# Hello, Hypercode!
```

### Common Workflows

#### Single File Compilation
```bash
hyperprompt root.hc --output compiled.md
```

#### Recursive Compilation with References
```bash
hyperprompt root.hc --output out.md --manifest manifest.json
```

#### Lenient Mode (Missing Files Treated as Text)
```bash
hyperprompt root.hc --lenient
```

#### Validation Only (No Output Written)
```bash
hyperprompt root.hc --dry-run
```

#### With Statistics
```bash
hyperprompt root.hc --stats
```

#### Full Diagnostic Output
```bash
hyperprompt root.hc --verbose --stats
```

## Documentation

- **[USAGE.md](Documentation.docc/USAGE.md)** — Complete CLI reference with all flags and options
- **[LANGUAGE.md](Documentation.docc/LANGUAGE.md)** — Hypercode grammar specification and syntax rules
- **[ARCHITECTURE.md](Documentation.docc/ARCHITECTURE.md)** — System design, module overview, data flow
- **[ERROR_CODES.md](Documentation.docc/ERROR_CODES.md)** — Exit codes, error scenarios, and solutions
- **[SPECS_INTEGRATION.md](Documentation.docc/SPECS_INTEGRATION.md)** — SpecificationCore integration patterns
- **[TROUBLESHOOTING.md](Documentation.docc/TROUBLESHOOTING.md)** — Common issues and frequently asked questions
- **[PRD_EditorEngine.md](DOCS/PRD/PRD_EditorEngine.md)** — Future EditorEngine module plan

## Example Files

See `Documentation.docc/examples/` for runnable example .hc files:
- `hello.hc` — Simple root node
- `nested.hc` — Hierarchical structure
- `with-markdown.hc` — Markdown file references
- `with-hypercode.hc` — Hypercode file references
- `comments.hc` — Using comments

## System Requirements

| Component | Requirement |
|-----------|-------------|
| **Swift Version** | 5.9+ (6.0+ recommended) |
| **macOS** | 11.0 or later (x86_64, arm64) |
| **Ubuntu** | 20.04, 22.04, 24.04 LTS |
| **Disk Space** | ~100 MB (build artifacts) |
| **Memory** | 512 MB minimum, 2 GB recommended |

## Building from Source

### Development Build
```bash
swift build
./.build/debug/hyperprompt --help
```

### VS Code Extension (RPC) PATH Setup

The VS Code extension spawns the `hyperprompt` CLI by name and requires the Editor trait build:

```bash
swift build --traits Editor
export PATH="$PWD/.build/debug:$PATH"
hyperprompt editor-rpc
```

Restart VS Code after updating PATH so the Extension Host picks it up.

### Release Build
```bash
swift build -c release
./.build/release/hyperprompt --help
```

### Running Tests
```bash
swift test
```

### Run Tests with Verbose Output
```bash
swift test -v
```

## Project Structure

```
Hyperprompt/
├── Sources/
│   ├── CLI/                    # Command-line interface
│   ├── Core/                   # Core data structures
│   ├── Parser/                 # Hypercode parser
│   ├── Resolver/               # File reference resolver
│   ├── Emitter/                # Markdown emitter
│   ├── Statistics/             # Compilation metrics
│   ├── HypercodeGrammar/        # Grammar specifications
│   └── EditorEngine/            # Future optional editor-facing engine (planned)
├── Tests/                       # Test suites
├── Documentation.docc/examples/ # Example .hc files
├── Documentation.docc/          # User documentation
└── Package.swift                # Swift Package manifest
```

## CLI Usage

### Basic Syntax
```bash
hyperprompt <input-file> [OPTIONS]
```

### Options
| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--output FILE` | `-o` | Output Markdown file | `out.md` |
| `--manifest FILE` | `-m` | Output manifest JSON | `manifest.json` |
| `--root DIR` | `-r` | Root directory for file resolution | `.` |
| `--lenient` | — | Treat missing files as inline text | — |
| `--verbose` | `-v` | Enable verbose logging | — |
| `--stats` | — | Collect compilation statistics | — |
| `--dry-run` | — | Validate without writing output | — |
| `--version` | — | Display version and exit | — |
| `--help` | `-h` | Display help information | — |

**Default Mode:** Strict (missing files cause compilation failure)

### Examples

Display help:
```bash
hyperprompt --help
```

Show version:
```bash
hyperprompt --version
```

Compile with all options:
```bash
hyperprompt root.hc -o output.md -m meta.json -r ./project -v --stats
```

## Error Codes

Exit codes indicate compilation result:

| Code | Meaning | Action |
|------|---------|--------|
| `0` | Success | Compilation completed successfully |
| `1` | IO Error | File not found, permission denied, or disk error |
| `2` | Syntax Error | Invalid Hypercode syntax |
| `3` | Resolution Error | Missing reference or circular dependency |
| `4` | Internal Error | Compiler bug (report to maintainers) |

For detailed solutions, see [ERROR_CODES.md](Documentation.docc/ERROR_CODES.md).

## Language Overview

Hypercode is a simple, indentation-based language for defining hierarchical document structures.

### Basic Syntax

**Inline text:**
```
"Hello, World!"
```

**Hierarchical nesting:**
```
"Root Section"
    "Subsection 1"
    "Subsection 2"
        "Nested item"
```

**File references:**
```
"Main Document"
    "details.md"
    "nested-structure.hc"
```

For complete syntax specification, see [LANGUAGE.md](Documentation.docc/LANGUAGE.md).

## Integration

### SpecificationCore Integration

Hyperprompt uses [SpecificationCore](https://github.com/0al-spec/SpecificationCore) for:
- Lexical validation (indentation, quotes, escapes)
- Path classification and validation (traversal checks, boundary enforcement)
- Decision-based routing (file type detection, resolution strategy)

See [SPECS_INTEGRATION.md](Documentation.docc/SPECS_INTEGRATION.md) for implementation details.

### Manifest Format

The generated `manifest.json` contains:
- List of all referenced files
- Compilation statistics (lines, nodes, depth)
- Dependency graph for circular reference detection
- Version and metadata

## Troubleshooting

### Common Issues

**"Input file not found: file.hc"**
- Verify file exists: `ls -la file.hc`
- Check working directory: `pwd`
- Use absolute path if needed

**"Invalid indentation"**
- Indentation must use spaces (4 spaces per level)
- No tabs allowed. Check: `cat -A file.hc` (no `^I`)
- Mixed spaces and tabs may cause errors

**"Missing file reference in strict mode"**
- Use `--lenient` flag to treat missing files as text
- Or verify referenced file exists and is readable

For more help, see [TROUBLESHOOTING.md](Documentation.docc/TROUBLESHOOTING.md).

## Development

### Running Tests
```bash
swift test
```

### Viewing Test Coverage
```bash
swift test --enable-code-coverage
```

### Building Documentation
```bash
swift build -c debug
# Generated docs in .build/release/documentation/
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass: `swift test`
5. Submit a pull request

For detailed contribution guidelines, see [Documentation.docc/FUTURE.md](Documentation.docc/FUTURE.md).

## License

MIT License — See LICENSE file for details.

## Support

- **Issues:** [Report bugs on GitHub](https://github.com/0al-spec/Hyperprompt/issues)
- **Documentation:** See `Documentation.docc/` directory
- **Examples:** See `Documentation.docc/examples/` directory

## Version History

| Version | Date | Status | Notes |
|---------|------|--------|-------|
| 0.1.0 | 2025-12-12 | Current | Initial release with core features |

---

**Last Updated:** December 12, 2025

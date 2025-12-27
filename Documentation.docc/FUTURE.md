# Future Roadmap (v0.2 and Beyond)

Vision for Hyperprompt's evolution beyond v0.1.

## Table of Contents

1. [Versioning Strategy](#versioning-strategy)
2. [v0.2 Planned Features](#v02-planned-features)
3. [v0.3+ Vision](#v03-vision)
4. [Community Contributions](#community-contributions)
5. [Feature Request Process](#feature-request-process)

---

## Versioning Strategy

**Version Format:** `MAJOR.MINOR.PATCH`

- **MAJOR (0):** Breaking changes, API rewrites (Hyperprompt is still pre-1.0)
- **MINOR (1+):** New features, backwards-compatible
- **PATCH (0+):** Bug fixes only

**Release Cycle:**
- v0.1: Initial release (December 2025)
- v0.2: 2026 Q1 (Performance, new formats)
- v0.3: 2026 Q2 (Extended language features)
- v1.0: 2026 Q4 (Stable API, production-ready)

---

## v0.2 Planned Features

### Phase 1: Performance (2026 Q1)

#### 1.1 AST Caching

**Goal:** Cache parsed Hypercode files to avoid re-parsing

**Implementation:**
- In-memory cache of parsed ASTs
- Cache invalidation on file modification
- Optional persistent cache

**Benefit:**
- Incremental compilation (5-10x faster)
- Watch mode support

**CLI:**
```bash
hyperprompt root.hc --use-cache              # Enable caching
hyperprompt root.hc --clear-cache            # Clear cache
hyperprompt root.hc --cache-dir /tmp/cache   # Custom location
```

#### 1.2 Parallel Processing

**Goal:** Compile multiple files concurrently

**Implementation:**
- Parallel file I/O
- Concurrent AST parsing
- Thread-safe dependency tracking

**Benefit:**
- 2-4x speedup on multi-core systems
- Automatic core detection

**CLI:**
```bash
hyperprompt root.hc --num-workers 4   # Use 4 cores
hyperprompt root.hc --parallel        # Auto-detect
```

#### 1.3 Lazy Evaluation

**Goal:** Defer processing of non-critical content

**Implementation:**
- Lazy file reading (only process when needed)
- Optional content (headers, metadata)
- Streaming output

**Benefit:**
- Process very large documents
- Lower memory footprint

### Phase 2: Output Formats (2026 Q1)

#### 2.1 HTML Output

**Goal:** Generate HTML from Hypercode

**Implementation:**
- HTML emitter module
- CSS styling options
- Table of contents generation

**CLI:**
```bash
hyperprompt root.hc --format html --output out.html
hyperprompt root.hc --format html --theme dark
```

**Output Features:**
- Responsive design
- Dark/light theme
- Syntax highlighting for code blocks
- Automatic TOC generation

#### 2.2 PDF Output (via Pandoc)

**Goal:** Generate PDF documents

**Implementation:**
- Integration with Pandoc
- Markdown → PDF pipeline
- Customizable templates

**CLI:**
```bash
hyperprompt root.hc --format pdf --output out.pdf
```

**Requirements:**
- Pandoc installed (`brew install pandoc` or `apt install pandoc`)
- Optional: pdflatex for advanced formatting

#### 2.3 DOCX Output (Word)

**Goal:** Generate Microsoft Word documents

**Implementation:**
- DOCX emitter (using `python-docx` or similar)
- Formatting preservation
- Hyperlinks and bookmarks

**CLI:**
```bash
hyperprompt root.hc --format docx --output out.docx
```

### Phase 3: Extended Language Features (2026 Q1-Q2)

#### 3.1 Variables and Substitution

**Goal:** Allow dynamic content replacement

**Syntax:**
```
"Document Title: {{project_name}}"
    "{{intro_file}}"
```

**CLI:**
```bash
hyperprompt root.hc --var project_name="MyProject" --var intro_file="intro.md"
```

**JSON configuration:**
```json
{
  "variables": {
    "project_name": "MyProject",
    "intro_file": "intro.md"
  }
}
```

#### 3.2 Conditionals

**Goal:** Include/exclude content based on conditions

**Syntax:**
```
"Introduction"
    ? isDev
        "Developer Notes"
            "dev/notes.md"
```

**CLI:**
```bash
hyperprompt root.hc --flag isDev
hyperprompt root.hc --flag isProd
```

#### 3.3 Loops/Repetition

**Goal:** Generate content from lists

**Syntax:**
```
"Chapters"
    * for chapter in chapters
        "{{chapter}}/main.hc"
```

**Configuration:**
```json
{
  "chapters": ["ch1", "ch2", "ch3"]
}
```

#### 3.4 Inline Code/Literals

**Goal:** Include code blocks and raw content

**Syntax:**
```
"Code Example"
    !code python
        def hello():
            print("world")
```

---

## v0.3+ Vision

### Advanced Features (2026 Q2+)

#### 1. Template System

```
# Use templates
hyperprompt root.hc --template standard
hyperprompt root.hc --template book
hyperprompt root.hc --template api
```

**Built-in templates:**
- `standard` — Basic document
- `book` — Multi-chapter book format
- `api` — API documentation
- `wiki` — Wiki-style documentation

#### 2. Plugins/Extensions

Allow custom validators and emitters:

```swift
protocol CustomSpecification {
    func isSatisfiedBy(_ value: String) -> Bool
}

protocol CustomEmitter {
    func emit(_ ast: AST) -> String
}
```

#### 3. Language Server Protocol (LSP)

IDE support with:
- Syntax highlighting
- Error reporting
- Autocomplete
- Go-to-definition

**Editor Integration:**
- VS Code extension
- Vim/Neovim plugin
- Emacs mode
- Sublime Text plugin

#### 4. Web-based Editor

- Browser-based IDE
- Real-time preview
- Collaborative editing (future)

### Platform Support

- **Current:** macOS, Linux
- **v0.2:** Windows (tested)
- **v0.3:** Linux ARM64, macOS ARM64 (M-series)

---

## Community Contributions

### How to Contribute

#### 1. Code Contributions

**Process:**
1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Write tests for new functionality
4. Ensure all tests pass: `swift test`
5. Submit pull request with description

**Code Style:**
- Follow Swift naming conventions (camelCase for functions)
- Add doc comments for public APIs
- Maximum 100 lines per function
- Use specifications where possible (not imperative)

#### 2. Documentation Contributions

- Fix typos, clarify instructions
- Add examples to Documentation.docc/
- Improve error messages
- Translate documentation

**Process:**
1. Edit relevant `.md` file
2. Test links and code examples
3. Submit pull request

#### 3. Example Contributions

Share `.hc` file examples:

```bash
# Create example in Documentation.docc/examples/
echo '"Example Documentation"' > Documentation.docc/examples/my-example.hc

# Document it
echo "## My Example\nDescription of what this example does" > Documentation.docc/examples/my-example.md
```

### Areas Needing Help

1. **Testing:** Expand test coverage, find edge cases
2. **Documentation:** Clarify existing docs, add examples
3. **Specification Improvements:** New grammar rules, security specs
4. **Bug Reports:** Report issues with detailed reproduction steps
5. **Performance:** Profile and optimize hot paths
6. **Packaging:** Create installers, package managers

---

## Feature Request Process

### Requesting a Feature

1. **Check existing issues:** Don't duplicate requests

2. **Create GitHub issue with:**
   - **Title:** Clear, descriptive
   - **Description:** What problem does this solve?
   - **Use case:** When would someone use this?
   - **Example:** Show desired usage

3. **Label:** Add `feature-request` label

**Example Issue:**
```
Title: Add YAML output format support

Description:
Compile Hypercode to YAML for configuration files.

Use Case:
I need to generate YAML configuration from templates.

Example:
hyperprompt config.hc --format yaml --output config.yaml
```

### Feature Evaluation Criteria

Features prioritized based on:

1. **Demand:** How many users need it?
2. **Complexity:** How much effort to implement?
3. **Maintenance:** Ongoing support burden?
4. **Scope Creep:** Does it align with project vision?
5. **Dependencies:** External tools required?

---

## Breaking Changes (Future Versions)

### Planned for v1.0

1. **Stricter Syntax Rules**
   - Currently lenient on some edge cases
   - v1.0 will enforce spec strictly

2. **CLI Changes**
   - `--mode` might replace `--strict`/`--lenient`
   - Consider `--config-file` support

3. **Manifest Format**
   - May add version field
   - Structure may change for better tooling

### Deprecation Policy

- New versions will support previous APIs for at least 1 minor version
- Deprecation warnings added 1 version before removal
- Clear migration guides provided

---

## Performance Goals

### v0.2 Targets

| Metric | Current | Target |
|--------|---------|--------|
| Parse time (100 lines) | 5ms | 1ms |
| File resolution | 10ms per file | 2ms per file |
| Emitter output | 2ms | 1ms |
| **Total (100 lines)** | **~20ms** | **~5ms** |

### Optimization Strategies

1. **Lazy loading:** Parse only needed sections
2. **Streaming:** Output as you generate
3. **Caching:** Avoid re-parsing
4. **Parallel:** Use all CPU cores

---

## Backwards Compatibility

**Policy:** Semantic versioning maintained

- **v0.x:** May have breaking changes (pre-release)
- **v1.x:** Stable API, backwards-compatible
- **v2.x:** Only if fundamentally rethinking approach

---

## Getting Involved

### Join the Community

- **GitHub Issues:** Ask questions, report bugs
- **Discussions:** Feature ideas, design reviews
- **Pull Requests:** Submit code contributions

### Development Setup

```bash
# Clone and setup
git clone https://github.com/0al-spec/Hyperprompt.git
cd Hyperprompt

# Build and test
swift build
swift test

# Run in development
./.build/debug/hyperprompt Documentation.docc/examples/hello.hc
```

### Development Roadmap

Track current work:
- Check [GitHub Project Board](https://github.com/0al-spec/Hyperprompt/projects)
- See [Issues with "Help Wanted" label](https://github.com/0al-spec/Hyperprompt/issues?q=label%3A%22help+wanted%22)

---

## Long-term Vision (2027+)

### Beyond v1.0

1. **Ecosystem:**
   - Package manager for templates
   - Community spec library
   - Plugin marketplace

2. **Integration:**
   - Git hooks for automated docs
   - CI/CD pipeline support
   - IDE integration

3. **Optimization:**
   - Incremental compilation
   - Distributed builds
   - GPU acceleration (research)

4. **AI Integration (Experimental):**
   - Auto-generate documentation
   - Content summarization
   - Smart linking

---

## Success Metrics

By v1.0, Hyperprompt will be considered successful if:

- ✓ 1000+ GitHub stars
- ✓ 500+ users reported
- ✓ 50+ community contributions
- ✓ 5+ third-party integrations
- ✓ Sub-1ms parse time for typical files
- ✓ 100% test coverage for core modules

---

## Questions & Feedback

- **Feature ideas:** Create GitHub issue with `feature-request` label
- **Design discussions:** Start GitHub Discussion
- **Bug reports:** Open issue with reproduction steps
- **General questions:** Check Discussions or ask in issue comments

---

**Last Updated:** December 12, 2025

**Current Version:** v0.1.0 (Released 2025-12-12)

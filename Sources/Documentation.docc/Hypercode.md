# ``Hypercode``

Deterministic, documentation-driven language for composing structured prompts with explicit link resolution and reproducible outputs.

## Overview

Hypercode is the source format compiled by Hyperprompt. It provides a strict, indentation-based structure, explicit linking rules, and deterministic output generation so that documentation pipelines stay predictable and verifiable.

### Key Features

- **📐 Deterministic Structure**: Indentation defines hierarchy with strict depth rules
- **🔗 Explicit Linking**: Links resolve to `.hc` and `.md` files with clear diagnostics
- **🧭 Predictable Output**: Compile results are deterministic across runs
- **🧪 Validation-Friendly**: Built-in diagnostics map cleanly to editor and CI workflows
- **📚 Documentation-First**: Designed for documentation-driven development flows

## Quick Start

### Minimal Hypercode File
```hc
# Project Documentation
  Intro
  @"getting-started.md"
  @"guide.hc"
```

### Include Markdown
```hc
# Installation Guide
  @"prerequisites.md"
  Setup Steps
```

### Nesting Example
```hc
# Root
  Section A
    Detail A1
  Section B
    Detail B1
```

## Tutorials

Start with the core language concepts and build toward full compiler usage:

- <doc:LANGUAGE> - Learn the syntax, indentation rules, and node structure
- <doc:USAGE> - See how Hypercode compiles into Markdown and manifests

## Getting Started

### Create Your First File

1. Create a file like `hello.hc`
2. Add a root heading and a few child nodes
3. Compile with Hyperprompt to generate Markdown

```hc
# Hello
  World
```

### Compile with Hyperprompt

```bash
hyperprompt hello.hc
```

The compiler outputs Markdown and a manifest file in the output folder (unless disabled).

## Topics

### Language Specification

- <doc:LANGUAGE>
- <doc:ERROR_CODES>

### Compilation & Output

- <doc:USAGE>
- <doc:RPC_PROTOCOL>

### Architecture

- <doc:ARCHITECTURE>
- <doc:SPECS_INTEGRATION>

### Examples

- <doc:examples/README>
- <doc:examples/hello>
- <doc:examples/with-markdown>

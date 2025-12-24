# SpecificationCore Integration

How Hyperprompt uses SpecificationCore for declarative, specification-driven validation.

## Table of Contents

1. [Overview](#overview)
2. [Integrated Specifications](#integrated-specifications)
3. [Usage Examples](#usage-examples)
4. [Benefits](#benefits)
5. [Extending with Custom Specs](#extending-with-custom-specs)

---

## Overview

Hyperprompt uses [SpecificationCore](https://github.com/0al-spec/SpecificationCore), a Swift library for composable validation rules, instead of imperative conditional logic.

### Core Concept

**Traditional (Imperative):**
```swift
func validatePath(_ path: String) -> Bool {
    if path.contains("..") {
        return false
    }
    if !path.contains("/") && !path.contains(".") {
        return false
    }
    // More conditions...
}
```

**Specification-Driven (Declarative):**
```swift
if NoTraversalSpec().isSatisfiedBy(path) &&
   LooksLikeFileReferenceSpec().isSatisfiedBy(path) {
    return true
}
```

**Advantages:**
- Self-documenting: Spec name explains intent
- Reusable: Same spec in multiple contexts
- Testable: Each spec independently tested
- Composable: Combine specs with boolean logic
- Maintainable: Business rules isolated

---

## Integrated Specifications

Hyperprompt integrates 5 key SpecificationCore specifications:

### 1. LooksLikeFileReferenceSpec

**Purpose:** Heuristically detect if a string is likely a file reference

**Implementation:**
```swift
struct LooksLikeFileReferenceSpec: Specification {
    func isSatisfiedBy(_ candidate: String) -> Bool {
        // Returns true if contains "/" or "."
        candidate.contains("/") || candidate.contains(".")
    }
}
```

**Used in:** `ReferenceResolver.looksLikeFilePath(_:)`

**Examples:**
```swift
LooksLikeFileReferenceSpec().isSatisfiedBy("README.md")     // true
LooksLikeFileReferenceSpec().isSatisfiedBy("docs/intro.md") // true
LooksLikeFileReferenceSpec().isSatisfiedBy("Hello World")   // false
```

**Logic:**
- Contains `/` → likely file path
- Contains `.` → likely filename with extension
- Neither → inline text

---

### 2. HasMarkdownExtensionSpec

**Purpose:** Detect Markdown files by `.md` extension

**Implementation:**
```swift
struct HasMarkdownExtensionSpec: Specification {
    func isSatisfiedBy(_ candidate: String) -> Bool {
        candidate.lowercased().hasSuffix(".md")
    }
}
```

**Used in:** `ReferenceResolver.resolve(_:node:)` for file type routing

**Examples:**
```swift
HasMarkdownExtensionSpec().isSatisfiedBy("README.md")      // true
HasMarkdownExtensionSpec().isSatisfiedBy("docs/file.MD")   // true (case-insensitive)
HasMarkdownExtensionSpec().isSatisfiedBy("document.hc")    // false
HasMarkdownExtensionSpec().isSatisfiedBy("readme.txt")     // false
```

**Decision Flow:**
```
File: "intro.md"
  ├─ HasMarkdownExtensionSpec() → true
  │  └─ → resolveMarkdown()
  └─ Process as Markdown file
```

---

### 3. HasHypercodeExtensionSpec

**Purpose:** Detect Hypercode files by `.hc` extension

**Implementation:**
```swift
struct HasHypercodeExtensionSpec: Specification {
    func isSatisfiedBy(_ candidate: String) -> Bool {
        candidate.lowercased().hasSuffix(".hc")
    }
}
```

**Used in:** `ReferenceResolver.resolve(_:node:)` for file type routing

**Examples:**
```swift
HasHypercodeExtensionSpec().isSatisfiedBy("main.hc")       // true
HasHypercodeExtensionSpec().isSatisfiedBy("nested.HC")     // true
HasHypercodeExtensionSpec().isSatisfiedBy("document.md")   // false
HasHypercodeExtensionSpec().isSatisfiedBy("file.txt")      // false
```

**Decision Flow:**
```
File: "chapter1.hc"
  ├─ HasMarkdownExtensionSpec() → false
  ├─ HasHypercodeExtensionSpec() → true
  │  └─ → resolveHypercode() (recursive parsing)
  └─ Process as Hypercode file
```

---

### 4. NoTraversalSpec

**Purpose:** Prevent path traversal attacks using `..`

**Implementation:**
```swift
struct NoTraversalSpec: Specification {
    func isSatisfiedBy(_ candidate: String) -> Bool {
        let components = candidate.split(separator: "/").map(String.init)
        return !components.contains("..")
    }
}
```

**Used in:** `ReferenceResolver.containsPathTraversal(_:)`

**Examples:**
```swift
NoTraversalSpec().isSatisfiedBy("docs/file.md")           // true
NoTraversalSpec().isSatisfiedBy("nested/path/to/file.md") // true
NoTraversalSpec().isSatisfiedBy("../etc/passwd")          // false
NoTraversalSpec().isSatisfiedBy("docs/../../secret.md")   // false
NoTraversalSpec().isSatisfiedBy("file.md")                // true (no /)
```

**Security Boundary:**
```
Input:  "../../sensitive/file.md"
         │
         ├─ NoTraversalSpec.isSatisfiedBy() → false
         └─ Compilation error: "Path traversal detected"

Output: 0 (success) or 3 (error)
```

---

### 5. WithinRootSpec

**Purpose:** Enforce file resolution stays within specified root directory

**Implementation:**
```swift
struct WithinRootSpec: Specification {
    let rootPath: String

    func isSatisfiedBy(_ candidate: String) -> Bool {
        let resolved = resolvePath(candidate, relativeTo: rootPath)
        return resolved.hasPrefix(rootPath)
    }
}
```

**Used in:** `ReferenceResolver.validateWithinRoot(_:)`

**Examples:**
```swift
let spec = WithinRootSpec(rootPath: "/home/user/project")

spec.isSatisfiedBy("/home/user/project/docs/file.md")      // true
spec.isSatisfiedBy("/home/user/project/../docs/file.md")   // depends on resolution
spec.isSatisfiedBy("/etc/passwd")                          // false
spec.isSatisfiedBy("/var/data")                            // false
```

**Usage in CLI:**
```bash
# Root directory boundary
hyperprompt root.hc --root /home/user/docs

# All references must resolve within /home/user/docs
# Prevents: ../../../etc/passwd or /tmp/external.md
```

**Security Boundary:**
```
--root /home/user/project
    │
    └─ WithinRootSpec(rootPath: "/home/user/project")
       ├─ "docs/file.md" → /home/user/project/docs/file.md ✓
       ├─ "../etc/passwd" → /home/user/etc/passwd ✗
       └─ "/tmp/file.md" → /tmp/file.md ✗
```

---

## Usage Examples

### Example 1: Extension Routing

**Code in ReferenceResolver:**
```swift
func resolve(_ node: Node) throws -> ResolutionResult {
    guard LooksLikeFileReferenceSpec().isSatisfiedBy(node.literal) else {
        return .success(.inlineText(node.literal))
    }

    if HasMarkdownExtensionSpec().isSatisfiedBy(node.literal) {
        return try resolveMarkdown(node.literal, node: node)
    } else if HasHypercodeExtensionSpec().isSatisfiedBy(node.literal) {
        return try resolveHypercode(node.literal, node: node)
    } else {
        throw ResolutionError.forbiddenExtension(fileExtension(node.literal))
    }
}
```

**Execution Flow:**
```
resolve("docs/intro.md")
    ├─ LooksLikeFileReferenceSpec().isSatisfiedBy()   → true
    ├─ HasMarkdownExtensionSpec().isSatisfiedBy()     → true
    └─ → resolveMarkdown()

resolve("Hello World")
    ├─ LooksLikeFileReferenceSpec().isSatisfiedBy()   → false
    └─ → return .inlineText()

resolve("script.js")
    ├─ LooksLikeFileReferenceSpec().isSatisfiedBy()   → true
    ├─ HasMarkdownExtensionSpec().isSatisfiedBy()     → false
    ├─ HasHypercodeExtensionSpec().isSatisfiedBy()    → false
    └─ → throw forbiddenExtension
```

### Example 2: Path Validation

**Code in ReferenceResolver:**
```swift
func validateWithinRoot(_ path: String, rootPath: String) throws -> Result<Void, Error> {
    if containsPathTraversal(path) {
        throw ResolutionError.pathTraversal(path)
    }

    let spec = WithinRootSpec(rootPath: rootPath)
    if !spec.isSatisfiedBy(resolvePath(path, relativeTo: rootPath)) {
        throw ResolutionError.outsideRoot(path, rootPath)
    }

    return .success(())
}

private func containsPathTraversal(_ path: String) -> Bool {
    !NoTraversalSpec().isSatisfiedBy(path)
}
```

**Security Scenario:**
```
Input:  "../../etc/passwd"
        │
        ├─ containsPathTraversal()     → true
        ├─ throw pathTraversal error
        └─ Exit code: 3 (Resolution Error)

Input:  "docs/file.md" (with --root /home/user/project)
        │
        ├─ containsPathTraversal()     → false
        ├─ WithinRootSpec.isSatisfiedBy() → true
        └─ → Continue processing ✓
```

### Example 3: Composition

Combine multiple specs for complex validation:

```swift
func isValidReference(_ literal: String, rootPath: String) -> Bool {
    let looksLikeFile = LooksLikeFileReferenceSpec().isSatisfiedBy(literal)
    let noTraversal = NoTraversalSpec().isSatisfiedBy(literal)
    let withinRoot = WithinRootSpec(rootPath: rootPath).isSatisfiedBy(literal)

    return looksLikeFile && noTraversal && withinRoot
}

// Usage
if isValidReference(reference, rootPath: rootDirectory) {
    // Safe to process
}
```

---

## Benefits

### 1. Clarity

Specification names are self-documenting:

**Imperative:**
```swift
if !path.contains("..") &&
   (path.contains("/") || path.contains(".")) &&
   path.hasPrefix(root) {
    // What is this checking?
}
```

**Declarative:**
```swift
if NoTraversalSpec().isSatisfiedBy(path) &&
   LooksLikeFileReferenceSpec().isSatisfiedBy(path) &&
   WithinRootSpec(rootPath: root).isSatisfiedBy(path) {
    // Clear: Check for no traversal, file reference pattern, and root boundary
}
```

### 2. Reusability

Same spec used in multiple places:

```swift
// In Resolver
NoTraversalSpec().isSatisfiedBy(path)

// In Parser validation
NoTraversalSpec().isSatisfiedBy(parsedPath)

// In Security checks
NoTraversalSpec().isSatisfiedBy(userInput)
```

### 3. Testability

Each spec independently testable:

```swift
func testNoTraversalSpec() {
    let spec = NoTraversalSpec()

    XCTAssertTrue(spec.isSatisfiedBy("docs/file.md"))
    XCTAssertFalse(spec.isSatisfiedBy("../file.md"))
    XCTAssertFalse(spec.isSatisfiedBy("docs/../../file.md"))
}
```

### 4. Maintainability

Business logic isolated and explicit:

```swift
// All path validation rules in one place
struct WithinRootSpec { /* ... */ }
struct NoTraversalSpec { /* ... */ }
struct LooksLikeFileReferenceSpec { /* ... */ }
```

---

## Extending with Custom Specs

### Creating a New Specification

Example: Require Markdown files in specific directory

```swift
struct InDocsDirSpec: Specification {
    func isSatisfiedBy(_ path: String) -> Bool {
        path.hasPrefix("docs/")
    }
}

// Usage
if InDocsDirSpec().isSatisfiedBy(reference) {
    // File is in docs/ directory
}
```

### Composite Specifications

Combine existing specs into new rules:

```swift
struct SafeMarkdownReferenceSpec: Specification {
    let rootPath: String

    func isSatisfiedBy(_ candidate: String) -> Bool {
        HasMarkdownExtensionSpec().isSatisfiedBy(candidate) &&
        NoTraversalSpec().isSatisfiedBy(candidate) &&
        WithinRootSpec(rootPath: rootPath).isSatisfiedBy(candidate)
    }
}

// Usage
let validRef = SafeMarkdownReferenceSpec(rootPath: "/project").isSatisfiedBy(ref)
```

### Adding to Integration

1. **Define specification:**
   ```swift
   struct MyCustomSpec: Specification {
       func isSatisfiedBy(_ candidate: String) -> Bool {
           // Validation logic
       }
   }
   ```

2. **Use in resolver or parser:**
   ```swift
   if MyCustomSpec().isSatisfiedBy(value) {
       // Process accordingly
   }
   ```

3. **Write tests:**
   ```swift
   func testMyCustomSpec() {
       let spec = MyCustomSpec()
       XCTAssertTrue(spec.isSatisfiedBy("valid input"))
       XCTAssertFalse(spec.isSatisfiedBy("invalid input"))
   }
   ```

---

## Architecture Integration

### Specification Usage Flow

```
┌─────────────────────────────────────┐
│ Input: String (path or content)     │
└────────────┬────────────────────────┘
             │
    ┌────────▼─────────────────────────┐
    │ Apply Specifications             │
    │ ├─ LooksLikeFileReferenceSpec    │
    │ ├─ HasMarkdownExtensionSpec      │
    │ ├─ HasHypercodeExtensionSpec     │
    │ ├─ NoTraversalSpec               │
    │ └─ WithinRootSpec                │
    └────────┬─────────────────────────┘
             │
    ┌────────▼─────────────────────────┐
    │ Decision Logic                   │
    │ if spec1 && spec2 && spec3 { }   │
    └────────┬─────────────────────────┘
             │
    ┌────────▼─────────────────────────┐
    │ Action (Resolve/Skip/Error)      │
    └─────────────────────────────────┘
```

### Integration Points

1. **Parser:** Syntax validation specs
2. **Resolver:** Path and file type specs
3. **Emitter:** Content escaping specs
4. **CLI:** Argument specs (planned)

---

## Best Practices

1. **Use spec names that self-document intent**
   - ✓ `NoTraversalSpec` (clear)
   - ✗ `PathValidationSpec` (vague)

2. **Combine specs with clear boolean logic**
   ```swift
   if spec1.isSatisfiedBy(candidate) &&
      spec2.isSatisfiedBy(candidate) {
       // Both conditions met
   }
   ```

3. **Test specifications independently**
   - One test per specification
   - Cover true and false cases

4. **Document specification purpose**
   ```swift
   /// Ensures path does not contain ".." components for security
   struct NoTraversalSpec: Specification { ... }
   ```

---

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) — System design
- [SpecificationCore](https://github.com/0al-spec/SpecificationCore) — Library documentation
- [LANGUAGE.md](LANGUAGE.md) — Grammar rules

---

**Last Updated:** December 12, 2025

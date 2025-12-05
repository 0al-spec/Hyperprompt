/// Core module providing foundational types for the Hyperprompt Compiler.
///
/// This module defines the essential infrastructure used throughout the compiler:
///
/// ## Source Location Tracking
/// - **SourceLocation**: Track precise source file positions for error reporting
///
/// ## Error Handling
/// - **CompilerError**: Protocol for all compiler errors with diagnostic information
/// - **ErrorCategory**: Classification of error types (IO, Syntax, Resolution, Internal)
///
/// ## File System Abstraction
/// - **FileSystem**: Abstract interface for file operations
/// - **LocalFileSystem**: Production implementation using Foundation APIs
///
/// ## Testing Support
/// - **MockFileSystem**: In-memory file system for unit tests (in Tests/CoreTests)
///
/// All compiler modules depend on Core for:
/// - Consistent error handling and reporting
/// - Source location tracking in diagnostics
/// - Testable file I/O through FileSystem protocol
///
/// ## Usage Example
///
/// ```swift
/// import Core
///
/// // Error handling
/// struct MyError: CompilerError {
///     let category: ErrorCategory = .syntax
///     let message: String
///     let location: SourceLocation?
/// }
///
/// // File system operations
/// let fs: FileSystem = LocalFileSystem()
/// let content = try fs.readFile(at: "input.hc")
/// ```
///
/// ## Design Principles
///
/// 1. **Protocol-based**: FileSystem protocol enables dependency injection
/// 2. **Type-safe**: Strong typing prevents category/exit code mismatches
/// 3. **Cross-platform**: Works on macOS, Linux, and Windows
/// 4. **Testable**: Mock implementations for all abstractions
public struct Core {
    // This file exists solely for documentation purposes.
    // The actual types are defined in separate files.
}

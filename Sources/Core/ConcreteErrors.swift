// ConcreteErrors.swift
// Core module
//
// Concrete implementations of CompilerError for different error categories.
// Provides convenient static methods for creating compiler errors.

import Foundation

/// Concrete implementation of CompilerError.
public struct ConcreteCompilerError: CompilerError {
    public let category: ErrorCategory
    public let message: String
    public let location: SourceLocation?

    public init(category: ErrorCategory, message: String, location: SourceLocation?) {
        self.category = category
        self.message = message
        self.location = location
    }
}

// MARK: - Convenience Constructors

extension CompilerError where Self == ConcreteCompilerError {
    /// Create an IO error (exit code 1).
    ///
    /// - Parameters:
    ///   - message: Description of the I/O error
    ///   - location: Optional source location
    /// - Returns: CompilerError with IO category
    public static func ioError(message: String, location: SourceLocation?) -> ConcreteCompilerError {
        ConcreteCompilerError(category: .io, message: message, location: location)
    }

    /// Create a Syntax error (exit code 2).
    ///
    /// - Parameters:
    ///   - message: Description of the syntax error
    ///   - location: Source location where error occurred
    /// - Returns: CompilerError with Syntax category
    public static func syntaxError(message: String, location: SourceLocation?) -> ConcreteCompilerError {
        ConcreteCompilerError(category: .syntax, message: message, location: location)
    }

    /// Create a Resolution error (exit code 3).
    ///
    /// - Parameters:
    ///   - message: Description of the resolution error
    ///   - location: Source location where error occurred
    /// - Returns: CompilerError with Resolution category
    public static func resolutionError(message: String, location: SourceLocation?) -> ConcreteCompilerError {
        ConcreteCompilerError(category: .resolution, message: message, location: location)
    }

    /// Create an Internal error (exit code 4).
    ///
    /// - Parameters:
    ///   - message: Description of the internal error
    ///   - location: Optional source location
    /// - Returns: CompilerError with Internal category
    public static func internalError(message: String, location: SourceLocation?) -> ConcreteCompilerError {
        ConcreteCompilerError(category: .internal, message: message, location: location)
    }
}

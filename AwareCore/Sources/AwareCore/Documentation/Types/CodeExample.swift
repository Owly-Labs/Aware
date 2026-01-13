//
//  CodeExample.swift
//  AwareCore
//
//  Supporting types for documentation metadata.
//

import Foundation

// MARK: - Code Example

/// Example code snippet with description
public struct CodeExample: Codable, Sendable, Hashable {
    public let code: String
    public let description: String
    public let platform: Platform?

    public init(code: String, description: String, platform: Platform? = nil) {
        self.code = code
        self.description = description
        self.platform = platform
    }
}

// MARK: - Parameter Metadata

/// Documentation for a function/modifier parameter
public struct ParameterMetadata: Codable, Sendable, Hashable {
    public let name: String
    public let type: String
    public let required: Bool
    public let defaultValue: String?
    public let description: String

    public init(name: String, type: String, required: Bool, defaultValue: String? = nil, description: String) {
        self.name = name
        self.type = type
        self.required = required
        self.defaultValue = defaultValue
        self.description = description
    }

    /// Compact representation for token efficiency
    /// Example: "id:String", "label:String?=nil"
    public var compactSignature: String {
        var sig = "\(name):\(type)"
        if let defaultVal = defaultValue {
            sig += "=\(defaultVal)"
        }
        return sig
    }
}

// MARK: - Property Metadata

/// Documentation for a struct/class property
public struct PropertyMetadata: Codable, Sendable, Hashable {
    public let name: String
    public let type: String
    public let description: String
    public let isOptional: Bool
    public let defaultValue: String?

    public init(name: String, type: String, description: String, isOptional: Bool = false, defaultValue: String? = nil) {
        self.name = name
        self.type = type
        self.description = description
        self.isOptional = isOptional
        self.defaultValue = defaultValue
    }
}

// MARK: - Enum Case Metadata

/// Documentation for an enum case
public struct EnumCaseMetadata: Codable, Sendable, Hashable {
    public let name: String
    public let value: String?
    public let description: String
    public let associatedValues: [ParameterMetadata]?

    public init(name: String, value: String? = nil, description: String, associatedValues: [ParameterMetadata]? = nil) {
        self.name = name
        self.value = value
        self.description = description
        self.associatedValues = associatedValues
    }
}

// MARK: - Platform

/// Platform availability
public enum Platform: String, Codable, Sendable, CaseIterable {
    case iOS = "iOS"
    case macOS = "macOS"
    case web = "web"
    case backend = "backend"
    case all = "all"

    public var displayName: String {
        switch self {
        case .iOS: return "iOS"
        case .macOS: return "macOS"
        case .web: return "Web"
        case .backend: return "Backend"
        case .all: return "All Platforms"
        }
    }
}

// MARK: - Documentation Scope

/// Scope for documentation export
public enum DocumentationScope: String, Codable, Sendable {
    case modifiers      // Only modifiers
    case types          // Only types
    case methods        // Only methods
    case all            // Everything
}

// MARK: - Type Kind

/// Kind of type (struct, enum, class, protocol)
public enum TypeKind: String, Codable, Sendable {
    case `struct` = "struct"
    case `enum` = "enum"
    case `class` = "class"
    case `protocol` = "protocol"
    case `actor` = "actor"
}

// MARK: - Markdown Format

/// Format options for markdown generation
public enum MarkdownFormat: String, Codable, Sendable {
    case full           // Complete documentation
    case summary        // Summary only
    case apiReference   // API reference style
}

// MARK: - Mermaid Diagram Type

/// Types of Mermaid diagrams
public enum MermaidDiagramType: String, Codable, Sendable {
    case architecture   // Component relationships
    case actionFlow     // Button → action → state flow
    case hierarchy      // View tree structure
    case stateMachine   // State transitions
    case dataFlow       // Behavior metadata flows
}

//
//  TypeMetadata.swift
//  AwareCore
//
//  Documentation metadata for types (structs, enums, classes, protocols).
//

import Foundation

// MARK: - Type Metadata

/// Documentation metadata for a type (struct, enum, class, protocol)
///
/// **Token Cost:** ~20-40 tokens per type (compact format)
public struct TypeMetadata: Codable, Sendable, Hashable, Identifiable {
    public let id: String                     // Unique identifier (same as name)
    public let name: String                   // "AwareActionMetadataV2"
    public let kind: TypeKind                 // .struct, .enum, .class, .protocol
    public let category: TypeCategory         // .metadata, .command, .result
    public let description: String            // What this type represents
    public let properties: [PropertyMetadata]? // For structs/classes
    public let cases: [EnumCaseMetadata]?     // For enums
    public let methods: [String]?             // Method names (brief list)
    public let conformsTo: [String]           // ["Codable", "Sendable"]
    public let examples: [CodeExample]        // Usage examples
    public let tokenCost: Int?                // For Codable types in snapshots (~40 tokens)
    public let since: String                  // "3.0.0"
    public let deprecated: String?            // Deprecation message

    public init(
        name: String,
        kind: TypeKind,
        category: TypeCategory,
        description: String,
        properties: [PropertyMetadata]? = nil,
        cases: [EnumCaseMetadata]? = nil,
        methods: [String]? = nil,
        conformsTo: [String] = [],
        examples: [CodeExample] = [],
        tokenCost: Int? = nil,
        since: String,
        deprecated: String? = nil
    ) {
        self.id = name
        self.name = name
        self.kind = kind
        self.category = category
        self.description = description
        self.properties = properties
        self.cases = cases
        self.methods = methods
        self.conformsTo = conformsTo
        self.examples = examples
        self.tokenCost = tokenCost
        self.since = since
        self.deprecated = deprecated
    }

    // MARK: - Compact Representations

    /// Ultra-compact format for LLM consumption
    /// Example: "AwareActionMetadataV2 - Action metadata [Codable,40tok]"
    public var compactSignature: String {
        var result = "\(name) - \(description)"
        if !conformsTo.isEmpty {
            result += " [\(conformsTo.joined(separator: ","))"
            if let cost = tokenCost {
                result += ",\(cost)tok"
            }
            result += "]"
        } else if let cost = tokenCost {
            result += " [\(cost)tok]"
        }
        return result
    }

    /// One-liner with kind badge
    /// Example: "[struct] AwareActionMetadataV2 - Action metadata"
    public var oneLiner: String {
        "[\(kind.rawValue)] \(name) - \(description)"
    }

    /// Count of properties/cases
    public var memberCount: Int {
        if let props = properties {
            return props.count
        }
        if let enumCases = cases {
            return enumCases.count
        }
        return 0
    }
}

// MARK: - Type Category

/// Category of type purpose
public enum TypeCategory: String, Codable, Sendable, CaseIterable {
    case command        // AwareCommand, AwareResult
    case snapshot       // AwareViewSnapshot, AwareViewNode
    case metadata       // AwareActionMetadataV2, AwareBehaviorMetadataV2
    case result         // AwareTapResult, AwareAssertionResult
    case error          // AwareErrorV3
    case platform       // AwarePlatform, AwareInputCommand
    case state          // AwareStateValue
    case testing        // Coverage, accessibility types

    public var displayName: String {
        switch self {
        case .command: return "Commands"
        case .snapshot: return "Snapshots"
        case .metadata: return "Metadata"
        case .result: return "Results"
        case .error: return "Errors"
        case .platform: return "Platform"
        case .state: return "State"
        case .testing: return "Testing"
        }
    }

    public var emoji: String {
        switch self {
        case .command: return "⚡"
        case .snapshot: return "📸"
        case .metadata: return "📋"
        case .result: return "✅"
        case .error: return "❌"
        case .platform: return "🖥️"
        case .state: return "🔄"
        case .testing: return "🧪"
        }
    }
}

//
//  ModifierMetadata.swift
//  AwareCore
//
//  Documentation metadata for SwiftUI modifiers.
//

import Foundation

// MARK: - Modifier Metadata

/// Documentation metadata for a SwiftUI modifier
///
/// **Token Cost:** ~15-25 tokens per modifier (compact format)
public struct ModifierMetadata: Codable, Sendable, Hashable, Identifiable {
    public let id: String                     // Unique identifier (same as name)
    public let name: String                   // ".awareButton"
    public let fullSignature: String          // Full function signature
    public let parameters: [ParameterMetadata]
    public let returnType: String             // "some View"
    public let platform: Platform             // .iOS, .macOS, .all
    public let category: ModifierCategory     // .action, .state, .registration
    public let description: String            // What this modifier does
    public let examples: [CodeExample]        // Usage examples
    public let tokenCost: Int?                // Token cost per invocation (~4 tokens)
    public let relatedModifiers: [String]     // [".awareMetadata", ".awareState"]
    public let since: String                  // "1.0.0"
    public let deprecated: String?            // Deprecation message if applicable

    // MARK: Validation Metadata (v3.0+ Protocol-Based Development)
    public let requiredParameters: [String]?  // ["id", "label"] - Parameters that must be provided
    public let validationPattern: String?     // Regex for compliance checking
    public let commonMistakes: [CommonMistake]? // Known error patterns
    public let autoFixes: [AutoFix]?          // Suggested corrections

    public init(
        name: String,
        fullSignature: String,
        parameters: [ParameterMetadata],
        returnType: String,
        platform: Platform,
        category: ModifierCategory,
        description: String,
        examples: [CodeExample] = [],
        tokenCost: Int? = nil,
        relatedModifiers: [String] = [],
        since: String,
        deprecated: String? = nil,
        requiredParameters: [String]? = nil,
        validationPattern: String? = nil,
        commonMistakes: [CommonMistake]? = nil,
        autoFixes: [AutoFix]? = nil
    ) {
        self.id = name
        self.name = name
        self.fullSignature = fullSignature
        self.parameters = parameters
        self.returnType = returnType
        self.platform = platform
        self.category = category
        self.description = description
        self.examples = examples
        self.tokenCost = tokenCost
        self.relatedModifiers = relatedModifiers
        self.since = since
        self.deprecated = deprecated
        self.requiredParameters = requiredParameters
        self.validationPattern = validationPattern
        self.commonMistakes = commonMistakes
        self.autoFixes = autoFixes
    }

    // MARK: - Compact Representations

    /// Ultra-compact signature for LLM consumption
    /// Example: ".awareButton(id,lbl?,act?) - Tappable button [4tok]"
    public var compactSignature: String {
        let params = parameters.map { param in
            let optional = param.type.hasSuffix("?") ? "?" : ""
            let hasDefault = param.defaultValue != nil ? "?" : ""
            return "\(param.name)\(optional)\(hasDefault)"
        }.joined(separator: ",")

        var result = "\(name)(\(params))"
        if let cost = tokenCost {
            result += " [\(cost)tok]"
        }
        return result
    }

    /// Short one-line description for lists
    /// Example: ".awareButton(id,lbl?,act?) - Tappable button"
    public var oneLiner: String {
        "\(compactSignature) - \(description)"
    }

    /// Platform badge
    public var platformBadge: String {
        switch platform {
        case .all: return "📱💻🌐"
        case .iOS: return "📱"
        case .macOS: return "💻"
        case .web: return "🌐"
        case .backend: return "⚙️"
        }
    }
}

// MARK: - Modifier Category

/// Category of modifier functionality
public enum ModifierCategory: String, Codable, Sendable, CaseIterable {
    case registration   // .aware(), .awareContainer()
    case state          // .awareState(), .awareTextField()
    case action         // .awareButton(), .awareMetadata()
    case behavior       // .awareBehavior()
    case focus          // .awareFocus()
    case animation      // .awareAnimation()
    case scroll         // .awareScroll()
    case navigation     // .awareNavigationContext()
    case gesture        // iOS gestures
    case convenience    // .uiLoadingState(), etc.

    public var displayName: String {
        switch self {
        case .registration: return "Registration"
        case .state: return "State Tracking"
        case .action: return "Actions"
        case .behavior: return "Behavior"
        case .focus: return "Focus Management"
        case .animation: return "Animation"
        case .scroll: return "Scrolling"
        case .navigation: return "Navigation"
        case .gesture: return "Gestures"
        case .convenience: return "Convenience"
        }
    }

    public var emoji: String {
        switch self {
        case .registration: return "📝"
        case .state: return "🔄"
        case .action: return "👆"
        case .behavior: return "🎭"
        case .focus: return "🎯"
        case .animation: return "✨"
        case .scroll: return "📜"
        case .navigation: return "🧭"
        case .gesture: return "👋"
        case .convenience: return "⚡"
        }
    }
}

// MARK: - Validation Types (v3.0+ Protocol-Based Development)

/// Common mistake pattern detected in code
public struct CommonMistake: Codable, Sendable, Hashable {
    public let pattern: String           // What to detect (regex or description)
    public let description: String       // Explain the mistake
    public let severity: ValidationSeverity
    public let example: String?          // Example of the mistake

    public init(
        pattern: String,
        description: String,
        severity: ValidationSeverity,
        example: String? = nil
    ) {
        self.pattern = pattern
        self.description = description
        self.severity = severity
        self.example = example
    }
}

/// Suggested automatic fix for a common mistake
public struct AutoFix: Codable, Sendable, Hashable {
    public let description: String       // What the fix does
    public let codeTransform: String     // How to fix (template or description)
    public let confidence: Double        // 0.0-1.0 (how confident the fix is correct)
    public let example: String?          // Example of the fix

    public init(
        description: String,
        codeTransform: String,
        confidence: Double,
        example: String? = nil
    ) {
        self.description = description
        self.codeTransform = codeTransform
        self.confidence = confidence
        self.example = example
    }
}

/// Validation severity level
public enum ValidationSeverity: String, Codable, Sendable, Hashable {
    case error      // Must fix
    case warning    // Should fix
    case info       // Nice to have
}

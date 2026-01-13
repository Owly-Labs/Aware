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
        deprecated: String? = nil
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

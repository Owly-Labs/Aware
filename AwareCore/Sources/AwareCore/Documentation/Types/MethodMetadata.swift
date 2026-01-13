//
//  MethodMetadata.swift
//  AwareCore
//
//  Documentation metadata for public methods.
//

import Foundation

// MARK: - Method Metadata

/// Documentation metadata for a public method
///
/// **Token Cost:** ~10-20 tokens per method (compact format)
public struct MethodMetadata: Codable, Sendable, Hashable, Identifiable {
    public let id: String                     // Unique identifier (className.name)
    public let name: String                   // "tap"
    public let fullSignature: String          // "tap(_ viewId: String) async -> AwareTapResult"
    public let className: String              // "Aware", "AwareFocusManager"
    public let parameters: [ParameterMetadata]
    public let returnType: String             // "AwareTapResult"
    public let isAsync: Bool                  // true for async methods
    public let `throws`: Bool                 // true for throwing methods
    public let description: String            // What this method does
    public let examples: [CodeExample]        // Usage examples
    public let category: MethodCategory       // .action, .snapshot, .assertion
    public let tokenCost: Int?                // Token cost per invocation (~15 tokens)
    public let since: String                  // "3.0.0"
    public let deprecated: String?            // Deprecation message

    public init(
        name: String,
        fullSignature: String,
        className: String,
        parameters: [ParameterMetadata],
        returnType: String,
        isAsync: Bool = false,
        throws: Bool = false,
        description: String,
        examples: [CodeExample] = [],
        category: MethodCategory,
        tokenCost: Int? = nil,
        since: String,
        deprecated: String? = nil
    ) {
        self.id = "\(className).\(name)"
        self.name = name
        self.fullSignature = fullSignature
        self.className = className
        self.parameters = parameters
        self.returnType = returnType
        self.isAsync = isAsync
        self.throws = `throws`
        self.description = description
        self.examples = examples
        self.category = category
        self.tokenCost = tokenCost
        self.since = since
        self.deprecated = deprecated
    }

    // MARK: - Compact Representations

    /// Ultra-compact signature for LLM consumption
    /// Example: "tap(id) -> AwareTapResult [async,15tok]"
    public var compactSignature: String {
        let params = parameters.map { $0.name }.joined(separator: ",")
        var modifiers: [String] = []
        if isAsync { modifiers.append("async") }
        if `throws` { modifiers.append("throws") }
        if let cost = tokenCost {
            modifiers.append("\(cost)tok")
        }

        var result = "\(name)(\(params)) -> \(returnType)"
        if !modifiers.isEmpty {
            result += " [\(modifiers.joined(separator: ","))]"
        }
        return result
    }

    /// One-liner with class name
    /// Example: "Aware.tap(id) -> AwareTapResult"
    public var oneLiner: String {
        "\(className).\(compactSignature) - \(description)"
    }

    /// Method invocation pattern
    /// Example: "await Aware.shared.tap(viewId: ...)"
    public var invocationPattern: String {
        let asyncPrefix = isAsync ? "await " : ""
        let throwsPrefix = `throws` ? "try " : ""
        let params = parameters.map { "\($0.name): ..." }.joined(separator: ", ")
        return "\(throwsPrefix)\(asyncPrefix)\(className).shared.\(name)(\(params))"
    }
}

// MARK: - Method Category

/// Category of method functionality
public enum MethodCategory: String, Codable, Sendable, CaseIterable {
    case registration   // registerView, registerState
    case action         // tap, setText, swipe
    case snapshot       // captureSnapshot, snapshotCompact
    case query          // findByLabel, findTappable
    case assertion      // assertVisible, assertState
    case focus          // focus, focusNext
    case navigation     // goBack, dismiss
    case gesture        // longPress, doubleTap
    case state          // getState, setState
    case lifecycle      // onAppear, onDisappear

    public var displayName: String {
        switch self {
        case .registration: return "Registration"
        case .action: return "Actions"
        case .snapshot: return "Snapshots"
        case .query: return "Queries"
        case .assertion: return "Assertions"
        case .focus: return "Focus"
        case .navigation: return "Navigation"
        case .gesture: return "Gestures"
        case .state: return "State"
        case .lifecycle: return "Lifecycle"
        }
    }

    public var emoji: String {
        switch self {
        case .registration: return "📝"
        case .action: return "⚡"
        case .snapshot: return "📸"
        case .query: return "🔍"
        case .assertion: return "✅"
        case .focus: return "🎯"
        case .navigation: return "🧭"
        case .gesture: return "👋"
        case .state: return "🔄"
        case .lifecycle: return "♻️"
        }
    }
}

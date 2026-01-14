//
//  AwareLLMSnapshot.swift
//  AwareCore
//
//  LLM-optimized snapshot format for AI-driven UI testing.
//  Self-describing, intent-aware, actionable.
//

import Foundation

// MARK: - Root Snapshot

/// LLM-optimized snapshot containing full UI state with guidance
public struct AwareLLMSnapshot: Codable, Sendable {
    public let view: ViewDescriptor
    public let meta: SnapshotMeta?  // Optional for token efficiency

    public init(view: ViewDescriptor, meta: SnapshotMeta? = nil) {
        self.view = view
        self.meta = meta
    }

    // Custom encoding to omit meta if nil
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(view, forKey: .view)
        if let m = meta {
            try container.encode(m, forKey: .meta)
        }
    }

    enum CodingKeys: String, CodingKey {
        case view, meta
    }
}

// MARK: - View Descriptor

/// Complete view description with intent and guidance
public struct ViewDescriptor: Codable, Sendable {
    // Identity
    public let id: String
    public let type: String

    // Semantics
    public let intent: String
    public let state: ViewState

    // Hierarchy
    public let elements: [ElementDescriptor]

    // LLM Guidance (shortened field names for token efficiency)
    public let testSuggestions: [String]  // Encoded as "tests"
    public let commonErrors: [String]?    // Encoded as "errors"

    // Navigation (only encoded if present)
    public let canNavigateBack: Bool?
    public let previousView: String?
    public let modalPresentation: Bool?

    public init(
        id: String,
        type: String,
        intent: String,
        state: ViewState,
        elements: [ElementDescriptor],
        testSuggestions: [String],
        commonErrors: [String]? = nil,
        canNavigateBack: Bool? = nil,
        previousView: String? = nil,
        modalPresentation: Bool? = nil
    ) {
        self.id = id
        self.type = type
        self.intent = intent
        self.state = state
        self.elements = elements
        self.testSuggestions = testSuggestions
        self.commonErrors = commonErrors
        self.canNavigateBack = canNavigateBack
        self.previousView = previousView
        self.modalPresentation = modalPresentation
    }

    // Custom encoding for token optimization
    enum CodingKeys: String, CodingKey {
        case id, type, intent, state, elements
        case testSuggestions = "tests"
        case commonErrors = "errors"
        case canNavigateBack, previousView, modalPresentation
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(intent, forKey: .intent)
        try container.encode(state, forKey: .state)
        try container.encode(elements, forKey: .elements)
        try container.encode(testSuggestions, forKey: .testSuggestions)

        // Only encode optional fields if present
        if let errors = commonErrors {
            try container.encode(errors, forKey: .commonErrors)
        }
        if let nav = canNavigateBack {
            try container.encode(nav, forKey: .canNavigateBack)
        }
        if let prev = previousView {
            try container.encode(prev, forKey: .previousView)
        }
        if let modal = modalPresentation {
            try container.encode(modal, forKey: .modalPresentation)
        }
    }
}

/// View state for LLM understanding
public enum ViewState: String, Codable, Sendable {
    case ready      // Ready for interaction
    case loading    // Waiting for data/action
    case error      // Error state
    case success    // Action succeeded
    case disabled   // Interaction disabled
}

// MARK: - Element Descriptor

/// Complete element description with validation and guidance
public struct ElementDescriptor: Codable, Sendable {
    // Identity
    public let id: String
    public let type: ElementType
    public let label: String

    // Current State
    public let value: String
    public let state: ElementState
    public let enabled: Bool
    public let visible: Bool
    public let focused: Bool?

    // Validation
    public let required: Bool?
    public let validation: String?
    public let errorMessage: String?
    public let placeholder: String?

    // LLM Guidance (shortened for token efficiency)
    public let nextAction: String      // Encoded as "next"
    public let exampleValue: String?   // Encoded as "example"

    // Behavior (for buttons/actions)
    public let action: String?
    public let nextView: String?
    public let failureView: String?
    public let dependencies: [String]?

    // Accessibility
    public let accessibilityLabel: String?
    public let accessibilityHint: String?

    // Position (optional)
    public let frame: FrameDescriptor?

    public init(
        id: String,
        type: ElementType,
        label: String,
        value: String,
        state: ElementState,
        enabled: Bool,
        visible: Bool,
        focused: Bool? = nil,
        required: Bool? = nil,
        validation: String? = nil,
        errorMessage: String? = nil,
        placeholder: String? = nil,
        nextAction: String,
        exampleValue: String? = nil,
        action: String? = nil,
        nextView: String? = nil,
        failureView: String? = nil,
        dependencies: [String]? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        frame: FrameDescriptor? = nil
    ) {
        self.id = id
        self.type = type
        self.label = label
        self.value = value
        self.state = state
        self.enabled = enabled
        self.visible = visible
        self.focused = focused
        self.required = required
        self.validation = validation
        self.errorMessage = errorMessage
        self.placeholder = placeholder
        self.nextAction = nextAction
        self.exampleValue = exampleValue
        self.action = action
        self.nextView = nextView
        self.failureView = failureView
        self.dependencies = dependencies
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.frame = frame
    }

    // Custom encoding for token optimization
    enum CodingKeys: String, CodingKey {
        case id, type, label, value, state
        case enabled, visible, focused
        case required, validation, errorMessage, placeholder
        case nextAction = "next"
        case exampleValue = "example"
        case action, nextView, failureView, dependencies
        case accessibilityLabel, accessibilityHint, frame
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Always encode core fields
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(label, forKey: .label)
        try container.encode(state, forKey: .state)
        try container.encode(nextAction, forKey: .nextAction)

        // Only encode value if not empty
        if !value.isEmpty {
            try container.encode(value, forKey: .value)
        }

        // Only encode enabled/visible if false (default is true)
        if !enabled {
            try container.encode(enabled, forKey: .enabled)
        }
        if !visible {
            try container.encode(visible, forKey: .visible)
        }

        // Only encode optional fields if present
        if let foc = focused {
            try container.encode(foc, forKey: .focused)
        }
        if let req = required {
            try container.encode(req, forKey: .required)
        }
        if let val = validation {
            try container.encode(val, forKey: .validation)
        }
        if let err = errorMessage {
            try container.encode(err, forKey: .errorMessage)
        }
        if let ph = placeholder {
            try container.encode(ph, forKey: .placeholder)
        }
        if let ex = exampleValue {
            try container.encode(ex, forKey: .exampleValue)
        }
        if let act = action {
            try container.encode(act, forKey: .action)
        }
        if let nv = nextView {
            try container.encode(nv, forKey: .nextView)
        }
        if let fv = failureView {
            try container.encode(fv, forKey: .failureView)
        }
        if let deps = dependencies {
            try container.encode(deps, forKey: .dependencies)
        }
        if let a11y = accessibilityLabel {
            try container.encode(a11y, forKey: .accessibilityLabel)
        }
        if let hint = accessibilityHint {
            try container.encode(hint, forKey: .accessibilityHint)
        }
        if let fr = frame {
            try container.encode(fr, forKey: .frame)
        }
    }
}

/// Element types understood by LLMs
public enum ElementType: String, Codable, Sendable {
    case textField = "TextField"
    case secureField = "SecureField"
    case button = "Button"
    case toggle = "Toggle"
    case picker = "Picker"
    case slider = "Slider"
    case text = "Text"
    case image = "Image"
    case link = "Link"
    case container = "Container"
    case list = "List"
    case navigationBar = "NavigationBar"
    case tabBar = "TabBar"
    case activityIndicator = "ActivityIndicator"
}

/// Element state for LLM understanding
public enum ElementState: String, Codable, Sendable {
    case empty      // No value
    case filled     // Has value
    case valid      // Value passes validation
    case invalid    // Value fails validation
    case focused    // Currently focused
    case disabled   // Interaction disabled
    case loading    // Action in progress
    case error      // Error occurred
}

/// Frame information (optional)
public struct FrameDescriptor: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

// MARK: - Snapshot Metadata

/// Metadata about the snapshot
public struct SnapshotMeta: Codable, Sendable {
    public let timestamp: String
    public let tokenCount: Int
    public let format: String
    public let version: String
    public let app: String?
    public let device: String?

    public init(
        timestamp: String,
        tokenCount: Int,
        format: String = "llm",
        version: String = "1.0.0",
        app: String? = nil,
        device: String? = nil
    ) {
        self.timestamp = timestamp
        self.tokenCount = tokenCount
        self.format = format
        self.version = version
        self.app = app
        self.device = device
    }
}

// MARK: - Encoding Extensions

extension AwareLLMSnapshot {
    /// Encode to pretty-printed JSON string
    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw AwareError.snapshotGenerationFailed(
                reason: "Failed to encode snapshot to UTF-8",
                format: "llm"
            )
        }
        return json
    }

    /// Calculate approximate token count (chars / 4)
    public func estimateTokens() -> Int {
        guard let json = try? self.toJSON() else { return 0 }
        return json.count / 4
    }
}

// MARK: - Helper Extensions

extension ElementType {
    /// Initialize from string with fallback
    public init(from string: String) {
        switch string.lowercased() {
        case "textfield": self = .textField
        case "securefield": self = .secureField
        case "button": self = .button
        case "toggle": self = .toggle
        case "picker": self = .picker
        case "slider": self = .slider
        case "text": self = .text
        case "image": self = .image
        case "link": self = .link
        case "list": self = .list
        case "navigationbar": self = .navigationBar
        case "tabbar": self = .tabBar
        case "activityindicator": self = .activityIndicator
        default: self = .container
        }
    }
}

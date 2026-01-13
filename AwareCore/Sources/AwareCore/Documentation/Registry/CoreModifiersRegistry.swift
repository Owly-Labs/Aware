//
//  CoreModifiersRegistry.swift
//  AwareCore
//
//  Registers core framework modifiers for API documentation.
//

import Foundation

// MARK: - Core Modifiers Registry

/// Registers core AwareCore modifiers
@MainActor
public struct CoreModifiersRegistry {

    /// Register all core modifiers
    public static func register() {
        let registry = AwareAPIRegistry.shared

        // Register core modifiers
        registry.registerModifier(awareModifier())
        registry.registerModifier(awareContainerModifier())
        registry.registerModifier(awareButtonModifier())
        registry.registerModifier(awareStateModifier())
        registry.registerModifier(awareTextModifier())
    }

    // MARK: - Modifier Definitions

    private static func awareModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".aware",
            fullSignature: "aware(_ id: String, label: String? = nil, captureVisuals: Bool = true, parent: String? = nil)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique view identifier for testing and snapshots"
                ),
                ParameterMetadata(
                    name: "label",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Human-readable label for the view"
                ),
                ParameterMetadata(
                    name: "captureVisuals",
                    type: "Bool",
                    required: false,
                    defaultValue: "true",
                    description: "Whether to capture visual properties (frame, opacity, etc.)"
                ),
                ParameterMetadata(
                    name: "parent",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Parent container ID for establishing view hierarchy"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .registration,
            description: "Register view for LLM introspection and testing with automatic visual capture",
            examples: [
                CodeExample(
                    code: """
                    Text("Hello, World!")
                        .aware("greeting-text", label: "Greeting")
                    """,
                    description: "Basic view registration"
                ),
                CodeExample(
                    code: """
                    VStack {
                        Text("Child View")
                            .aware("child", parent: "container")
                    }
                    .awareContainer("container", label: "Main Container")
                    """,
                    description: "Hierarchical view registration with parent"
                )
            ],
            tokenCost: 3,
            relatedModifiers: [".awareContainer", ".awareState"],
            since: "1.0.0"
        )
    }

    private static func awareContainerModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareContainer",
            fullSignature: "awareContainer(_ id: String, label: String? = nil, parent: String? = nil)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique container identifier"
                ),
                ParameterMetadata(
                    name: "label",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Human-readable container label"
                ),
                ParameterMetadata(
                    name: "parent",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Parent container ID for nested hierarchies"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .registration,
            description: "Mark view as container for hierarchical snapshot capture and organization",
            examples: [
                CodeExample(
                    code: """
                    VStack {
                        Text("Item 1").aware("item1", parent: "list")
                        Text("Item 2").aware("item2", parent: "list")
                    }
                    .awareContainer("list", label: "Item List")
                    """,
                    description: "Container with child views"
                )
            ],
            tokenCost: 3,
            relatedModifiers: [".aware"],
            since: "1.0.0"
        )
    }

    private static func awareButtonModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareButton",
            fullSignature: "awareButton(_ id: String, label: String, parent: String? = nil)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique button identifier"
                ),
                ParameterMetadata(
                    name: "label",
                    type: "String",
                    required: true,
                    description: "Button label text for LLM understanding"
                ),
                ParameterMetadata(
                    name: "parent",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Parent container ID"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .action,
            description: "Register tappable button with automatic tap tracking for ghost UI testing",
            examples: [
                CodeExample(
                    code: """
                    Button("Sign In") { signIn() }
                        .awareButton("signin-btn", label: "Sign In")
                    """,
                    description: "Basic button registration"
                ),
                CodeExample(
                    code: """
                    Button("Save") { save() }
                        .awareButton("save-btn", label: "Save Document")
                        .awareMetadata(
                            "save-btn",
                            description: "Saves document to cloud",
                            type: .network
                        )
                    """,
                    description: "Button with action metadata"
                )
            ],
            tokenCost: 4,
            relatedModifiers: [".awareMetadata", ".awareTappable", ".awareAction"],
            since: "1.0.0"
        )
    }

    private static func awareStateModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareState",
            fullSignature: "awareState<T>(_ viewId: String, key: String, value: T)",
            parameters: [
                ParameterMetadata(
                    name: "viewId",
                    type: "String",
                    required: true,
                    description: "View identifier to attach state to"
                ),
                ParameterMetadata(
                    name: "key",
                    type: "String",
                    required: true,
                    description: "State key name (e.g., 'isEnabled', 'count')"
                ),
                ParameterMetadata(
                    name: "value",
                    type: "T",
                    required: true,
                    description: "State value (any type - converted to String)"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .state,
            description: "Track arbitrary state values with automatic change detection for snapshots",
            examples: [
                CodeExample(
                    code: """
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .aware("darkmode-toggle", label: "Dark Mode Toggle")
                        .awareState("darkmode-toggle", key: "isOn", value: isDarkMode)
                    """,
                    description: "Track toggle state"
                ),
                CodeExample(
                    code: """
                    Text("Count: \\(count)")
                        .aware("counter", label: "Counter")
                        .awareState("counter", key: "value", value: count)
                    """,
                    description: "Track numeric state"
                )
            ],
            tokenCost: 4,
            relatedModifiers: [".aware"],
            since: "1.0.0"
        )
    }

    private static func awareTextModifier() -> ModifierMetadata {
        ModifierMetadata(
            name: ".awareText",
            fullSignature: "awareText(_ id: String, text: String, parent: String? = nil)",
            parameters: [
                ParameterMetadata(
                    name: "id",
                    type: "String",
                    required: true,
                    description: "Unique text view identifier"
                ),
                ParameterMetadata(
                    name: "text",
                    type: "String",
                    required: true,
                    description: "Text content to track"
                ),
                ParameterMetadata(
                    name: "parent",
                    type: "String?",
                    required: false,
                    defaultValue: "nil",
                    description: "Parent container ID"
                )
            ],
            returnType: "some View",
            platform: .all,
            category: .state,
            description: "Track text content with automatic change detection for content verification",
            examples: [
                CodeExample(
                    code: """
                    Text(displayName)
                        .awareText("username", text: displayName)
                    """,
                    description: "Track dynamic text content"
                )
            ],
            tokenCost: 3,
            relatedModifiers: [".aware", ".awareTextField"],
            since: "1.0.0"
        )
    }
}

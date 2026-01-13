//
//  CoreMethodsRegistry.swift
//  AwareCore
//
//  Registers core framework methods for API documentation.
//

import Foundation

// MARK: - Core Methods Registry

/// Registers core AwareCore methods
@MainActor
public struct CoreMethodsRegistry {

    /// Register all core methods
    public static func register() {
        let registry = AwareAPIRegistry.shared

        // Register key methods
        registry.registerMethod(tapMethod())
        registry.registerMethod(captureSnapshotMethod())
        registry.registerMethod(findByLabelMethod())
    }

    // MARK: - Method Definitions

    private static func tapMethod() -> MethodMetadata {
        MethodMetadata(
            name: "tap",
            fullSignature: "tap(viewId: String) async -> AwareTapResult",
            className: "Aware",
            parameters: [
                ParameterMetadata(
                    name: "viewId",
                    type: "String",
                    required: true,
                    description: "View identifier to tap"
                )
            ],
            returnType: "AwareTapResult",
            isAsync: true,
            throws: false,
            description: "Execute tap action on view (ghost UI - no mouse movement required)",
            examples: [
                CodeExample(
                    code: """
                    let result = await Aware.shared.tap(viewId: "signin-btn")
                    assert(result.success, result.message)
                    """,
                    description: "Tap button without mouse"
                )
            ],
            category: .action,
            tokenCost: 15,
            since: "3.0.0"
        )
    }

    private static func captureSnapshotMethod() -> MethodMetadata {
        MethodMetadata(
            name: "captureSnapshot",
            fullSignature: "captureSnapshot(format: AwareSnapshotFormat = .compact, includeHidden: Bool = false, maxDepth: Int = 10, compression: CompressionStrategy = .basic) -> AwareSnapshotResult",
            className: "Aware",
            parameters: [
                ParameterMetadata(
                    name: "format",
                    type: "AwareSnapshotFormat",
                    required: false,
                    defaultValue: ".compact",
                    description: "Output format (compact|text|json|markdown)"
                ),
                ParameterMetadata(
                    name: "includeHidden",
                    type: "Bool",
                    required: false,
                    defaultValue: "false",
                    description: "Whether to include hidden views"
                ),
                ParameterMetadata(
                    name: "maxDepth",
                    type: "Int",
                    required: false,
                    defaultValue: "10",
                    description: "Maximum tree depth"
                ),
                ParameterMetadata(
                    name: "compression",
                    type: "CompressionStrategy",
                    required: false,
                    defaultValue: ".basic",
                    description: "Compression strategy for large snapshots"
                )
            ],
            returnType: "AwareSnapshotResult",
            isAsync: false,
            throws: false,
            description: "Capture current UI state as text snapshot (100-120 tokens in compact format)",
            examples: [
                CodeExample(
                    code: """
                    let snapshot = Aware.shared.captureSnapshot(format: .compact)
                    print(snapshot.content) // ~100-120 tokens
                    """,
                    description: "Get compact UI snapshot"
                )
            ],
            category: .snapshot,
            tokenCost: 20,
            since: "1.0.0"
        )
    }

    private static func findByLabelMethod() -> MethodMetadata {
        MethodMetadata(
            name: "findByLabel",
            fullSignature: "findByLabel(_ label: String) async -> [AwareViewDescription]",
            className: "Aware",
            parameters: [
                ParameterMetadata(
                    name: "label",
                    type: "String",
                    required: true,
                    description: "Label text to search for"
                )
            ],
            returnType: "[AwareViewDescription]",
            isAsync: true,
            throws: false,
            description: "Find all views matching a label (case-insensitive search)",
            examples: [
                CodeExample(
                    code: """
                    let buttons = await Aware.shared.findByLabel("Sign In")
                    if let firstButton = buttons.first {
                        await Aware.shared.tap(viewId: firstButton.id)
                    }
                    """,
                    description: "Find and tap button by label"
                )
            ],
            category: .query,
            tokenCost: 10,
            since: "3.0.0"
        )
    }
}

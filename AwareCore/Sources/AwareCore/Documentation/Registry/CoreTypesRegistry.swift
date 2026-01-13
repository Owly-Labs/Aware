//
//  CoreTypesRegistry.swift
//  AwareCore
//
//  Registers core framework types for API documentation.
//

import Foundation

// MARK: - Core Types Registry

/// Registers core AwareCore types
@MainActor
public struct CoreTypesRegistry {

    /// Register all core types
    public static func register() {
        let registry = AwareAPIRegistry.shared

        // Register key types
        registry.registerType(awareActionMetadataV2Type())
        registry.registerType(awareViewSnapshotType())
        registry.registerType(awareTapResultType())
    }

    // MARK: - Type Definitions

    private static func awareActionMetadataV2Type() -> TypeMetadata {
        TypeMetadata(
            name: "AwareActionMetadataV2",
            kind: .struct,
            category: .metadata,
            description: "Enhanced action metadata for LLM decision-making with preconditions and risk assessment",
            properties: [
                PropertyMetadata(
                    name: "actionDescription",
                    type: "String",
                    description: "What this action does"
                ),
                PropertyMetadata(
                    name: "actionType",
                    type: "ActionType",
                    description: "Category: navigation|mutation|network|fileSystem|system|destructive"
                ),
                PropertyMetadata(
                    name: "riskLevel",
                    type: "RiskLevel",
                    description: "Risk assessment: low|medium|high|critical"
                ),
                PropertyMetadata(
                    name: "preconditions",
                    type: "[String]?",
                    description: "Conditions required before execution",
                    isOptional: true
                ),
                PropertyMetadata(
                    name: "successIndicators",
                    type: "[String]?",
                    description: "How to verify successful execution",
                    isOptional: true
                )
            ],
            conformsTo: ["Codable", "Sendable"],
            examples: [
                CodeExample(
                    code: """
                    AwareActionMetadataV2(
                        actionDescription: "Saves document to cloud",
                        actionType: .network,
                        riskLevel: .medium,
                        expectedDurationMs: 1500,
                        preconditions: ["user.isAuthenticated", "document.hasChanges"]
                    )
                    """,
                    description: "Network action with preconditions"
                )
            ],
            tokenCost: 40,
            since: "3.0.0"
        )
    }

    private static func awareViewSnapshotType() -> TypeMetadata {
        TypeMetadata(
            name: "AwareViewSnapshot",
            kind: .struct,
            category: .snapshot,
            description: "Registry entry for a registered view with frame and visual properties",
            properties: [
                PropertyMetadata(
                    name: "id",
                    type: "String",
                    description: "Unique view identifier"
                ),
                PropertyMetadata(
                    name: "label",
                    type: "String?",
                    description: "Human-readable label",
                    isOptional: true
                ),
                PropertyMetadata(
                    name: "frame",
                    type: "CGRect?",
                    description: "View frame in global coordinates",
                    isOptional: true
                ),
                PropertyMetadata(
                    name: "visual",
                    type: "AwareSnapshot?",
                    description: "Visual properties snapshot",
                    isOptional: true
                ),
                PropertyMetadata(
                    name: "isVisible",
                    type: "Bool",
                    description: "Whether view is currently visible"
                )
            ],
            conformsTo: ["Codable", "Sendable"],
            tokenCost: 25,
            since: "1.0.0"
        )
    }

    private static func awareTapResultType() -> TypeMetadata {
        TypeMetadata(
            name: "AwareTapResult",
            kind: .struct,
            category: .result,
            description: "Result of tap action execution with success status and message",
            properties: [
                PropertyMetadata(
                    name: "success",
                    type: "Bool",
                    description: "Whether tap was successful"
                ),
                PropertyMetadata(
                    name: "message",
                    type: "String",
                    description: "Result message or error description"
                ),
                PropertyMetadata(
                    name: "viewId",
                    type: "String",
                    description: "View that was tapped"
                )
            ],
            conformsTo: ["Codable", "Sendable"],
            examples: [
                CodeExample(
                    code: """
                    let result = await Aware.shared.tap(viewId: "signin-btn")
                    if result.success {
                        print("Tap succeeded: \\(result.message)")
                    }
                    """,
                    description: "Check tap result"
                )
            ],
            tokenCost: 15,
            since: "3.0.0"
        )
    }
}

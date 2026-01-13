//
//  AwareOpenAPIGenerator.swift
//  AwareCore
//
//  Generates OpenAPI 3.0 specification for external tool integration.
//

import Foundation

// MARK: - Aware OpenAPI Generator

/// Generates OpenAPI 3.0 specification
@MainActor
public struct AwareOpenAPIGenerator {
    private let registry: AwareAPIRegistry

    public init(registry: AwareAPIRegistry) {
        self.registry = registry
    }

    public func generate(version: String) -> String {
        let spec: [String: Any] = [
            "openapi": version,
            "info": [
                "title": "Aware Framework API",
                "version": registry.frameworkVersion,
                "description": "Runtime API for LLM-driven UI testing and documentation"
            ],
            "paths": generatePaths(),
            "components": [
                "schemas": generateSchemas()
            ]
        ]

        return try! JSONSerialization.data(withJSONObject: spec, options: [.prettyPrinted, .sortedKeys]).utf8String
    }

    private func generatePaths() -> [String: Any] {
        var paths: [String: Any] = [:]

        // Snapshot endpoint
        paths["/snapshot"] = [
            "get": [
                "summary": "Capture UI snapshot",
                "parameters": [
                    [
                        "name": "format",
                        "in": "query",
                        "schema": [
                            "type": "string",
                            "enum": ["compact", "text", "json", "markdown"]
                        ]
                    ]
                ],
                "responses": [
                    "200": [
                        "description": "Snapshot generated successfully",
                        "content": [
                            "application/json": [
                                "schema": [
                                    "$ref": "#/components/schemas/AwareSnapshotResult"
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        // Tap action endpoint
        paths["/action/tap"] = [
            "post": [
                "summary": "Execute tap action",
                "requestBody": [
                    "content": [
                        "application/json": [
                            "schema": [
                                "$ref": "#/components/schemas/TapCommand"
                            ]
                        ]
                    ]
                ],
                "responses": [
                    "200": [
                        "description": "Action executed successfully",
                        "content": [
                            "application/json": [
                                "schema": [
                                    "$ref": "#/components/schemas/AwareTapResult"
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        return paths
    }

    private func generateSchemas() -> [String: Any] {
        var schemas: [String: Any] = [:]

        // Basic schemas
        schemas["TapCommand"] = [
            "type": "object",
            "properties": [
                "viewId": [
                    "type": "string",
                    "description": "View identifier to tap"
                ]
            ],
            "required": ["viewId"]
        ]

        schemas["AwareTapResult"] = [
            "type": "object",
            "properties": [
                "success": ["type": "boolean"],
                "message": ["type": "string"]
            ]
        ]

        schemas["AwareSnapshotResult"] = [
            "type": "object",
            "properties": [
                "format": ["type": "string"],
                "content": ["type": "string"],
                "viewCount": ["type": "integer"],
                "timestamp": ["type": "string", "format": "date-time"]
            ]
        ]

        // Add schemas for registered types
        for (name, type) in registry.types {
            schemas[name] = generateTypeSchema(type)
        }

        return schemas
    }

    private func generateTypeSchema(_ type: TypeMetadata) -> [String: Any] {
        var schema: [String: Any] = [
            "type": "object",
            "description": type.description
        ]

        if let properties = type.properties {
            var propsSchema: [String: Any] = [:]
            for prop in properties {
                propsSchema[prop.name] = [
                    "type": inferJSONType(from: prop.type),
                    "description": prop.description
                ]
            }
            schema["properties"] = propsSchema
        }

        return schema
    }

    private func inferJSONType(from swiftType: String) -> String {
        if swiftType.contains("String") { return "string" }
        if swiftType.contains("Int") { return "integer" }
        if swiftType.contains("Double") || swiftType.contains("Float") { return "number" }
        if swiftType.contains("Bool") { return "boolean" }
        if swiftType.hasPrefix("[") { return "array" }
        return "object"
    }
}

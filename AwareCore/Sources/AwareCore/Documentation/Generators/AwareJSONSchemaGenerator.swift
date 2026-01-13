//
//  AwareJSONSchemaGenerator.swift
//  AwareCore
//
//  Generates JSON Schema from Codable types for programmatic consumption.
//

import Foundation

// MARK: - Aware JSON Schema Generator

/// Generates JSON Schema for API types
@MainActor
public struct AwareJSONSchemaGenerator {
    private let registry: AwareAPIRegistry

    public init(registry: AwareAPIRegistry) {
        self.registry = registry
    }

    public func generate(scope: DocumentationScope) -> String {
        // TODO: Implement full JSON Schema generation
        var schema: [String: Any] = [
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "title": "Aware Framework API",
            "version": registry.frameworkVersion,
            "generated": ISO8601DateFormatter().string(from: Date())
        ]

        var definitions: [String: Any] = [:]

        // Generate schemas for types based on scope
        let types: [TypeMetadata]
        switch scope {
        case .modifiers:
            types = []
        case .types:
            types = Array(registry.types.values)
        case .methods:
            types = []
        case .all:
            types = Array(registry.types.values)
        }

        for type in types {
            definitions[type.name] = generateTypeSchema(type)
        }

        schema["definitions"] = definitions

        return try! JSONSerialization.data(withJSONObject: schema, options: [.prettyPrinted, .sortedKeys]).utf8String
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

extension Data {
    var utf8String: String {
        String(data: self, encoding: .utf8) ?? "{}"
    }
}

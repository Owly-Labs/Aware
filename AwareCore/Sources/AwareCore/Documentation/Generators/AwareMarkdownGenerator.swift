//
//  AwareMarkdownGenerator.swift
//  AwareCore
//
//  Generates Markdown documentation for human-readable API reference.
//

import Foundation

// MARK: - Aware Markdown Generator

/// Generates Markdown API documentation
@MainActor
public struct AwareMarkdownGenerator {
    private let registry: AwareAPIRegistry

    public init(registry: AwareAPIRegistry) {
        self.registry = registry
    }

    public func generate(format: MarkdownFormat) -> String {
        var output = "# Aware Framework API Reference\n\n"
        output += "_Generated: \(timestamp)_\n\n"
        output += "_Version: \(registry.frameworkVersion)_\n\n"

        switch format {
        case .full:
            output += generateFullDocumentation()
        case .summary:
            output += generateSummary()
        case .apiReference:
            output += generateAPIReference()
        }

        return output
    }

    private func generateFullDocumentation() -> String {
        var output = ""
        output += generateModifiersSection()
        output += generateTypesSection()
        output += generateMethodsSection()
        return output
    }

    private func generateSummary() -> String {
        let stats = registry.getStatistics()
        return """
        ## Summary

        - **Modifiers**: \(stats.modifierCount)
        - **Types**: \(stats.typeCount)
        - **Methods**: \(stats.methodCount)
        - **Total APIs**: \(stats.totalAPIs)

        """
    }

    private func generateAPIReference() -> String {
        generateFullDocumentation()
    }

    private func generateModifiersSection() -> String {
        let modifiers = registry.modifiers.values.sorted { $0.name < $1.name }
        guard !modifiers.isEmpty else { return "" }

        var output = "## Modifiers\n\n"

        for modifier in modifiers {
            output += "### `\(modifier.name)`\n\n"
            output += "\(modifier.description)\n\n"

            if !modifier.parameters.isEmpty {
                output += "**Parameters:**\n"
                for param in modifier.parameters {
                    output += "- `\(param.name)` (\(param.type)): \(param.description)\n"
                }
                output += "\n"
            }

            if !modifier.examples.isEmpty, let example = modifier.examples.first {
                output += "**Example:**\n```swift\n\(example.code)\n```\n\n"
            }

            output += "**Platform**: \(modifier.platform.displayName)  \n"
            output += "**Since**: \(modifier.since)\n\n"
            output += "---\n\n"
        }

        return output
    }

    private func generateTypesSection() -> String {
        let types = registry.types.values.sorted { $0.name < $1.name }
        guard !types.isEmpty else { return "" }

        var output = "## Types\n\n"

        for type in types {
            output += "### `\(type.name)`\n\n"
            output += "\(type.description)\n\n"

            if let properties = type.properties, !properties.isEmpty {
                output += "**Properties:**\n"
                for prop in properties {
                    output += "- `\(prop.name)`: \(prop.type) - \(prop.description)\n"
                }
                output += "\n"
            }

            output += "**Kind**: \(type.kind.rawValue)  \n"
            output += "**Since**: \(type.since)\n\n"
            output += "---\n\n"
        }

        return output
    }

    private func generateMethodsSection() -> String {
        let methods = registry.methods.values.sorted { $0.id < $1.id }
        guard !methods.isEmpty else { return "" }

        var output = "## Methods\n\n"

        for method in methods {
            output += "### `\(method.className).\(method.name)()`\n\n"
            output += "\(method.description)\n\n"

            output += "**Signature:**\n```swift\n\(method.fullSignature)\n```\n\n"

            if !method.parameters.isEmpty {
                output += "**Parameters:**\n"
                for param in method.parameters {
                    output += "- `\(param.name)` (\(param.type)): \(param.description)\n"
                }
                output += "\n"
            }

            output += "**Returns**: `\(method.returnType)`  \n"
            if method.isAsync { output += "**Async**: Yes  \n" }
            if method.throws { output += "**Throws**: Yes  \n" }
            output += "**Since**: \(method.since)\n\n"
            output += "---\n\n"
        }

        return output
    }

    private var timestamp: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date())
    }
}

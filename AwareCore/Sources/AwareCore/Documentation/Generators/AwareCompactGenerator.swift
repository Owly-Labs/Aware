//
//  AwareCompactGenerator.swift
//  AwareCore
//
//  Generates ultra-compact API reference optimized for LLM token efficiency.
//  Target: <1500 tokens (ideally ~1200 tokens)
//

import Foundation

// MARK: - Aware Compact Generator

/// Generates ultra-compact API documentation for LLM consumption
///
/// **Token Budget**: 1000-1200 tokens (vs 15,000 for full CLAUDE.md = 92% reduction)
/// **Pattern Reference**: `AwareSnapshotRenderer.renderAsCompact()` (line 167-250)
@MainActor
public struct AwareCompactGenerator {
    private let registry: AwareAPIRegistry

    public init(registry: AwareAPIRegistry) {
        self.registry = registry
    }

    // MARK: - Generation

    public func generate(maxTokens: Int = 1500) -> String {
        var output = ""
        var estimatedTokens = 0

        // Header
        let header = "AWARE API v\(registry.frameworkVersion) [Generated: \(timestamp)]\n\n"
        output += header
        estimatedTokens += estimateTokens(header)

        // Modifiers section (most important for LLMs)
        let modifiersSection = generateModifiersSection()
        output += modifiersSection
        estimatedTokens += estimateTokens(modifiersSection)

        // Types section (key types only to stay under budget)
        if estimatedTokens < maxTokens - 400 {
            let typesSection = generateTypesSection(maxTypes: 15)
            output += typesSection
            estimatedTokens += estimateTokens(typesSection)
        }

        // Methods section (core methods only)
        if estimatedTokens < maxTokens - 300 {
            let methodsSection = generateMethodsSection(maxMethods: 25)
            output += methodsSection
            estimatedTokens += estimateTokens(methodsSection)
        }

        // Error categories (compact)
        if estimatedTokens < maxTokens - 100 {
            let errorsSection = generateErrorsSection()
            output += errorsSection
            estimatedTokens += estimateTokens(errorsSection)
        }

        // Footer with token count
        output += "\n[\(estimatedTokens) tokens]"

        return output
    }

    // MARK: - Section Generators

    private func generateModifiersSection() -> String {
        let modifiers = registry.modifiers.values.sorted { $0.name < $1.name }
        guard !modifiers.isEmpty else { return "" }

        var output = "MODIFIERS [\(modifiers.count)]:\n"

        // Group by category for better organization
        let grouped = Dictionary(grouping: modifiers) { $0.category }
        let sortedCategories: [ModifierCategory] = [
            .registration, .state, .action, .behavior,
            .focus, .animation, .scroll, .navigation, .gesture, .convenience
        ]

        for category in sortedCategories {
            guard let categoryModifiers = grouped[category], !categoryModifiers.isEmpty else { continue }

            output += "  \(category.emoji) \(category.displayName):\n"
            for modifier in categoryModifiers {
                output += "    \(modifier.compactSignature) - \(truncate(modifier.description, maxLength: 40))\n"
            }
        }

        output += "\n"
        return output
    }

    private func generateTypesSection(maxTypes: Int) -> String {
        // Prioritize key types by category
        let priorityCategories: [TypeCategory] = [.metadata, .command, .snapshot, .result, .error]
        var selectedTypes: [TypeMetadata] = []

        for category in priorityCategories {
            let categoryTypes = registry.getTypes(category: category)
            selectedTypes.append(contentsOf: categoryTypes.prefix(maxTypes / priorityCategories.count))
        }

        // Fill remaining slots with other types
        let remainingSlots = maxTypes - selectedTypes.count
        if remainingSlots > 0 {
            let allTypes = registry.types.values.sorted { $0.name < $1.name }
            let otherTypes = allTypes.filter { type in
                !selectedTypes.contains { $0.name == type.name }
            }
            selectedTypes.append(contentsOf: otherTypes.prefix(remainingSlots))
        }

        guard !selectedTypes.isEmpty else { return "" }

        var output = "TYPES [\(selectedTypes.count) key types]:\n"

        for type in selectedTypes.sorted(by: { $0.name < $1.name }) {
            output += "  \(type.compactSignature)\n"

            // Show 3-5 key properties for metadata types
            if type.category == .metadata, let props = type.properties?.prefix(5) {
                for prop in props {
                    output += "    .\(prop.name): \(prop.type)\n"
                }
            }
        }

        output += "\n"
        return output
    }

    private func generateMethodsSection(maxMethods: Int) -> String {
        // Prioritize by category
        let priorityCategories: [MethodCategory] = [.action, .snapshot, .query, .assertion, .focus]
        var selectedMethods: [MethodMetadata] = []

        for category in priorityCategories {
            let categoryMethods = registry.getMethods(category: category)
            selectedMethods.append(contentsOf: categoryMethods.prefix(maxMethods / priorityCategories.count))
        }

        guard !selectedMethods.isEmpty else { return "" }

        var output = "METHODS [\(selectedMethods.count) core]:\n"

        // Group by class
        let grouped = Dictionary(grouping: selectedMethods) { $0.className }

        for (className, methods) in grouped.sorted(by: { $0.key < $1.key }) {
            output += "  \(className):\n"
            for method in methods.sorted(by: { $0.name < $1.name }) {
                output += "    \(method.compactSignature)\n"
            }
        }

        output += "\n"
        return output
    }

    private func generateErrorsSection() -> String {
        // Get error types from registry
        let errorTypes = registry.getTypes(category: .error)
        guard !errorTypes.isEmpty else { return "" }

        var output = "ERRORS:\n"

        for errorType in errorTypes {
            output += "  \(errorType.name) - \(truncate(errorType.description, maxLength: 50))\n"
            if let cases = errorType.cases?.prefix(10) {
                for enumCase in cases {
                    output += "    .\(enumCase.name) - \(truncate(enumCase.description, maxLength: 40))\n"
                }
            }
        }

        output += "\n"
        return output
    }

    // MARK: - Utilities

    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func truncate(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength - 1)) + "…"
    }

    /// Estimate token count (rough approximation: 1 token ≈ 4 characters)
    private func estimateTokens(_ text: String) -> Int {
        text.count / 4
    }
}

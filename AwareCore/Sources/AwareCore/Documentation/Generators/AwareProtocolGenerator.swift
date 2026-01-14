//
//  AwareProtocolGenerator.swift
//  AwareCore
//
//  Generates protocol-based development artifacts for MCP-guided code generation.
//  Enables LLMs to generate Aware-compatible code without framework import.
//

import Foundation

// MARK: - Protocol Generator

/// Generates lightweight stub implementations for protocol-based development
///
/// **Purpose**: Transform Aware from "framework as dependency" to "framework as protocol specification"
/// **Output**: Stubs (50-100 LOC), Validation Rules (JSON), Pattern Catalog (JSON)
@MainActor
public struct AwareProtocolGenerator {
    private let registry: AwareAPIRegistry

    public init(registry: AwareAPIRegistry) {
        self.registry = registry
    }

    // MARK: - Public API

    /// Generate all protocol artifacts
    public func generate() -> ProtocolSpecificationResult {
        let stubs = generateStubs(platform: .all, language: .swift)
        let validationRules = generateValidationRules()
        let patternCatalog = generatePatternCatalog()

        return ProtocolSpecificationResult(
            stubs: stubs,
            validationRules: validationRules,
            patternCatalog: patternCatalog,
            version: registry.frameworkVersion,
            generatedAt: Date()
        )
    }

    /// Generate lightweight stub implementations (50-100 LOC)
    public func generateStubs(platform: Platform, language: Language) -> ProtocolStubsResult {
        guard language == .swift else {
            return ProtocolStubsResult(
                code: "",
                language: language,
                platform: platform,
                lineCount: 0,
                modifiers: [],
                instructions: "Only Swift is currently supported"
            )
        }

        let modifiers = registry.modifiers.values
            .filter { platform == .all || $0.platform == platform || $0.platform == .all }
            .sorted { $0.category.rawValue < $1.category.rawValue }

        var code = generateStubHeader()

        // Group by category for organization
        let grouped = Dictionary(grouping: modifiers) { $0.category }
        let sortedCategories: [ModifierCategory] = [
            .registration, .state, .action, .behavior,
            .focus, .animation, .scroll, .navigation, .gesture, .convenience
        ]

        for category in sortedCategories {
            guard let categoryModifiers = grouped[category], !categoryModifiers.isEmpty else { continue }

            code += "\n    // MARK: \(category.displayName)\n"
            for modifier in categoryModifiers {
                code += generateStubModifier(modifier)
            }
        }

        code += generateStubFooter()

        let lineCount = code.components(separatedBy: "\n").count
        let modifierNames = modifiers.map { $0.name }

        return ProtocolStubsResult(
            code: code,
            language: language,
            platform: platform,
            lineCount: lineCount,
            modifiers: modifierNames,
            instructions: generateStubInstructions(platform: platform, modifierCount: modifiers.count)
        )
    }

    /// Generate validation rules (JSON schema)
    public func generateValidationRules() -> ValidationRulesResult {
        var rules: [ValidationRule] = []

        // Rule 1: ID Uniqueness
        rules.append(ValidationRule(
            name: "id_uniqueness",
            category: .consistency,
            severity: .error,
            pattern: nil,
            description: "View IDs must be unique within the hierarchy",
            fix: "Use unique IDs for each view. Consider prefixing with view name.",
            confidence: 1.0
        ))

        // Rule 2: Button requires awareButton modifier
        rules.append(ValidationRule(
            name: "button_requires_modifier",
            category: .completeness,
            severity: .warning,
            pattern: #"Button\([^)]*\)(?!.*\.awareButton)"#,
            description: "Button elements should use .awareButton() modifier",
            fix: "Add .awareButton(\"<id>\", label: \"<label>\") after Button declaration",
            confidence: 0.9
        ))

        // Rule 3: TextField requires awareTextField modifier
        rules.append(ValidationRule(
            name: "textfield_requires_modifier",
            category: .completeness,
            severity: .warning,
            pattern: #"TextField\([^)]*\)(?!.*\.awareTextField)"#,
            description: "TextField elements should use .awareTextField() modifier",
            fix: "Add .awareTextField(\"<id>\", text: $binding, label: \"<label>\") after TextField declaration",
            confidence: 0.9
        ))

        // Rule 4: State variables should be tracked
        rules.append(ValidationRule(
            name: "state_should_be_tracked",
            category: .completeness,
            severity: .info,
            pattern: #"@State\s+(private\s+)?var\s+(\w+)"#,
            description: "@State variables should be tracked with .awareState()",
            fix: "Add .awareState(\"<viewId>\", key: \"<varName>\", value: <varName>) to the view",
            confidence: 0.7
        ))

        // Rule 5: Required parameters
        rules.append(ValidationRule(
            name: "required_parameters",
            category: .correctness,
            severity: .error,
            pattern: nil,
            description: "All required parameters must be provided",
            fix: "Check modifier signature and provide all required parameters",
            confidence: 1.0
        ))

        // Rule 6: Container hierarchy
        rules.append(ValidationRule(
            name: "container_hierarchy",
            category: .structure,
            severity: .info,
            pattern: nil,
            description: "Related views should be grouped in .awareContainer()",
            fix: "Wrap related views with .awareContainer(\"<id>\", label: \"<label>\")",
            confidence: 0.6
        ))

        // Rule 7: Action metadata
        rules.append(ValidationRule(
            name: "action_metadata_recommended",
            category: .completeness,
            severity: .info,
            pattern: #"\.awareButton\([^)]*\)(?!.*\.awareMetadata)"#,
            description: "Consider adding .awareMetadata() to describe button actions",
            fix: "Add .awareMetadata(\"<id>\", description: \"...\", type: .action) for better LLM understanding",
            confidence: 0.5
        ))

        return ValidationRulesResult(
            rules: rules,
            categories: Set(rules.map { $0.category }),
            severityLevels: Set(rules.map { $0.severity })
        )
    }

    /// Generate pattern catalog (examples + metadata)
    public func generatePatternCatalog() -> PatternCatalogResult {
        var patterns: [String: ModifierPattern] = [:]

        for modifier in registry.modifiers.values {
            let pattern = ModifierPattern(
                name: modifier.name,
                signature: modifier.fullSignature,
                category: modifier.category,
                description: modifier.description,
                parameters: modifier.parameters.map { param in
                    PatternParameter(
                        name: param.name,
                        type: param.type,
                        description: param.description,
                        required: param.defaultValue == nil,
                        defaultValue: param.defaultValue
                    )
                },
                examples: modifier.examples,
                relatedModifiers: modifier.relatedModifiers,
                commonMistakes: [],  // To be populated from validation metadata
                tokenCost: modifier.tokenCost ?? 4,
                platform: modifier.platform
            )

            patterns[modifier.name] = pattern
        }

        return PatternCatalogResult(
            patterns: patterns,
            categories: Set(patterns.values.map { $0.category }),
            totalPatterns: patterns.count
        )
    }

    // MARK: - Stub Generation Helpers

    private func generateStubHeader() -> String {
        """
        // MARK: - Aware-Lite Protocol Stubs
        // Generated by AwareProtocolGenerator
        // Version: \(registry.frameworkVersion)
        // Generated: \(timestamp)
        //
        // NO IMPORT REQUIRED - Paste into any Swift file
        // These stubs provide Aware-compatible modifiers without framework dependency
        //
        // Migration Path:
        //   Stage 1: Use stubs (no dependency)
        //   Stage 2: import AwareCore (types only)
        //   Stage 3: import Aware (full features)

        import SwiftUI

        extension View {
        """
    }

    private func generateStubModifier(_ modifier: ModifierMetadata) -> String {
        let params = modifier.parameters.map { param in
            let typeStr = param.type
            if let defaultVal = param.defaultValue {
                return "_ \(param.name): \(typeStr) = \(defaultVal)"
            } else {
                return "_ \(param.name): \(typeStr)"
            }
        }.joined(separator: ", ")

        let signature = "\(modifier.name)(\(params)) -> some View"
        let comment = "    /// \(modifier.description)\n"
        let stub = "    func \(signature) { self }\n"

        return comment + stub
    }

    private func generateStubFooter() -> String {
        """
        }

        // MARK: - End of Aware-Lite Stubs
        """
    }

    private func generateStubInstructions(platform: Platform, modifierCount: Int) -> String {
        """
        Add this to your project once. No Aware dependency needed.

        Instructions:
        1. Create a new Swift file (e.g., AwareLite.swift)
        2. Paste the stub code above
        3. Use .aware*() modifiers in your views
        4. Validate with MCP tool: aware_validate_code
        5. Auto-fix with MCP tool: aware_fix_code

        Platform: \(platform.rawValue)
        Modifiers: \(modifierCount)

        Migration Path:
        - Later: replace stubs with 'import Aware' for enhanced features
        - Zero code changes needed!
        - Get: Performance monitoring, accessibility, coverage tracking
        """
    }

    // MARK: - Utilities

    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - Result Types

/// Complete protocol specification export
public struct ProtocolSpecificationResult: Codable, Sendable {
    public let stubs: ProtocolStubsResult
    public let validationRules: ValidationRulesResult
    public let patternCatalog: PatternCatalogResult
    public let version: String
    public let generatedAt: Date
}

/// Lightweight stub implementations
public struct ProtocolStubsResult: Codable, Sendable {
    public let code: String              // Swift code (50-100 LOC)
    public let language: Language
    public let platform: Platform
    public let lineCount: Int
    public let modifiers: [String]       // Modifier names included
    public let instructions: String      // How to use
}

/// Validation rules for Aware-compliance
public struct ValidationRulesResult: Codable, Sendable {
    public let rules: [ValidationRule]
    public let categories: Set<ValidationCategory>
    public let severityLevels: Set<ValidationSeverity>
}

/// Pattern catalog with examples
public struct PatternCatalogResult: Codable, Sendable {
    public let patterns: [String: ModifierPattern]
    public let categories: Set<ModifierCategory>
    public let totalPatterns: Int
}

// MARK: - Validation Types

public struct ValidationRule: Codable, Sendable, Hashable {
    public let name: String
    public let category: ValidationCategory
    public let severity: ValidationSeverity
    public let pattern: String?          // Regex pattern (nil = manual check)
    public let description: String
    public let fix: String               // Suggested correction
    public let confidence: Double        // 0.0-1.0
}

public enum ValidationCategory: String, Codable, Sendable, Hashable {
    case completeness   // Missing required modifiers
    case correctness    // Wrong parameter types/values
    case consistency    // Conflicting state
    case structure      // Hierarchy issues
    case performance    // Performance concerns
    case accessibility  // A11y issues
}

// MARK: - Pattern Types

public struct ModifierPattern: Codable, Sendable {
    public let name: String
    public let signature: String
    public let category: ModifierCategory
    public let description: String
    public let parameters: [PatternParameter]
    public let examples: [CodeExample]
    public let relatedModifiers: [String]
    public let commonMistakes: [String]
    public let tokenCost: Int
    public let platform: Platform
}

public struct PatternParameter: Codable, Sendable {
    public let name: String
    public let type: String
    public let description: String
    public let required: Bool
    public let defaultValue: String?
}

// MARK: - Language Support

public enum Language: String, Codable, Sendable {
    case swift = "Swift"
    case typescript = "TypeScript"
    case python = "Python"
}

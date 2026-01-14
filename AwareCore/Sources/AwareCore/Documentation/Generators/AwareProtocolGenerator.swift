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

        // MARK: - WCAG Accessibility Rules (v3.1+)

        // Rule 8: Interactive elements require labels (WCAG 2.4.6)
        rules.append(ValidationRule(
            name: "interactive_elements_require_labels",
            category: .accessibility,
            severity: .warning,
            pattern: #"\.aware(Button|TextField|SecureField|Toggle)\([^,]*,\s*label:\s*nil"#,
            description: "Interactive elements should have descriptive labels for accessibility (WCAG 2.4.6 - Headings and Labels)",
            fix: "Add label parameter: .awareButton(\"id\", label: \"Descriptive Label\")",
            confidence: 0.95
        ))

        // Rule 9: Toggle requires label (WCAG 4.1.2)
        rules.append(ValidationRule(
            name: "toggle_requires_label",
            category: .accessibility,
            severity: .warning,
            pattern: #"Toggle\([^)]*\)(?!.*\.awareToggle)"#,
            description: "Toggle elements must have labels for screen readers (WCAG 4.1.2 - Name, Role, Value)",
            fix: "Add .awareToggle(\"<id>\", isOn: $binding, label: \"Toggle Purpose\") after Toggle declaration",
            confidence: 0.9
        ))

        // Rule 10: Navigation links require descriptive labels (WCAG 2.4.4)
        rules.append(ValidationRule(
            name: "navigation_requires_descriptive_label",
            category: .accessibility,
            severity: .warning,
            pattern: #"NavigationLink\([^)]*\)(?!.*\.awareNavigation)"#,
            description: "Navigation links must have descriptive labels indicating destination (WCAG 2.4.4 - Link Purpose)",
            fix: "Add .awareNavigation(\"<id>\", destination: \"DestinationView\") with clear destination name",
            confidence: 0.85
        ))

        // Rule 11: Container hierarchy for semantic structure (WCAG 1.3.1)
        rules.append(ValidationRule(
            name: "semantic_container_structure",
            category: .accessibility,
            severity: .info,
            pattern: nil,
            description: "Use .awareContainer() to define semantic regions for screen reader navigation (WCAG 1.3.1 - Info and Relationships)",
            fix: "Wrap related views with .awareContainer(\"<id>\", label: \"Section Name\") to create landmark regions",
            confidence: 0.7
        ))

        // Rule 12: Touch target minimum size (WCAG 2.5.5)
        rules.append(ValidationRule(
            name: "touch_target_size",
            category: .accessibility,
            severity: .info,
            pattern: nil,
            description: "Interactive elements should meet minimum touch target size of 44x44 points (WCAG 2.5.5 - Target Size)",
            fix: "Ensure buttons and tappable elements have .frame(minWidth: 44, minHeight: 44) or equivalent padding",
            confidence: 0.6
        ))

        // Rule 13: State changes should be announced (WCAG 4.1.3)
        rules.append(ValidationRule(
            name: "state_changes_announced",
            category: .accessibility,
            severity: .info,
            pattern: #"@State\s+(private\s+)?var\s+(\w+).*(?!.*\.awareState)"#,
            description: "State changes should be tracked and announced to assistive technologies (WCAG 4.1.3 - Status Messages)",
            fix: "Add .awareState(\"<viewId>\", key: \"<stateName>\", value: <stateValue>) to announce changes",
            confidence: 0.65
        ))

        // Rule 14: Form validation feedback (WCAG 3.3.1)
        rules.append(ValidationRule(
            name: "form_validation_feedback",
            category: .accessibility,
            severity: .warning,
            pattern: nil,
            description: "Form fields with validation should provide clear error messages (WCAG 3.3.1 - Error Identification)",
            fix: "Use .awareState() to track validation errors and display them with .aware() labeled error text",
            confidence: 0.8
        ))

        // MARK: - Performance Budget Rules (v3.1+)

        // Rule 15: Action execution time budget
        rules.append(ValidationRule(
            name: "action_execution_budget",
            category: .performance,
            severity: .warning,
            pattern: nil,
            description: "Action handlers should complete within performance budget (Standard: 250ms, Strict: 100ms, Lenient: 500ms)",
            fix: "Use .awareMetadata() with expectedDurationMs parameter to declare expected execution time and enable performance monitoring",
            confidence: 0.75
        ))

        // Rule 16: Animation duration budget
        rules.append(ValidationRule(
            name: "animation_duration_budget",
            category: .performance,
            severity: .info,
            pattern: #"\.awareAnimation\([^)]*,\s*duration:\s*([0-9.]+)"#,
            description: "Animations should complete within 500ms for good UX (300ms recommended for most transitions)",
            fix: "Reduce animation duration or use .spring() for natural feel. Add duration parameter to .awareAnimation() for tracking",
            confidence: 0.7
        ))

        // Rule 17: Network action timeout
        rules.append(ValidationRule(
            name: "network_action_timeout",
            category: .performance,
            severity: .warning,
            pattern: #"\.awareMetadata\([^)]*,\s*type:\s*\.network"#,
            description: "Network actions should have timeout budgets (Standard: 30s, Fast: 10s, Slow: 60s)",
            fix: "Add expectedDurationMs to .awareMetadata() and implement timeout handling in action handler",
            confidence: 0.8
        ))

        // Rule 18: Scroll performance tracking
        rules.append(ValidationRule(
            name: "scroll_performance_tracking",
            category: .performance,
            severity: .info,
            pattern: #"ScrollView\([^)]*\)(?!.*\.awareScroll)"#,
            description: "ScrollView with many items should track scroll performance to detect janky scrolling",
            fix: "Add .awareScroll(\"<id>\", position: $scrollPosition, isScrolling: $isScrolling) to track scroll metrics",
            confidence: 0.65
        ))

        // Rule 19: State update performance
        rules.append(ValidationRule(
            name: "state_update_performance",
            category: .performance,
            severity: .info,
            pattern: nil,
            description: "Frequent state updates (@State variables) should be tracked to identify performance bottlenecks",
            fix: "Use .awareState() on views with frequently updating state to monitor update frequency and render performance",
            confidence: 0.6
        ))

        // Rule 20: Heavy computation warning
        rules.append(ValidationRule(
            name: "heavy_computation_warning",
            category: .performance,
            severity: .warning,
            pattern: nil,
            description: "Expensive computations in view body should be avoided (use computed properties or @State)",
            fix: "Move heavy computation to background queue or use .task {} modifier. Track with .awareMetadata() if unavoidable",
            confidence: 0.7
        ))

        // MARK: - State Machine Validation Rules (v3.1+)

        // Rule 21: Conflicting state detection
        rules.append(ValidationRule(
            name: "conflicting_state_detection",
            category: .consistency,
            severity: .error,
            pattern: nil,
            description: "Views should not have conflicting state combinations (e.g., isLoading && hasError simultaneously)",
            fix: "Use .awareState() to track all states and ensure mutually exclusive states are properly managed with enums or state machine patterns",
            confidence: 0.85
        ))

        // Rule 22: State initialization required
        rules.append(ValidationRule(
            name: "state_initialization_required",
            category: .correctness,
            severity: .warning,
            pattern: #"@State\s+(private\s+)?var\s+(\w+)(?!\s*=)"#,
            description: "@State variables should be initialized with default values to prevent undefined behavior",
            fix: "Initialize @State variables: @State private var myState = defaultValue",
            confidence: 0.9
        ))

        // Rule 23: State transition tracking
        rules.append(ValidationRule(
            name: "state_transition_tracking",
            category: .completeness,
            severity: .info,
            pattern: nil,
            description: "State transitions (e.g., loading → loaded → error) should be tracked with .awareState() at each transition",
            fix: "Add .awareState() calls after each state change to enable transition monitoring and debugging",
            confidence: 0.7
        ))

        // Rule 24: Unidirectional data flow
        rules.append(ValidationRule(
            name: "unidirectional_data_flow",
            category: .structure,
            severity: .info,
            pattern: nil,
            description: "State updates should follow unidirectional data flow (actions → state → view)",
            fix: "Move state mutations to action handlers and track with .awareButton() + .awareState() pattern",
            confidence: 0.65
        ))

        // Rule 25: State dependency tracking
        rules.append(ValidationRule(
            name: "state_dependency_tracking",
            category: .completeness,
            severity: .info,
            pattern: nil,
            description: "Derived state (computed from other @State) should be tracked to understand view dependencies",
            fix: "Track derived state with .awareState() even if computed, to enable dependency analysis",
            confidence: 0.6
        ))

        // Rule 26: Loading state pattern
        rules.append(ValidationRule(
            name: "loading_state_pattern",
            category: .structure,
            severity: .info,
            pattern: #"@State\s+.*\s+isLoading"#,
            description: "Loading states should follow standard pattern: isLoading, loadingMessage, and error states",
            fix: "Use complete loading state pattern: @State isLoading, @State loadingMessage, @State error with .awareState() tracking",
            confidence: 0.75
        ))

        // Rule 27: Error state handling
        rules.append(ValidationRule(
            name: "error_state_handling",
            category: .correctness,
            severity: .warning,
            pattern: #"@State\s+.*\s+(error|errorMessage)"#,
            description: "Error states should be tracked and displayed to users with proper recovery actions",
            fix: "Track error state with .awareState() and provide .awareButton() for retry/dismiss actions",
            confidence: 0.8
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

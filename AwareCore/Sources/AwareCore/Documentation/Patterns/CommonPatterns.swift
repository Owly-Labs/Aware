//
//  CommonPatterns.swift
//  AwareCore
//
//  Common UI patterns library for protocol-based development.
//  Provides templates and best practices for typical SwiftUI views.
//

import Foundation

/// Common UI pattern template
public struct UIPattern: Codable, Sendable {
    public let name: String
    public let category: PatternCategory
    public let description: String
    public let complexity: PatternComplexity
    public let codeTemplate: String
    public let elements: [String]  // UI elements used
    public let modifiersUsed: [String]
    public let bestPractices: [String]
    public let commonMistakes: [String]
    public let tokenEstimate: Int  // Estimated tokens for instrumented version
    public let exampleUseCases: [String]
}

public enum PatternCategory: String, Codable, Sendable {
    case authentication = "Authentication"
    case forms = "Forms"
    case lists = "Lists"
    case navigation = "Navigation"
    case settings = "Settings"
    case dataEntry = "Data Entry"
    case feedback = "Feedback"
}

public enum PatternComplexity: String, Codable, Sendable {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
}

/// Common patterns library
@MainActor
public struct CommonPatternsLibrary {
    public static let patterns: [UIPattern] = [
        // MARK: - Authentication Patterns

        loginFormPattern(),
        signupFormPattern(),
        forgotPasswordPattern(),

        // MARK: - Form Patterns

        basicFormPattern(),
        multiStepFormPattern(),
        validatedFormPattern(),

        // MARK: - List Patterns

        simpleListPattern(),
        pullToRefreshListPattern(),
        searchableListPattern(),

        // MARK: - Navigation Patterns

        tabbedInterfacePattern(),
        masterDetailPattern(),
        wizardPattern(),

        // MARK: - Settings Patterns

        settingsPanelPattern(),
        preferencesGroupPattern(),

        // MARK: - Feedback Patterns

        loadingStatePattern(),
        errorStatePattern(),
        emptyStatePattern(),
    ]

    // Pattern implementations are in separate files:
    // - AuthenticationPatterns.swift
    // - FormPatterns.swift
    // - ListPatterns.swift
    // - NavigationPatterns.swift
    // - SettingsPatterns.swift
    // - FeedbackPatterns.swift
}

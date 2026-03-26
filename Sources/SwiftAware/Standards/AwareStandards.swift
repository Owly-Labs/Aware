// AwareStandards.swift
// SwiftAware Standards Module
//
// Provides a registry of development standards for consistent
// logging, testing, UI, performance, security, and architecture practices.

import Foundation

// MARK: - Standard Category

/// Categories for organizing development standards.
public enum StandardCategory: String, Sendable, CaseIterable, Codable {
    case logging
    case testing
    case ui
    case performance
    case security
    case architecture
}

// MARK: - Standard Severity

/// Severity levels indicating how strictly a standard should be followed.
public enum StandardSeverity: String, Sendable, CaseIterable, Codable {
    /// Must be followed in all cases.
    case required
    /// Should be followed unless there's a documented reason not to.
    case recommended
    /// Nice to have, follow when practical.
    case optional
}

// MARK: - Aether Standard

/// A development standard with metadata and examples.
public struct AwareStandard: Sendable, Identifiable, Codable {
    public let id: String
    public let category: StandardCategory
    public let severity: StandardSeverity
    public let title: String
    public let description: String
    public let examples: [String]

    public init(
        id: String,
        category: StandardCategory,
        severity: StandardSeverity,
        title: String,
        description: String,
        examples: [String] = []
    ) {
        self.id = id
        self.category = category
        self.severity = severity
        self.title = title
        self.description = description
        self.examples = examples
    }
}

// MARK: - Standards Registry

/// Thread-safe registry for managing and querying development standards.
public actor StandardsRegistry {

    /// Shared singleton instance with built-in standards pre-loaded.
    public static let shared = StandardsRegistry(builtIn: true)

    private var standards: [String: AwareStandard]

    /// Initialize an empty registry.
    public init() {
        self.standards = [:]
    }

    /// Initialize with optional built-in standards.
    public init(builtIn: Bool) {
        if builtIn {
            var dict: [String: AwareStandard] = [:]
            for standard in Self.loggingStandards + Self.testingStandards + Self.performanceStandards {
                dict[standard.id] = standard
            }
            self.standards = dict
        } else {
            self.standards = [:]
        }
    }

    // MARK: - Registration

    /// Register a new standard.
    public func register(_ standard: AwareStandard) {
        standards[standard.id] = standard
    }

    /// Register multiple standards at once.
    public func register(_ newStandards: [AwareStandard]) {
        for standard in newStandards {
            standards[standard.id] = standard
        }
    }

    // MARK: - Queries

    /// Get a standard by ID.
    public func standard(for id: String) -> AwareStandard? {
        standards[id]
    }

    /// Get all standards.
    public func allStandards() -> [AwareStandard] {
        Array(standards.values)
    }

    /// Get standards by category.
    public func standards(in category: StandardCategory) -> [AwareStandard] {
        standards.values.filter { $0.category == category }
    }

    /// Get standards by severity.
    public func standards(with severity: StandardSeverity) -> [AwareStandard] {
        standards.values.filter { $0.severity == severity }
    }

    /// Get standards matching category and severity.
    public func standards(
        in category: StandardCategory,
        with severity: StandardSeverity
    ) -> [AwareStandard] {
        standards.values.filter {
            $0.category == category && $0.severity == severity
        }
    }

    /// Get all required standards.
    public func requiredStandards() -> [AwareStandard] {
        standards(with: .required)
    }
}

// MARK: - Built-in Logging Standards

extension StandardsRegistry {

    /// Pre-built logging standards with emoji conventions.
    public static let loggingStandards: [AwareStandard] = [
        AwareStandard(
            id: "logging.emoji.lifecycle",
            category: .logging,
            severity: .recommended,
            title: "Lifecycle Emoji Convention",
            description: "Use consistent emojis for lifecycle events to enable quick visual scanning of logs.",
            examples: [
                "// View appeared",
                "logger.info(\"appeared\", \"MainView\")",
                "// View disappeared",
                "logger.info(\"disappeared\", \"MainView\")"
            ]
        ),
        AwareStandard(
            id: "logging.emoji.actions",
            category: .logging,
            severity: .recommended,
            title: "Action Emoji Convention",
            description: "Use distinct emojis for user actions and system events.",
            examples: [
                "// User tap",
                "logger.info(\"tapped\", \"SubmitButton\")",
                "// State change",
                "logger.info(\"stateChanged\", \"isLoading: true\")"
            ]
        ),
        AwareStandard(
            id: "logging.structured",
            category: .logging,
            severity: .required,
            title: "Structured Logging",
            description: "Always use structured logging with context rather than string interpolation.",
            examples: [
                "// Good: Structured",
                "logger.error(\"Failed to load\", metadata: [\"userId\": userId])",
                "// Bad: String interpolation",
                "logger.error(\"Failed to load user \\(userId)\")"
            ]
        ),
        AwareStandard(
            id: "logging.levels",
            category: .logging,
            severity: .required,
            title: "Appropriate Log Levels",
            description: "Use appropriate log levels: debug for development, info for events, warning for recoverable issues, error for failures.",
            examples: [
                "logger.debug(\"Cache hit\", metadata: [\"key\": key])",
                "logger.info(\"User logged in\")",
                "logger.warning(\"Retrying request\", metadata: [\"attempt\": 2])",
                "logger.error(\"Request failed\", error: error)"
            ]
        )
    ]
}

// MARK: - Built-in Testing Standards

extension StandardsRegistry {

    /// Pre-built testing standards with tier definitions.
    public static let testingStandards: [AwareStandard] = [
        AwareStandard(
            id: "testing.tier1.smoke",
            category: .testing,
            severity: .required,
            title: "Tier 1: Smoke Tests",
            description: "Fast smoke tests that run on every build. Should complete in under 5 seconds total. Verify app launches and critical paths are reachable.",
            examples: [
                "func testAppLaunches() {",
                "    XCTAssertNotNil(app.windows.firstMatch)",
                "}",
                "",
                "func testMainViewExists() {",
                "    XCTAssertTrue(app.staticTexts[\"Welcome\"].exists)",
                "}"
            ]
        ),
        AwareStandard(
            id: "testing.tier2.structure",
            category: .testing,
            severity: .required,
            title: "Tier 2: Structure Tests",
            description: "Tests that validate view hierarchy and navigation structure. Use text-based log assertions rather than visual comparisons.",
            examples: [
                "func testNavigationStructure() {",
                "    app.buttons[\"Settings\"].tap()",
                "    XCTAssertTrue(app.navigationBars[\"Settings\"].exists)",
                "}"
            ]
        ),
        AwareStandard(
            id: "testing.tier3.visual",
            category: .testing,
            severity: .optional,
            title: "Tier 3: Visual Tests",
            description: "Tests that assert visual properties like colors, fonts, and frames. Use text-based assertions with logged values rather than screenshot comparisons.",
            examples: [
                "func testButtonStyling() async {",
                "    let style = await UILogger.shared.capturedStyle(\"SubmitButton\")",
                "    XCTAssertEqual(style.backgroundColor, \"#007AFF\")",
                "}"
            ]
        ),
        AwareStandard(
            id: "testing.naming",
            category: .testing,
            severity: .recommended,
            title: "Test Naming Convention",
            description: "Use descriptive test names that explain the scenario and expected outcome.",
            examples: [
                "// Good: Descriptive",
                "func testLogin_withValidCredentials_showsHomePage()",
                "func testLogin_withInvalidPassword_showsError()",
                "",
                "// Bad: Vague",
                "func testLogin()",
                "func testLoginError()"
            ]
        )
    ]
}

// MARK: - Built-in Performance Standards

extension StandardsRegistry {

    /// Pre-built performance standards with baselines.
    public static let performanceStandards: [AwareStandard] = [
        AwareStandard(
            id: "performance.launch",
            category: .performance,
            severity: .required,
            title: "App Launch Time",
            description: "Cold launch should complete in under 1 second. Warm launch should complete in under 400ms.",
            examples: [
                "// Measure with Instruments or XCTest",
                "measure(metrics: [XCTApplicationLaunchMetric()]) {",
                "    app.launch()",
                "}"
            ]
        ),
        AwareStandard(
            id: "performance.navigation",
            category: .performance,
            severity: .required,
            title: "Navigation Response Time",
            description: "Navigation transitions should complete in under 300ms. Views should be interactive within 100ms of appearing.",
            examples: [
                "// Target: < 300ms for transition",
                "// Target: < 100ms for interactivity"
            ]
        ),
        AwareStandard(
            id: "performance.memory",
            category: .performance,
            severity: .recommended,
            title: "Memory Usage",
            description: "Base memory footprint should stay under 50MB. Avoid memory leaks by using weak references in closures and delegates.",
            examples: [
                "// Use weak self in closures",
                "task = Task { [weak self] in",
                "    await self?.loadData()",
                "}",
                "",
                "// Use weak delegates",
                "weak var delegate: SomeDelegate?"
            ]
        ),
        AwareStandard(
            id: "performance.scrolling",
            category: .performance,
            severity: .required,
            title: "Scrolling Performance",
            description: "Maintain 60fps during scrolling. Avoid blocking the main thread with heavy computations.",
            examples: [
                "// Offload heavy work",
                "Task.detached(priority: .userInitiated) {",
                "    let result = await heavyComputation()",
                "    await MainActor.run {",
                "        self.updateUI(with: result)",
                "    }",
                "}"
            ]
        )
    ]
}

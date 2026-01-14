//
//  TokenEfficiencyBenchmarks.swift
//  Aware - Performance Benchmarks
//
//  Measures and validates token efficiency claims (99.3% reduction vs screenshots).
//

import XCTest
@testable import AwareCore

/// Benchmarks to validate and document token efficiency
@MainActor
final class TokenEfficiencyBenchmarks: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        Aware.shared.reset()
    }

    // MARK: - Scenario Benchmarks

    func testLoginFormTokenEfficiency() async {
        // GIVEN: A typical login form
        setupLoginForm()

        // WHEN: We capture snapshots in different formats
        let compact = Aware.shared.captureSnapshot(format: .compact)
        let text = Aware.shared.captureSnapshot(format: .text)
        let json = Aware.shared.captureSnapshot(format: .json)

        // THEN: Calculate token counts
        let results = BenchmarkResult(
            scenario: "Login Form",
            compactChars: compact.content.count,
            compactTokens: compact.content.count / 4,
            textChars: text.content.count,
            textTokens: text.content.count / 4,
            jsonChars: json.content.count,
            jsonTokens: json.content.count / 4,
            screenshotTokens: 15000  // 2048x1536 baseline
        )

        results.print()
        results.assertEfficiency()
    }

    func testDashboardViewTokenEfficiency() async {
        // GIVEN: A dashboard with multiple widgets
        setupDashboardView()

        let compact = Aware.shared.captureSnapshot(format: .compact)
        let text = Aware.shared.captureSnapshot(format: .text)
        let json = Aware.shared.captureSnapshot(format: .json)

        let results = BenchmarkResult(
            scenario: "Dashboard (5 widgets)",
            compactChars: compact.content.count,
            compactTokens: compact.content.count / 4,
            textChars: text.content.count,
            textTokens: text.content.count / 4,
            jsonChars: json.content.count,
            jsonTokens: json.content.count / 4,
            screenshotTokens: 15000
        )

        results.print()
        results.assertEfficiency()
    }

    func testListViewTokenEfficiency() async {
        // GIVEN: A list with 20 items
        setupListView(itemCount: 20)

        let compact = Aware.shared.captureSnapshot(format: .compact)
        let text = Aware.shared.captureSnapshot(format: .text)
        let json = Aware.shared.captureSnapshot(format: .json)

        let results = BenchmarkResult(
            scenario: "List View (20 items)",
            compactChars: compact.content.count,
            compactTokens: compact.content.count / 4,
            textChars: text.content.count,
            textTokens: text.content.count / 4,
            jsonChars: json.content.count,
            jsonTokens: json.content.count / 4,
            screenshotTokens: 15000
        )

        results.print()
        results.assertEfficiency()
    }

    func testMultiStepFormTokenEfficiency() async {
        // GIVEN: A multi-step form (wizard)
        setupMultiStepForm()

        let compact = Aware.shared.captureSnapshot(format: .compact)
        let text = Aware.shared.captureSnapshot(format: .text)
        let json = Aware.shared.captureSnapshot(format: .json)

        let results = BenchmarkResult(
            scenario: "Multi-Step Form (3 steps)",
            compactChars: compact.content.count,
            compactTokens: compact.content.count / 4,
            textChars: text.content.count,
            textTokens: text.content.count / 4,
            jsonChars: json.content.count,
            jsonTokens: json.content.count / 4,
            screenshotTokens: 15000
        )

        results.print()
        results.assertEfficiency()
    }

    // MARK: - Cost Analysis

    func testCostSavingsCalculation() async {
        // GIVEN: Various test scenarios
        let scenarios: [(name: String, setup: () -> Void)] = [
            ("Login Form", setupLoginForm),
            ("Dashboard", setupDashboardView),
            ("List (20 items)", { self.setupListView(itemCount: 20) }),
            ("Multi-Step Form", setupMultiStepForm)
        ]

        var totalCompactTokens = 0
        var totalScreenshotTokens = 0

        print("\n📊 Token Efficiency Report")
        print("=" * 60)

        for (name, setup) in scenarios {
            Aware.shared.reset()
            setup()

            let compact = Aware.shared.captureSnapshot(format: .compact)
            let compactTokens = compact.content.count / 4
            let screenshotTokens = 15000

            totalCompactTokens += compactTokens
            totalScreenshotTokens += screenshotTokens

            let reduction = Double(screenshotTokens - compactTokens) / Double(screenshotTokens) * 100

            print("\n\(name):")
            print("  Aware:      \(compactTokens) tokens")
            print("  Screenshot: \(screenshotTokens) tokens")
            print("  Reduction:  \(String(format: "%.1f", reduction))%")
        }

        // Calculate overall savings
        let avgCompact = totalCompactTokens / scenarios.count
        let avgScreenshot = totalScreenshotTokens / scenarios.count
        let overallReduction = Double(avgScreenshot - avgCompact) / Double(avgScreenshot) * 100

        // Cost calculation (at $3/M input tokens)
        let costPerTest_Screenshot = Double(avgScreenshot) * 0.003 / 1000
        let costPerTest_Aware = Double(avgCompact) * 0.003 / 1000
        let savings_per1000Tests = (costPerTest_Screenshot - costPerTest_Aware) * 1000

        print("\n" + "=" * 60)
        print("Overall Results:")
        print("  Average Aware tokens:      \(avgCompact)")
        print("  Average screenshot tokens: \(avgScreenshot)")
        print("  Average reduction:         \(String(format: "%.1f", overallReduction))%")
        print("\nCost Analysis (1000 tests):")
        print("  Screenshot cost: $\(String(format: "%.2f", costPerTest_Screenshot * 1000))")
        print("  Aware cost:      $\(String(format: "%.2f", costPerTest_Aware * 1000))")
        print("  Savings:         $\(String(format: "%.2f", savings_per1000Tests))")
        print("=" * 60 + "\n")

        XCTAssertGreaterThan(overallReduction, 99.0, "Should achieve >99% reduction")
        XCTAssertGreaterThan(savings_per1000Tests, 40.0, "Should save >$40 per 1000 tests")
    }

    // MARK: - Format Comparison

    func testFormatComparison() async {
        // GIVEN: A standard view
        setupLoginForm()

        // WHEN: We generate all formats
        let formats: [(name: String, format: AwareSnapshotFormat)] = [
            ("Compact", .compact),
            ("Text", .text),
            ("JSON", .json),
            ("Markdown", .markdown)
        ]

        print("\n📋 Format Comparison")
        print("=" * 60)

        for (name, format) in formats {
            let snapshot = Aware.shared.captureSnapshot(format: format)
            let tokens = snapshot.content.count / 4

            print("\n\(name):")
            print("  Characters: \(snapshot.content.count)")
            print("  Est. Tokens: \(tokens)")
            print("  Use Case: \(format.useCaseDescription)")

            if format == .compact {
                print("  → Recommended for LLM testing ✅")
            }
        }

        print("\n" + "=" * 60 + "\n")
    }

    // MARK: - Benchmark Report Generation

    func testGenerateMarkdownReport() async throws {
        // Generate comprehensive report
        let scenarios = [
            ("Login Form", setupLoginForm),
            ("Dashboard", setupDashboardView),
            ("List View", { self.setupListView(itemCount: 20) }),
            ("Multi-Step Form", setupMultiStepForm)
        ]

        var results: [BenchmarkResult] = []

        for (name, setup) in scenarios {
            Aware.shared.reset()
            setup()

            let compact = Aware.shared.captureSnapshot(format: .compact)
            let text = Aware.shared.captureSnapshot(format: .text)
            let json = Aware.shared.captureSnapshot(format: .json)

            let result = BenchmarkResult(
                scenario: name,
                compactChars: compact.content.count,
                compactTokens: compact.content.count / 4,
                textChars: text.content.count,
                textTokens: text.content.count / 4,
                jsonChars: json.content.count,
                jsonTokens: json.content.count / 4,
                screenshotTokens: 15000
            )

            results.append(result)
        }

        let report = TokenEfficiencyReport(results: results)
        let markdown = report.toMarkdown()

        // Write to file
        let reportPath = "token-efficiency-report.md"
        try markdown.write(toFile: reportPath, atomically: true, encoding: .utf8)

        print("📄 Report saved to: \(reportPath)")
        print("\nPreview:\n")
        print(markdown.prefix(500))
        print("...\n")
    }

    // MARK: - Setup Helpers

    private func setupLoginForm() {
        Aware.shared.registerView("login-form", label: "Login", isContainer: true)
        Aware.shared.registerView("email", label: "Email", parentId: "login-form")
        Aware.shared.registerView("password", label: "Password", parentId: "login-form")
        Aware.shared.registerView("submit", label: "Login", parentId: "login-form")

        Aware.shared.registerStateTyped("email", key: "value", value: .string(""))
        Aware.shared.registerStateTyped("password", key: "value", value: .string(""))
        Aware.shared.registerStateTyped("submit", key: "isEnabled", value: .bool(true))
        Aware.shared.registerStateTyped("login-form", key: "isLoading", value: .bool(false))
    }

    private func setupDashboardView() {
        Aware.shared.registerView("dashboard", label: "Dashboard", isContainer: true)

        // Navigation
        Aware.shared.registerView("nav", label: "Navigation", isContainer: true, parentId: "dashboard")
        Aware.shared.registerView("home-tab", label: "Home", parentId: "nav")
        Aware.shared.registerView("profile-tab", label: "Profile", parentId: "nav")
        Aware.shared.registerView("settings-tab", label: "Settings", parentId: "nav")

        // Widgets
        for i in 1...5 {
            let widgetId = "widget-\(i)"
            Aware.shared.registerView(widgetId, label: "Widget \(i)", isContainer: true, parentId: "dashboard")
            Aware.shared.registerStateTyped(widgetId, key: "isLoading", value: .bool(false))
            Aware.shared.registerStateTyped(widgetId, key: "data", value: .string("Sample Data"))
        }
    }

    private func setupListView(itemCount: Int) {
        Aware.shared.registerView("list", label: "Items List", isContainer: true)
        Aware.shared.registerView("search", label: "Search", parentId: "list")

        for i in 0..<itemCount {
            let itemId = "item-\(i)"
            Aware.shared.registerView(itemId, label: "Item \(i + 1)", parentId: "list")
            Aware.shared.registerStateTyped(itemId, key: "isSelected", value: .bool(false))
        }

        Aware.shared.registerStateTyped("list", key: "count", value: .int(itemCount))
    }

    private func setupMultiStepForm() {
        Aware.shared.registerView("form", label: "Registration", isContainer: true)
        Aware.shared.registerView("step-1", label: "Personal Info", parentId: "form")
        Aware.shared.registerView("step-2", label: "Contact", parentId: "form")
        Aware.shared.registerView("step-3", label: "Preferences", parentId: "form")
        Aware.shared.registerView("next-btn", label: "Next", parentId: "form")
        Aware.shared.registerView("back-btn", label: "Back", parentId: "form")

        Aware.shared.registerStateTyped("form", key: "currentStep", value: .int(1))
        Aware.shared.registerStateTyped("form", key: "totalSteps", value: .int(3))
        Aware.shared.registerStateTyped("form", key: "isComplete", value: .bool(false))
    }
}

// MARK: - Supporting Types

struct BenchmarkResult {
    let scenario: String
    let compactChars: Int
    let compactTokens: Int
    let textChars: Int
    let textTokens: Int
    let jsonChars: Int
    let jsonTokens: Int
    let screenshotTokens: Int

    var compactReduction: Double {
        Double(screenshotTokens - compactTokens) / Double(screenshotTokens) * 100
    }

    func print() {
        Swift.print("\n🎯 Scenario: \(scenario)")
        Swift.print("   Compact:    \(compactTokens) tokens (\(compactChars) chars)")
        Swift.print("   Text:       \(textTokens) tokens (\(textChars) chars)")
        Swift.print("   JSON:       \(jsonTokens) tokens (\(jsonChars) chars)")
        Swift.print("   Screenshot: \(screenshotTokens) tokens (baseline)")
        Swift.print("   Reduction:  \(String(format: "%.1f", compactReduction))%")
    }

    func assertEfficiency() {
        XCTAssertGreaterThan(compactReduction, 99.0,
            "\(scenario) should achieve >99% reduction, got \(String(format: "%.1f", compactReduction))%")
    }
}

struct TokenEfficiencyReport {
    let results: [BenchmarkResult]

    func toMarkdown() -> String {
        var lines: [String] = []

        lines.append("# Token Efficiency Report")
        lines.append("")
        lines.append("**Generated:** \(ISO8601DateFormatter().string(from: Date()))")
        lines.append("**Framework:** Aware v3.1.0-alpha")
        lines.append("")

        lines.append("## Executive Summary")
        lines.append("")
        let avgReduction = results.map(\.compactReduction).reduce(0, +) / Double(results.count)
        lines.append("- **Average Token Reduction:** \(String(format: "%.1f", avgReduction))%")
        lines.append("- **Test Scenarios:** \(results.count)")
        lines.append("")

        lines.append("## Detailed Results")
        lines.append("")
        lines.append("| Scenario | Compact | Screenshot | Reduction |")
        lines.append("|----------|---------|------------|-----------|")

        for result in results {
            lines.append("| \(result.scenario) | \(result.compactTokens) | \(result.screenshotTokens) | \(String(format: "%.1f", result.compactReduction))% |")
        }

        lines.append("")
        lines.append("## Cost Analysis")
        lines.append("")

        let avgCompact = results.map(\.compactTokens).reduce(0, +) / results.count
        let avgScreenshot = results.map(\.screenshotTokens).reduce(0, +) / results.count

        let costScreenshot = Double(avgScreenshot) * 0.003 / 1000 * 1000  // Per 1000 tests
        let costAware = Double(avgCompact) * 0.003 / 1000 * 1000
        let savings = costScreenshot - costAware

        lines.append("**Cost per 1000 tests** (at $3/M input tokens):")
        lines.append("")
        lines.append("- Screenshot-based: $\(String(format: "%.2f", costScreenshot))")
        lines.append("- Aware-based: $\(String(format: "%.2f", costAware))")
        lines.append("- **Savings: $\(String(format: "%.2f", savings))**")
        lines.append("")

        lines.append("---")
        lines.append("*Generated by Aware Token Efficiency Benchmarks*")

        return lines.joined(separator: "\n")
    }
}

extension AwareSnapshotFormat {
    var useCaseDescription: String {
        switch self {
        case .compact: return "LLM testing, minimal tokens"
        case .text: return "Human-readable debugging"
        case .json: return "Structured data, API integration"
        case .markdown: return "Documentation, reports"
        }
    }
}

// String repeat helper
extension String {
    static func * (lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}

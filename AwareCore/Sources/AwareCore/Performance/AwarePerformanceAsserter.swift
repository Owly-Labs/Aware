//
//  AwarePerformanceAsserter.swift
//  AwareCore
//
//  Budget-based performance assertions for LLM testing.
//  Enforces performance SLAs for snapshots, actions, and queries.
//

import Foundation

// MARK: - AwarePerformanceAsserter

/// Budget-based performance assertions for LLM testing
@MainActor
public class AwarePerformanceAsserter {
    public static let shared = AwarePerformanceAsserter()

    // MARK: - Budget Levels

    /// Lenient budget (500ms snapshot, 300ms action, 50ms query)
    /// **LLM Guidance:** Use for complex operations or initial development
    public static let lenient = PerformanceBudget(
        snapshotMs: 500,
        actionMs: 300,
        queryMs: 50,
        name: "lenient"
    )

    /// Standard budget (250ms snapshot, 150ms action, 20ms query)
    /// **LLM Guidance:** Recommended for most applications
    public static let standard = PerformanceBudget(
        snapshotMs: 250,
        actionMs: 150,
        queryMs: 20,
        name: "standard"
    )

    /// Strict budget (100ms snapshot, 50ms action, 10ms query)
    /// **LLM Guidance:** Use for instant feedback requirements
    public static let strict = PerformanceBudget(
        snapshotMs: 100,
        actionMs: 50,
        queryMs: 10,
        name: "strict"
    )

    private init() {}

    // MARK: - Assertions

    /// Assert metrics are within budget
    ///
    /// **Token Cost:** ~25 tokens per result
    /// **LLM Guidance:** Use after measuring an operation to enforce SLAs
    ///
    /// - Parameters:
    ///   - metrics: Performance metrics to check
    ///   - budget: Budget to check against
    /// - Returns: Assertion result with pass/fail status
    public func assertWithinBudget(
        _ metrics: PerformanceMetrics,
        budget: PerformanceBudget
    ) async -> PerformanceAssertionResult {
        let budgetMs: Int

        // Determine budget based on operation name
        if metrics.name.contains("snapshot") {
            budgetMs = budget.snapshotMs
        } else if metrics.name.contains("action") || metrics.name.contains("tap") || metrics.name.contains("type") {
            budgetMs = budget.actionMs
        } else if metrics.name.contains("query") || metrics.name.contains("find") {
            budgetMs = budget.queryMs
        } else {
            // Default to action budget for unknown operations
            budgetMs = budget.actionMs
        }

        let actualMs = Int(metrics.duration * 1000)
        let passed = actualMs <= budgetMs
        let overrunMs = passed ? nil : actualMs - budgetMs

        return PerformanceAssertionResult(
            passed: passed,
            actualMs: actualMs,
            budgetMs: budgetMs,
            overrunMs: overrunMs,
            message: passed
                ? "✓ '\(metrics.name)' within budget: \(actualMs)ms <= \(budgetMs)ms (\(budget.name))"
                : "✗ '\(metrics.name)' exceeded budget by \(overrunMs!)ms: \(actualMs)ms > \(budgetMs)ms (\(budget.name))"
        )
    }

    /// Assert snapshot performance within budget
    ///
    /// **Token Cost:** ~30 tokens per result
    /// **LLM Guidance:** Use to enforce snapshot generation SLAs
    ///
    /// - Parameters:
    ///   - format: Snapshot format being tested
    ///   - budget: Budget to check against
    /// - Returns: Assertion result
    public func assertSnapshotWithinBudget(
        format: String,
        budget: PerformanceBudget
    ) async -> PerformanceAssertionResult {
        let metrics = await AwarePerformanceMonitor.shared.measureSnapshot(format: format)
        return await assertWithinBudget(metrics, budget: budget)
    }

    /// Assert action performance within budget
    ///
    /// **Token Cost:** ~30 tokens per result
    /// **LLM Guidance:** Use to enforce action execution SLAs
    ///
    /// - Parameters:
    ///   - action: Async action to measure and assert
    ///   - budget: Budget to check against
    /// - Returns: Assertion result
    public func assertActionWithinBudget(
        _ action: () async throws -> Void,
        budget: PerformanceBudget
    ) async -> PerformanceAssertionResult {
        let metrics = await AwarePerformanceMonitor.shared.measureAction(action)
        return await assertWithinBudget(metrics, budget: budget)
    }

    /// Assert query performance within budget
    ///
    /// **Token Cost:** ~30 tokens per result
    /// **LLM Guidance:** Use to enforce query execution SLAs
    ///
    /// - Parameters:
    ///   - query: Async query to measure and assert
    ///   - budget: Budget to check against
    /// - Returns: Assertion result
    public func assertQueryWithinBudget(
        _ query: () async throws -> Void,
        budget: PerformanceBudget
    ) async throws -> PerformanceAssertionResult {
        let (_, metrics) = try await AwarePerformanceMonitor.shared.measure(name: "query", operation: query)
        return await assertWithinBudget(metrics, budget: budget)
    }

    /// Assert multiple operations are within budget
    ///
    /// **Token Cost:** ~N * 30 tokens where N = number of operations
    /// **LLM Guidance:** Use for batch performance testing
    ///
    /// - Parameters:
    ///   - operations: Dictionary of operation name to async operation
    ///   - budget: Budget to check against
    /// - Returns: Dictionary of operation name to assertion result
    public func assertBatchWithinBudget(
        _ operations: [String: () async throws -> Void],
        budget: PerformanceBudget
    ) async -> [String: PerformanceAssertionResult] {
        var results: [String: PerformanceAssertionResult] = [:]

        for (name, operation) in operations {
            // Use try? to measure even if operation fails
            let (_, metrics) = (try? await AwarePerformanceMonitor.shared.measure(name: name, operation: operation)) ?? ((), PerformanceMetrics(name: name, startTime: Date(), endTime: Date(), duration: 0))
            results[name] = await assertWithinBudget(metrics, budget: budget)
        }

        return results
    }

    /// Create custom budget
    ///
    /// **LLM Guidance:** Use when standard budgets don't fit your requirements
    ///
    /// - Parameters:
    ///   - snapshotMs: Snapshot budget in milliseconds
    ///   - actionMs: Action budget in milliseconds
    ///   - queryMs: Query budget in milliseconds
    ///   - name: Budget name for identification
    /// - Returns: Custom performance budget
    public static func customBudget(
        snapshotMs: Int,
        actionMs: Int,
        queryMs: Int,
        name: String = "custom"
    ) -> PerformanceBudget {
        return PerformanceBudget(
            snapshotMs: snapshotMs,
            actionMs: actionMs,
            queryMs: queryMs,
            name: name
        )
    }
}

// MARK: - Performance Budget

/// Performance budget for different operation types
public struct PerformanceBudget: Sendable {
    /// Snapshot generation budget (milliseconds)
    public let snapshotMs: Int

    /// Action execution budget (milliseconds)
    public let actionMs: Int

    /// Query execution budget (milliseconds)
    public let queryMs: Int

    /// Budget name for identification
    public let name: String

    public init(snapshotMs: Int, actionMs: Int, queryMs: Int, name: String) {
        self.snapshotMs = snapshotMs
        self.actionMs = actionMs
        self.queryMs = queryMs
        self.name = name
    }

    /// Human-readable description (~20 tokens)
    public var description: String {
        return "\(name): snapshot \(snapshotMs)ms, action \(actionMs)ms, query \(queryMs)ms"
    }

    /// Compact description (~10 tokens)
    public var compactDescription: String {
        return "\(name): \(snapshotMs)/\(actionMs)/\(queryMs)ms"
    }
}

// MARK: - Performance Assertion Result

/// Result of a performance assertion
public struct PerformanceAssertionResult: Sendable {
    /// Whether the assertion passed
    public let passed: Bool

    /// Actual duration (milliseconds)
    public let actualMs: Int

    /// Budget duration (milliseconds)
    public let budgetMs: Int

    /// How much over budget (if failed)
    public let overrunMs: Int?

    /// Human-readable message (~25 tokens)
    public let message: String

    public init(passed: Bool, actualMs: Int, budgetMs: Int, overrunMs: Int?, message: String) {
        self.passed = passed
        self.actualMs = actualMs
        self.budgetMs = budgetMs
        self.overrunMs = overrunMs
        self.message = message
    }

    /// Compact description for token efficiency (~15 tokens)
    public var compactDescription: String {
        return passed
            ? "✓ \(actualMs)ms <= \(budgetMs)ms"
            : "✗ \(actualMs)ms > \(budgetMs)ms (+\(overrunMs!)ms)"
    }

    /// Detailed breakdown for LLM analysis (~30 tokens)
    public var detailedDescription: String {
        var parts = [
            "Result: \(passed ? "PASS" : "FAIL")",
            "Actual: \(actualMs)ms",
            "Budget: \(budgetMs)ms"
        ]

        if let overrun = overrunMs {
            parts.append("Overrun: +\(overrun)ms (\(String(format: "%.1f", Double(overrun) / Double(budgetMs) * 100))%)")
        }

        return parts.joined(separator: ", ")
    }
}

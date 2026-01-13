//
//  AwareTestRunner.swift
//  Aware
//
//  Test orchestration for Aware-instrumented views.
//

import Foundation
import SwiftUI
import Aware

// MARK: - Test Suite

/// A collection of test cases
public struct TestSuite: Identifiable {
    public let id = UUID()
    public let name: String
    public let tests: [TestCase]

    public init(name: String, tests: [TestCase]) {
        self.name = name
        self.tests = tests
    }

    public var testCount: Int { tests.count }
}

// MARK: - Test Case

/// A single test case with steps and assertions
public struct TestCase: Identifiable {
    public let id: String
    public let name: String
    public let steps: [TestStep]
    public let assertions: [TestAssertion]

    public init(
        id: String = UUID().uuidString,
        name: String,
        steps: [TestStep] = [],
        assertions: [TestAssertion] = []
    ) {
        self.id = id
        self.name = name
        self.steps = steps
        self.assertions = assertions
    }
}

// MARK: - Test Step

/// A single step in a test case
public enum TestStep {
    case navigate(to: String)
    case tap(viewId: String)
    case type(viewId: String, text: String)
    case wait(seconds: Double)
    case waitForState(viewId: String, key: String, value: String, timeout: TimeInterval)
    case waitForVisible(viewId: String, timeout: TimeInterval)
    case captureSnapshot(name: String)

    public var description: String {
        switch self {
        case .navigate(let to): return "Navigate to '\(to)'"
        case .tap(let viewId): return "Tap '\(viewId)'"
        case .type(let viewId, let text): return "Type '\(text)' into '\(viewId)'"
        case .wait(let seconds): return "Wait \(seconds)s"
        case .waitForState(let viewId, let key, let value, _): return "Wait for '\(viewId).\(key)' = '\(value)'"
        case .waitForVisible(let viewId, _): return "Wait for '\(viewId)' visible"
        case .captureSnapshot(let name): return "Capture snapshot '\(name)'"
        }
    }
}

// MARK: - Test Assertion

/// An assertion to validate test expectations
public enum TestAssertion {
    case visible(viewId: String)
    case exists(viewId: String)
    case stateEquals(viewId: String, key: String, value: String)
    case textContains(viewId: String, substring: String)
    case noStaleness
    case viewCount(atLeast: Int)
    case tappable(viewId: String)

    public var description: String {
        switch self {
        case .visible(let viewId): return "Assert '\(viewId)' is visible"
        case .exists(let viewId): return "Assert '\(viewId)' exists"
        case .stateEquals(let viewId, let key, let value): return "Assert '\(viewId).\(key)' = '\(value)'"
        case .textContains(let viewId, let substring): return "Assert '\(viewId)' contains '\(substring)'"
        case .noStaleness: return "Assert no staleness"
        case .viewCount(let minimum): return "Assert view count >= \(minimum)"
        case .tappable(let viewId): return "Assert '\(viewId)' is tappable"
        }
    }
}

// MARK: - Test Runner

/// Orchestrates test execution for Aware-instrumented views
@MainActor
public class AwareTestRunner: ObservableObject {

    public static let shared = AwareTestRunner()

    // MARK: - State

    @Published public private(set) var isRunning = false
    @Published public private(set) var currentTest: String?
    @Published public private(set) var progress: Double = 0

    private var aware: Aware { Aware.shared }
    private var startTime: Date?
    private var snapshots: [String: AwareSnapshotResult] = [:]

    public init() {}

    // MARK: - Suite Execution

    /// Run a complete test suite
    public func runSuite(_ suite: TestSuite) async -> TestRun {
        isRunning = true
        startTime = Date()
        progress = 0

        var results: [TestResult] = []
        let totalTests = suite.tests.count

        for (index, test) in suite.tests.enumerated() {
            currentTest = test.name
            progress = Double(index) / Double(totalTests)

            let result = await runTest(test, runId: suite.id.uuidString)
            results.append(result)

            // Track coverage for each visited view
            for step in test.steps {
                if case .navigate(let viewId) = step {
                    AwareCoverage.shared.trackVisit(viewId)
                }
                if case .tap(let viewId) = step {
                    AwareCoverage.shared.trackAction(viewId, action: "tap")
                }
            }
        }

        isRunning = false
        currentTest = nil
        progress = 1.0

        let durationMs = Int((Date().timeIntervalSince(startTime ?? Date())) * 1000)
        let passed = results.filter { $0.passed }.count
        let coverage = AwareCoverage.shared.coveragePercent

        return TestRun(
            projectId: "aware",
            testsTotal: results.count,
            testsPassed: passed,
            testsFailed: results.count - passed,
            durationMs: durationMs,
            coveragePercent: coverage,
            results: results
        )
    }

    /// Run a single test case
    public func runTest(_ test: TestCase, runId: String) async -> TestResult {
        let testStartTime = Date()
        var snapshotBefore: String?
        var snapshotAfter: String?
        var errorMessage: String?
        var assertionResults: [AssertionResult] = []

        // Capture before snapshot
        snapshotBefore = aware.captureSnapshot(format: .compact).content

        // Execute steps
        for step in test.steps {
            do {
                try await executeStep(step)
            } catch {
                errorMessage = "Step failed: \(step.description) - \(error.localizedDescription)"
                break
            }
        }

        // Run assertions only if no step errors
        if errorMessage == nil {
            for assertion in test.assertions {
                let result = await executeAssertion(assertion)
                assertionResults.append(result)

                if !result.passed {
                    errorMessage = result.message
                }
            }
        }

        // Capture after snapshot
        snapshotAfter = aware.captureSnapshot(format: .compact).content

        let durationMs = Int((Date().timeIntervalSince(testStartTime)) * 1000)
        let passed = errorMessage == nil && assertionResults.allSatisfy { $0.passed }

        return TestResult(
            runId: runId,
            testName: test.name,
            passed: passed,
            durationMs: durationMs,
            assertions: assertionResults,
            snapshotBefore: snapshotBefore,
            snapshotAfter: snapshotAfter,
            errorMessage: errorMessage
        )
    }

    // MARK: - Step Execution

    private func executeStep(_ step: TestStep) async throws {
        switch step {
        case .navigate(let viewId):
            _ = await aware.tapDirect(viewId)
            try await Task.sleep(for: .milliseconds(300))

        case .tap(let viewId):
            let result = await aware.tapDirect(viewId)
            if !result.success {
                throw TestRunnerError.actionFailed(result.message)
            }
            try await Task.sleep(for: .milliseconds(100))

        case .type(let viewId, let text):
            // Focus the field
            _ = await aware.tapDirect(viewId)
            try await Task.sleep(for: .milliseconds(100))

            // Type text notification
            NotificationCenter.default.post(
                name: Notification.Name("AwareTextInput"),
                object: nil,
                userInfo: ["viewId": viewId, "text": text]
            )
            try await Task.sleep(for: .milliseconds(100))

        case .wait(let seconds):
            try await Task.sleep(for: .seconds(seconds))

        case .waitForState(let viewId, let key, let value, let timeout):
            let deadline = Date().addingTimeInterval(timeout)
            while Date() < deadline {
                if aware.getStateValue(viewId, key: key) == value {
                    return
                }
                try await Task.sleep(for: .milliseconds(100))
            }
            throw TestRunnerError.timeout("State '\(viewId).\(key)' did not become '\(value)'")

        case .waitForVisible(let viewId, let timeout):
            let deadline = Date().addingTimeInterval(timeout)
            while Date() < deadline {
                if aware.assertVisible(viewId).passed {
                    return
                }
                try await Task.sleep(for: .milliseconds(100))
            }
            throw TestRunnerError.timeout("View '\(viewId)' did not become visible")

        case .captureSnapshot(let name):
            snapshots[name] = aware.captureSnapshot(format: .compact)
        }
    }

    // MARK: - Assertion Execution

    private func executeAssertion(_ assertion: TestAssertion) async -> AssertionResult {
        switch assertion {
        case .visible(let viewId):
            let result = aware.assertVisible(viewId)
            return AssertionResult(
                type: "visible",
                passed: result.passed,
                expected: nil,
                actual: nil,
                message: result.message
            )

        case .exists(let viewId):
            let result = aware.assertExists(viewId)
            return AssertionResult(
                type: "exists",
                passed: result.passed,
                expected: nil,
                actual: nil,
                message: result.message
            )

        case .stateEquals(let viewId, let key, let value):
            let result = aware.assertState(viewId, key: key, equals: value)
            return AssertionResult(
                type: "stateEquals",
                passed: result.passed,
                expected: value,
                actual: aware.getStateValue(viewId, key: key),
                message: result.message
            )

        case .textContains(let viewId, let substring):
            let result = aware.assertTextContains(viewId, substring: substring)
            return AssertionResult(
                type: "textContains",
                passed: result.passed,
                expected: substring,
                actual: nil,
                message: result.message
            )

        case .noStaleness:
            let result = aware.assertNoPropStateStaleness()
            return AssertionResult(
                type: "noStaleness",
                passed: result.passed,
                expected: nil,
                actual: nil,
                message: result.message
            )

        case .viewCount(let minimum):
            let result = aware.assertViewCount(atLeast: minimum)
            return AssertionResult(
                type: "viewCount",
                passed: result.passed,
                expected: String(minimum),
                actual: String(aware.visibleViewCount),
                message: result.message
            )

        case .tappable(let viewId):
            let hasTap = aware.hasDirectAction(viewId)
            return AssertionResult(
                type: "tappable",
                passed: hasTap,
                expected: nil,
                actual: nil,
                message: hasTap ? "'\(viewId)' is tappable" : "'\(viewId)' has no action callback"
            )
        }
    }

    // MARK: - Helpers

    /// Navigate to a view
    public func navigateTo(_ viewId: String) async {
        _ = await aware.tapDirect(viewId)
        try? await Task.sleep(for: .milliseconds(300))
    }

    /// Assert visibility
    public func assertVisible(_ viewId: String) -> Bool {
        aware.assertVisible(viewId).passed
    }

    /// Assert state value
    public func assertState(_ viewId: String, key: String, equals value: String) -> Bool {
        aware.assertState(viewId, key: key, equals: value).passed
    }

    /// Assert tappable
    public func assertTappable(_ viewId: String) -> Bool {
        aware.hasDirectAction(viewId)
    }

    /// Get captured snapshot
    public func getSnapshot(_ name: String) -> AwareSnapshotResult? {
        snapshots[name]
    }

    /// Clear snapshots
    public func clearSnapshots() {
        snapshots.removeAll()
    }
}

// MARK: - Errors

public enum TestRunnerError: Error, LocalizedError {
    case actionFailed(String)
    case timeout(String)
    case assertionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .actionFailed(let message): return "Action failed: \(message)"
        case .timeout(let message): return "Timeout: \(message)"
        case .assertionFailed(let message): return "Assertion failed: \(message)"
        }
    }
}

// MARK: - Aware Extension

extension Aware {
    /// Assert view count is at least minimum
    public func assertViewCount(atLeast minimum: Int) -> AwareAssertionResult {
        let count = visibleViewCount
        if count >= minimum {
            return AwareAssertionResult(passed: true, message: "View count \(count) >= \(minimum)")
        } else {
            return AwareAssertionResult(passed: false, message: "View count \(count) < \(minimum)")
        }
    }
}

// MARK: - Pre-built Test Suites

extension TestSuite {

    /// Smoke test suite - basic navigation and visibility
    public static func smoke() -> TestSuite {
        TestSuite(
            name: "Smoke Tests",
            tests: [
                TestCase(
                    name: "App Launches",
                    assertions: [.viewCount(atLeast: 1)]
                ),
                TestCase(
                    name: "No Staleness on Launch",
                    assertions: [.noStaleness]
                )
            ]
        )
    }

    /// Navigation test suite - all major views accessible
    public static func navigation(tabs: [String]) -> TestSuite {
        var tests: [TestCase] = []

        for tab in tabs {
            tests.append(TestCase(
                name: "Navigate to \(tab)",
                steps: [.tap(viewId: tab)],
                assertions: [.visible(viewId: tab)]
            ))
        }

        return TestSuite(name: "Navigation Tests", tests: tests)
    }

    /// Button functionality test suite
    public static func buttons(buttonIds: [(id: String, expectedAction: String)]) -> TestSuite {
        var tests: [TestCase] = []

        for (buttonId, _) in buttonIds {
            tests.append(TestCase(
                name: "Button \(buttonId) is tappable",
                assertions: [.tappable(viewId: buttonId)]
            ))
        }

        return TestSuite(name: "Button Tests", tests: tests)
    }
}

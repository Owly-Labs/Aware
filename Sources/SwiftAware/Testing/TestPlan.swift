import Foundation

// MARK: - Test Plan

/// A test plan defines a sequence of steps with expected outcomes
/// Enables plan vs actual comparison during test execution
public struct TestPlan: Sendable {
    public let name: String
    public let description: String?
    public let steps: [TestStep]
    public let tags: [String]

    public init(
        name: String,
        description: String? = nil,
        tags: [String] = [],
        @TestStepBuilder steps: () -> [TestStep]
    ) {
        self.name = name
        self.description = description
        self.tags = tags
        self.steps = steps()
    }

    public init(
        name: String,
        description: String? = nil,
        tags: [String] = [],
        steps: [TestStep]
    ) {
        self.name = name
        self.description = description
        self.tags = tags
        self.steps = steps
    }
}

// MARK: - Test Step

/// A single step in a test plan with expected outcome
public struct TestStep: Sendable, Identifiable {
    public let id: UUID
    public let action: UITestAction
    public let expectation: StepExpectation
    public let description: String?

    public init(
        action: UITestAction,
        expectation: StepExpectation = .success,
        description: String? = nil
    ) {
        self.id = UUID()
        self.action = action
        self.expectation = expectation
        self.description = description
    }
}

// MARK: - Step Expectation

/// Expected outcome of a test step
public enum StepExpectation: Sendable {
    case success
    case failure(reason: String?)
    case viewVisible(id: String)
    case viewHidden(id: String)
    case stateEquals(key: String, value: String)
    case stateChanged(key: String)
    case custom(description: String, validator: @Sendable () async -> Bool)
}

// MARK: - Result Builder

@resultBuilder
public struct TestStepBuilder {
    public static func buildBlock(_ components: TestStep...) -> [TestStep] {
        components
    }

    public static func buildArray(_ components: [[TestStep]]) -> [TestStep] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [TestStep]?) -> [TestStep] {
        component ?? []
    }

    public static func buildEither(first component: [TestStep]) -> [TestStep] {
        component
    }

    public static func buildEither(second component: [TestStep]) -> [TestStep] {
        component
    }
}

// MARK: - Test Plan Runner

/// Executes a test plan and generates plan vs actual comparison
public struct TestPlanRunner {

    public init() {}

    /// Run a test plan and return detailed results
    @MainActor
    public func run(_ plan: TestPlan) async -> TestPlanResult {
        let startTime = Date()
        var stepResults: [StepResult] = []
        let dispatcher = UIActionDispatcher.shared

        dispatcher.clearLog()

        Aware.logger.info("═══════════ TEST PLAN: \(plan.name) ═══════════")
        Aware.logger.info("Steps: \(plan.steps.count)")

        for (index, step) in plan.steps.enumerated() {
            let stepStart = Date()

            Aware.logger.debug("[\(index + 1)/\(plan.steps.count)] \(step.description ?? actionDescription(step.action))")

            // Execute action
            let result = await dispatcher.dispatch(step.action)

            // Validate expectation
            let expectationMet = await validateExpectation(step.expectation, result: result, dispatcher: dispatcher)

            let stepDuration = Date().timeIntervalSince(stepStart)

            let stepResult = StepResult(
                stepId: step.id,
                stepIndex: index,
                action: step.action,
                expectation: step.expectation,
                passed: result.success && expectationMet,
                duration: stepDuration,
                plannedDescription: step.description ?? actionDescription(step.action),
                actualDescription: result.message ?? (result.success ? "Success" : "Failed"),
                discrepancy: result.success && !expectationMet ? "Expectation not met" : nil
            )

            stepResults.append(stepResult)

            // Log comparison
            let status = stepResult.passed ? "✅" : "❌"
            Aware.logger.debug("  PLAN: \(stepResult.plannedDescription)")
            Aware.logger.debug("  ACTUAL: \(status) \(stepResult.actualDescription)")
            if let discrepancy = stepResult.discrepancy {
                Aware.logger.debug("  ⚠️ DISCREPANCY: \(discrepancy)")
            }
        }

        let totalDuration = Date().timeIntervalSince(startTime)
        let passedCount = stepResults.filter { $0.passed }.count

        // Generate summary
        let summary = generateSummary(plan: plan, results: stepResults, duration: totalDuration)

        Aware.logger.info(summary)

        return TestPlanResult(
            planName: plan.name,
            startTime: startTime,
            duration: totalDuration,
            passed: passedCount == plan.steps.count,
            totalSteps: plan.steps.count,
            passedSteps: passedCount,
            failedSteps: plan.steps.count - passedCount,
            stepResults: stepResults,
            planVsActualReport: dispatcher.getPlanVsActualReport()
        )
    }

    @MainActor
    private func validateExpectation(_ expectation: StepExpectation, result: DispatchResult, dispatcher: UIActionDispatcher) async -> Bool {
        switch expectation {
        case .success:
            return result.success

        case .failure:
            return !result.success

        case .viewVisible(let id):
            return dispatcher.isViewVisible(id)

        case .viewHidden(let id):
            return !dispatcher.isViewVisible(id)

        case .stateEquals(let key, let value):
            return dispatcher.getState(key) == value

        case .stateChanged(let key):
            return dispatcher.getState(key) != nil

        case .custom(_, let validator):
            return await validator()
        }
    }

    private func actionDescription(_ action: UITestAction) -> String {
        switch action {
        case .tap(let id): return "Tap '\(id)'"
        case .doubleTap(let id): return "Double-tap '\(id)'"
        case .longPress(let id): return "Long-press '\(id)'"
        case .swipe(let id, let dir): return "Swipe \(dir.rawValue) on '\(id)'"
        case .type(let id, let text): return "Type '\(text)' in '\(id)'"
        case .scroll(let id, let dir): return "Scroll \(dir.rawValue) on '\(id)'"
        case .selectTab(let name): return "Select tab '\(name)'"
        case .selectSubTab(let name): return "Select sub-tab '\(name)'"
        case .wait(let seconds): return "Wait \(seconds)s"
        case .waitForView(let id, let timeout): return "Wait for '\(id)' (\(timeout)s)"
        case .expectVisible(let id): return "Expect '\(id)' visible"
        case .expectHidden(let id): return "Expect '\(id)' hidden"
        case .expectState(let key, let value): return "Expect [\(key)] == '\(value)'"
        case .custom(let name): return "Custom: \(name)"
        case .log(let msg): return "Log: \(msg)"
        }
    }

    private func generateSummary(plan: TestPlan, results: [StepResult], duration: TimeInterval) -> String {
        let passed = results.filter { $0.passed }.count
        let failed = results.count - passed
        let status = failed == 0 ? "✅ PASSED" : "❌ FAILED"

        var summary = """

        ═══════════ PLAN VS ACTUAL SUMMARY ═══════════
        Test Plan: \(plan.name)
        Status: \(status)
        Steps: \(passed)/\(results.count) passed
        Duration: \(String(format: "%.2fs", duration))

        """

        if failed > 0 {
            summary += "FAILURES:\n"
            for result in results where !result.passed {
                summary += "  [\(result.stepIndex + 1)] \(result.plannedDescription)\n"
                summary += "      Expected: Success\n"
                summary += "      Actual: \(result.actualDescription)\n"
                if let discrepancy = result.discrepancy {
                    summary += "      Discrepancy: \(discrepancy)\n"
                }
            }
        }

        summary += "═══════════════════════════════════════════════"
        return summary
    }
}

// MARK: - Step Result

/// Result of executing a single test step
public struct StepResult: Sendable {
    public let stepId: UUID
    public let stepIndex: Int
    public let action: UITestAction
    public let expectation: StepExpectation
    public let passed: Bool
    public let duration: TimeInterval
    public let plannedDescription: String
    public let actualDescription: String
    public let discrepancy: String?
}

// MARK: - Test Plan Result

/// Complete result of running a test plan
public struct TestPlanResult: Sendable {
    public let planName: String
    public let startTime: Date
    public let duration: TimeInterval
    public let passed: Bool
    public let totalSteps: Int
    public let passedSteps: Int
    public let failedSteps: Int
    public let stepResults: [StepResult]
    public let planVsActualReport: String
}

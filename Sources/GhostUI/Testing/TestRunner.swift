import Foundation

/// Coordinates test execution
public actor TestRunner {
    private let config: AwareConfig
    private var registeredTests: [RegisteredTest] = []

    private struct RegisteredTest: Sendable {
        let id: String
        let name: String
        let tier: TestTier
        let testCase: any AwareTestCase
    }

    public init(config: AwareConfig) {
        self.config = config
    }

    /// Register a test case
    public func register<T: AwareTestCase>(_ testCase: T) {
        let test = RegisteredTest(
            id: UUID().uuidString,
            name: String(describing: type(of: testCase)),
            tier: testCase.tier,
            testCase: testCase
        )
        registeredTests.append(test)
    }

    /// Clear all registered tests
    public func clear() {
        registeredTests.removeAll()
    }

    /// Run tests with given options
    public func run(options: RunOptions) async -> TestResult {
        let sessionId = UUID().uuidString
        let startedAt = Date()

        let testsToRun = registeredTests.filter { options.tiers.contains($0.tier) }

        GhostUI.logger.info("Starting test run", metadata: [
            "total": "\(testsToRun.count)",
            "tiers": options.tiers.map { $0.rawValue }.joined(separator: ", ")
        ])

        var results: [TestCaseResult] = []
        var failures: [TestFailure] = []
        var passed = 0
        var failed = 0
        var skipped = 0

        for test in testsToRun {
            let testStart = Date()
            GhostUI.logger.testStarted(test.name, tier: test.tier)

            var status: TestCaseResult.Status = .passed
            var testError: TestError?
            var retries = 0

            while retries <= options.retries {
                do {
                    // Setup
                    try await test.testCase.setup()

                    // Run with timeout
                    let timeout = config.testing.timeout.timeout(for: test.tier)
                    try await withTimeout(seconds: timeout) {
                        try await test.testCase.runTest()
                    }

                    // Teardown
                    try await test.testCase.teardown()

                    status = .passed
                    testError = nil
                    break

                } catch is TimeoutError {
                    status = .timeout
                    testError = TestError(
                        message: "Test timed out",
                        expected: nil,
                        actual: nil,
                        file: nil,
                        line: nil
                    )

                } catch {
                    status = .failed
                    testError = TestError(
                        message: error.localizedDescription,
                        expected: nil,
                        actual: nil,
                        file: nil,
                        line: nil
                    )
                }

                if retries < options.retries {
                    retries += 1
                    let delay = config.testing.useExponentialBackoff
                        ? config.testing.retryDelay * pow(2, Double(retries - 1))
                        : config.testing.retryDelay
                    try? await Task.sleep(for: .seconds(delay))
                } else {
                    break
                }
            }

            let duration = Date().timeIntervalSince(testStart)

            if status == .passed {
                passed += 1
                GhostUI.logger.testPassed(test.name, duration: duration)
            } else {
                failed += 1
                GhostUI.logger.testFailed(test.name, error: testError?.message ?? "Unknown error")

                failures.append(TestFailure(
                    testId: test.id,
                    testName: test.name,
                    tier: test.tier,
                    message: testError?.message ?? "Unknown error",
                    expected: testError?.expected,
                    actual: testError?.actual
                ))

                if options.stopOnFirstFailure {
                    // Mark remaining as skipped
                    let remaining = testsToRun.dropFirst(testsToRun.firstIndex { $0.id == test.id }! + 1)
                    for t in remaining {
                        results.append(TestCaseResult(
                            id: t.id,
                            name: t.name,
                            tier: t.tier,
                            status: .skipped,
                            duration: 0,
                            retries: 0,
                            error: nil
                        ))
                        skipped += 1
                    }
                    break
                }
            }

            results.append(TestCaseResult(
                id: test.id,
                name: test.name,
                tier: test.tier,
                status: status,
                duration: duration,
                retries: retries,
                error: testError
            ))
        }

        let finishedAt = Date()
        let totalDuration = finishedAt.timeIntervalSince(startedAt)

        GhostUI.logger.testSummary(
            passed: passed,
            failed: failed,
            skipped: skipped,
            duration: totalDuration
        )

        // Calculate by-tier summary
        var byTier: [TestTier: TestResult.TierSummary] = [:]
        for tier in TestTier.allCases {
            let tierResults = results.filter { $0.tier == tier }
            if !tierResults.isEmpty {
                byTier[tier] = TestResult.TierSummary(
                    passed: tierResults.filter { $0.status == .passed }.count,
                    failed: tierResults.filter { $0.status == .failed || $0.status == .timeout }.count
                )
            }
        }

        return TestResult(
            session: TestResult.Session(
                id: sessionId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                duration: totalDuration,
                platform: "swift",
                preset: nil,
                buildNumber: config.project.buildNumber
            ),
            summary: TestResult.Summary(
                total: testsToRun.count,
                passed: passed,
                failed: failed,
                skipped: skipped,
                byTier: byTier
            ),
            tests: results,
            failures: failures
        )
    }

    // MARK: - Timeout Helper

    private func withTimeout<T: Sendable>(seconds: Double, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw TimeoutError()
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

private struct TimeoutError: Error {}

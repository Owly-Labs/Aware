//
//  AwareAsyncTesterTests.swift
//  AwareTests
//
//  Comprehensive tests for AwareAsyncTester.
//

import XCTest
@testable import AwareCore

@MainActor
final class AwareAsyncTesterTests: XCTestCase {

    var tester: AwareAsyncTester!

    override func setUp() async throws {
        try await super.setUp()
        tester = AwareAsyncTester.shared

        // Reset configuration
        tester.defaultTimeout = 3.0
        tester.pollingInterval = 0.1
        tester.useExponentialBackoff = true
    }

    // MARK: - Smart Waiting Tests

    func testWaitFor_successImmediately() async throws {
        // Given: A condition that is true immediately
        var conditionCalled = false

        // When: Wait for condition
        let result = try await tester.waitFor(timeout: 1.0, description: "immediate condition") {
            conditionCalled = true
            return true
        }

        // Then: Should succeed on first attempt
        XCTAssertTrue(result.success)
        XCTAssertTrue(conditionCalled)
        XCTAssertEqual(result.attempts, 1)
        XCTAssertLessThan(result.duration, 0.2) // Should be very fast
        XCTAssertTrue(result.message.contains("immediate condition"))
    }

    func testWaitFor_successAfterDelay() async throws {
        // Given: A condition that becomes true after 300ms
        let startTime = Date()

        // When: Wait for condition
        let result = try await tester.waitFor(timeout: 2.0, description: "delayed condition") {
            let elapsed = Date().timeIntervalSince(startTime)
            return elapsed >= 0.3
        }

        // Then: Should succeed after delay
        XCTAssertTrue(result.success)
        XCTAssertGreaterThan(result.attempts, 1)
        XCTAssertGreaterThan(result.duration, 0.3)
        XCTAssertLessThan(result.duration, 0.6) // Should not wait too long
    }

    func testWaitFor_timeout() async throws {
        // Given: A condition that never becomes true

        // When/Then: Should throw timeout error
        do {
            _ = try await tester.waitFor(timeout: 0.5, description: "impossible condition") {
                return false
            }
            XCTFail("Should have thrown timeout error")
        } catch let error as AsyncTestError {
            switch error {
            case .timeout(let desc, let duration):
                XCTAssertEqual(desc, "impossible condition")
                XCTAssertEqual(duration, 0.5, accuracy: 0.1)
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testWaitFor_exponentialBackoff() async throws {
        // Given: Track polling intervals
        var intervals: [TimeInterval] = []
        var lastCheck = Date()
        var attemptCount = 0

        // When: Wait with exponential backoff enabled
        _ = try? await tester.waitFor(timeout: 1.0, pollingInterval: 0.1) {
            let now = Date()
            if attemptCount > 0 {
                intervals.append(now.timeIntervalSince(lastCheck))
            }
            lastCheck = now
            attemptCount += 1
            return false // Never succeed (will timeout)
        }

        // Then: Intervals should increase (exponential backoff)
        XCTAssertGreaterThan(intervals.count, 2)

        // Check that intervals are increasing (with tolerance for timing variance)
        for i in 1..<min(intervals.count, 3) {
            XCTAssertGreaterThan(intervals[i], intervals[i-1] * 0.8) // Allow 20% variance
        }
    }

    func testWaitFor_linearBackoff() async throws {
        // Given: Disable exponential backoff
        tester.useExponentialBackoff = false
        var intervals: [TimeInterval] = []
        var lastCheck = Date()
        var attemptCount = 0

        // When: Wait with linear polling
        _ = try? await tester.waitFor(timeout: 0.5, pollingInterval: 0.1) {
            let now = Date()
            if attemptCount > 0 {
                intervals.append(now.timeIntervalSince(lastCheck))
            }
            lastCheck = now
            attemptCount += 1
            return false
        }

        // Then: Intervals should be consistent
        XCTAssertGreaterThan(intervals.count, 2)

        // Check that intervals are roughly consistent
        for interval in intervals {
            XCTAssertEqual(interval, 0.1, accuracy: 0.05) // 50ms tolerance
        }
    }

    func testWaitFor_progressUpdates() async throws {
        // Given: Monitor progress updates
        var progressValues: [Double] = []

        // When: Wait for condition (will timeout)
        let expectation = expectation(description: "Progress updates")
        expectation.expectedFulfillmentCount = 3

        Task {
            for _ in 0..<3 {
                try await Task.sleep(for: .milliseconds(100))
                progressValues.append(tester.progress)
                expectation.fulfill()
            }
        }

        _ = try? await tester.waitFor(timeout: 0.5) {
            return false
        }

        await fulfillment(of: [expectation], timeout: 1.0)

        // Then: Progress should increase
        XCTAssertGreaterThan(progressValues.count, 0)
        if progressValues.count >= 2 {
            XCTAssertGreaterThan(progressValues[1], progressValues[0])
        }
    }

    // MARK: - Retry Orchestration Tests

    func testRetry_successFirstAttempt() async throws {
        // Given: Action that succeeds immediately
        var callCount = 0

        // When: Retry action
        let result = await tester.retry(maxAttempts: 3, delay: 0.1) {
            callCount += 1
        }

        // Then: Should succeed on first attempt
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.attempts, 1)
        XCTAssertEqual(callCount, 1)
        XCTAssertNil(result.lastError)
        XCTAssertLessThan(result.totalDuration, 0.2)
    }

    func testRetry_successAfterFailures() async throws {
        // Given: Action that succeeds on 3rd attempt
        var attemptCount = 0

        // When: Retry action
        let result = await tester.retry(maxAttempts: 5, delay: 0.1) {
            attemptCount += 1
            if attemptCount < 3 {
                throw NSError(domain: "test", code: 1)
            }
        }

        // Then: Should succeed on 3rd attempt
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.attempts, 3)
        XCTAssertNil(result.lastError)
        XCTAssertGreaterThan(result.totalDuration, 0.2) // At least 2 delays
    }

    func testRetry_maxRetriesExceeded() async throws {
        // Given: Action that always fails
        var attemptCount = 0

        // When: Retry action
        let result = await tester.retry(maxAttempts: 3, delay: 0.05) {
            attemptCount += 1
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }

        // Then: Should fail after max attempts
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.attempts, 3)
        XCTAssertEqual(attemptCount, 3)
        XCTAssertNotNil(result.lastError)
        XCTAssertTrue(result.message.contains("failed after 3 attempts"))
    }

    func testRetry_exponentialBackoff() async throws {
        // Given: Track delays between attempts
        var timestamps: [Date] = []

        // When: Retry with exponential backoff
        _ = await tester.retry(maxAttempts: 4, delay: 0.1, backoff: .exponential) {
            timestamps.append(Date())
            throw NSError(domain: "test", code: 1)
        }

        // Then: Delays should double (100ms, 200ms, 400ms)
        XCTAssertEqual(timestamps.count, 4)

        if timestamps.count >= 3 {
            let delay1 = timestamps[1].timeIntervalSince(timestamps[0])
            let delay2 = timestamps[2].timeIntervalSince(timestamps[1])

            XCTAssertGreaterThan(delay2, delay1 * 1.5) // Should roughly double
        }
    }

    func testRetry_linearBackoff() async throws {
        // Given: Track delays between attempts
        var timestamps: [Date] = []

        // When: Retry with linear backoff
        _ = await tester.retry(maxAttempts: 3, delay: 0.1, backoff: .linear) {
            timestamps.append(Date())
            throw NSError(domain: "test", code: 1)
        }

        // Then: Delays should increase linearly
        XCTAssertEqual(timestamps.count, 3)

        if timestamps.count >= 3 {
            let delay1 = timestamps[1].timeIntervalSince(timestamps[0])
            let delay2 = timestamps[2].timeIntervalSince(timestamps[1])

            // Linear should roughly double as well
            XCTAssertGreaterThan(delay2, delay1 * 1.5)
        }
    }

    func testRetry_fixedBackoff() async throws {
        // Given: Track delays between attempts
        var timestamps: [Date] = []

        // When: Retry with fixed backoff
        _ = await tester.retry(maxAttempts: 3, delay: 0.1, backoff: .fixed) {
            timestamps.append(Date())
            throw NSError(domain: "test", code: 1)
        }

        // Then: Delays should be consistent
        XCTAssertEqual(timestamps.count, 3)

        if timestamps.count >= 3 {
            let delay1 = timestamps[1].timeIntervalSince(timestamps[0])
            let delay2 = timestamps[2].timeIntervalSince(timestamps[1])

            XCTAssertEqual(delay1, delay2, accuracy: 0.05) // Should be same
        }
    }

    func testRetryUntil_conditionMet() async throws {
        // Given: Condition that becomes true after 2 attempts
        var attemptCount = 0
        var conditionValue = false

        // When: Retry until condition met
        let result = await tester.retryUntil(maxAttempts: 5, delay: 0.05) {
            return conditionValue
        } action: {
            attemptCount += 1
            if attemptCount >= 2 {
                conditionValue = true
            }
        }

        // Then: Should succeed when condition met
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.attempts, 2)
    }

    func testRetryUntil_conditionNeverMet() async throws {
        // Given: Condition that never becomes true

        // When: Retry until condition met
        let result = await tester.retryUntil(maxAttempts: 3, delay: 0.05) {
            return false // Never true
        } action: {
            // Action succeeds but condition fails
        }

        // Then: Should fail after max attempts
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.attempts, 3)
    }

    // MARK: - Timeout Budget Tests

    func testWithinBudget_success() async throws {
        // Given: Operation that completes quickly

        // When: Execute within budget
        let result = await tester.withinBudget(0.5, description: "fast operation") {
            try await Task.sleep(for: .milliseconds(100))
        }

        // Then: Should succeed
        XCTAssertTrue(result.success)
        XCTAssertNil(result.overrun)
        XCTAssertGreaterThan(result.duration, 0.1)
        XCTAssertLessThan(result.duration, 0.5)
        XCTAssertTrue(result.message.contains("fast operation"))
    }

    func testWithinBudget_exceeded() async throws {
        // Given: Operation that takes too long

        // When: Execute within budget
        let result = await tester.withinBudget(0.2, description: "slow operation") {
            try await Task.sleep(for: .milliseconds(300))
        }

        // Then: Should fail with overrun
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.overrun)
        XCTAssertGreaterThan(result.overrun!, 0.05) // At least 50ms over
        XCTAssertTrue(result.message.contains("exceeded budget"))
    }

    func testWithinBudget_operationFails() async throws {
        // Given: Operation that throws error

        // When: Execute within budget
        let result = await tester.withinBudget(1.0) {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }

        // Then: Should report failure
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.message.contains("failed"))
        XCTAssertTrue(result.message.contains("Test error"))
    }

    func testWithStages_allSucceed() async throws {
        // Given: Three stages with budgets
        var stage1Complete = false
        var stage2Complete = false
        var stage3Complete = false

        let stages = [
            TimeoutStage(name: "Stage 1", budget: 0.2) {
                try await Task.sleep(for: .milliseconds(50))
                stage1Complete = true
            },
            TimeoutStage(name: "Stage 2", budget: 0.2) {
                try await Task.sleep(for: .milliseconds(50))
                stage2Complete = true
            },
            TimeoutStage(name: "Stage 3", budget: 0.2) {
                try await Task.sleep(for: .milliseconds(50))
                stage3Complete = true
            }
        ]

        // When: Execute with stages
        let result = await tester.withStages(stages: stages) {
            // Main operation
        }

        // Then: All stages should complete
        XCTAssertTrue(result.success)
        XCTAssertTrue(stage1Complete)
        XCTAssertTrue(stage2Complete)
        XCTAssertTrue(stage3Complete)
        XCTAssertLessThan(result.duration, 0.6) // Total budget
    }

    func testWithStages_stageFails() async throws {
        // Given: Three stages, second one fails
        let stages = [
            TimeoutStage(name: "Stage 1", budget: 0.2) {
                try await Task.sleep(for: .milliseconds(50))
            },
            TimeoutStage(name: "Stage 2", budget: 0.1) {
                // This will exceed budget
                try await Task.sleep(for: .milliseconds(200))
            },
            TimeoutStage(name: "Stage 3", budget: 0.2) {
                try await Task.sleep(for: .milliseconds(50))
            }
        ]

        // When: Execute with stages
        let result = await tester.withStages(stages: stages) {
            // Main operation
        }

        // Then: Should fail at stage 2
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.message.contains("Stage 2"))
    }

    // MARK: - Backoff Strategy Tests

    func testBackoffStrategy_fixed() {
        // Given: Fixed backoff
        let strategy = BackoffStrategy.fixed

        // When: Calculate next delays
        let delay1 = strategy.nextDelay(current: 1.0, attempt: 1)
        let delay2 = strategy.nextDelay(current: 1.0, attempt: 2)

        // Then: Should always return same value
        XCTAssertEqual(delay1, 1.0)
        XCTAssertEqual(delay2, 1.0)
    }

    func testBackoffStrategy_linear() {
        // Given: Linear backoff
        let strategy = BackoffStrategy.linear

        // When: Calculate next delay
        let delay = strategy.nextDelay(current: 1.0, attempt: 1)

        // Then: Should double
        XCTAssertEqual(delay, 2.0)
    }

    func testBackoffStrategy_exponential() {
        // Given: Exponential backoff
        let strategy = BackoffStrategy.exponential

        // When: Calculate next delay
        let delay = strategy.nextDelay(current: 1.0, attempt: 1)

        // Then: Should double
        XCTAssertEqual(delay, 2.0)
    }

    func testBackoffStrategy_fibonacci() {
        // Given: Fibonacci backoff
        let strategy = BackoffStrategy.fibonacci

        // When: Calculate next delay
        let delay = strategy.nextDelay(current: 1.0, attempt: 1)

        // Then: Should multiply by golden ratio (~1.618)
        XCTAssertEqual(delay, 1.618, accuracy: 0.001)
    }

    // MARK: - Error Tests

    func testAsyncTestError_timeout() {
        // Given: Timeout error
        let error = AsyncTestError.timeout(description: "test", duration: 5.0)

        // Then: Should have correct description
        XCTAssertTrue(error.errorDescription!.contains("Timeout"))
        XCTAssertTrue(error.errorDescription!.contains("test"))
        XCTAssertTrue(error.errorDescription!.contains("5.0"))
        XCTAssertTrue(error.isRetryable)
    }

    func testAsyncTestError_maxRetriesExceeded() {
        // Given: Max retries error
        let testError = NSError(domain: "test", code: 1)
        let error = AsyncTestError.maxRetriesExceeded(attempts: 5, lastError: testError)

        // Then: Should have correct description
        XCTAssertTrue(error.errorDescription!.contains("Max retries"))
        XCTAssertTrue(error.errorDescription!.contains("5"))
        XCTAssertFalse(error.isRetryable)
    }

    func testAsyncTestError_budgetExceeded() {
        // Given: Budget exceeded error
        let error = AsyncTestError.budgetExceeded(budget: 1.0, actual: 2.5)

        // Then: Should have correct description
        XCTAssertTrue(error.errorDescription!.contains("Budget exceeded"))
        XCTAssertTrue(error.errorDescription!.contains("2.5"))
        XCTAssertTrue(error.errorDescription!.contains("1.0"))
        XCTAssertFalse(error.isRetryable)
    }

    func testAsyncTestError_conditionNotMet() {
        // Given: Condition not met error
        let error = AsyncTestError.conditionNotMet

        // Then: Should have correct description
        XCTAssertTrue(error.errorDescription!.contains("Condition not met"))
        XCTAssertTrue(error.isRetryable)
    }
}

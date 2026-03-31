import Foundation

/// Protocol for GhostUI test cases
///
/// Usage:
/// ```swift
/// class MyTests: AwareTestCase {
///     var tier: TestTier { .smoke }
///
///     func setup() async throws {
///         // Setup before test
///     }
///
///     func runTest() async throws {
///         // Test logic
///         try assert(true)
///     }
///
///     func teardown() async throws {
///         // Cleanup after test
///     }
/// }
/// ```
public protocol AwareTestCase: Sendable {
    /// Test tier classification
    var tier: TestTier { get }

    /// Called before runTest()
    func setup() async throws

    /// Main test execution
    func runTest() async throws

    /// Called after runTest() (even on failure)
    func teardown() async throws
}

// MARK: - Default Implementations

public extension AwareTestCase {
    var tier: TestTier { .structure }

    func setup() async throws {
        // Default: no setup
    }

    func teardown() async throws {
        // Default: no teardown
    }
}

// MARK: - Assertion Helpers

public extension AwareTestCase {

    /// Assert that a condition is true
    func assert(_ condition: Bool, _ message: String = "Assertion failed", file: String = #file, line: Int = #line) throws {
        guard condition else {
            throw AssertionError(message: message, file: file, line: line)
        }
    }

    /// Assert that two values are equal
    func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String? = nil, file: String = #file, line: Int = #line) throws {
        guard actual == expected else {
            let msg = message ?? "Expected \(expected), got \(actual)"
            throw AssertionError(message: msg, expected: String(describing: expected), actual: String(describing: actual), file: file, line: line)
        }
    }

    /// Assert that a value is not nil
    func assertNotNil<T>(_ value: T?, _ message: String = "Expected non-nil value", file: String = #file, line: Int = #line) throws {
        guard value != nil else {
            throw AssertionError(message: message, file: file, line: line)
        }
    }

    /// Assert that a value is nil
    func assertNil<T>(_ value: T?, _ message: String = "Expected nil value", file: String = #file, line: Int = #line) throws {
        guard value == nil else {
            throw AssertionError(message: message, file: file, line: line)
        }
    }

    /// Assert that an async operation throws
    func assertThrows<T>(_ operation: () async throws -> T, _ expectedMessage: String? = nil, file: String = #file, line: Int = #line) async throws {
        var didThrow = false
        var thrownMessage: String?

        do {
            _ = try await operation()
        } catch {
            didThrow = true
            thrownMessage = error.localizedDescription
        }

        guard didThrow else {
            throw AssertionError(message: "Expected operation to throw", file: file, line: line)
        }

        if let expected = expectedMessage, let actual = thrownMessage {
            guard actual.contains(expected) else {
                throw AssertionError(
                    message: "Expected error message to contain \"\(expected)\"",
                    expected: expected,
                    actual: actual,
                    file: file,
                    line: line
                )
            }
        }
    }

    /// Wait for a condition to be true
    func waitFor(_ condition: @escaping () async -> Bool, timeout: TimeInterval = 5, interval: TimeInterval = 0.1) async throws {
        let start = Date()

        while Date().timeIntervalSince(start) < timeout {
            if await condition() {
                return
            }
            try await Task.sleep(for: .seconds(interval))
        }

        throw AssertionError(message: "Condition not met within \(timeout) seconds")
    }

    /// Sleep for a duration
    func sleep(_ seconds: TimeInterval) async throws {
        try await Task.sleep(for: .seconds(seconds))
    }
}

// MARK: - Assertion Error

public struct AssertionError: Error, LocalizedError {
    public let message: String
    public let expected: String?
    public let actual: String?
    public let file: String?
    public let line: Int?

    public init(message: String, expected: String? = nil, actual: String? = nil, file: String? = nil, line: Int? = nil) {
        self.message = message
        self.expected = expected
        self.actual = actual
        self.file = file
        self.line = line
    }

    public var errorDescription: String? {
        message
    }
}

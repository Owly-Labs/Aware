import Foundation

/// Result of a test run
public struct TestResult: Sendable {
    public let version: String = "1.0"
    public let session: Session
    public let summary: Summary
    public let tests: [TestCaseResult]
    public let failures: [TestFailure]

    public struct Session: Sendable {
        public let id: String
        public let startedAt: Date
        public let finishedAt: Date
        public let duration: TimeInterval
        public let platform: String
        public let preset: String?
        public let buildNumber: String?
    }

    public struct Summary: Sendable {
        public let total: Int
        public let passed: Int
        public let failed: Int
        public let skipped: Int
        public let byTier: [TestTier: TierSummary]
    }

    public struct TierSummary: Sendable {
        public let passed: Int
        public let failed: Int
    }

    public var success: Bool {
        summary.failed == 0
    }
}

/// Result of a single test case
public struct TestCaseResult: Sendable {
    public let id: String
    public let name: String
    public let tier: TestTier
    public let status: Status
    public let duration: TimeInterval
    public let retries: Int
    public let error: TestError?

    public enum Status: String, Sendable {
        case passed
        case failed
        case skipped
        case timeout
    }
}

/// Test error details
public struct TestError: Sendable {
    public let message: String
    public let expected: String?
    public let actual: String?
    public let file: String?
    public let line: Int?
}

/// Test failure summary
public struct TestFailure: Sendable {
    public let testId: String
    public let testName: String
    public let tier: TestTier
    public let message: String
    public let expected: String?
    public let actual: String?
}

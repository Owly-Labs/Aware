// CookSystemProtocol.swift
// SwiftAware Cook Module
//
// Main protocol for Cook system coordination between Breathe app and BreatheMCP.
// Defines agent management, task queue, blocking, context window, and learning APIs.
//
// NOTE: This file uses types defined in:
// - CookTask.swift: TaskID, AgentID, ProjectPath, TaskStatus, CookTask, TaskResult, TaskProgress
// - CookAgent.swift: AgentType, AgentStatus, AgentProtocol
// - CookStorageProtocol.swift: LearningRecord, LearningStats
// - CookBlocking.swift: BlockingState, BlockingEvent, BlockingError

import Foundation

// MARK: - Context Status

/// Status of an agent's context window usage
public struct ContextStatus: Codable, Sendable, Equatable {
    /// Number of tokens currently used
    public let usedTokens: Int

    /// Maximum tokens available in context window
    public let maxTokens: Int

    /// Percentage of context window used (0.0 to 1.0)
    public var percentage: Double {
        guard maxTokens > 0 else { return 0.0 }
        return Double(usedTokens) / Double(maxTokens)
    }

    /// Whether the context needs to be saved (true if > 80% used)
    public var needsSave: Bool {
        percentage > 0.80
    }

    /// Whether the context is critical (true if > 95% used)
    public var isCritical: Bool {
        percentage > 0.95
    }

    public init(usedTokens: Int, maxTokens: Int) {
        self.usedTokens = usedTokens
        self.maxTokens = maxTokens
    }

    /// Empty context status
    public static let empty = ContextStatus(usedTokens: 0, maxTokens: 0)
}

// MARK: - Retry Decision

/// Decision made when a task fails
public enum RetryDecision: Codable, Sendable, Equatable {
    /// Retry the task with the given attempt number
    case retry(attempt: Int)

    /// Give up on the task entirely
    case giveUp

    /// Defer the task for later execution
    case `defer`
}

// MARK: - Learning Insights

/// Insights gathered from task executions for learning and optimization.
/// This extends the LearningStats from CookStorageProtocol with additional analysis.
public struct LearningInsights: Codable, Sendable, Equatable {
    /// Project path these insights are for
    public let projectPath: String

    /// Average tokens used per task
    public let averageTokens: Int

    /// Task success rate (0.0 to 1.0)
    public let successRate: Double

    /// Most common error patterns
    public let commonErrors: [ErrorPattern]

    /// Average task duration in seconds
    public let averageDuration: TimeInterval

    /// Total tasks analyzed
    public let totalTasks: Int

    /// Tasks completed successfully
    public let successfulTasks: Int

    /// Tasks that failed
    public let failedTasks: Int

    /// Tasks that were retried
    public let retriedTasks: Int

    /// Suggested optimizations
    public let suggestions: [String]

    /// When these insights were last updated
    public let lastUpdated: Date

    public init(
        projectPath: String,
        averageTokens: Int = 0,
        successRate: Double = 0.0,
        commonErrors: [ErrorPattern] = [],
        averageDuration: TimeInterval = 0,
        totalTasks: Int = 0,
        successfulTasks: Int = 0,
        failedTasks: Int = 0,
        retriedTasks: Int = 0,
        suggestions: [String] = [],
        lastUpdated: Date = Date()
    ) {
        self.projectPath = projectPath
        self.averageTokens = averageTokens
        self.successRate = successRate
        self.commonErrors = commonErrors
        self.averageDuration = averageDuration
        self.totalTasks = totalTasks
        self.successfulTasks = successfulTasks
        self.failedTasks = failedTasks
        self.retriedTasks = retriedTasks
        self.suggestions = suggestions
        self.lastUpdated = lastUpdated
    }

    /// Empty insights for a new project
    public static func empty(for project: String) -> LearningInsights {
        LearningInsights(projectPath: project)
    }

    /// Create insights from learning stats
    public static func from(stats: LearningStats, project: String) -> LearningInsights {
        let errorPatterns = stats.commonErrors.map { (pattern, count) in
            ErrorPattern(pattern: pattern, occurrences: count)
        }

        return LearningInsights(
            projectPath: project,
            averageTokens: Int(stats.avgTokenRatio * 1000),  // Approximate from ratio
            successRate: stats.successRate,
            commonErrors: errorPatterns,
            averageDuration: stats.avgDuration,
            totalTasks: stats.totalTasks,
            successfulTasks: Int(Double(stats.totalTasks) * stats.successRate),
            failedTasks: Int(Double(stats.totalTasks) * (1 - stats.successRate)),
            retriedTasks: 0,  // Not tracked in LearningStats
            suggestions: []
        )
    }
}

// MARK: - Error Pattern

/// A common error pattern identified from task failures
public struct ErrorPattern: Codable, Sendable, Equatable {
    /// The error message or pattern
    public let pattern: String

    /// Number of times this error occurred
    public let occurrences: Int

    /// Suggested fix or workaround
    public let suggestedFix: String?

    /// Category of error
    public let category: ErrorCategory

    public init(
        pattern: String,
        occurrences: Int,
        suggestedFix: String? = nil,
        category: ErrorCategory = .unknown
    ) {
        self.pattern = pattern
        self.occurrences = occurrences
        self.suggestedFix = suggestedFix
        self.category = category
    }
}

// MARK: - Error Category

/// Categories of errors for classification
public enum ErrorCategory: String, Codable, Sendable, CaseIterable {
    case compilation
    case runtime
    case timeout
    case dependency
    case permission
    case network
    case resource
    case configuration
    case unknown
}

// MARK: - Cook System Protocol

/// Main protocol for Cook system coordination.
/// Implemented by both Breathe app (for UI) and BreatheMCP (for CLI).
///
/// This protocol uses TaskID as String (from CookTask.swift) for compatibility
/// with the storage layer. The blocking layer uses its own TaskID struct type
/// which can be converted using TaskID("string").
public protocol CookSystemProtocol: Actor {

    // MARK: - Agent Management

    /// All currently active agents
    var agents: [any AgentProtocol] { get async }

    /// Spawn a new agent of the given type for a task
    /// - Parameters:
    ///   - type: Type of agent to spawn
    ///   - task: Initial task for the agent (uses CookTask from CookAgent.swift)
    /// - Returns: The spawned agent
    func spawn(type: AgentType, for task: CookTask) async throws -> any AgentProtocol

    /// Terminate an agent
    /// - Parameter agent: ID of the agent to terminate
    func terminate(agent: UUID) async

    // MARK: - Task Queue (Self-Serve)

    /// Claim the next available task for an agent
    /// - Parameter agent: ID of the agent claiming a task
    /// - Returns: The claimed task, or nil if no tasks available
    func claim(by agent: UUID) async throws -> CookTask?

    /// Complete a task with a result
    /// - Parameters:
    ///   - task: ID of the completed task
    ///   - result: Result of the task execution
    /// - Returns: Tasks that were unblocked by this completion
    func complete(task: String, result: TaskResult) async throws -> [CookTask]

    /// Report a task failure
    /// - Parameters:
    ///   - task: ID of the failed task
    ///   - error: Error description
    /// - Returns: Decision on how to handle the failure
    func fail(task: String, error: String) async throws -> RetryDecision

    // MARK: - Blocking (Deferred Callback)

    /// Block a task on another task
    /// - Parameters:
    ///   - task: ID of the task to block
    ///   - blockedBy: ID of the blocking task
    ///   - partialBranch: Git branch with partial work
    func block(task: String, blockedBy: String, partialBranch: String) async throws

    /// Get tasks that are blocking a given task
    /// - Parameter task: ID of the blocked task
    /// - Returns: Tasks that are blocking this task
    func getBlockedBy(task: String) async -> [CookTask]

    /// Unblock a task after its blocker completes
    /// - Parameters:
    ///   - task: ID of the task to unblock
    ///   - mergedContext: Optional context from the completed blocker
    func unblock(task: String, mergedContext: String?) async throws

    // MARK: - Context Window

    /// Check context window status for an agent
    /// - Parameter agent: ID of the agent to check
    /// - Returns: Current context status
    func checkContext(agent: UUID) async -> ContextStatus

    /// Save a checkpoint for a task
    /// - Parameters:
    ///   - task: ID of the task
    ///   - progress: Progress to checkpoint
    func checkpoint(task: String, progress: TaskProgress) async throws

    /// Save agent state and context
    /// - Parameters:
    ///   - agent: ID of the agent to save
    ///   - reason: Reason for the save (e.g., "context_limit", "manual")
    func save(agent: UUID, reason: String) async throws

    // MARK: - Learning

    /// Record a task execution for learning
    /// - Parameters:
    ///   - task: ID of the executed task
    ///   - tokens: Tokens consumed
    ///   - duration: Duration of execution
    func recordExecution(task: String, tokens: Int, duration: TimeInterval) async

    /// Get learning insights for a project
    /// - Parameter project: Path to the project
    /// - Returns: Learning insights for the project
    func getInsights(for project: String) async -> LearningInsights
}

// MARK: - Cook System Error

/// Errors that can occur in the Cook system
public enum CookSystemError: Error, Sendable, LocalizedError {
    case agentNotFound(UUID)
    case taskNotFound(String)
    case taskAlreadyClaimed(String)
    case taskNotClaimable(String, String)  // taskId, reason
    case dependencyNotSatisfied(String, blocking: String)
    case contextOverflow(UUID)
    case checkpointFailed(String, reason: String)
    case spawnFailed(AgentType, reason: String)
    case invalidState(String)

    public var errorDescription: String? {
        switch self {
        case .agentNotFound(let id):
            return "Agent not found: \(id)"
        case .taskNotFound(let id):
            return "Task not found: \(id)"
        case .taskAlreadyClaimed(let id):
            return "Task already claimed: \(id)"
        case .taskNotClaimable(let id, let reason):
            return "Task \(id) not claimable: \(reason)"
        case .dependencyNotSatisfied(let task, let blocking):
            return "Task \(task) blocked by \(blocking)"
        case .contextOverflow(let agent):
            return "Context overflow for agent: \(agent)"
        case .checkpointFailed(let task, let reason):
            return "Checkpoint failed for task \(task): \(reason)"
        case .spawnFailed(let type, let reason):
            return "Failed to spawn \(type) agent: \(reason)"
        case .invalidState(let msg):
            return "Invalid state: \(msg)"
        }
    }
}

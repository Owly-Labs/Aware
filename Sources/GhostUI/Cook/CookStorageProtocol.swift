// CookStorageProtocol.swift
// GhostUI Cook Module
//
// Storage protocol for Cook task management, agent queues, and learning data.
// Implemented by BreatheMCP's SQLite storage.

import Foundation

// MARK: - Agent Queue

/// Tracks an agent's current work and blocked tasks
public struct AgentQueue: Codable, Sendable, Equatable {
    /// Unique identifier for the agent
    public let agentId: AgentID

    /// Task currently being worked on (nil if idle)
    public var workingTaskId: TaskID?

    /// Tasks blocked waiting on this agent's current work
    public var blockedByMe: [TaskID]

    /// When this agent queue was created
    public let createdAt: Date

    public init(
        agentId: AgentID,
        workingTaskId: TaskID? = nil,
        blockedByMe: [TaskID] = [],
        createdAt: Date = Date()
    ) {
        self.agentId = agentId
        self.workingTaskId = workingTaskId
        self.blockedByMe = blockedByMe
        self.createdAt = createdAt
    }

    /// Whether this agent is currently working on a task
    public var isWorking: Bool {
        workingTaskId != nil
    }
}

// MARK: - Learning Record

/// Records actual vs estimated performance for machine learning
public struct LearningRecord: Codable, Sendable, Equatable {
    /// Task that was executed
    public let taskId: TaskID

    /// Project the task belonged to
    public let projectPath: ProjectPath

    /// Estimated tokens before execution
    public let estimatedTokens: Int

    /// Actual tokens used
    public let actualTokens: Int

    /// Duration in seconds
    public let duration: TimeInterval

    /// Whether the task succeeded
    public let success: Bool

    /// Error pattern if failed (for categorization)
    public let errorPattern: String?

    /// When this record was created
    public let recordedAt: Date

    public init(
        taskId: TaskID,
        projectPath: ProjectPath,
        estimatedTokens: Int,
        actualTokens: Int,
        duration: TimeInterval,
        success: Bool,
        errorPattern: String? = nil,
        recordedAt: Date = Date()
    ) {
        self.taskId = taskId
        self.projectPath = projectPath
        self.estimatedTokens = estimatedTokens
        self.actualTokens = actualTokens
        self.duration = duration
        self.success = success
        self.errorPattern = errorPattern
        self.recordedAt = recordedAt
    }

    /// Ratio of actual to estimated tokens (for calibration)
    public var tokenRatio: Double {
        guard estimatedTokens > 0 else { return 1.0 }
        return Double(actualTokens) / Double(estimatedTokens)
    }
}

// MARK: - Blocking Relationship

/// Tracks task blocking relationships with partial work branches
public struct BlockingRelationship: Codable, Sendable, Equatable {
    /// Task that is blocked
    public let blockedTaskId: TaskID

    /// Task that is causing the block
    public let blockerTaskId: TaskID

    /// Git branch containing partial work (if any)
    public let partialBranch: String

    /// When the blocking relationship was created
    public let createdAt: Date

    public init(
        blockedTaskId: TaskID,
        blockerTaskId: TaskID,
        partialBranch: String,
        createdAt: Date = Date()
    ) {
        self.blockedTaskId = blockedTaskId
        self.blockerTaskId = blockerTaskId
        self.partialBranch = partialBranch
        self.createdAt = createdAt
    }
}

// MARK: - PRD Summary

/// Summary of a PRD for quick reference
public struct PRDSummary: Codable, Sendable, Equatable {
    /// Unique identifier for the PRD
    public let id: String

    /// Human-readable name
    public let name: String

    /// Overall direction/goal of the PRD
    public let direction: String

    /// Number of subplans
    public let subplanCount: Int

    /// Total number of tasks across all subplans
    public let taskCount: Int

    /// Project path this PRD belongs to
    public let projectPath: ProjectPath

    /// When the PRD was created
    public let createdAt: Date

    /// When the PRD was last updated
    public let updatedAt: Date

    public init(
        id: String,
        name: String,
        direction: String,
        subplanCount: Int,
        taskCount: Int,
        projectPath: ProjectPath,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.direction = direction
        self.subplanCount = subplanCount
        self.taskCount = taskCount
        self.projectPath = projectPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Learning Stats

/// Aggregate statistics from learning records
public struct LearningStats: Codable, Sendable, Equatable {
    /// Average ratio of actual to estimated tokens
    public let avgTokenRatio: Double

    /// Success rate (0.0 to 1.0)
    public let successRate: Double

    /// Average task duration in seconds
    public let avgDuration: TimeInterval

    /// Total tasks analyzed
    public let totalTasks: Int

    /// Most common error patterns
    public let commonErrors: [String: Int]

    public init(
        avgTokenRatio: Double,
        successRate: Double,
        avgDuration: TimeInterval,
        totalTasks: Int,
        commonErrors: [String: Int] = [:]
    ) {
        self.avgTokenRatio = avgTokenRatio
        self.successRate = successRate
        self.avgDuration = avgDuration
        self.totalTasks = totalTasks
        self.commonErrors = commonErrors
    }
}

// MARK: - Cook Storage Protocol

/// Protocol for Cook task storage implementations.
/// Implemented by BreatheMCP's SQLite storage for persistent task management.
public protocol CookStorageProtocol: Actor {

    // MARK: - Task Queue

    /// Save a task to storage (insert or update)
    func saveTask(_ task: CookTask) async throws

    /// Load tasks with optional status filter
    func loadTasks(status: TaskStatus?) async throws -> [CookTask]

    /// Load a specific task by ID
    func loadTask(id: TaskID) async throws -> CookTask?

    /// Update an existing task
    func updateTask(_ task: CookTask) async throws

    /// Atomically claim the next available task for an agent.
    /// Returns nil if no tasks are available.
    /// This should be atomic to prevent race conditions in multi-agent scenarios.
    func claimTask(by agent: AgentID) async throws -> CookTask?

    /// Load tasks for a specific project
    func loadTasks(project: ProjectPath, status: TaskStatus?) async throws -> [CookTask]

    /// Delete a task
    func deleteTask(id: TaskID) async throws

    // MARK: - Agent Queues

    /// Save or update an agent queue
    func saveAgentQueue(_ queue: AgentQueue) async throws

    /// Load an agent's queue
    func loadAgentQueue(id: AgentID) async throws -> AgentQueue?

    /// Delete an agent's queue (when agent terminates)
    func deleteAgentQueue(id: AgentID) async throws

    /// List all active agent queues
    func listAgentQueues() async throws -> [AgentQueue]

    // MARK: - Blocking Relationships

    /// Add a blocking relationship between tasks
    func addBlocking(task: TaskID, blockedBy: TaskID, partialBranch: String) async throws

    /// Remove a blocking relationship (when blocker completes)
    func removeBlocking(task: TaskID) async throws

    /// Get all tasks blocked by a specific task
    func getBlockedTasks(by blocker: TaskID) async throws -> [CookTask]

    /// Get the task that is blocking a specific task
    func getBlocker(for task: TaskID) async throws -> (blocker: TaskID, branch: String)?

    // MARK: - Learning Data

    /// Record learning data for completed task
    func recordLearning(_ data: LearningRecord) async throws

    /// Query learning records for analysis
    func queryLearning(project: ProjectPath, days: Int) async throws -> [LearningRecord]

    /// Get aggregate learning statistics for a project
    func getLearningStats(project: ProjectPath) async throws -> LearningStats?

    // MARK: - PRD

    /// Load PRD summary for a project (optional, for completeness)
    func loadPRD(project: ProjectPath) async throws -> PRDSummary?

    /// Save PRD summary
    func savePRD(_ summary: PRDSummary) async throws
}

// MARK: - Cook Storage Error

/// Errors that can occur during Cook storage operations
public enum CookStorageError: Error, Sendable {
    case taskNotFound(TaskID)
    case agentNotFound(AgentID)
    case duplicateTask(TaskID)
    case claimFailed(String)
    case transactionFailed(String)
    case invalidState(String)
    case databaseError(String)

    public var localizedDescription: String {
        switch self {
        case .taskNotFound(let id):
            return "Task not found: \(id)"
        case .agentNotFound(let id):
            return "Agent not found: \(id)"
        case .duplicateTask(let id):
            return "Duplicate task ID: \(id)"
        case .claimFailed(let msg):
            return "Failed to claim task: \(msg)"
        case .transactionFailed(let msg):
            return "Transaction failed: \(msg)"
        case .invalidState(let msg):
            return "Invalid state: \(msg)"
        case .databaseError(let msg):
            return "Database error: \(msg)"
        }
    }
}

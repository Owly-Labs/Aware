// CookTask.swift
// GhostUI Cook Module
//
// Task management types for the Cook orchestration system.
// This file defines the canonical task types used by the swarm factory.
//
// NOTE: To compile, remove duplicate TaskID/AgentID/ProjectPath/TaskStatus/CookTask/TaskResult/TaskProgress
// definitions from CookSystemProtocol.swift and CookStorageProtocol.swift.

import Foundation

// MARK: - Type Aliases

/// Unique identifier for a task
public typealias TaskID = String

/// Unique identifier for an agent
public typealias AgentID = String

/// Path to a project directory
public typealias ProjectPath = String

// MARK: - Task Status

/// Current status of a task in the execution pipeline
public enum TaskStatus: String, Codable, Sendable, Equatable, CaseIterable {
    /// Task is waiting to be processed
    case pending
    /// Task dependencies are satisfied and task is ready to execute
    case ready
    /// Task has been claimed by an agent
    case claimed
    /// Task is blocked by one or more dependencies
    case blocked
    /// Task has been completed successfully
    case completed
    /// Task has failed execution
    case failed
}

// MARK: - Cook Task

/// A task to be executed by a cook agent
public struct CookTask: Codable, Sendable, Equatable, Identifiable {
    /// Unique identifier for this task
    public let id: TaskID

    /// Human-readable name for the task
    public let name: String

    /// Detailed objective describing what needs to be accomplished
    public let objective: String

    /// Optional subplan identifier if this task belongs to a subplan
    public let subplanId: String?

    /// Optional feature identifier if this task is part of a feature
    public let featureId: String?

    /// Maximum token budget for this task
    public let tokenBudget: Int

    /// Current status of the task
    public var status: TaskStatus

    /// Task IDs that must complete before this task can start
    public let dependencies: [TaskID]

    /// Task ID that is currently blocking this task (if blocked)
    public var blockedBy: TaskID?

    /// Task IDs that are waiting for this task to complete
    public var blocks: [TaskID]

    /// Branch name for partial work if task was interrupted
    public var partialBranch: String?

    /// Agent ID that has claimed this task
    public var claimedBy: AgentID?

    /// Files relevant to this task
    public let files: [String]

    /// Estimated context size in tokens
    public let contextSize: Int

    /// When the task was created
    public let createdAt: Date

    /// When the task was completed (if completed)
    public var completedAt: Date?

    public init(
        id: TaskID,
        name: String,
        objective: String,
        subplanId: String? = nil,
        featureId: String? = nil,
        tokenBudget: Int,
        status: TaskStatus = .pending,
        dependencies: [TaskID] = [],
        blockedBy: TaskID? = nil,
        blocks: [TaskID] = [],
        partialBranch: String? = nil,
        claimedBy: AgentID? = nil,
        files: [String] = [],
        contextSize: Int = 0,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.objective = objective
        self.subplanId = subplanId
        self.featureId = featureId
        self.tokenBudget = tokenBudget
        self.status = status
        self.dependencies = dependencies
        self.blockedBy = blockedBy
        self.blocks = blocks
        self.partialBranch = partialBranch
        self.claimedBy = claimedBy
        self.files = files
        self.contextSize = contextSize
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

// MARK: - Task Result Status

/// Outcome of a task execution
public enum TaskResultStatus: String, Codable, Sendable, Equatable {
    case success
    case failure
}

// MARK: - Task Result

/// Result of executing a task
public struct TaskResult: Codable, Sendable, Equatable {
    /// Whether the task succeeded or failed
    public let status: TaskResultStatus

    /// Output produced by the task (e.g., commit hash, summary)
    public let output: String?

    /// Error message if the task failed
    public let error: String?

    /// Actual tokens consumed during execution
    public let actualTokens: Int?

    /// Duration of task execution in seconds
    public let duration: TimeInterval?

    public init(
        status: TaskResultStatus,
        output: String? = nil,
        error: String? = nil,
        actualTokens: Int? = nil,
        duration: TimeInterval? = nil
    ) {
        self.status = status
        self.output = output
        self.error = error
        self.actualTokens = actualTokens
        self.duration = duration
    }

    /// Create a successful result
    public static func success(output: String? = nil, actualTokens: Int? = nil, duration: TimeInterval? = nil) -> TaskResult {
        TaskResult(status: .success, output: output, actualTokens: actualTokens, duration: duration)
    }

    /// Create a failure result
    public static func failure(error: String, actualTokens: Int? = nil, duration: TimeInterval? = nil) -> TaskResult {
        TaskResult(status: .failure, error: error, actualTokens: actualTokens, duration: duration)
    }
}

// MARK: - Task Progress

/// Progress checkpoint for a task in execution
public struct TaskProgress: Codable, Sendable, Equatable {
    /// Progress percentage (0.0 to 1.0)
    public let progress: Double

    /// Last commit hash if any commits were made
    public let lastCommit: String?

    /// Notes about current progress or state
    public let notes: String?

    /// Timestamp of this progress update
    public let timestamp: Date

    public init(
        progress: Double,
        lastCommit: String? = nil,
        notes: String? = nil,
        timestamp: Date = Date()
    ) {
        self.progress = min(1.0, max(0.0, progress))
        self.lastCommit = lastCommit
        self.notes = notes
        self.timestamp = timestamp
    }

    /// Create a progress update at a specific percentage
    public static func at(_ percentage: Double, notes: String? = nil) -> TaskProgress {
        TaskProgress(progress: percentage / 100.0, notes: notes)
    }

    /// Create a progress update with a commit
    public static func committed(_ hash: String, progress: Double, notes: String? = nil) -> TaskProgress {
        TaskProgress(progress: progress, lastCommit: hash, notes: notes)
    }
}

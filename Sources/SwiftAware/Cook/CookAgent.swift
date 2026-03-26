// CookAgent.swift
// SwiftAware Cook Module
//
// Agent types and protocol for the Cook multi-agent system.
// Defines the 7-agent taxonomy with execution characteristics.
//
// NOTE: Uses types from CookTask.swift (AgentID, CookTask, TaskResult).

import Foundation

// MARK: - Agent Type

/// Agent types for the Cook multi-agent system.
/// Each type has specific responsibilities, model requirements, and parallelism characteristics.
///
/// ## Agent Taxonomy (7 types)
/// - `pm`: Vision Keeper - maintains project vision and requirements (sequential)
/// - `architect`: CTO - designs technical architecture and implementation plans (sequential)
/// - `explorer`: Research Team - parallel codebase exploration (x5)
/// - `developer`: Engineers - implements code changes (auto-scale)
/// - `validator`: QA Team - parallel build/test/lint validation (x3)
/// - `observer`: Code Reviewer - reviews plans and implementations (sequential)
/// - `context`: Librarian - manages memory bank and session context (sequential)
public enum AgentType: String, Codable, Sendable, CaseIterable {
    /// Vision Keeper - maintains project vision and requirements
    /// Sequential execution, uses Sonnet model
    case pm

    /// CTO - designs technical architecture and implementation plans
    /// Sequential execution, uses Sonnet model
    case architect

    /// Research Team - parallel codebase exploration
    /// Parallel execution (x5), uses Haiku model for speed
    case explorer

    /// Engineers - implements code changes
    /// Parallel execution (auto-scale based on workload)
    /// Uses Sonnet model for complex reasoning
    case developer

    /// QA Team - parallel build/test/lint validation
    /// Parallel execution (x3), uses Haiku model for fast feedback
    case validator

    /// Code Reviewer - reviews plans and implementations
    /// Sequential execution, uses Sonnet model
    case observer

    /// Librarian - manages memory bank and session context
    /// Sequential execution, uses Sonnet model
    case context

    // MARK: - Display Properties

    /// Human-readable display name for the agent type
    public var displayName: String {
        switch self {
        case .pm:
            return "Vision Keeper"
        case .architect:
            return "CTO"
        case .explorer:
            return "Research Team"
        case .developer:
            return "Engineers"
        case .validator:
            return "QA Team"
        case .observer:
            return "Code Reviewer"
        case .context:
            return "Librarian"
        }
    }

    // MARK: - Execution Properties

    /// Number of parallel instances allowed.
    /// - 1: Sequential execution
    /// - 5: Explorer parallel count
    /// - 3: Validator parallel count
    /// - 0: Developer auto-scales based on workload
    public var parallelism: Int {
        switch self {
        case .pm:
            return 1
        case .architect:
            return 1
        case .explorer:
            return 5
        case .developer:
            return 0  // Auto-scale
        case .validator:
            return 3
        case .observer:
            return 1
        case .context:
            return 1
        }
    }

    /// Recommended Claude model for this agent type.
    /// - "haiku": Fast, cheap - for read-only exploration and validation
    /// - "sonnet": Capable reasoning - for planning, implementation, and review
    public var model: String {
        switch self {
        case .pm:
            return "sonnet"
        case .architect:
            return "sonnet"
        case .explorer:
            return "haiku"
        case .developer:
            return "sonnet"
        case .validator:
            return "haiku"
        case .observer:
            return "sonnet"
        case .context:
            return "sonnet"
        }
    }

    /// Whether this agent type runs sequentially (parallelism == 1)
    public var isSequential: Bool {
        parallelism == 1
    }

    /// Whether this agent type auto-scales (parallelism == 0)
    public var autoScales: Bool {
        parallelism == 0
    }

    /// Whether this agent type can run multiple instances in parallel
    public var canParallelize: Bool {
        parallelism != 1
    }
}

// MARK: - Agent Status

/// Current execution status of an agent
public enum AgentStatus: String, Codable, Sendable {
    /// Agent is idle, waiting for work
    case idle

    /// Agent is actively executing a task
    case working

    /// Agent is blocked waiting for dependencies or resources
    case blocked

    /// Agent is saving results/context before completion
    case saving

    /// Agent has completed and terminated
    case terminated

    /// Whether this status represents an active agent
    public var isActive: Bool {
        switch self {
        case .working, .saving:
            return true
        case .idle, .blocked, .terminated:
            return false
        }
    }

    /// Whether this status represents a terminal state
    public var isTerminal: Bool {
        self == .terminated
    }
}

// MARK: - Agent Protocol

/// Protocol defining the interface for all Cook agents.
/// Agents are actors that execute tasks and coordinate with other agents.
///
/// Uses `CookTask` from CookTask.swift for task representation
/// and `TaskResult` for execution results.
public protocol AgentProtocol: Actor {
    /// Unique identifier for this agent instance (String from CookTask.swift)
    var id: AgentID { get }

    /// Type of agent (determines capabilities and execution model)
    var type: AgentType { get }

    /// Current status of the agent
    var status: AgentStatus { get }

    /// The task currently being executed, if any
    var workingTask: CookTask? { get }

    /// Tasks that are blocked by this agent (waiting for this agent to complete)
    var blockedByMe: [CookTask] { get }

    /// Execute a task and return the result
    /// - Parameter task: The task to execute
    /// - Returns: The result of task execution
    /// - Throws: If execution fails in an unrecoverable way
    func execute(task: CookTask) async throws -> TaskResult

    /// Handle tasks that were previously blocked and are now unblocked
    /// Called when dependencies complete, allowing the agent to pick up new work
    /// - Parameter tasks: Tasks that are now ready for execution
    func handleUnblocked(tasks: [CookTask]) async

    /// Check if the agent needs to save state before shutdown
    /// Used during graceful shutdown to ensure work is not lost
    /// - Returns: true if the agent has unsaved state
    func needsSave() -> Bool
}

// MARK: - Agent Protocol Extensions

public extension AgentProtocol {
    /// Whether this agent is currently idle and can accept work
    var isAvailable: Bool {
        status == .idle
    }

    /// Whether this agent is currently executing a task
    var isWorking: Bool {
        status == .working
    }

    /// Whether this agent has completed and cannot accept more work
    var isTerminated: Bool {
        status == .terminated
    }
}

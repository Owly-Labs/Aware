// CookBlocking.swift
// GhostUI Cook Module
//
// Deferred callback pattern for blocked tasks in the Cook system.
// Enables tasks to be blocked by dependencies and unblocked when those complete.

import Foundation

// MARK: - Blocking Task ID

/// Unique identifier for a task in the blocking system.
/// Uses a struct wrapper for type safety in blocking operations.
/// Can be converted to/from String for storage compatibility.
public struct BlockingTaskID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public var description: String { value }
}

// MARK: - Blocking State

/// Represents the current blocking state of a task
public enum BlockingState: Sendable, Equatable {
    /// Task is ready to execute (not blocked)
    case ready

    /// Task is blocked by another task
    /// - Parameters:
    ///   - by: The ID of the blocking task
    ///   - since: When the block started
    ///   - partialBranch: Git branch containing partial work before blocking
    case blocked(by: BlockingTaskID, since: Date, partialBranch: String)

    /// Task was unblocked after its blocker completed
    /// - Parameter mergedFrom: The ID of the completed blocker task
    case unblocked(mergedFrom: BlockingTaskID)
}

// MARK: - Blocking Event

/// Events emitted when blocking state changes
public enum BlockingEvent: Sendable {
    /// A task has been blocked by another task
    /// - Parameters:
    ///   - task: The blocked task
    ///   - blocker: The blocking task
    case taskBlocked(task: BlockingTaskID, blocker: BlockingTaskID)

    /// A task has been unblocked
    /// - Parameters:
    ///   - task: The unblocked task
    ///   - completedBlocker: The blocker that completed
    case taskUnblocked(task: BlockingTaskID, completedBlocker: BlockingTaskID)

    /// A blocker task completed, unblocking dependent tasks
    /// - Parameters:
    ///   - blocker: The completed blocker task
    ///   - unblockedTasks: Tasks that were unblocked
    case blockerCompleted(blocker: BlockingTaskID, unblockedTasks: [BlockingTaskID])
}

// MARK: - Blocking Error

/// Errors that can occur during blocking operations
public enum BlockingError: Error, Sendable {
    /// Task was not found
    case taskNotFound(BlockingTaskID)

    /// Task is already blocked
    case alreadyBlocked(BlockingTaskID)

    /// Task is not currently blocked
    case notBlocked(BlockingTaskID)

    /// Cannot block a task by itself
    case selfBlock(BlockingTaskID)

    /// Circular dependency detected
    case circularDependency(chain: [BlockingTaskID])

    public var localizedDescription: String {
        switch self {
        case .taskNotFound(let id):
            return "Task not found: \(id)"
        case .alreadyBlocked(let id):
            return "Task already blocked: \(id)"
        case .notBlocked(let id):
            return "Task is not blocked: \(id)"
        case .selfBlock(let id):
            return "Cannot block task by itself: \(id)"
        case .circularDependency(let chain):
            return "Circular dependency detected: \(chain.map(\.value).joined(separator: " -> "))"
        }
    }
}

// MARK: - Blocking Protocol

/// Protocol for managing task blocking relationships
public protocol BlockingProtocol: Sendable {
    /// Check if a task is currently blocked
    /// - Parameter task: The task to check
    /// - Returns: True if the task is blocked
    func isBlocked(_ task: BlockingTaskID) async -> Bool

    /// Get the current blocking state of a task
    /// - Parameter task: The task to check
    /// - Returns: The current blocking state
    func getBlockingState(_ task: BlockingTaskID) async -> BlockingState

    /// Block a task by another task
    /// - Parameters:
    ///   - task: The task to block
    ///   - blocker: The blocking task
    ///   - partialBranch: Git branch with partial work
    /// - Throws: BlockingError if the operation fails
    func block(task: BlockingTaskID, by blocker: BlockingTaskID, partialBranch: String) async throws

    /// Unblock a task, optionally providing merged context
    /// - Parameters:
    ///   - task: The task to unblock
    ///   - mergedContext: Optional context from the completed blocker
    /// - Throws: BlockingError if the task is not blocked
    func unblock(task: BlockingTaskID, mergedContext: String?) async throws

    /// Get all tasks blocked by a specific blocker
    /// - Parameter blocker: The blocking task
    /// - Returns: Array of blocked task IDs
    func getTasksBlockedBy(_ blocker: BlockingTaskID) async -> [BlockingTaskID]

    /// Register a handler for blocking events
    /// - Parameter handler: Async handler called when blocking events occur
    func onBlockingEvent(_ handler: @escaping @Sendable (BlockingEvent) async -> Void)
}

// MARK: - Stuck Action

/// Actions to take when a task has been blocked too long
public enum StuckAction: Sendable, Equatable {
    /// Task is not stuck
    case ok

    /// Task is approaching stuck status, warning issued
    /// - Parameter duration: How long the task has been blocked
    case warn(duration: TimeInterval)

    /// Suggest retrying the blocker task
    /// - Parameter blocker: The blocking task to retry
    case retry(blocker: BlockingTaskID)

    /// Notify the user about the stuck task
    case notifyUser
}

// MARK: - Stuck Detector

/// Detects tasks that have been blocked for too long
public struct StuckDetector: Sendable {
    /// Warning threshold in seconds (default: 5 minutes)
    public let warnThreshold: TimeInterval

    /// Retry threshold in seconds (default: 15 minutes)
    public let retryThreshold: TimeInterval

    /// Notify threshold in seconds (default: 30 minutes)
    public let notifyThreshold: TimeInterval

    public init(
        warnThreshold: TimeInterval = 300,      // 5 minutes
        retryThreshold: TimeInterval = 900,     // 15 minutes
        notifyThreshold: TimeInterval = 1800    // 30 minutes
    ) {
        self.warnThreshold = warnThreshold
        self.retryThreshold = retryThreshold
        self.notifyThreshold = notifyThreshold
    }

    /// Check if a task is stuck based on how long it's been blocked
    /// - Parameters:
    ///   - blockedFor: Duration the task has been blocked
    ///   - blocker: The blocking task (for retry action)
    /// - Returns: The appropriate action to take
    public func checkStuck(blockedFor: TimeInterval, blocker: BlockingTaskID? = nil) -> StuckAction {
        if blockedFor >= notifyThreshold {
            return .notifyUser
        } else if blockedFor >= retryThreshold, let blocker = blocker {
            return .retry(blocker: blocker)
        } else if blockedFor >= warnThreshold {
            return .warn(duration: blockedFor)
        }
        return .ok
    }
}

// MARK: - Blocking Record

/// Internal record for tracking a blocked task
struct BlockingRecord: Sendable {
    let task: BlockingTaskID
    let blocker: BlockingTaskID
    let since: Date
    let partialBranch: String
}

// MARK: - Blocking Engine

/// Actor that manages blocking relationships between tasks
public actor BlockingEngine: BlockingProtocol {

    // MARK: - Properties

    /// Active blocking records indexed by blocked task
    private var blockedTasks: [BlockingTaskID: BlockingRecord] = [:]

    /// Index of tasks blocked by each blocker
    private var blockerIndex: [BlockingTaskID: Set<BlockingTaskID>] = [:]

    /// Unblocked tasks with their merge context
    private var unblockedTasks: [BlockingTaskID: BlockingTaskID] = [:]

    /// Event handlers
    private var eventHandlers: [@Sendable (BlockingEvent) async -> Void] = []

    /// Stuck detector for timing checks
    public let stuckDetector: StuckDetector

    // MARK: - Initialization

    public init(stuckDetector: StuckDetector = StuckDetector()) {
        self.stuckDetector = stuckDetector
    }

    // MARK: - BlockingProtocol Implementation

    public func isBlocked(_ task: BlockingTaskID) async -> Bool {
        blockedTasks[task] != nil
    }

    public func getBlockingState(_ task: BlockingTaskID) async -> BlockingState {
        if let record = blockedTasks[task] {
            return .blocked(by: record.blocker, since: record.since, partialBranch: record.partialBranch)
        }
        if let mergedFrom = unblockedTasks[task] {
            return .unblocked(mergedFrom: mergedFrom)
        }
        return .ready
    }

    public func block(task: BlockingTaskID, by blocker: BlockingTaskID, partialBranch: String) async throws {
        // Validate: can't block by self
        guard task != blocker else {
            throw BlockingError.selfBlock(task)
        }

        // Validate: not already blocked
        guard blockedTasks[task] == nil else {
            throw BlockingError.alreadyBlocked(task)
        }

        // Check for circular dependency
        if wouldCreateCircle(blocking: task, by: blocker) {
            let chain = buildCircularChain(from: task, to: blocker)
            throw BlockingError.circularDependency(chain: chain)
        }

        // Create blocking record
        let record = BlockingRecord(
            task: task,
            blocker: blocker,
            since: Date(),
            partialBranch: partialBranch
        )

        blockedTasks[task] = record
        blockerIndex[blocker, default: []].insert(task)

        // Remove from unblocked if present
        unblockedTasks.removeValue(forKey: task)

        // Emit event
        await emitEvent(.taskBlocked(task: task, blocker: blocker))
    }

    public func unblock(task: BlockingTaskID, mergedContext: String?) async throws {
        // Validate: must be blocked
        guard let record = blockedTasks[task] else {
            throw BlockingError.notBlocked(task)
        }

        let blocker = record.blocker

        // Remove blocking record
        blockedTasks.removeValue(forKey: task)
        blockerIndex[blocker]?.remove(task)
        if blockerIndex[blocker]?.isEmpty == true {
            blockerIndex.removeValue(forKey: blocker)
        }

        // Mark as unblocked
        unblockedTasks[task] = blocker

        // Emit event
        await emitEvent(.taskUnblocked(task: task, completedBlocker: blocker))
    }

    public func getTasksBlockedBy(_ blocker: BlockingTaskID) async -> [BlockingTaskID] {
        Array(blockerIndex[blocker] ?? [])
    }

    public nonisolated func onBlockingEvent(_ handler: @escaping @Sendable (BlockingEvent) async -> Void) {
        Task {
            await addEventHandler(handler)
        }
    }

    // MARK: - Additional Methods

    /// Complete a blocker and unblock all dependent tasks
    /// - Parameter blocker: The completed blocker task
    /// - Returns: Array of tasks that were unblocked
    @discardableResult
    public func completeBlocker(_ blocker: BlockingTaskID) async -> [BlockingTaskID] {
        guard let blockedByThis = blockerIndex[blocker] else {
            return []
        }

        var unblockedList: [BlockingTaskID] = []

        for task in blockedByThis {
            blockedTasks.removeValue(forKey: task)
            unblockedTasks[task] = blocker
            unblockedList.append(task)
        }

        blockerIndex.removeValue(forKey: blocker)

        // Emit individual unblock events
        for task in unblockedList {
            await emitEvent(.taskUnblocked(task: task, completedBlocker: blocker))
        }

        // Emit blocker completed event
        await emitEvent(.blockerCompleted(blocker: blocker, unblockedTasks: unblockedList))

        return unblockedList
    }

    /// Check stuck status for a specific blocked task
    /// - Parameter task: The task to check
    /// - Returns: StuckAction indicating what to do
    public func checkStuckStatus(for task: BlockingTaskID) async -> StuckAction {
        guard let record = blockedTasks[task] else {
            return .ok
        }

        let blockedFor = Date().timeIntervalSince(record.since)
        return stuckDetector.checkStuck(blockedFor: blockedFor, blocker: record.blocker)
    }

    /// Get all currently blocked tasks
    /// - Returns: Array of blocked task IDs
    public func getAllBlockedTasks() async -> [BlockingTaskID] {
        Array(blockedTasks.keys)
    }

    /// Get all tasks that were unblocked
    /// - Returns: Dictionary mapping task to the blocker that completed
    public func getAllUnblockedTasks() async -> [BlockingTaskID: BlockingTaskID] {
        unblockedTasks
    }

    /// Clear the unblocked status for a task (after it resumes)
    /// - Parameter task: The task that has resumed
    public func clearUnblockedStatus(for task: BlockingTaskID) async {
        unblockedTasks.removeValue(forKey: task)
    }

    /// Reset all blocking state (for testing)
    public func reset() async {
        blockedTasks.removeAll()
        blockerIndex.removeAll()
        unblockedTasks.removeAll()
    }

    // MARK: - Private Helpers

    private func addEventHandler(_ handler: @escaping @Sendable (BlockingEvent) async -> Void) {
        eventHandlers.append(handler)
    }

    private func emitEvent(_ event: BlockingEvent) async {
        for handler in eventHandlers {
            await handler(event)
        }
    }

    /// Check if blocking would create a circular dependency
    private func wouldCreateCircle(blocking task: BlockingTaskID, by blocker: BlockingTaskID) -> Bool {
        // If the proposed blocker is blocked by the task (directly or transitively),
        // then blocking task by blocker would create a circle
        var visited = Set<BlockingTaskID>()
        var queue = [blocker]

        while !queue.isEmpty {
            let current = queue.removeFirst()

            if current == task {
                return true
            }

            if visited.contains(current) {
                continue
            }
            visited.insert(current)

            // Check if current is blocked by something
            if let record = blockedTasks[current] {
                queue.append(record.blocker)
            }
        }

        return false
    }

    /// Build the circular dependency chain for error reporting
    private func buildCircularChain(from task: BlockingTaskID, to blocker: BlockingTaskID) -> [BlockingTaskID] {
        var chain: [BlockingTaskID] = [task, blocker]
        var current = blocker

        while let record = blockedTasks[current] {
            chain.append(record.blocker)
            if record.blocker == task {
                break
            }
            current = record.blocker
        }

        return chain
    }
}

// MARK: - BlockingState Codable

extension BlockingState: Codable {
    enum CodingKeys: String, CodingKey {
        case type, blocker, since, partialBranch, mergedFrom
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "ready":
            self = .ready
        case "blocked":
            let blocker = try container.decode(BlockingTaskID.self, forKey: .blocker)
            let since = try container.decode(Date.self, forKey: .since)
            let partialBranch = try container.decode(String.self, forKey: .partialBranch)
            self = .blocked(by: blocker, since: since, partialBranch: partialBranch)
        case "unblocked":
            let mergedFrom = try container.decode(BlockingTaskID.self, forKey: .mergedFrom)
            self = .unblocked(mergedFrom: mergedFrom)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown BlockingState type: \(type)")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .ready:
            try container.encode("ready", forKey: .type)
        case .blocked(let blocker, let since, let partialBranch):
            try container.encode("blocked", forKey: .type)
            try container.encode(blocker, forKey: .blocker)
            try container.encode(since, forKey: .since)
            try container.encode(partialBranch, forKey: .partialBranch)
        case .unblocked(let mergedFrom):
            try container.encode("unblocked", forKey: .type)
            try container.encode(mergedFrom, forKey: .mergedFrom)
        }
    }
}

// MARK: - Convenience Extensions

extension BlockingTaskID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}

extension BlockingTaskID: ExpressibleByStringInterpolation {}

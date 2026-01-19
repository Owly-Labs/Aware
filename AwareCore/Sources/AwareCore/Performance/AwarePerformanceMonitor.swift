//
//  AwarePerformanceMonitor.swift
//  AwareCore
//
//  Monitors performance of Aware operations for LLM feedback loops.
//  Provides lightweight timing, memory, and CPU tracking.
//

import Foundation

#if canImport(os)
import os
#endif

// MARK: - AwarePerformanceMonitor

/// Monitors performance of Aware operations for LLM feedback loops
@MainActor
public class AwarePerformanceMonitor: ObservableObject {
    public static let shared = AwarePerformanceMonitor()

    // MARK: - State

    /// History of performance measurements (limited to last 100)
    @Published public private(set) var history: [PerformanceMetrics] = []

    /// Active operation tracking
    private var activeOperations: [String: Date] = [:]

    /// Performance breakdown tracking (for Context-Rich Responses)
    private var performanceBreakdowns: [String: [PerformanceBreakdownItem]] = [:]

    /// Maximum history size
    private let maxHistorySize = 100

    /// Performance budget thresholds (in seconds)
    private var budgets: [String: TimeInterval] = [
        "snapshot": 0.1,      // 100ms
        "action": 0.05,       // 50ms
        "render": 0.016,      // 16ms (60fps)
        "query": 0.01         // 10ms
    ]

    private init() {}

    // MARK: - Measurement

    /// Measure execution time of an operation
    ///
    /// **Token Cost:** ~30 tokens per result
    /// **Overhead:** <2ms
    /// **LLM Guidance:** Use to measure any operation for performance feedback
    ///
    /// - Parameters:
    ///   - name: Operation name for identification
    ///   - operation: Async operation to measure
    /// - Returns: Tuple of (result, metrics)
    public func measure<T>(
        name: String = "operation",
        operation: () async throws -> T
    ) async rethrows -> (result: T, metrics: PerformanceMetrics) {
        let operationId = UUID().uuidString
        let startTime = Date()

        #if canImport(os)
        let startMemory = self.currentMemoryUsage()
        #endif

        // Execute operation
        let result = try await operation()

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        #if canImport(os)
        let endMemory = self.currentMemoryUsage()
        let memoryDelta = endMemory - startMemory
        #else
        let memoryDelta: Int? = nil
        #endif

        let metrics = PerformanceMetrics(
            operationId: operationId,
            name: name,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            memoryUsage: memoryDelta,
            cpuUsage: nil // CPU tracking disabled for performance
        )

        addToHistory(metrics)

        // Log performance with budget threshold
        let threshold = budgets[name] ?? 1.0 // Default 1s threshold
        Task {
            await AwareCentralLogger.shared.logPerformance(
                operation: name,
                duration: duration,
                threshold: threshold
            )
        }

        return (result, metrics)
    }

    /// Measure snapshot generation time
    ///
    /// **Token Cost:** ~30 tokens per result
    /// **LLM Guidance:** Use to track snapshot performance over time
    ///
    /// - Parameter format: Snapshot format to measure
    /// - Returns: Performance metrics
    public func measureSnapshot(
        format: String = "compact"
    ) async -> PerformanceMetrics {
        let (_, metrics) = await measure(name: "snapshot(\(format))") {
            // TODO: Integrate with Aware.shared.snapshot() when available
            // Simulate snapshot generation
            try? await Task.sleep(for: .milliseconds(5))
        }
        return metrics
    }

    /// Measure action execution time
    ///
    /// **Token Cost:** ~30 tokens per result
    /// **LLM Guidance:** Use to track action performance (tap, type, etc.)
    ///
    /// - Parameter action: Async action to measure
    /// - Returns: Performance metrics
    public func measureAction(
        _ action: () async throws -> Void
    ) async rethrows -> PerformanceMetrics {
        let (_, metrics) = try await measure(name: "action") {
            try await action()
        }
        return metrics
    }

    // MARK: - Operation Tracking

    /// Start tracking an operation
    ///
    /// **LLM Guidance:** Use for long-running operations you want to track separately
    ///
    /// - Parameter operationId: Unique identifier for this operation
    public func startTracking(_ operationId: String) {
        activeOperations[operationId] = Date()
    }

    /// End tracking and get metrics
    ///
    /// **LLM Guidance:** Call after startTracking() to get duration
    ///
    /// - Parameter operationId: Operation identifier from startTracking()
    /// - Returns: Performance metrics or nil if not found
    public func endTracking(_ operationId: String) -> PerformanceMetrics? {
        guard let startTime = activeOperations.removeValue(forKey: operationId) else {
            return nil
        }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        let metrics = PerformanceMetrics(
            operationId: operationId,
            name: "tracked-operation",
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            memoryUsage: nil,
            cpuUsage: nil
        )

        addToHistory(metrics)

        // Log performance
        Task {
            await AwareCentralLogger.shared.logPerformance(
                operation: "tracked-operation",
                duration: duration,
                threshold: 1.0
            )
        }

        return metrics
    }

    // MARK: - Performance Breakdown (for Context-Rich Responses)

    /// Record a sub-operation timing for breakdown analysis
    ///
    /// **LLM Guidance:** Use to track where time is spent within an operation
    ///
    /// - Parameters:
    ///   - operationId: Parent operation ID
    ///   - subOperation: Name of the sub-operation
    ///   - duration: Duration in seconds
    ///   - file: Source file (auto-captured)
    ///   - line: Source line (auto-captured)
    public func recordBreakdown(
        _ operationId: String,
        subOperation: String,
        duration: TimeInterval,
        file: String = #file,
        line: Int = #line
    ) {
        let filename = (file as NSString).lastPathComponent
        let item = PerformanceBreakdownItem(
            operation: subOperation,
            duration: duration,
            file: filename,
            line: line
        )

        performanceBreakdowns[operationId, default: []].append(item)
    }

    /// Get performance breakdown for an operation
    ///
    /// **LLM Guidance:** Use to identify bottlenecks in failed/slow operations
    ///
    /// - Parameter operationId: Operation identifier
    /// - Returns: Array of breakdown items, sorted by duration (slowest first)
    public func getBreakdown(_ operationId: String) -> [PerformanceBreakdownItem] {
        return performanceBreakdowns[operationId]?.sorted { $0.duration > $1.duration } ?? []
    }

    /// Clear breakdown data for an operation
    public func clearBreakdown(_ operationId: String) {
        performanceBreakdowns.removeValue(forKey: operationId)
    }

    /// Get metrics for a completed operation
    ///
    /// - Parameter operationId: Operation identifier
    /// - Returns: Metrics if found in history
    public func getMetrics(_ operationId: String) -> PerformanceMetrics? {
        return history.first { $0.operationId == operationId }
    }

    /// Get all tracked metrics
    ///
    /// **Token Cost:** ~N * 30 tokens where N = history size
    /// **LLM Guidance:** Use to analyze performance trends
    ///
    /// - Returns: Dictionary of operation ID to metrics
    public func getAllMetrics() -> [String: PerformanceMetrics] {
        var result: [String: PerformanceMetrics] = [:]
        for metrics in history {
            result[metrics.operationId] = metrics
        }
        return result
    }

    // MARK: - History Management

    /// Get recent performance history
    ///
    /// **Token Cost:** ~N * 30 tokens where N = limit
    /// **LLM Guidance:** Use to identify performance trends or regressions
    ///
    /// - Parameter limit: Maximum number of entries to return
    /// - Returns: Array of recent performance metrics (newest first)
    public func history(limit: Int = 10) -> [PerformanceMetrics] {
        return Array(history.prefix(limit))
    }

    /// Clear performance history
    ///
    /// **LLM Guidance:** Use to reset measurements between test runs
    public func clearHistory() {
        history.removeAll()
        activeOperations.removeAll()
    }

    /// Get aggregate statistics for operations by name
    ///
    /// **Token Cost:** ~50 tokens per operation type
    /// **LLM Guidance:** Use to identify slow operations
    ///
    /// - Returns: Dictionary of operation name to statistics
    public func statistics() -> [String: OperationStatistics] {
        var stats: [String: [TimeInterval]] = [:]

        for metrics in history {
            stats[metrics.name, default: []].append(metrics.duration)
        }

        var result: [String: OperationStatistics] = [:]
        for (name, durations) in stats {
            result[name] = OperationStatistics(
                name: name,
                count: durations.count,
                min: durations.min() ?? 0,
                max: durations.max() ?? 0,
                average: durations.reduce(0, +) / Double(durations.count),
                total: durations.reduce(0, +)
            )
        }

        return result
    }

    // MARK: - Private Helpers

    private func addToHistory(_ metrics: PerformanceMetrics) {
        history.insert(metrics, at: 0)

        // Limit history size
        if history.count > maxHistorySize {
            history.removeLast()
        }
    }

    #if canImport(os)
    private func currentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    #endif
}

// MARK: - Performance Metrics

/// Performance metrics for an operation
public struct PerformanceMetrics: Codable, Sendable, Identifiable {
    /// Unique identifier
    public let operationId: String

    /// Operation name (e.g., "snapshot(compact)", "tap", "action")
    public let name: String

    /// Start timestamp
    public let startTime: Date

    /// End timestamp
    public let endTime: Date

    /// Duration in seconds
    public let duration: TimeInterval

    /// Memory delta in bytes (optional, platform-dependent)
    public let memoryUsage: Int?

    /// CPU usage percentage (optional, disabled for performance)
    public let cpuUsage: Double?

    public var id: String { operationId }

    public init(
        operationId: String = UUID().uuidString,
        name: String,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        memoryUsage: Int? = nil,
        cpuUsage: Double? = nil
    ) {
        self.operationId = operationId
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
    }

    /// Human-readable description for LLMs (~15-20 tokens)
    public var description: String {
        let ms = Int(duration * 1000)
        var parts = ["\(name): \(ms)ms"]

        if let mem = memoryUsage, mem != 0 {
            let kb = mem / 1024
            if kb > 0 {
                parts.append("\(kb)KB")
            }
        }

        if let cpu = cpuUsage {
            parts.append("\(String(format: "%.1f", cpu))% CPU")
        }

        return parts.joined(separator: ", ")
    }

    /// Compact description for token efficiency (~10 tokens)
    public var compactDescription: String {
        let ms = Int(duration * 1000)
        return "\(name): \(ms)ms"
    }
}

// MARK: - Operation Statistics

/// Aggregate statistics for operations of the same type
public struct OperationStatistics: Sendable {
    /// Operation name
    public let name: String

    /// Number of measurements
    public let count: Int

    /// Minimum duration (seconds)
    public let min: TimeInterval

    /// Maximum duration (seconds)
    public let max: TimeInterval

    /// Average duration (seconds)
    public let average: TimeInterval

    /// Total duration (seconds)
    public let total: TimeInterval

    /// Human-readable description (~30 tokens)
    public var description: String {
        let avgMs = Int(average * 1000)
        let minMs = Int(min * 1000)
        let maxMs = Int(max * 1000)
        return "\(name): avg \(avgMs)ms (min \(minMs)ms, max \(maxMs)ms, n=\(count))"
    }

    /// Compact description (~15 tokens)
    public var compactDescription: String {
        let avgMs = Int(average * 1000)
        return "\(name): avg \(avgMs)ms (n=\(count))"
    }
}

// Note: PerformanceBreakdownItem is defined in HTTPTypes.swift

//
//  AwareCentralLogger.swift
//  Breathe
//
//  Centralized logging service for Aware framework.
//  Automatically correlates logs with UI snapshots and state for LLM-friendly debugging.
//
//  Key Features:
//  - Ring buffer (last 1000 entries)
//  - Auto-correlation with UI snapshots on errors
//  - Auto-capture state snapshots
//  - Query API with filtering
//  - LLM-friendly formatting
//

import Foundation

/// Centralized logger for Aware framework with UI/state correlation
@MainActor
public final class AwareCentralLogger: ObservableObject {
    public static let shared = AwareCentralLogger()

    // MARK: - Published State

    /// In-memory ring buffer (last 1000 entries)
    @Published public private(set) var entries: [AwareLogEntry] = []

    // MARK: - Configuration

    private let maxEntries = 1000

    /// Auto-capture UI snapshot ID on error/warning logs
    public var autoSnapshotOnError = true

    /// Auto-capture state snapshot on all logs
    public var autoStateCapture = true

    // MARK: - State

    /// Persistent storage (optional - for future persistence with GRDB)
    private let storage: AwareLogStorage?

    /// Entry lookup by ID
    private var entriesById: [String: AwareLogEntry] = [:]

    // MARK: - Initialization

    private init(storage: AwareLogStorage? = nil) {
        self.storage = storage
    }

    // MARK: - Public API

    /// Log an entry with automatic correlation
    /// - Returns: Log entry ID for later retrieval
    @discardableResult
    public func log(
        level: AwareLogLevel,
        component: String,
        message: String,
        error: Error? = nil,
        file: String = #file,
        line: Int = #line,
        function: String = #function,
        tags: [String] = []
    ) async -> String {
        // Determine if we should capture UI snapshot
        let shouldCaptureSnapshot = autoSnapshotOnError && (level == .error || level == .warning || level == .critical)
        let uiSnapshotId = shouldCaptureSnapshot ? await captureUISnapshot() : nil

        // Capture state snapshot if enabled
        let stateSnapshot = autoStateCapture ? await captureStateSnapshot() : nil

        // Create log entry
        let entry = AwareLogEntry(
            level: level,
            component: component,
            message: message,
            error: error,
            file: file,
            line: line,
            function: function,
            uiSnapshotId: uiSnapshotId,
            stateSnapshot: stateSnapshot,
            tags: tags
        )

        // Add to ring buffer
        addEntry(entry)

        // Persist if storage available
        if let storage = storage {
            do {
                try await storage.save(entry)
            } catch {
                // Log storage failure (but don't recurse!)
                print("AwareCentralLogger: Failed to persist log entry: \(error)")
            }
        }

        return entry.id
    }

    /// Query logs with filters
    public func query(_ query: AwareLogQuery) -> [AwareLogEntry] {
        var results = entries

        // Filter by time range
        if let startTime = query.startTime {
            results = results.filter { $0.timestamp >= startTime }
        }
        if let endTime = query.endTime {
            results = results.filter { $0.timestamp <= endTime }
        }

        // Filter by levels
        if let levels = query.levels {
            results = results.filter { levels.contains($0.level) }
        }

        // Filter by components
        if let components = query.components {
            results = results.filter { components.contains($0.component) }
        }

        // Filter by tags
        if let tags = query.tags {
            results = results.filter { entry in
                tags.contains(where: { entry.tags.contains($0) })
            }
        }

        // Filter by search text
        if let searchText = query.searchText, !searchText.isEmpty {
            results = results.filter { entry in
                entry.message.localizedCaseInsensitiveContains(searchText) ||
                (entry.error?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter by error presence
        if let hasError = query.hasError {
            results = results.filter { ($0.error != nil) == hasError }
        }

        // Filter by UI snapshot presence
        if let hasUISnapshot = query.hasUISnapshot {
            results = results.filter { ($0.uiSnapshotId != nil) == hasUISnapshot }
        }

        // Apply limit
        if let limit = query.limit {
            results = Array(results.prefix(limit))
        }

        return results
    }

    /// Get entry by ID
    public func getEntry(_ id: String) -> AwareLogEntry? {
        return entriesById[id]
    }

    /// Clear all log entries
    public func clear() {
        entries.removeAll()
        entriesById.removeAll()
    }

    /// Export logs in LLM-friendly format
    public func export() -> String {
        guard !entries.isEmpty else {
            return "No log entries"
        }

        let formatted = entries.map { $0.llmDescription }.joined(separator: "\n\n---\n\n")
        return """
        Aware Centralized Logs
        Total Entries: \(entries.count)

        \(formatted)
        """
    }

    // MARK: - Private Helpers

    private func addEntry(_ entry: AwareLogEntry) {
        // Add to ring buffer
        entries.append(entry)

        // Maintain max size
        if entries.count > maxEntries {
            if let removed = entries.first {
                entriesById.removeValue(forKey: removed.id)
            }
            entries.removeFirst()
        }

        // Index by ID
        entriesById[entry.id] = entry
    }

    private func captureUISnapshot() async -> String? {
        // TODO: Integrate with AwareSnapshotRenderer once available
        // For now, generate a placeholder ID
        return "snapshot-\(UUID().uuidString.prefix(8))"
    }

    private func captureStateSnapshot() async -> [String: String]? {
        // TODO: Integrate with Aware view registry once available
        // For now, return nil (state capture will be added in Phase 2)
        return nil
    }
}

/// Optional persistent storage (placeholder for future GRDB implementation)
@MainActor
public final class AwareLogStorage {
    // Placeholder for future GRDB integration
    // Will be implemented in Phase 1, Day 3-4

    public func save(_ entry: AwareLogEntry) async throws {
        // TODO: Implement GRDB persistence
    }

    public func query(_ query: AwareLogQuery) async throws -> [AwareLogEntry] {
        // TODO: Implement GRDB query
        return []
    }

    public func prune(olderThan: Date) async throws {
        // TODO: Implement GRDB pruning
    }
}
